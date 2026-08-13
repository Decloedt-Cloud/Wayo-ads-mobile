/// Result of comparing the installed build to Remote Config thresholds.
enum AppUpdateStatus {
  /// App is current — no UI.
  none,

  /// Soft prompt — user may continue with "Later".
  optional,

  /// Hard block — user must update.
  required,
}
