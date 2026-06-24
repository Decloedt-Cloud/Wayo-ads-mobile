import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// True once every supplied key is attached with a usable layout.
bool shellCoachNavTabsReady(Map<ShellTutorialTarget, GlobalKey> keys) {
  for (final MapEntry(:value) in keys.entries) {
    if (!_coachTargetBoxReady(value)) return false;
  }
  return true;
}

/// Coach card sits at the bottom of the body overlay (nav is outside the overlay).
const double _shellTutorialCoachCardBottomGap = 12;

const Duration _shellTutorialSlideDuration = shellTutorialSlideDuration;
const Curve _shellTutorialSlideCurve = shellTutorialSlideCurve;

class _ShellTutorialStep {
  const _ShellTutorialStep({
    required this.target,
    required this.title,
    required this.subtitle,
  });

  final ShellTutorialTarget target;
  final String title;
  final String subtitle;
}

/// Orchestrates the first-login, role-aware **coach-mark tour** around the
/// bottom navigation bar.
class ShellTutorialController {
  ShellTutorialController._();

  static final ShellTutorialController instance = ShellTutorialController._();

  OverlayEntry? _activeEntry;

  static String _prefsKey(int userId, WayoAdsAccountRole role) =>
      'onboarding.shell.user_$userId.role_${role.name}.seen';

  bool hasSeen({
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
  }) =>
      prefs.getString(_prefsKey(userId, role)) == '1';

  Future<void> reset({
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
  }) =>
      prefs.setString(_prefsKey(userId, role), '0');

  Future<void> _markSeen({
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
  }) =>
      prefs.setString(_prefsKey(userId, role), '1');

  void _dismiss(OverlayEntry entry) {
    entry.remove();
    if (identical(_activeEntry, entry)) {
      _activeEntry = null;
    }
  }

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

  Future<bool> show({
    required BuildContext context,
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
    required Map<ShellTutorialTarget, GlobalKey> keys,
  }) async {
    if (_activeEntry != null) return false;

    final steps = _buildSteps(context: context, role: role, keys: keys);
    if (steps.isEmpty) return false;

    final accent = role == WayoAdsAccountRole.creator
        ? CreatorColors.primaryOf(context)
        : AppColors.primary;
    final t = context.t;
    final overlay = Overlay.of(context, rootOverlay: false);

    shellTutorialHighlightTab.value = steps.first.target;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _ShellTutorialOverlay(
        steps: steps,
        accent: accent,
        skipLabel: t.onboarding.skip,
        onSkip: () {
          HapticFeedback.lightImpact();
          clearShellTutorialHighlight();
          unawaited(_markSeen(prefs: prefs, userId: userId, role: role));
          _dismiss(entry);
        },
        onFinish: () {
          HapticFeedback.mediumImpact();
          clearShellTutorialHighlight();
          unawaited(_markSeen(prefs: prefs, userId: userId, role: role));
          _dismiss(entry);
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
    return true;
  }

  List<_ShellTutorialStep> _buildSteps({
    required BuildContext context,
    required WayoAdsAccountRole role,
    required Map<ShellTutorialTarget, GlobalKey> keys,
  }) {
    final t = context.t;
    final isCreator = role == WayoAdsAccountRole.creator;

    final List<(ShellTutorialTarget, String, String)> rawSteps;
    if (isCreator) {
      final tc = t.onboarding.creator;
      rawSteps = [
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
      rawSteps = [
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

    final out = <_ShellTutorialStep>[];
    for (final (id, title, subtitle) in rawSteps) {
      final key = keys[id];
      if (key == null) continue;
      if (!_coachTargetBoxReady(key)) continue;
      out.add(
        _ShellTutorialStep(target: id, title: title, subtitle: subtitle),
      );
    }
    return out;
  }
}

class _ShellTutorialOverlay extends StatefulWidget {
  const _ShellTutorialOverlay({
    required this.steps,
    required this.accent,
    required this.skipLabel,
    required this.onSkip,
    required this.onFinish,
  });

  final List<_ShellTutorialStep> steps;
  final Color accent;
  final String skipLabel;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  @override
  State<_ShellTutorialOverlay> createState() => _ShellTutorialOverlayState();
}

class _ShellTutorialOverlayState extends State<_ShellTutorialOverlay> {
  int _page = 0;
  int _slideDirection = 1;

  Future<void> _goToPage(int page) async {
    if (!mounted || page == _page) return;

    final direction = page > _page ? 1 : -1;
    shellTutorialHighlightTab.value = widget.steps[page].target;
    setState(() {
      _slideDirection = direction;
      _page = page;
    });
  }

  void _onNext() {
    final last = widget.steps.length - 1;
    if (_page >= last) {
      widget.onFinish();
      return;
    }
    HapticFeedback.selectionClick();
    unawaited(_goToPage(_page + 1));
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_page];

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onNext,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.92),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onSkip,
                child: Text(
                  widget.skipLabel,
                  style: GoogleFonts.inter(
                    color: widget.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: _shellTutorialCoachCardBottomGap,
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : _shellTutorialSlideDuration,
              switchInCurve: _shellTutorialSlideCurve,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: _shellTutorialSlideCurve,
                  reverseCurve: Curves.easeInCubic,
                );
                final offset = Tween<Offset>(
                  begin: Offset(_slideDirection * 0.12, 0),
                  end: Offset.zero,
                ).animate(curved);
                return SlideTransition(
                  position: offset,
                  child: FadeTransition(opacity: curved, child: child),
                );
              },
              child: _CoachCard(
                key: ValueKey(step.target),
                accent: widget.accent,
                title: step.title,
                subtitle: step.subtitle,
                stepIndex: _page,
                stepCount: widget.steps.length,
                onNext: _onNext,
                onFinish: widget.onFinish,
                isLast: _page == widget.steps.length - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    super.key,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          duration: _shellTutorialSlideDuration,
          curve: _shellTutorialSlideCurve,
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
