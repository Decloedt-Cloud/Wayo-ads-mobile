import 'package:dio/dio.dart';

import '../config/auth_runtime_config.dart';
import '../errors/auth_exceptions.dart';
import '../result.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/models/auth_response.dart';
import 'interceptors/certificate_pinning.dart';

/// Stateless Auth_Wayo HTTP helpers without app [Dio] interceptors (avoids refresh recursion).
///
/// // TODO(dev): align paths and error payloads with Auth_Wayo production behavior.
class AuthRemote {
  AuthRemote._();

  static Dio _plainClient() {
    final runtime = AuthRuntimeConfig.instance;
    final base = runtime.resolvedDioBaseUrl;
    final client = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Client': 'wayo-ads-go',
          'X-Client-Version': runtime.effectiveAppRelease,
        },
      ),
    );
    CertificatePinning.attach(
      client,
      pinnedSha256Base64: runtime.mergedPinnedSha256Base64,
    );
    return client;
  }

  static Future<Result<AuthResponse>> refresh({
    required String accessToken,
    required String refreshToken,
  }) async {
    final client = _plainClient();
    final path = AuthRuntimeConfig.instance.authHttpPath('refresh');
    try {
      final res = await client.post<Map<String, dynamic>>(
        path,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      final data = res.data;
      if (data == null) {
        return const Failure(ServerException('Invalid auth response'));
      }
      return Success(AuthResponse.fromJson(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Failure(SessionInvalidException());
      }
      return Failure(_mapDio(e));
    } catch (_) {
      return const Failure(NetworkException('Unexpected error during refresh'));
    } finally {
      client.close();
    }
  }

  static Future<Result<AuthResponse>> refreshFromStorage(SecureStorageService storage) async {
    final access = await storage.getAccessToken();
    final refreshToken = await storage.getRefreshToken();
    if (access == null || access.isEmpty || refreshToken == null || refreshToken.isEmpty) {
      final b = AuthRuntimeConfig.instance.resolvedDioBaseUrl;
      return Failure(ServerException('Missing tokens ($b)'));
    }
    return AuthRemote.refresh(accessToken: access, refreshToken: refreshToken);
  }

  static AuthException _mapDio(DioException e) {
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
    if (status == 422) {
      return InvalidCredentialsException(message);
    }
    return ServerException(message);
  }
}
