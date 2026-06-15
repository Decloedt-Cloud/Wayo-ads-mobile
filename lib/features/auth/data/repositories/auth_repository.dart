import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_oauth_extras.dart';
import '../../../../core/network/auth_remote.dart';
import '../../../../core/network/request_flags.dart';
import '../../../../core/result.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/app_user.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../../domain/wayo_ads_account_role.dart';

part 'auth_repository.g.dart';

abstract class IAuthRepository {
  Future<Result<AuthResponse>> login({
    required String email,
    required String password,
    bool forceWebLogout = false,
  });
  Future<Result<AuthResponse>> loginWithGoogle({
    required String idToken,
    bool forceWebLogout = false,
  });
  Future<Result<AuthResponse>> loginWithApple({
    required String identityToken,
    required String rawNonce,
    String? authorizationCode,
    String? appleUserId,
    bool forceWebLogout = false,
  });
  Future<Result<AuthResponse>> refresh({required String refreshToken});

  /// GET `/api/auth/user?app=…` — refreshes [AppUser] (roles, name) without new tokens.
  Future<Result<AppUser>> fetchCurrentUser();

  /// Binds `CREATOR` or `ADVERTISER` for [AUTH_APP_NAME].
  /// Tries `POST …/api/auth/wayo-ads/role` on Auth; on **404** falls back to
  /// `POST {WAYO_ADS_API_BASE_URL}/api/user/role` (Next) if `WAYO_ADS_API_BASE_URL` is set.
  Future<Result<AppUser>> setWayoAdsAppRole(String role);

  /// Sends the verification email: `POST …/api/auth/resend-verification` with `{ email, app? }`
  /// (same as Wayo-ads web → Auth). If [email] is null/empty, uses [fetchCurrentUser].
  /// On **404** (legacy): `email/verify/send` with `{ app? }`, then **404** → Next
  /// `api/auth/resend-verification` if `WAYO_ADS_API_BASE_URL` is set.
  Future<Result<int>> sendEmailVerificationOtp({String? email});

  /// Verifies the code: `POST …/api/auth/verify-email` with `{ email, code }` (Auth + web).
  /// If [email] is null/empty, uses [fetchCurrentUser]. On **404**: legacy
  /// `email/verify/confirm` with `{ otp }`, then **404** → Next `api/auth/verify-email`.
  Future<Result<AppUser>> confirmEmailAddressOtp(String otp, {String? email});

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

  Future<Result<AppUser>>? _fetchCurrentUserInFlight;

  /// Static deduplicator for Google login — prevents multiple concurrent API calls
  /// (e.g. if the user double-taps or the widget rebuilds during login).
  static Future<Result<AuthResponse>>? _googleLoginInFlight;

  /// Static deduplicator for Apple login.
  static Future<Result<AuthResponse>>? _appleLoginInFlight;

  /// Last successful [fetchCurrentUser] result + timestamp for short TTL cache.
  Result<AppUser>? _lastFetchCurrentUserResult;
  DateTime? _lastFetchCurrentUserTime;

  /// TTL for cached [fetchCurrentUser] result (avoids rate limits on rapid refreshes).
  /// Set to 15 seconds to give more buffer against 429 during post-login flows.
  static const Duration _fetchCurrentUserCacheTtl = Duration(seconds: 15);

  @override
  Future<Result<AuthResponse>> login({
    required String email,
    required String password,
    bool forceWebLogout = false,
  }) async {
    try {
      final path = AuthRuntimeConfig.instance.authHttpPath('login');
      final loginOptions = Options(extra: {kSkipAuthInjection: true})
        ..disableRetry = true;
      final cfg = AuthRuntimeConfig.instance;
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: mergeWayoAuthPayload(
          LoginRequest(
            email: email,
            password: password,
            app: cfg.authAppName.isNotEmpty ? cfg.authAppName : null,
            appKey: cfg.wayoAdsAppKey.isNotEmpty ? cfg.wayoAdsAppKey : null,
            forceWebLogout: forceWebLogout,
          ).toJson(),
        ),
        options: loginOptions,
      );
      final data = res.data;
      if (data == null) {
        return const Failure(ServerException('Empty response'));
      }
      final conflict = _parseWebSessionConflict(data);
      if (conflict != null) {
        return Failure(conflict);
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
    bool forceWebLogout = false,
  }) {
    final existing = _googleLoginInFlight;
    if (existing != null) {
      return existing;
    }
    final runner = _loginWithGoogleOnce(
      idToken,
      forceWebLogout: forceWebLogout,
    );
    _googleLoginInFlight = runner;
    return runner.whenComplete(() {
      if (identical(_googleLoginInFlight, runner)) {
        _googleLoginInFlight = null;
      }
    });
  }

