import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'wayo_retry_evaluator.dart';

/// Builds a [RetryInterceptor] with Wayo backoff and evaluator rules.
RetryInterceptor buildWayoRetryInterceptor(
  Dio dio, {
  List<String> excludedPostPaths = kAuthSideEffectPostSuffixes,
  void Function(String message)? logPrint,
}) {
  return RetryInterceptor(
    dio: dio,
    retries: 3,
    retryDelays: const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
    logPrint: logPrint,
    retryEvaluator: (err, attempt) => wayoRetryEvaluator(
      err,
      attempt,
      excludedPostPaths: excludedPostPaths,
    ),
  );
}
