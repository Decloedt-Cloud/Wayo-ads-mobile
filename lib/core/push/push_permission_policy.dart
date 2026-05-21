import '../storage/app_prefs.dart';

/// Why the push opt-in sheet is being shown (timing rules differ slightly).
enum PushPermissionContext {
  /// First visit / 14 days after « Pas maintenant » on the dashboard.
  generic,

  /// Incoming chat message (peer, not self).
  chatMessage,

  /// Campaign created / updated / paused, etc.
  campaignStatus,

  /// Invoice, payout, or wallet balance event.
  invoice,
}

/// B2B-friendly re-prompt rules (min gap, 14-day deferral, max 3 shows).
class PushPermissionPolicy {
  PushPermissionPolicy(this._prefs);

  final AppPrefs _prefs;

  /// Never re-prompt sooner than this (avoids feeling aggressive).
  static const int minDaysBetweenPrompts = 3;

  /// Default deferral after « Pas maintenant » before a generic prompt again.
  static const int daysAfterDismiss = 14;

  /// Hard cap on how many times the sheet may appear (all contexts combined).
  static const int maxTotalPrompts = 3;

  static String _legacyKey(int userId) => 'push.prompt.v1.$userId';

  static String _completedKey(int userId) => 'push.prompt.completed.$userId';

  static String _dismissCountKey(int userId) => 'push.prompt.dismiss_count.$userId';

  static String _dismissedMsKey(int userId) => 'push.prompt.dismissed_ms.$userId';

  static String _totalShownKey(int userId) => 'push.prompt.total_shown.$userId';

  static String _lastShownMsKey(int userId) => 'push.prompt.last_shown_ms.$userId';

  Future<void> _migrateLegacy(int userId) async {
    if (_prefs.getString(_legacyKey(userId)) != '1') {
      return;
    }
    if (_prefs.getInt(_totalShownKey(userId)) == 0) {
      await _prefs.setInt(_totalShownKey(userId), 1);
    }
    if (_prefs.getInt(_dismissedMsKey(userId)) == 0) {
      await _prefs.setInt(
        _dismissedMsKey(userId),
        DateTime.now()
            .subtract(const Duration(days: daysAfterDismiss))
            .millisecondsSinceEpoch,
      );
    }
    await _prefs.setString(_legacyKey(userId), 'migrated');
  }

  bool isCompleted(int userId) {
    return _prefs.getString(_completedKey(userId)) == '1';
  }

  Future<bool> shouldShowPrompt({
    required int userId,
    required PushPermissionContext context,
    required bool systemNotificationsGranted,
  }) async {
    if (userId <= 0) return false;
    await _migrateLegacy(userId);

    if (systemNotificationsGranted) {
      return false;
    }
    if (isCompleted(userId)) {
      return false;
    }

    final totalShown = _prefs.getInt(_totalShownKey(userId));
    if (totalShown >= maxTotalPrompts) {
      return false;
    }

    final lastShownMs = _prefs.getInt(_lastShownMsKey(userId));
    if (lastShownMs > 0) {
      final daysSinceShown = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastShownMs))
          .inDays;
      if (daysSinceShown < minDaysBetweenPrompts) {
        return false;
      }
    }

    if (context == PushPermissionContext.generic) {
      final dismissMs = _prefs.getInt(_dismissedMsKey(userId));
      if (dismissMs <= 0) {
        return true;
      }
      final daysSinceDismiss = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(dismissMs))
          .inDays;
      return daysSinceDismiss >= daysAfterDismiss;
    }

    return true;
  }

  Future<void> recordPromptShown(int userId) async {
    if (userId <= 0) return;
    final total = _prefs.getInt(_totalShownKey(userId)) + 1;
    await _prefs.setInt(_totalShownKey(userId), total);
    await _prefs.setInt(
      _lastShownMsKey(userId),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> recordDismissed(int userId) async {
    if (userId <= 0) return;
    final count = _prefs.getInt(_dismissCountKey(userId)) + 1;
    await _prefs.setInt(_dismissCountKey(userId), count);
    await _prefs.setInt(
      _dismissedMsKey(userId),
      DateTime.now().millisecondsSinceEpoch,
    );
    if (count >= maxTotalPrompts) {
      await _prefs.setString(_completedKey(userId), '1');
    }
  }

  Future<void> recordEnabled(int userId) async {
    if (userId <= 0) return;
    await _prefs.setString(_completedKey(userId), '1');
  }
}
