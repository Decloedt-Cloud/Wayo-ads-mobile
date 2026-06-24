void Function()? _onSessionsChanged;

/// Registered by [RealtimeDashboardWire] so an FCM `sessions.changed` control
/// message can refresh the active sessions list and re-validate the current
/// session (force logout if revoked) without import cycles.
void setSessionsChangedHandler(void Function()? fn) {
  _onSessionsChanged = fn;
}

void clearSessionsChangedHandler() {
  _onSessionsChanged = null;
}

void notifySessionsChanged() {
  _onSessionsChanged?.call();
}
