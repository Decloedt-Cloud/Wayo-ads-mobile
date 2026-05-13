import 'dart:async';

import 'package:dio/dio.dart';

import '../errors/auth_exceptions.dart';
import '../result.dart';
import '../storage/secure_storage.dart';
import 'auth_force_logout_hub.dart';
import 'auth_remote.dart';
import 'request_flags.dart';
import 'session_expired_exception.dart';

/// Injects Bearer tokens, refreshes once on 401, and queues concurrent refresh attempts.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.storage, required this.dio});

  final SecureStorageService storage;
  final Dio dio;

  static Completer<void>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[kSkipAuthInjection] == true) {
      return handler.next(options);
    }

    // [QueuedInterceptor] runs onRequest and onError on separate queues: a burst of
    // calls can otherwise attach a stale bearer while onError is mid-refresh.
    // Retries marked [kAuthRetry] must not await here (same isolate held the refresh).
    if (options.extra[kAuthRetry] != true) {
      final waitOn = _refreshCompleter;
      if (waitOn != null) {
        try {
          await waitOn.future;
        } catch (_) {
          // Refresh failed; attempt with current storage state below.
        }
      }
    }

    var token = await storage.getAccessToken();
    if (token != null &&
        token.isNotEmpty &&
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
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    if (status != 401) {
      return handler.next(err);
    }

    final req = err.requestOptions;
    if (req.extra[kSkipAuthInjection] == true ||
        req.extra[kAuthRetry] == true) {
      return handler.next(err);
    }

    final path = req.uri.path.toLowerCase();
    if (path.endsWith('auth/login') || path.endsWith('auth/logout')) {
      return handler.next(err);
    }

    final refreshTok = await storage.getRefreshToken();
    if (refreshTok == null || refreshTok.isEmpty) {
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
      return handler.next(err);
    }
  }

  Future<void> _runSerializedRefresh() async {
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
            c.completeError(SessionExpiredException(), StackTrace.current);
            throw SessionExpiredException();
          }
          c.completeError(error, StackTrace.current);
          throw error;
      }
    } catch (e, st) {
      if (!c.isCompleted) {
        c.completeError(e, st);
      }
      rethrow;
    } finally {
      _refreshCompleter = null;
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
