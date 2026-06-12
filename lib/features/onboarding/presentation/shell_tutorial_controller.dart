import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/creator_colors.dart';
import '../../../i18n/strings.g.dart';
import '../../auth/domain/wayo_ads_account_role.dart';
import 'shell_tutorial_highlight.dart';

export 'shell_tutorial_highlight.dart';

bool _coachTargetBoxReady(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null) return false;
  final box = ctx.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return false;
  return box.size.width > 8 && box.size.height > 8;
}

/// True once every supplied key is attached with a usable layout (for [TutorialCoachMark]).
bool shellCoachNavTabsReady(Map<ShellTutorialTarget, GlobalKey> keys) {
  for (final MapEntry(:value) in keys.entries) {
    if (!_coachTargetBoxReady(value)) return false;
  }
  return true;
}

/// Invisible hole anchor — the real tab spotlight is painted by the bottom nav
/// via [shellTutorialHighlightTab] while this overlay only dims the shell body.
final TargetPosition _shellTutorialBodyAnchor =
    TargetPosition(const Size(1, 1), const Offset(1, 1));

/// Coach card sits at the bottom of the body overlay (nav is outside the overlay).
const double _shellTutorialCoachCardBottomGap = 12;

/// Orchestrates the first-login, role-aware **coach-mark tour** around the
/// bottom navigation bar.
///
/// Design goals:
/// - **Shown once per (user, role)** — returning accounts are never bothered.
///   Stored under `onboarding.shell.user_<id>.role_<name>.seen` in [AppPrefs].
/// - **No deps on UI internals** — callers pass a `{target: GlobalKey}` map
///   from the shell; this class resolves copy, color and order based on role.
/// - **Safe to call from any frame** — validates that every key has a rendered
///   context before calling `.show()` to avoid the package's
///   "TargetPosition is not valid" crash.
/// - **Skippable + re-playable** — a single tap on "Skip" marks the tour as
///   seen; external "Replay tutorial" buttons can call [reset] and re-invoke.
class ShellTutorialController {
  ShellTutorialController._();

  /// Shared instance — the controller itself is stateless, this is just a
  /// convenient singleton for callers who don't want to wire DI.
  static final ShellTutorialController instance = ShellTutorialController._();

  static String _prefsKey(int userId, WayoAdsAccountRole role) =>
      'onboarding.shell.user_$userId.role_${role.name}.seen';

  /// Returns `true` if the tour has already run for this user + role.
  bool hasSeen({
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
  }) => prefs.getString(_prefsKey(userId, role)) == '1';

  /// Clears the "seen" flag so the tour shows again at the next opportunity.
  Future<void> reset({
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
  }) => prefs.setString(_prefsKey(userId, role), '0');

  /// Marks the tour as seen (called after finish **and** skip).
  Future<void> _markSeen({
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
  }) => prefs.setString(_prefsKey(userId, role), '1');

  /// Launches the tour if it hasn't run yet for this user + role.
  ///
  /// [keys] should include every target for the tour (5 tabs for shell users
  /// with an invoices branch). Missing keys are skipped.
  Future<bool> maybeShow({
    required BuildContext context,
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
    required Map<ShellTutorialTarget, GlobalKey> keys,
  }) async {
    if (hasSeen(prefs: prefs, userId: userId, role: role)) return false;
    return show(
      context: context,
      prefs: prefs,
      userId: userId,
      role: role,
      keys: keys,
    );
  }

  /// Forces the tour to run (used by "Replay tutorial" buttons).
  ///
  /// [context] must be the shell body overlay host (see [AppShell]) so the
  /// dimmed layer does not cover the bottom navigation bar.
  /// Returns `true` if the overlay was shown (at least one valid target).
  Future<bool> show({
    required BuildContext context,
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
    required Map<ShellTutorialTarget, GlobalKey> keys,
  }) async {
    final targets = _buildTargets(context: context, role: role, keys: keys);
    if (targets.isEmpty) return false;

    final accent = role == WayoAdsAccountRole.creator
        ? CreatorColors.primaryOf(context)
        : AppColors.primary;
    final t = context.t;

    shellTutorialHighlightTab.value =
        shellTutorialTargetFromIdentify(targets.first.identify);

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.92,
      paddingFocus: 0,
      focusAnimationDuration: const Duration(milliseconds: 320),
      unFocusAnimationDuration: const Duration(milliseconds: 200),
      // Pulse shrinks the RRect hole slightly — keep framing stable at 100%.
      pulseEnable: false,
      beforeFocus: (target) async {
        shellTutorialHighlightTab.value =
            shellTutorialTargetFromIdentify(target.identify);
      },
      textSkip: t.onboarding.skip,
      textStyleSkip: GoogleFonts.inter(
        color: accent,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      alignSkip: Alignment.topRight,
      useSafeArea: true,
      onSkip: () {
        HapticFeedback.lightImpact();
        clearShellTutorialHighlight();
        unawaited(_markSeen(prefs: prefs, userId: userId, role: role));
        return true;
      },
      onFinish: () {
        HapticFeedback.mediumImpact();
        clearShellTutorialHighlight();
        unawaited(_markSeen(prefs: prefs, userId: userId, role: role));
      },
      onClickTarget: (_) => HapticFeedback.selectionClick(),
      onClickOverlay: (_) => HapticFeedback.selectionClick(),
    ).show(context: context, rootOverlay: false);
    return true;
  }

