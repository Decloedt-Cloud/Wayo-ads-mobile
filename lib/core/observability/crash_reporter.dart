import 'package:sentry_flutter/sentry_flutter.dart';

import '../network/scrubber.dart';

/// Global crash / error sink (Sentry in release when configured, otherwise no-op).
abstract interface class CrashReporter {
  Future<void> init();

  Future<void> captureException(Object error, [StackTrace? stackTrace]);

  Future<void> addBreadcrumb(String message, {Map<String, dynamic>? data});

  Future<void> setUserId(String? hashedId);

  Future<void> flush();
}

/// Mutable holder so [main] can swap implementation after [SentryFlutter.init].
abstract final class CrashReporterHolder {
  static CrashReporter instance = NoopCrashReporter();
}

final class NoopCrashReporter implements CrashReporter {
  @override
  Future<void> init() async {}

  @override
  Future<void> captureException(Object error, [StackTrace? stackTrace]) async {}

  @override
  Future<void> addBreadcrumb(String message, {Map<String, dynamic>? data}) async {}

  @override
  Future<void> setUserId(String? hashedId) async {}

  @override
  Future<void> flush() async {}
}

final class SentryCrashReporter implements CrashReporter {
  @override
  Future<void> init() async {}

  @override
  Future<void> captureException(Object error, [StackTrace? stackTrace]) async {
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  @override
  Future<void> addBreadcrumb(String message, {Map<String, dynamic>? data}) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        data: data == null ? null : scrub(data),
      ),
    );
  }

  @override
  Future<void> setUserId(String? hashedId) async {
    await Sentry.configureScope((scope) {
      if (hashedId == null || hashedId.isEmpty) {
        scope.setUser(null);
      } else {
        scope.setUser(SentryUser(id: hashedId));
      }
    });
  }

  @override
  Future<void> flush() async {
    // NOTE: Sentry Dart 8.x has no stable public flush API; events are queued asynchronously.
  }
}
