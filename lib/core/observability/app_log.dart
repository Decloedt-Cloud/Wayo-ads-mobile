import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Opt-in verbose diagnostics for **profile/release** (visible in `adb logcat`).
///
/// Build or run with:
/// `flutter build apk --release --dart-define=WAYO_VERBOSE_LOGS=true`
///
/// Enables [WayoLoggingInterceptor], retry logs, and connectivity failure hints
/// without turning them on for normal store builds.
const bool kWayoVerboseLogs = bool.fromEnvironment(
  'WAYO_VERBOSE_LOGS',
  defaultValue: false,
);

/// Lightweight release-only diagnostics (`adb logcat`, tag `wayo.config`) without
/// full HTTP body logging. Use `--dart-define=WAYO_AUTH_DIAG=true`.
const bool kWayoAuthDiag = bool.fromEnvironment(
  'WAYO_AUTH_DIAG',
  defaultValue: false,
);

/// When true, emit the same network/bootstrap-style diagnostics as debug mode.
bool get kWayoDiagnosticsLogging => kDebugMode || kWayoVerboseLogs;

/// Config / TLS one-liners in release when [kWayoAuthDiag] or verbose logs are on.
bool get kWayoConfigDiagnosticLogging =>
    kDebugMode || kWayoVerboseLogs || (kReleaseMode && kWayoAuthDiag);

/// Single-line diagnostics that respect [kWayoDiagnosticsLogging].
void wayoDiagPrint(String message, {String name = 'wayo'}) {
  if (!kWayoDiagnosticsLogging) return;
  developer.log(message, name: name);
  // `adb logcat -s flutter` only shows print/debugPrint — not developer.log.
  if (kReleaseMode || kProfileMode) {
    debugPrint('[$name] $message');
  }
}

void wayoConfigDiagPrint(String message, {String name = 'wayo.config'}) {
  if (!kWayoConfigDiagnosticLogging) return;
  developer.log(message, name: name);
  if (kReleaseMode || kProfileMode) {
    debugPrint('[$name] $message');
  }
}

/// TLS pinning rejections: visible with [kWayoVerboseLogs], [kWayoAuthDiag] in release, or debug.
void wayoTlsDiagPrint(String message) {
  if (!kWayoDiagnosticsLogging && !kWayoConfigDiagnosticLogging) return;
  developer.log(message, name: 'wayo.tls');
  if (kReleaseMode || kProfileMode) {
    debugPrint('[wayo.tls] $message');
  }
}