  /// Builds coach-mark targets in a fixed order, skipping any whose
  /// [GlobalKey] is unmounted (happens if the screen animates in late).
  List<TargetFocus> _buildTargets({
    required BuildContext context,
    required WayoAdsAccountRole role,
    required Map<ShellTutorialTarget, GlobalKey> keys,
  }) {
    final t = context.t;
    final isCreator = role == WayoAdsAccountRole.creator;
    final accent = isCreator
        ? CreatorColors.primaryOf(context)
        : AppColors.primary;

    List<(ShellTutorialTarget, String, String)> steps;
    if (isCreator) {
      final tc = t.onboarding.creator;
      steps = [
        (
          ShellTutorialTarget.dashboard,
          tc.dashboard_title,
          tc.dashboard_subtitle,
        ),
        (
          ShellTutorialTarget.campaigns,
          tc.campaigns_title,
          tc.campaigns_subtitle,
        ),
        (ShellTutorialTarget.wallet, tc.wallet_title, tc.wallet_subtitle),
        (
          ShellTutorialTarget.invoices,
          tc.invoices_title,
          tc.invoices_subtitle,
        ),
        (ShellTutorialTarget.chat, tc.chat_title, tc.chat_subtitle),
      ];
    } else {
      final ta = t.onboarding.advertiser;
      steps = [
        (
          ShellTutorialTarget.dashboard,
          ta.dashboard_title,
          ta.dashboard_subtitle,
        ),
        (
          ShellTutorialTarget.campaigns,
          ta.campaigns_title,
          ta.campaigns_subtitle,
        ),
        (ShellTutorialTarget.wallet, ta.wallet_title, ta.wallet_subtitle),
        (
          ShellTutorialTarget.invoices,
          ta.invoices_title,
          ta.invoices_subtitle,
        ),
        (ShellTutorialTarget.chat, ta.chat_title, ta.chat_subtitle),
      ];
    }

    final total = steps.length;
    final out = <TargetFocus>[];
    for (var i = 0; i < total; i++) {
      final (id, title, subtitle) = steps[i];
      final key = keys[id];
      if (key == null) continue;
      // Skip silently if the widget isn't laid out yet — the caller re-runs
      // after the first frame so nav keys are ready for [shellTutorialHighlightTab].
      if (!_coachTargetBoxReady(key)) continue;

      out.add(
        TargetFocus(
          identify: id.name,
          targetPosition: _shellTutorialBodyAnchor,
          shape: ShapeLightFocus.RRect,
          radius: 0,
          paddingFocus: 0,
          enableOverlayTab: true,
          enableTargetTab: false,
          focusAnimationDuration: const Duration(milliseconds: 320),
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                left: 16,
                right: 16,
                bottom: _shellTutorialCoachCardBottomGap,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              builder: (ctx, ctrl) => _CoachCard(
                accent: accent,
                title: title,
                subtitle: subtitle,
                stepIndex: i,
                stepCount: total,
                onNext: () {
                  HapticFeedback.selectionClick();
                  ctrl.next();
                },
                onFinish: () {
                  HapticFeedback.mediumImpact();
                  ctrl.next();
                },
                isLast: i == total - 1,
              ),
            ),
          ],
        ),
      );
    }
    return out;
  }
}

/// Content card rendered above the focused tab. Keeps the package's black
/// backdrop but uses the Wayo brand accent + Inter to match the rest of the
/// app. All colors derive from [accent] so the creator tour looks teal and
/// the advertiser tour looks amber without any branching in the caller.
class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.stepIndex,
    required this.stepCount,
    required this.onNext,
    required this.onFinish,
    required this.isLast,
  });

  final Color accent;
  final String title;
  final String subtitle;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${stepIndex + 1} / $stepCount',
                      style: GoogleFonts.inter(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DotsIndicator(
                      count: stepCount,
                      activeIndex: stepIndex,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: isLast ? onFinish : onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLast ? t.onboarding.done : t.onboarding.next,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.activeIndex,
    required this.accent,
  });

  final int count;
  final int activeIndex;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? accent : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
