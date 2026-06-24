import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../i18n/strings.g.dart';
import '../../onboarding/presentation/shell_tutorial_highlight.dart';

/// Number of shell branches (dashboard, campaigns, wallet, invoices, chat).
const int kWayoShellTabCount = 5;

/// Height of the bottom nav bar.
const double kWayoBottomNavBarHeight = 72;

/// Gap between nav bottom and safe-area inset.
const double kWayoBottomNavOuterBottomGap = 0;

/// Coach-mark hole matches each tab column (not label-dependent pill width).
const double kWayoNavCoachMarkRadius = 14;

/// Bottom inset so tab bodies clear the nav bar.
double wayoFloatingBottomNavReserve(BuildContext context, {double extraGap = 12}) {
  return MediaQuery.viewPaddingOf(context).bottom +
      kWayoBottomNavOuterBottomGap +
      kWayoBottomNavBarHeight +
      extraGap;
}

/// Shell body padding — drops nav reserve while the keyboard is open so a
/// dark gap does not appear between content and the keyboard.
double wayoShellBodyBottomPadding(BuildContext context, {double extraGap = 12}) {
  if (MediaQuery.viewInsetsOf(context).bottom > 0) return 0;
  return wayoFloatingBottomNavReserve(context, extraGap: extraGap);
}

bool wayoShellKeyboardOpen(BuildContext context) {
  return MediaQuery.viewInsetsOf(context).bottom > 0;
}

/// Professional bottom nav 2026 — clean, minimal, with badges and onboarding support.
class WayoBottomNav extends StatefulWidget {
  const WayoBottomNav({
    super.key,
    required this.navigationShell,
    required this.notificationUnread,
    required this.chatUnread,
    required this.campaignsAttentionCount,
    this.showInvoicesTab = true,
    required this.invoicesNavLabel,
    this.dashboardTabKey,
    this.campaignsTabKey,
    this.walletTabKey,
    this.invoicesTabKey,
    this.chatTabKey,
    this.coachAccentColor = AppColors.primary,
  });

  /// Role accent (amber advertiser / teal creator) — selected tab + coach lift.
  final Color coachAccentColor;

  final StatefulNavigationShell navigationShell;
  final int notificationUnread;
  final int chatUnread;

  /// When `false`, hides the invoices tab and maps shell indices (chat shifts).
  final bool showInvoicesTab;

  /// Bottom-nav label for the invoices tab (e.g. creator "Statements" vs "Invoices").
  final String invoicesNavLabel;

  /// Brouillons / campagnes à traiter (badge rouge sur l'onglet Campagnes).
  final int campaignsAttentionCount;

  /// Optional [GlobalKey]s used by the first-login coach-mark tour.
  final GlobalKey? dashboardTabKey;
  final GlobalKey? campaignsTabKey;
  final GlobalKey? walletTabKey;
  final GlobalKey? invoicesTabKey;
  final GlobalKey? chatTabKey;

  @override
  State<WayoBottomNav> createState() => _WayoBottomNavState();
}

class _WayoBottomNavState extends State<WayoBottomNav> {
  final GlobalKey _navStackKey = GlobalKey();

