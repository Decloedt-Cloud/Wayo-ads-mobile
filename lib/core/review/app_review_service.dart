import 'dart:developer' as developer;

import 'package:in_app_review/in_app_review.dart';

import '../storage/app_prefs.dart';

/// Positive user actions that may trigger an in-app review (after [minSessionsBeforePositivePrompt]).
enum AppReviewPositiveMoment {
  withdrawalSubmitted,
}

/// Native App Store / Google Play review prompts via [InAppReview].
///
/// Apple/Google enforce their own quotas; we additionally cap client-side prompts
/// and avoid launch / error paths. Session milestones: 5, 20, 50 shell entries.
class AppReviewService {
  AppReviewService._();

  static final AppReviewService instance = AppReviewService._();

  static const _sessionMilestones = <int>{5, 20, 50};
  static const minSessionsBeforePositivePrompt = 3;
  static const maxPromptsPerCalendarYear = 3;
  static const minDaysBetweenPrompts = 14;

  final InAppReview _inAppReview = InAppReview.instance;

  static String _sessionCountKey(int userId) =>
      'review.session_count.user_$userId';

  static String _lastPromptMsKey(int userId) =>
      'review.last_prompt_ms.user_$userId';

  static String _promptYearKey(int userId) => 'review.prompt_year.user_$userId';

  static String _promptCountKey(int userId) =>
      'review.prompt_count.user_$userId';

  /// Call when the authenticated main shell is shown (once per cold start).
  Future<void> onShellEntered({
    required AppPrefs prefs,
    required int userId,
    required bool shellTutorialPending,
  }) async {
    if (userId <= 0) return;

    final nextCount = prefs.getInt(_sessionCountKey(userId)) + 1;
    await prefs.setInt(_sessionCountKey(userId), nextCount);

    if (shellTutorialPending) return;
    if (!_sessionMilestones.contains(nextCount)) return;

    await Future<void>.delayed(const Duration(seconds: 2));
    await _requestReviewIfEligible(prefs: prefs, userId: userId);
  }

  /// Call after a meaningful success (e.g. withdrawal submitted).
  Future<void> onPositiveMoment({
    required AppPrefs prefs,
    required int userId,
    required AppReviewPositiveMoment moment,
  }) async {
    if (userId <= 0) return;

    final sessions = prefs.getInt(_sessionCountKey(userId));
    if (sessions < minSessionsBeforePositivePrompt) return;

    developer.log(
      'Considering review after $moment',
      name: 'wayo.review',
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    await _requestReviewIfEligible(prefs: prefs, userId: userId);
  }

  /// Opens the store listing (no native popup quota). For explicit user taps.
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
    } catch (e, st) {
      developer.log(
        'openStoreListing failed: $e',
        name: 'wayo.review',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _requestReviewIfEligible({
    required AppPrefs prefs,
    required int userId,
  }) async {
    if (!_canPromptFromPrefs(prefs, userId)) return;

    try {
      if (!await _inAppReview.isAvailable()) return;
      await _inAppReview.requestReview();
      await _recordPrompt(prefs: prefs, userId: userId);
    } catch (e, st) {
      developer.log(
        'requestReview failed: $e',
        name: 'wayo.review',
        error: e,
        stackTrace: st,
      );
    }
  }

  bool _canPromptFromPrefs(AppPrefs prefs, int userId) {
    final year = DateTime.now().year;
    final storedYear = prefs.getInt(_promptYearKey(userId));
    var count = prefs.getInt(_promptCountKey(userId));
    if (storedYear != year) {
      count = 0;
    }
    if (count >= maxPromptsPerCalendarYear) return false;

    final lastMs = prefs.getInt(_lastPromptMsKey(userId));
    if (lastMs <= 0) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final daysSince = DateTime.now().difference(last).inDays;
    return daysSince >= minDaysBetweenPrompts;
  }

  Future<void> _recordPrompt({
    required AppPrefs prefs,
    required int userId,
  }) async {
    final year = DateTime.now().year;
    final storedYear = prefs.getInt(_promptYearKey(userId));
    var count = prefs.getInt(_promptCountKey(userId));
    if (storedYear != year) {
      count = 0;
    }
    await prefs.setInt(_promptYearKey(userId), year);
    await prefs.setInt(_promptCountKey(userId), count + 1);
    await prefs.setInt(
      _lastPromptMsKey(userId),
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
