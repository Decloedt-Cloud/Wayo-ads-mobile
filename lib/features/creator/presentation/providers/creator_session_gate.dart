import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/session_expired_exception.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';

/// Extra buffer after the chat post-login gate before surfacing load errors.
const Duration _kPostLoginRetryDelay = Duration(milliseconds: 450);

/// Matches [AuthInterceptor._postLoginGrace] — hide load errors while tokens settle.
const Duration _kSessionBootstrapWindow = Duration(seconds: 5);

/// Set on login / account switch; independent of chat bootstrap clearing.
final sessionBootstrapStartedAtProvider = StateProvider<DateTime?>(
  (ref) => null,
  name: 'sessionBootstrapStartedAtProvider',
);

void markSessionBootstrapStarted(dynamic ref) {
  ref.read(sessionBootstrapStartedAtProvider.notifier).state = DateTime.now();
}

void clearSessionBootstrap(dynamic ref) {
  ref.read(sessionBootstrapStartedAtProvider.notifier).state = null;
}

bool isSessionBootstrapActive(dynamic ref) {
  final started = ref.read(sessionBootstrapStartedAtProvider);
  if (started != null &&
      DateTime.now().difference(started) < _kSessionBootstrapWindow) {
    return true;
  }
  final chatGate = ref.read(chatPostLoginGateProvider);
  if (chatGate != null &&
      DateTime.now().difference(chatGate) < _kSessionBootstrapWindow) {
    return true;
  }
  return false;
}

bool isPostLoginBootstrapActive(dynamic ref) => isSessionBootstrapActive(ref);

/// Same cadence as [awaitChatPostLoginGate] — works from widgets and providers.
Future<void> awaitPostLoginBootstrapReader(dynamic ref) async {
  final at = ref.read(chatPostLoginGateProvider);
  if (at == null) return;
  const minDelay = Duration(milliseconds: 550);
  final elapsed = DateTime.now().difference(at);
  if (elapsed < minDelay) {
    await Future<void>.delayed(minDelay - elapsed);
  }
}

Future<void> awaitPostLoginBootstrap(Ref ref) async {
  await awaitPostLoginBootstrapReader(ref);
}

Future<int> awaitCreatorSessionUserId(Ref ref) async {
  await awaitPostLoginBootstrap(ref);
  final storage = ref.read(secureStorageProvider);
  for (var i = 0; i < 16; i++) {
    final token = await storage.getAccessToken();
    if (token != null && token.isNotEmpty) break;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  for (var i = 0; i < 12; i++) {
    final id = ref.read(currentAppUserProvider)?.id;
    if (id != null) return id;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  final id = ref.read(currentAppUserProvider)?.id;
  if (id == null) {
    throw StateError('Creator session requires an authenticated user');
  }
  return id;
}

bool isTransientSessionError(Object error) {
  if (error is StateError) return true;
  if (error is SessionExpiredException) return true;
  if (error is SessionInvalidException) return true;
  if (error is NetworkException) return true;
  if (error is DioException) {
    final code = error.response?.statusCode;
    if (code == 401 || code == 403 || code == 429) return true;
    if (code != null && code >= 500) return true;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        break;
    }
  }
  if (error is ServerException) {
    final code = error.statusCode;
    if (code == null || code == 401 || code == 403 || code == 429) {
      return true;
    }
    if (code >= 500) return true;
  }
  return false;
}

bool shouldSuppressSessionLoadError(dynamic ref, Object error) {
  if (isSessionBootstrapActive(ref)) return true;
  final auth = ref.read(authNotifierProvider);
  if (auth.isLoading) return true;
  if (isTransientSessionError(error) &&
      ref.read(currentAppUserProvider)?.id == null) {
    return true;
  }
  return false;
}

/// Alias kept for creator dashboards / wallet screens.
bool shouldSuppressCreatorLoadError(dynamic ref, Object error) =>
    shouldSuppressSessionLoadError(ref, error);

Future<T> fetchWithSessionRetry<T>(
  Ref ref,
  Future<T> Function() fetcher,
) async {
  Object? lastError;
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      return await fetcher();
    } catch (e) {
      lastError = e;
      final canRetry =
          isTransientSessionError(e) || isSessionBootstrapActive(ref);
      if (!canRetry || attempt >= 3) rethrow;
      await awaitPostLoginBootstrapReader(ref);
      await Future<void>.delayed(
        _kPostLoginRetryDelay * (attempt + 1),
      );
    }
  }
  throw lastError ?? StateError('fetchWithSessionRetry failed');
}

/// Alias kept for creator wallet / dashboard repositories.
Future<T> fetchCreatorWithAuthRetry<T>(
  Ref ref,
  Future<T> Function() fetcher,
) =>
    fetchWithSessionRetry(ref, fetcher);

void scheduleSessionRetryAfterBootstrap(dynamic ref, VoidCallback callback) {
  unawaited(Future<void>(() async {
    await awaitPostLoginBootstrapReader(ref);
    await Future<void>.delayed(_kPostLoginRetryDelay);
    callback();
  }));
}

/// Alias kept for creator dashboard screen.
void scheduleCreatorRetryAfterBootstrap(dynamic ref, VoidCallback callback) =>
    scheduleSessionRetryAfterBootstrap(ref, callback);

bool shouldSuppressAdvertiserSectionError(dynamic ref, AuthException? error) {
  if (error == null) return false;
  if (isSessionBootstrapActive(ref)) return true;
  if (ref.read(authNotifierProvider).isLoading) return true;
  return false;
}