  void _goBranch(int shellIndex) {
    HapticFeedback.lightImpact();
    widget.navigationShell.goBranch(
      shellIndex,
      initialLocation: shellIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idx = widget.navigationShell.currentIndex;
    final coachAccent = widget.coachAccentColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.06) 
                : Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: kWayoBottomNavBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ValueListenableBuilder<ShellTutorialTarget?>(
          valueListenable: shellTutorialHighlightTab,
          builder: (context, coachTarget, _) {
            return Stack(
              key: _navStackKey,
              clipBehavior: Clip.none,
              children: [
                if (coachTarget != null)
                  _SlidingCoachHighlight(
                    stackKey: _navStackKey,
                    tabKey: shellTutorialTabKeyForTarget(
                      coachTarget,
                      dashboardKey: widget.dashboardTabKey,
                      campaignsKey: widget.campaignsTabKey,
                      walletKey: widget.walletTabKey,
                      invoicesKey: widget.invoicesTabKey,
                      chatKey: widget.chatTabKey,
                      showInvoicesTab: widget.showInvoicesTab,
                    ),
                    accent: coachAccent,
                    isDark: isDark,
                  ),
                Row(
                  children: [
                    Expanded(
                      child: WayoProNavTabItem(
                        tabKey: widget.dashboardTabKey,
                        coachTarget: ShellTutorialTarget.dashboard,
                        coachAccent: coachAccent,
                        icon: Icons.space_dashboard_rounded,
                        label: t.nav.dashboard,
                        isSelected: idx == 0,
                        onTap: () => _goBranch(0),
                        badge: widget.notificationUnread > 0 && idx != 0
                            ? widget.notificationUnread
                            : null,
                      ),
                    ),
                    Expanded(
                      child: WayoProNavTabItem(
                        tabKey: widget.campaignsTabKey,
                        coachTarget: ShellTutorialTarget.campaigns,
                        coachAccent: coachAccent,
                        icon: Icons.work_rounded,
                        label: t.nav.campaigns,
                        isSelected: idx == 1,
                        onTap: () => _goBranch(1),
                        showDot: widget.campaignsAttentionCount > 0,
                      ),
                    ),
                    Expanded(
                      child: WayoProNavTabItem(
                        tabKey: widget.walletTabKey,
                        coachTarget: ShellTutorialTarget.wallet,
                        coachAccent: coachAccent,
                        icon: Icons.account_balance_wallet_rounded,
                        label: t.nav.wallet,
                        isSelected: idx == 2,
                        onTap: () => _goBranch(2),
                      ),
                    ),
                    if (widget.showInvoicesTab)
                      Expanded(
                        child: WayoProNavTabItem(
                          tabKey: widget.invoicesTabKey,
                          coachTarget: ShellTutorialTarget.invoices,
                          coachAccent: coachAccent,
                          icon: Icons.receipt_long_rounded,
                          label: widget.invoicesNavLabel,
                          isSelected: idx == 3,
                          onTap: () => _goBranch(3),
                        ),
                      ),
                    Expanded(
                      child: WayoProNavTabItem(
                        tabKey: widget.chatTabKey,
                        coachTarget: ShellTutorialTarget.chat,
                        coachAccent: coachAccent,
                        icon: Icons.forum_rounded,
                        label: t.nav.chat,
                        isSelected: idx == 4,
                        onTap: () => _goBranch(4),
                        badge: widget.chatUnread > 0 && idx != 4
                            ? widget.chatUnread
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

/// Single pill that slides between tab cells — avoids overlap on the previous icon.
class _SlidingCoachHighlight extends StatefulWidget {
  const _SlidingCoachHighlight({
    required this.stackKey,
    required this.tabKey,
    required this.accent,
    required this.isDark,
  });

  final GlobalKey stackKey;
  final GlobalKey? tabKey;
  final Color accent;
  final bool isDark;

  @override
  State<_SlidingCoachHighlight> createState() => _SlidingCoachHighlightState();
}

class _SlidingCoachHighlightState extends State<_SlidingCoachHighlight> {
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    shellTutorialHighlightTab.addListener(_scheduleMeasure);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _SlidingCoachHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabKey != widget.tabKey) {
      _scheduleMeasure();
    }
  }

  @override
  void dispose() {
    shellTutorialHighlightTab.removeListener(_scheduleMeasure);
    super.dispose();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
  }

  void _measure() {
    final tabKey = widget.tabKey;
    if (tabKey == null) return;

    final tabBox = tabKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox =
        widget.stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (tabBox == null || stackBox == null || !tabBox.hasSize) return;

    final topLeft = tabBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final nextRect = topLeft & tabBox.size;
    if (_rect == nextRect) return;

    setState(() => _rect = nextRect);
  }

  @override
  Widget build(BuildContext context) {
    final rect = _rect;
    if (rect == null) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: shellTutorialSlideDuration,
      curve: shellTutorialSlideCurve,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(kWayoNavCoachMarkRadius + 2),
            border: Border.all(color: widget.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.4),
                blurRadius: 14,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared tab cell for advertiser, creator, and superadmin bottom nav bars.
class WayoProNavTabItem extends StatelessWidget {
  const WayoProNavTabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.showDot = false,
    this.tabKey,
    this.coachTarget,
    this.coachAccent = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;
  final bool showDot;
  final GlobalKey? tabKey;
  final ShellTutorialTarget? coachTarget;
  final Color coachAccent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = coachAccent;

    return ValueListenableBuilder<ShellTutorialTarget?>(
      valueListenable: shellTutorialHighlightTab,
      builder: (context, coachFocused, _) {
        final isCoachFocused =
            coachTarget != null && coachFocused == coachTarget;
        final highlightDuration = const Duration(milliseconds: 200);
        const highlightCurve = Curves.easeOutCubic;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox.expand(
            key: tabKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: AnimatedContainer(
                duration: highlightDuration,
                curve: highlightCurve,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(kWayoNavCoachMarkRadius + 2),
                  border: Border.all(color: Colors.transparent, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: highlightDuration,
                          curve: highlightCurve,
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            icon,
                            size: 22,
                            color: isCoachFocused || isSelected
                                ? accent
                                : (isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.black.withOpacity(0.4)),
                          ),
                        ),
                        if (badge != null && badge! > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                badge! > 99 ? '99+' : '$badge',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (showDot && !isSelected)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF0D0D0D)
                                      : Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: highlightDuration,
                      curve: highlightCurve,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCoachFocused || isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isCoachFocused || isSelected
                            ? accent
                            : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.4)),
                        letterSpacing: isCoachFocused || isSelected ? 0.3 : 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
