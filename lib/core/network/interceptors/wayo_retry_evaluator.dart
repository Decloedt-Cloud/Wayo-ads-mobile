import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

/// POST path suffixes excluded from automatic retry (auth side-effects).
const List<String> kAuthSideEffectPostSuffixes = [
  'auth/login',
  'auth/google',
  'auth/apple',
  'auth/refresh',
  'auth/reset-password',
];

/// HTTP status codes eligible for automatic retry (defense-in-depth vs default set).
const Set<int> kWayoRetryableHttpStatuses = {
  408,
  // Never 429: auto-retry makes throttling worse and ignores Retry-After semantics.
  500,
  502,
  503,
  504,
};

/// Pure evaluator used by [RetryInterceptor] from `dio_smart_retry`.
///
/// [excludedPostPaths] — normalized path suffixes (lowercase, leading `/`) for POST
/// requests that must never be retried (e.g. auth side-effects).
FutureOr<bool> wayoRetryEvaluator(
  DioException error,
  int attempt, {
  Iterable<String> excludedPostPaths = kAuthSideEffectPostSuffixes,
}) {
  final req = error.requestOptions;
  if (req.disableRetry) {
    return false;
  }
  final method = req.method.toUpperCase();
  final path = req.uri.path.toLowerCase();

  if (method == 'POST') {
    for (final raw in excludedPostPaths) {
      final suffix = raw.toLowerCase().replaceAll(RegExp(r'^/+'), '');
      if (suffix.isEmpty) {
        continue;
      }
      if (path.endsWith(suffix) || path.endsWith('/$suffix')) {
        return false;
      }
    }
  }

  if (error.type == DioExceptionType.badResponse) {
    final code = error.response?.statusCode;
    if (code == null) {
      return false;
    }
    if (code == 429) {
      return false;
    }
    // Maintenance / gateway — show the maintenance screen immediately, do not retry.
    if (code == 502 || code == 503 || code == 521) {
      return false;
    }
    if (code >= 400 && code < 500) {
      return kWayoRetryableHttpStatuses.contains(code);
    }
    if (code >= 500) {
      return kWayoRetryableHttpStatuses.contains(code);
    }
    return false;
  }

  return error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError;
}
