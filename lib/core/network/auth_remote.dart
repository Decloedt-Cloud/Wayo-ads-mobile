import 'package:dio/dio.dart';

import '../config/auth_runtime_config.dart';
import '../constants/app_constants.dart' as ac;
import '../errors/auth_exceptions.dart';
import 'auth_oauth_extras.dart';
import '../result.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/models/auth_response.dart';
import 'interceptors/certificate_pinning.dart';

/// Authoritative verdict on whether an access token is still accepted by Auth_Wayo.
///
/// Used to decide if a 401 from a *downstream* API (e.g. Wayo-ads) reflects a
/// genuinely revoked session or just transient introspection flakiness.
enum TokenValidity {
  /// Auth_Wayo accepted the token — the session is alive.
  valid,

  /// Auth_Wayo rejected the token (401/403) — the session is revoked/expired.
  invalid,

  /// Could not determine (network/timeout/429/5xx) — must NOT force logout.
  indeterminate,
}

/// Stateless Auth_Wayo HTTP helpers without app [Dio] interceptors (avoids refresh recursion).
///
/// // TODO(dev): align paths and error payloads with Auth_Wayo production behavior.
class AuthRemote {
  AuthRemote._();

  /// Asks Auth_Wayo (the session owner) whether [accessToken] is still valid.
  ///
  /// Runs on a plain client (no interceptors) to avoid refresh/logout recursion.
  /// Only a real 401/403 maps to [TokenValidity.invalid]; everything transient
  /// maps to [TokenValidity.indeterminate] so callers never log out on a blip.
  static Future<TokenValidity> verifyAccessToken(String accessToken) async {
    if (accessToken.isEmpty) {
      return TokenValidity.invalid;
    }
    final client = _plainClient();
    final cfg = AuthRuntimeConfig.instance;
    final path = cfg.authHttpPath('user');
    final qp = <String, dynamic>{};
    if (cfg.authAppName.trim().isNotEmpty) {
      qp['app'] = cfg.authAppName.trim();
    }
    try {
      final res = await client.get<Map<String, dynamic>>(
        path,
        queryParameters: qp.isEmpty ? null : qp,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = res.data;
      if (data != null && data['success'] == false) {
        return TokenValidity.invalid;
      }
      return TokenValidity.valid;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return TokenValidity.invalid;
      }
      // Network/timeout/429/5xx — cannot conclude the session is dead.
      return TokenValidity.indeterminate;
    } catch (_) {
      return TokenValidity.indeterminate;
    } finally {
      client.close();
    }
  }

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
          if (ac.authOAuthRedirectUri.trim().isNotEmpty)
            'X-OAuth-Redirect-Uri': ac.authOAuthRedirectUri.trim(),
          if (ac.authOAuthClientId.trim().isNotEmpty)
            'X-OAuth-Client-Id': ac.authOAuthClientId.trim(),
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
        data: mergeWayoAuthPayload({'refresh_token': refreshToken}),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
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

  static Future<Result<AuthResponse>> refreshFromStorage(
    SecureStorageService storage,
  ) async {
    const maxAttempts = 4;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final access = await storage.getAccessToken();
      final refreshToken = await storage.getRefreshToken();
      if (access == null ||
          access.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        final b = AuthRuntimeConfig.instance.resolvedDioBaseUrl;
        return Failure(ServerException('Missing tokens ($b)'));
      }

      final result = await AuthRemote.refresh(
        accessToken: access,
        refreshToken: refreshToken,
      );
      switch (result) {
        case Success():
          return result;
        case Failure(:final error):
          if (error is SessionInvalidException) {
            return result;
          }
          final canRetry =
              attempt < maxAttempts - 1 && _isTransientRefreshFailure(error);
          if (canRetry) {
            final wait = _refreshRetryDelaySeconds(error, attempt);
            await Future<void>.delayed(Duration(seconds: wait));
            continue;
          }
          return result;
      }
    }
    return const Failure(NetworkException('Refresh failed after retries'));
  }

  static bool _isTransientRefreshFailure(AuthException error) {
    if (error is RateLimitedException || error is NetworkException) {
      return true;
    }
    if (error is ServerException) {
      final c = error.statusCode;
      return c != null && c >= 500;
    }
    return false;
  }

  static int _refreshRetryDelaySeconds(AuthException error, int zeroBasedAttempt) {
    if (error is RateLimitedException) {
      return error.retryAfterSeconds.clamp(1, 90);
    }
    return (zeroBasedAttempt + 1).clamp(1, 8);
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
    if (status == 429) {
      return RateLimitedException(
        retryAfterSeconds: _parseRetryAfterSeconds(e),
      );
    }
    if (status == 422) {
      return InvalidCredentialsException(message);
    }
    return ServerException(message, status);
  }

  static int _parseRetryAfterSeconds(DioException e) {
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
}
