/// Explicit reasons for backend push unregister (DELETE /api/user/push-device).
///
/// DELETE must never use a generic "cleanup" path — every call sites a reason.
enum PushUnregisterReason {
  logout,
  forceLogout,
  accountSwitch,
  userDisabled,
  manualReset,
}

/// Why a registration (POST) was attempted.
enum PushRegisterReason {
  appStart,
  login,
  tokenRefresh,
  userEnabled,
  permissionPrompt,
  debugRetry,
  resumeRefresh,
  ensureAfterCache,
  /// Forced heal when delivery suppress is sticky or server token was dropped.
  forceHeal,
}

/// Process-wide gate so logout/unregister cannot race with token-refresh POST.
abstract final class PushRegistrationGate {
  static bool _blocked = false;
  static int _generation = 0;

  static bool get isBlocked => _blocked;

  static int get generation => _generation;

  /// Call at the start of logout / force-logout / disable before DELETE.
  static void block({required String reason}) {
    _blocked = true;
    _generation++;
    // ignore: avoid_print
    assert(() {
      // Lifecycle logs go through logPushLifecycle in callers.
      return true;
    }());
  }

  /// Call after successful login / enable when registration is allowed again.
  static void allow({required String reason}) {
    _blocked = false;
  }

  /// Snapshot for race checks: if generation changed mid-flight, abort POST.
  static int beginAttempt() => _generation;
}
