import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/request_flags.dart';
import '../../../../core/result.dart';

final passwordResetRemoteDataSourceProvider =
    Provider<PasswordResetRemoteDataSource>((ref) {
      return PasswordResetRemoteDataSource(ref.watch(dioProvider));
    });

/// Calls Auth_Wayo `POST /api/auth/forgot-password|verify-otp|reset-password`.
class PasswordResetRemoteDataSource {
  PasswordResetRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Result<int>> sendOtp(String email) async {
    try {
      final path = AuthRuntimeConfig.instance.authHttpPath('forgot-password');
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'email': email},
        options: Options(
          extra: {kSkipAuthInjection: true, kDisableSmartRetry: true},
        ),
      );
      final data = res.data;
      if (data == null) {
        return const Failure(ServerException('Empty response'));
      }
      if (data['success'] != true) {
        final msg = data['message'] as String? ?? 'Request failed';
        return Failure(InvalidCredentialsException(msg));
      }
      final inner = data['data'];
      final ttl = inner is Map && inner['ttl'] is num
          ? (inner['ttl'] as num).toInt()
          : 600;
      return Success(ttl);
    } on DioException catch (e) {
      return Failure(_mapDio(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  Future<Result<({String resetToken, int expiresIn})>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final path = AuthRuntimeConfig.instance.authHttpPath('verify-otp');
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'email': email, 'otp': otp},
        options: Options(
          extra: {kSkipAuthInjection: true, kDisableSmartRetry: true},
        ),
      );
      final data = res.data;
      if (data == null) {
        return const Failure(ServerException('Empty response'));
      }
      if (data['success'] != true) {
        final msg = data['message'] as String? ?? 'Verification failed';
        return Failure(InvalidCredentialsException(msg));
      }
      final inner = data['data'];
      if (inner is! Map<String, dynamic>) {
        return const Failure(ServerException('Invalid response'));
      }
      final token = inner['reset_token'] as String?;
      if (token == null || token.isEmpty) {
        return const Failure(ServerException('Missing reset_token'));
      }
      final expiresIn = (inner['expires_in'] as num?)?.toInt() ?? 900;
      return Success((resetToken: token, expiresIn: expiresIn));
    } on DioException catch (e) {
      return Failure(_mapDio(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  Future<Result<bool>> resetPassword({
    required String resetToken,
    required String password,
  }) async {
    try {
      final path = AuthRuntimeConfig.instance.authHttpPath('reset-password');
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'reset_token': resetToken,
          'password': password,
          'password_confirmation': password,
        },
        options: Options(
          extra: {kSkipAuthInjection: true, kDisableSmartRetry: true},
        ),
      );
      final data = res.data;
      if (data == null) {
        return const Failure(ServerException('Empty response'));
      }
      if (data['success'] != true) {
        final msg = data['message'] as String? ?? 'Reset failed';
        return Failure(ServerException(msg));
      }
      return const Success(true);
    } on DioException catch (e) {
      return Failure(_mapDio(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  AuthException _mapDio(DioException e) {
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
    if (status == 404) {
      return EmailNotRegisteredException(message);
    }
    if (status == 429) {
      return RateLimitedException(
        retryAfterSeconds: _parseRetryAfterSeconds(e, message),
      );
    }
    if (status == 401 || status == 422) {
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
  return 60;
}
