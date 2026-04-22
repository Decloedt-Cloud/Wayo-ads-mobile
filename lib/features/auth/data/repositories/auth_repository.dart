import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_remote.dart';
import '../../../../core/network/request_flags.dart';
import '../../../../core/result.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/app_user.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';

part 'auth_repository.g.dart';

abstract class IAuthRepository {
  Future<Result<AuthResponse>> login({
    required String email,
    required String password,
  });
  Future<Result<AuthResponse>> loginWithGoogle({required String idToken});
  Future<Result<AuthResponse>> refresh({required String refreshToken});

  /// GET `/api/auth/user?app=…` — refreshes [AppUser] (roles, name) without new tokens.
  Future<Result<AppUser>> fetchCurrentUser();

  Future<void> logout();
}

@Riverpod(keepAlive: true)
IAuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureStorageProvider),
  );
}

// TODO(dev): confirm Auth_Wayo JSON error format and HTTP codes for login/logout edge cases.
class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl({required Dio dio, required SecureStorageService storage})
    : _dio = dio,
      _storage = storage;

  final Dio _dio;
  final SecureStorageService _storage;

  @override
  Future<Result<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final path = AuthRuntimeConfig.instance.authHttpPath('login');
      final loginOptions = Options(extra: {kSkipAuthInjection: true})
        ..disableRetry = true;
      final cfg = AuthRuntimeConfig.instance;
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: LoginRequest(
          email: email,
          password: password,
          app: cfg.authAppName.isNotEmpty ? cfg.authAppName : null,
          appKey: cfg.wayoAdsAppKey.isNotEmpty ? cfg.wayoAdsAppKey : null,
        ).toJson(),
        options: loginOptions,
      );
      final data = res.data;
      if (data == null) {
        return const Failure(ServerException('Empty response'));
      }
      if (data['success'] == false) {
        final msg = data['message'] as String? ?? 'Login failed';
        return Failure(InvalidCredentialsException(msg));
      }
      return Success(AuthResponse.fromJson(data));
    } on DioException catch (e) {
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  @override
  Future<Result<AuthResponse>> loginWithGoogle({
    required String idToken,
  }) async {
    try {
      final cfg = AuthRuntimeConfig.instance;
      final body = <String, dynamic>{
        'id_token': idToken,
        if (cfg.authAppName.isNotEmpty) 'app': cfg.authAppName,
        if (cfg.wayoAdsAppKey.isNotEmpty) 'app_key': cfg.wayoAdsAppKey,
      };
      final path = AuthRuntimeConfig.instance.authHttpPath('google');
      final googleOptions = Options(extra: {kSkipAuthInjection: true})
        ..disableRetry = true;
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: googleOptions,
      );
      final data = res.data;
      if (data == null) {
        return const Failure(ServerException('Empty response'));
      }
      if (data['success'] == false) {
        final msg = data['message'] as String? ?? 'Google sign-in failed';
        return Failure(InvalidCredentialsException(msg));
      }
      return Success(AuthResponse.fromJson(data));
    } on DioException catch (e) {
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  @override
  Future<Result<AppUser>> fetchCurrentUser() async {
    try {
      final cfg = AuthRuntimeConfig.instance;
      final path = cfg.authHttpPath('user');
      final qp = <String, dynamic>{};
      if (cfg.authAppName.trim().isNotEmpty) {
        qp['app'] = cfg.authAppName.trim();
      }
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: qp.isEmpty ? null : qp,
      );
      final data = res.data;
      if (data == null) {
        return const Failure(ServerException('Empty user response'));
      }
      if (data['success'] == false) {
        final msg = data['message'] as String? ?? 'Unauthorized';
        return Failure(InvalidCredentialsException(msg));
      }
      final root = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      final userRaw = root['user'];
      if (userRaw is! Map<String, dynamic>) {
        return const Failure(ServerException('Invalid user payload'));
      }
      return Success(AppUser.fromJson(userRaw));
    } on DioException catch (e) {
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  @override
  Future<Result<AuthResponse>> refresh({required String refreshToken}) async {
    final access = await _storage.getAccessToken();
    if (access == null || access.isEmpty) {
      return const Failure(ServerException('Missing access token'));
    }
    return AuthRemote.refresh(accessToken: access, refreshToken: refreshToken);
  }

  @override
  Future<void> logout() async {
    try {
      final path = AuthRuntimeConfig.instance.authHttpPath('logout');
      await _dio.post<Map<String, dynamic>>(
        path,
        options: Options(extra: {kSkipAuthInjection: false}),
      );
    } catch (_) {
      // Fire-and-forget: ignore network failures on logout.
    }
  }

  AuthException _mapDioLogin(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    final status = e.response?.statusCode;
    final body = e.response?.data;
    var message = e.message ?? 'Request failed';
    if (body is Map && body['message'] is String) {
      message = body['message'] as String;
    }
    if (status == 429) {
      return RateLimitedException(
        retryAfterSeconds: _parseRetryAfterSeconds(e, message),
      );
    }
    if (status == 401 || status == 422) {
      return InvalidCredentialsException(message);
    }
    if (status == 403) {
      return InvalidCredentialsException(message);
    }
    return ServerException(message);
  }
}

int _parseRetryAfterSeconds(DioException e, String message) {
  final data = e.response?.data;
  if (data is Map) {
    final r = data['retry_after'];
    if (r is int) return r.clamp(1, 86400);
    if (r is num) return r.toInt().clamp(1, 86400);
    if (r is String) {
      final p = int.tryParse(r);
      if (p != null) return p.clamp(1, 86400);
    }
  }
  final header = e.response?.headers.value('retry-after');
  final fromHeader = int.tryParse(header ?? '');
  if (fromHeader != null && fromHeader > 0) {
    return fromHeader.clamp(1, 86400);
  }
  final match = RegExp(
    r'(\d+)\s*(second|seconds|sec|minute|minutes|min)\b',
    caseSensitive: false,
  ).firstMatch(message);
  if (match != null) {
    final n = int.tryParse(match.group(1) ?? '') ?? 60;
    final unit = (match.group(2) ?? 's').toLowerCase();
    if (unit.startsWith('min')) {
      return (n * 60).clamp(1, 86400);
    }
    return n.clamp(1, 86400);
  }
  return 60;
}
