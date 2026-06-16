import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/auth_exceptions.dart';
import '../result.dart';
import '../storage/secure_storage.dart';
import 'auth_force_logout_hub.dart';
import 'auth_remote.dart';
import 'request_flags.dart';
import 'session_expired_exception.dart';

/// Injects Bearer tokens, refreshes once on 401, and queues concurrent refresh attempts.
///
/// Key behaviors:
/// 1. Concurrent refresh attempts are serialized via [_refreshCompleter]
/// 2. After transient refresh failures, a short cooldown prevents refresh spam
/// 3. Only permanent failures (refresh 401) trigger force logout
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.storage, required this.dio});

  final SecureStorageService storage;
  final Dio dio;

  /// Serializes concurrent token refresh attempts across all requests.
  static Completer<void>? _refreshCompleter;

  /// After a transient refresh failure, block further attempts briefly.
  static DateTime? _refreshCooldownUntil;

  /// When the current session started (login). Used to avoid force-logout on a
  /// transient 401 in the brief window right after sign-in.
  static DateTime? _sessionStartedAt;

  /// Grace window after login during which a no-refresh-token 401 does NOT
  /// force logout (covers token-propagation races).
  static const Duration _postLoginGrace = Duration(seconds: 4);

  /// Reset state after successful login (clears any stale cooldown).
  static void resetSessionState() {
    _refreshCooldownUntil = null;
    _refreshCompleter = null;
    _sessionStartedAt = DateTime.now();
  }

  static bool get _pastPostLoginGrace {
    final started = _sessionStartedAt;
    return started == null ||
        DateTime.now().difference(started) > _postLoginGrace;
  }

  bool get _inCooldown {
    final until = _refreshCooldownUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (options.extra[kSkipAuthInjection] == true) {
        return handler.next(options);
      }

      // Wait on any in-progress refresh (unless this is an auth retry).
      if (options.extra[kAuthRetry] != true) {
        final waitOn = _refreshCompleter;
        if (waitOn != null) {
          try {
            await waitOn.future;
          } catch (_) {
            // Refresh failed; proceed with current token anyway.
          }
        }
      }

      var token = await storage.getAccessToken();

      // Proactive refresh if token is about to expire (and not in cooldown).
      if (token != null &&
          token.isNotEmpty &&
          !_inCooldown &&
          await storage.shouldRefreshAccessToken()) {
        try {
          await _runSerializedRefresh();
          token = await storage.getAccessToken();
        } on SessionExpiredException catch (e) {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: e,
              type: DioExceptionType.unknown,
            ),
          );
        } catch (_) {
          // Transient refresh failure — still attempt with current bearer below.
        }
      }

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else if (kDebugMode) {
        debugPrint('[auth] No token for ${options.uri.path}');
      }
      handler.next(options);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[auth] onRequest exception for ${options.uri.path}: $e\n$st');
      }
      // Proceed without token rather than fail the request entirely.
      handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final req = err.requestOptions;

    // Handle 429 (Rate Limited) — apply cooldown and pass through without logout.
    if (status == 429) {
      final retryAfter = _parseRetryAfterSeconds(err);
      _setCooldown(retryAfter);
      if (kDebugMode) {
        debugPrint('[auth] 429 on ${req.uri.path} — cooldown ${retryAfter}s');
      }
      return handler.next(err);
    }

    if (status != 401) {
      return handler.next(err);
    }

    if (req.extra[kSkipAuthInjection] == true ||
        req.extra[kAuthRetry] == true) {
      return handler.next(err);
    }

    final path = req.uri.path.toLowerCase();
    if (path.endsWith('auth/login') ||
        path.endsWith('auth/logout') ||
        path.endsWith('auth/refresh') ||
        path.endsWith('auth/google') ||
        path.endsWith('auth/apple')) {
      return handler.next(err);
    }

    // Don't attempt refresh if in cooldown after recent failure.
    if (_inCooldown) {
      if (kDebugMode) {
        debugPrint('[auth] 401 on $path — in cooldown, skipping refresh');
      }
      return handler.next(err);
    }

    final refreshTok = await storage.getRefreshToken();
    if (refreshTok == null || refreshTok.isEmpty) {
      // Mobile uses Passport personal-access tokens (no refresh token). A genuine
      // 401 here means the token was revoked server-side — e.g. the user tapped
      // "Disconnect Other Device" on the web. Past the brief post-login grace
      // window, end the session so the mobile reflects the remote logout.
      if (_pastPostLoginGrace) {
        if (kDebugMode) {
          debugPrint('[auth] 401 on $path — token revoked (no refresh), forcing logout');
        }
        notifyAuthForceLogout();
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const SessionExpiredException(),
            type: DioExceptionType.unknown,
          ),
        );
      }
      // Within grace window — likely a token-propagation race; pass through.
      if (kDebugMode) {
        debugPrint('[auth] 401 on $path — no refresh token (post-login grace), passing through');
      }
      return handler.next(err);
    }

    try {
      await _runSerializedRefresh();
      final retry = await _cloneForRetry(req);
      final response = await dio.fetch<dynamic>(retry);
      return handler.resolve(response);
    } on SessionExpiredException catch (e) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    } catch (e) {
      // Transient failure; pass original 401 through without logout.
      if (kDebugMode) {
        debugPrint('[auth] 401 refresh failed transiently on $path: $e');
      }
      return handler.next(err);
    }
  }

  int _parseRetryAfterSeconds(DioException err) {
    final header = err.response?.headers.value('retry-after');
    if (header != null) {
      final parsed = int.tryParse(header);
      if (parsed != null && parsed > 0) {
        return parsed.clamp(1, 120);
      }
    }
    return 5;
  }

  /// Throws [SessionExpiredException] if session is permanently invalid.
  Future<void> _runSerializedRefresh() async {
    // If another refresh is running, wait for it.
    final existing = _refreshCompleter;
    if (existing != null) {
      await existing.future;
      return;
    }

    final c = Completer<void>();
    _refreshCompleter = c;
    try {
      final result = await AuthRemote.refreshFromStorage(storage);
      switch (result) {
        case Success(:final data):
          await storage.saveAuthSession(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            expiresIn: data.expiresIn,
            userJson: data.user.toJson(),
          );
          c.complete();
          return;
        case Failure(:final error):
          if (error is SessionInvalidException) {
            notifyAuthForceLogout();
            if (kDebugMode) {
              debugPrint('[auth] Session invalidated — forcing logout');
            }
            c.completeError(SessionExpiredException(), StackTrace.current);
            throw SessionExpiredException();
          }
          // Transient failure: set cooldown so we don't spam refresh.
          _setCooldown(error);
          c.completeError(error, StackTrace.current);
          throw error;
      }
    } catch (e, st) {
      if (!c.isCompleted) {
        _setCooldown(null);
        c.completeError(e, st);
      }
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  void _setCooldown([dynamic errorOrSeconds]) {
    int seconds = 5;
    if (errorOrSeconds is int) {
      seconds = errorOrSeconds.clamp(5, 120);
    } else if (errorOrSeconds is RateLimitedException) {
      seconds = errorOrSeconds.retryAfterSeconds.clamp(5, 120);
    }
    _refreshCooldownUntil = DateTime.now().add(Duration(seconds: seconds));
    if (kDebugMode) {
      debugPrint('[auth] Cooldown set for ${seconds}s');
    }
  }

  Future<RequestOptions> _cloneForRetry(RequestOptions req) async {
    final headers = Map<String, dynamic>.from(req.headers);
    final token = await storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final extra = Map<String, dynamic>.from(req.extra)..[kAuthRetry] = true;
    return req.copyWith(headers: headers, extra: extra);
  }
}