  Future<Result<AuthResponse>> _loginWithGoogleOnce(
    String idToken, {
    bool forceWebLogout = false,
  }) async {
    try {
      final cfg = AuthRuntimeConfig.instance;
      final body = mergeWayoAuthPayload(<String, dynamic>{
        'id_token': idToken,
        if (cfg.authAppName.isNotEmpty) 'app': cfg.authAppName,
        if (cfg.wayoAdsAppKey.isNotEmpty) 'app_key': cfg.wayoAdsAppKey,
        if (forceWebLogout) 'force_web_logout': true,
      });
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
      final conflict = _parseWebSessionConflict(data);
      if (conflict != null) {
        return Failure(conflict);
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
  Future<Result<AuthResponse>> loginWithApple({
    required String identityToken,
    required String rawNonce,
    String? authorizationCode,
    String? appleUserId,
    bool forceWebLogout = false,
  }) {
    final existing = _appleLoginInFlight;
    if (existing != null) {
      return existing;
    }
    final runner = _loginWithAppleOnce(
      identityToken: identityToken,
      rawNonce: rawNonce,
      authorizationCode: authorizationCode,
      appleUserId: appleUserId,
      forceWebLogout: forceWebLogout,
    );
    _appleLoginInFlight = runner;
    return runner.whenComplete(() {
      if (identical(_appleLoginInFlight, runner)) {
        _appleLoginInFlight = null;
      }
    });
  }

  Future<Result<AuthResponse>> _loginWithAppleOnce({
    required String identityToken,
    required String rawNonce,
    String? authorizationCode,
    String? appleUserId,
    bool forceWebLogout = false,
  }) async {
    try {
      final cfg = AuthRuntimeConfig.instance;
      final body = mergeWayoAuthPayload(<String, dynamic>{
        'identity_token': identityToken,
        'id_token': identityToken,
        'nonce': rawNonce,
        if (authorizationCode != null && authorizationCode.isNotEmpty)
          'authorization_code': authorizationCode,
        if (appleUserId != null && appleUserId.isNotEmpty)
          'apple_user_id': appleUserId,
        if (cfg.authAppName.isNotEmpty) 'app': cfg.authAppName,
        if (cfg.wayoAdsAppKey.isNotEmpty) 'app_key': cfg.wayoAdsAppKey,
        if (forceWebLogout) 'force_web_logout': true,
      });
      final path = AuthRuntimeConfig.instance.authHttpPath('apple');
      final appleOptions = Options(
        extra: {kSkipAuthInjection: true},
        // Auth_Wayo may return 503 with JSON `{ success: false, message: … }`.
        validateStatus: (status) => status != null && status < 600,
      )..disableRetry = true;
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: appleOptions,
      );
      final data = res.data;
      if (data == null) {
        return const Failure(ServerException('Empty response'));
      }
      final conflict = _parseWebSessionConflict(data);
      if (conflict != null) {
        return Failure(conflict);
      }
      if (data['success'] == false) {
        final msg = data['message'] as String? ?? 'Apple sign-in failed';
        return Failure(InvalidCredentialsException(msg));
      }
      final code = res.statusCode ?? 0;
      if (code >= 400) {
        final msg = data['message'] as String? ?? 'Apple sign-in failed';
        return Failure(ServerException(msg, code));
      }
      return Success(AuthResponse.fromJson(data));
    } on DioException catch (e) {
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  @override
  Future<Result<AppUser>> fetchCurrentUser() {
    // Return cached result if fresh enough (avoids rapid-fire requests hitting rate limits).
    final cached = _lastFetchCurrentUserResult;
    final cachedAt = _lastFetchCurrentUserTime;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _fetchCurrentUserCacheTtl) {
      return Future.value(cached);
    }

    final existing = _fetchCurrentUserInFlight;
    if (existing != null) {
      return existing;
    }
    final runner = _fetchCurrentUserWith429Retry();
    _fetchCurrentUserInFlight = runner;
    return runner.whenComplete(() {
      if (identical(_fetchCurrentUserInFlight, runner)) {
        _fetchCurrentUserInFlight = null;
      }
    });
  }

  /// One in-flight `GET /api/auth/user` for the whole app + bounded 429 backoff.
  Future<Result<AppUser>> _fetchCurrentUserWith429Retry() async {
    const maxAttempts = 4;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final once = await _fetchCurrentUserOnce();
      switch (once) {
        case Success():
          _lastFetchCurrentUserResult = once;
          _lastFetchCurrentUserTime = DateTime.now();
          return once;
        case Failure(:final error):
          final isLast = attempt >= maxAttempts - 1;
          if (error is RateLimitedException && !isLast) {
            final wait = error.retryAfterSeconds.clamp(1, 90);
            await Future<void>.delayed(Duration(seconds: wait));
            continue;
          }
          return once;
      }
    }
    return const Failure(ServerException('Profile fetch failed'));
  }

  Future<Result<AppUser>> _fetchCurrentUserOnce() async {
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
  Future<Result<AppUser>> setWayoAdsAppRole(String role) async {
    final cfg = AuthRuntimeConfig.instance;
    try {
      return await _postAuthWayoAdsRole(cfg, role);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _setWayoAdsRoleViaWayoAdsNextFallback(role);
      }
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  Future<Result<AppUser>> _postAuthWayoAdsRole(
    AuthRuntimeConfig cfg,
    String role,
  ) async {
    final path = cfg.authHttpPath('wayo-ads/role');
    final res = await _dio.post<Map<String, dynamic>>(
      path,
      data: mergeWayoAuthPayload(<String, dynamic>{
        'role': role,
        if (cfg.authAppName.isNotEmpty) 'app': cfg.authAppName,
        if (cfg.wayoAdsAppKey.isNotEmpty) 'app_key': cfg.wayoAdsAppKey,
      }),
      options: Options(extra: {kSkipAuthInjection: false})..disableRetry = true,
    );
    final data = res.data;
    if (data == null) {
      return const Failure(ServerException('Empty response'));
    }
    if (data['success'] == false) {
      final msg = data['message'] as String? ?? 'Request failed';
      return Failure(InvalidCredentialsException(msg));
    }
    final inner = data['data'];
    if (inner is Map<String, dynamic>) {
      final u = inner['user'];
      if (u is Map<String, dynamic>) {
        return Success(AppUser.fromJson(u));
      }
    }
    return _finishSetRoleWithFetch(role);
  }

  /// Refreshes from Auth; if `app_roles` is still empty, keep the chosen [role] in session.
  Future<Result<AppUser>> _finishSetRoleWithFetch(String role) async {
    final u = await fetchCurrentUser();
    return u.when(
      success: (data) => Success(_mergeRoleIfUnknown(data, role)),
      failure: (error) => Failure(error),
    );
  }

  AppUser _mergeRoleIfUnknown(AppUser user, String role) {
    if (user.wayoAdsRole != WayoAdsAccountRole.unknown) {
      return user;
    }
    return user.withWayoAdsRolePatchedFromApiString(role);
  }

  /// `POST {WAYO_ADS}/api/user/role` (Next) when Laravel `api/auth/wayo-ads/role` is missing (404).
  Future<Result<AppUser>> _setWayoAdsRoleViaWayoAdsNextFallback(
    String role,
  ) async {
    final cfg = AuthRuntimeConfig.instance;
    final abs = cfg.explicitWayoAdsAbsoluteUrl('api/user/role');
    if (abs == null || abs.isEmpty) {
      return const Failure(
        ServerException(
          'Auth has no wayo-ads/role route (404). Set WAYO_ADS_API_BASE_URL to your '
          'Wayo-ads (Next) origin, or implement POST /api/auth/wayo-ads/role on Auth_Wayo.',
        ),
      );
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        abs,
        data: <String, dynamic>{'role': role},
        options: Options(extra: {kSkipAuthInjection: false})
          ..disableRetry = true,
      );
      final data = res.data;
      if (data is Map<String, dynamic> && data['success'] == false) {
        final msg = data['message'] as String? ?? 'Request failed';
        return Failure(InvalidCredentialsException(msg));
      }
      return _finishSetRoleWithFetch(role);
    } on DioException catch (e) {
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  Future<Result<String>> _emailForVerificationRequest(String? email) async {
    final direct = email?.trim() ?? '';
    if (direct.isNotEmpty) {
      return Success(direct);
    }
    return (await fetchCurrentUser()).when(
      success: (user) {
        final e = user.email.trim();
        if (e.isEmpty) {
          return const Failure(
            ServerException('No email on account for verification'),
          );
        }
        return Success(e);
      },
      failure: (e) => Failure(e),
    );
  }

  @override
  Future<Result<int>> sendEmailVerificationOtp({String? email}) async {
    final em = await _emailForVerificationRequest(email);
    return em.when(
      success: (resolved) => _postResendVerification(resolved),
      failure: (e) => Failure(e),
    );
  }

  /// `POST /api/auth/resend-verification` — same contract as Wayo-ads `resend-verification` API route.
  Future<Result<int>> _postResendVerification(String email) async {
    final cfg = AuthRuntimeConfig.instance;
    try {
      final path = cfg.authHttpPath('resend-verification');
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: mergeWayoAuthPayload(<String, dynamic>{
          'email': email,
          if (cfg.authAppName.isNotEmpty) 'app': cfg.authAppName,
        }),
        options: Options(extra: {kSkipAuthInjection: false})
          ..disableRetry = true,
      );
      return _parseSendEmailOtpResponse(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _postLegacyEmailVerifySend();
      }
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  /// Older Auth: `api/auth/email/verify/send` (body was `{ app }` only, user from token).
  Future<Result<int>> _postLegacyEmailVerifySend() async {
    final cfg = AuthRuntimeConfig.instance;
    try {
      final path = cfg.authHttpPath('email/verify/send');
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: mergeWayoAuthPayload(<String, dynamic>{
          if (cfg.authAppName.isNotEmpty) 'app': cfg.authAppName,
        }),
        options: Options(extra: {kSkipAuthInjection: false})
          ..disableRetry = true,
      );
      return _parseSendEmailOtpResponse(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _sendEmailOtpViaWayoAdsNext();
      }
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  Result<int> _parseSendEmailOtpResponse(Map<String, dynamic>? data) {
    if (data == null) {
      return const Failure(ServerException('Empty response'));
    }
    if (data['success'] == false) {
      final msg = data['message'] as String? ?? 'Request failed';
      return Failure(InvalidCredentialsException(msg));
    }
    final inner = data['data'];
    final ttl = inner is Map && inner['ttl'] is num
        ? (inner['ttl'] as num).toInt()
        : 60;
    return Success(ttl.clamp(30, 3600));
  }

  Future<Result<int>> _sendEmailOtpViaWayoAdsNext() async {
    final abs = AuthRuntimeConfig.instance.explicitWayoAdsAbsoluteUrl(
      'api/auth/resend-verification',
    );
    if (abs == null || abs.isEmpty) {
      return const Failure(
        ServerException(
          'Auth has no resend-verification (404). Set WAYO_ADS_API_BASE_URL to your '
          'Wayo-ads origin, or implement POST /api/auth/resend-verification on Auth.',
        ),
      );
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        abs,
        options: Options(extra: {kSkipAuthInjection: false})
          ..disableRetry = true,
      );
      return _parseSendEmailOtpResponse(res.data);
    } on DioException catch (e) {
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  @override
  Future<Result<AppUser>> confirmEmailAddressOtp(
    String otp, {
    String? email,
  }) async {
    final em = await _emailForVerificationRequest(email);
    return em.when(
      success: (resolved) => _confirmEmailVerifyLaravel(resolved, otp),
      failure: (e) => Failure(e),
    );
  }

  /// Same as Wayo-ads: `POST …/api/auth/verify-email` with `{ email, code }`.
  Future<Result<AppUser>> _confirmEmailVerifyLaravel(
    String email,
    String otp,
  ) async {
    final code = otp.trim();
    try {
      final path = AuthRuntimeConfig.instance.authHttpPath('verify-email');
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: mergeWayoAuthPayload(<String, dynamic>{'email': email, 'code': code}),
        options: Options(extra: {kSkipAuthInjection: false})
          ..disableRetry = true,
      );
      return await _parseConfirmEmailOtpResponse(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _confirmEmailLegacyOtpBody(code);
      }
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  Future<Result<AppUser>> _confirmEmailLegacyOtpBody(String otp) async {
    try {
      final path = AuthRuntimeConfig.instance.authHttpPath(
        'email/verify/confirm',
      );
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: mergeWayoAuthPayload(<String, dynamic>{'otp': otp}),
        options: Options(extra: {kSkipAuthInjection: false})
          ..disableRetry = true,
      );
      return await _parseConfirmEmailOtpResponse(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _confirmEmailOtpViaWayoAdsNext(otp);
      }
      return Failure(_mapDioLogin(e));
    } catch (e) {
      return Failure(ServerException('$e'));
    }
  }

  Future<Result<AppUser>> _parseConfirmEmailOtpResponse(
    Map<String, dynamic>? data,
  ) async {
    if (data == null) {
      return const Failure(ServerException('Empty response'));
    }
    if (data['success'] == false) {
      final msg = data['message'] as String? ?? 'Verification failed';
      return Failure(InvalidCredentialsException(msg));
    }
    final inner = data['data'];
    if (inner is Map<String, dynamic>) {
      final u = inner['user'];
      if (u is Map<String, dynamic>) {
        return Success(AppUser.fromJson(u));
      }
    }
    return fetchCurrentUser();
  }

  Future<Result<AppUser>> _confirmEmailOtpViaWayoAdsNext(String otp) async {
    final abs = AuthRuntimeConfig.instance.explicitWayoAdsAbsoluteUrl(
      'api/auth/verify-email',
    );
    if (abs == null || abs.isEmpty) {
      return const Failure(
        ServerException(
          'Auth has no verify-email / email/verify/confirm (404). Set WAYO_ADS_API_BASE_URL '
          'or implement POST /api/auth/verify-email on Auth.',
        ),
      );
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        abs,
        data: <String, dynamic>{'code': otp},
        options: Options(extra: {kSkipAuthInjection: false})
          ..disableRetry = true,
      );
      final data = res.data;
      if (data is Map<String, dynamic> && data['success'] == false) {
        final msg =
            data['message'] as String? ??
            data['error'] as String? ??
            'Verification failed';
        return Failure(InvalidCredentialsException(msg));
      }
      return await fetchCurrentUser();
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
      final oauthBody = wayoAuthOAuthJsonExtras();
      await _dio.post<Map<String, dynamic>>(
        path,
        data: oauthBody.isEmpty ? null : oauthBody,
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
    if (body is Map<String, dynamic>) {
      final conflict = _parseWebSessionConflict(body);
      if (conflict != null) {
        return conflict;
      }
    } else if (body is Map) {
      final conflict = _parseWebSessionConflict(body.cast<String, dynamic>());
      if (conflict != null) {
        return conflict;
      }
    }
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
    return ServerException(message, status);
  }

  WebSessionActiveException? _parseWebSessionConflict(Map<String, dynamic> data) {
    final code = data['code'];
    if (code != 'WEB_SESSION_ACTIVE') {
      return null;
    }
    final message = data['message'] as String?;
    final logoutUrl = data['web_logout_url'] as String?;
    return WebSessionActiveException(
      message: message ??
          'You are already signed in on the Wayo Ads website. Sign out from the web before signing in on the app.',
      logoutUrl: logoutUrl,
    );
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
