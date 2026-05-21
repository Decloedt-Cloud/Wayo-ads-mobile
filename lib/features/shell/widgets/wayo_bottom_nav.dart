import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../i18n/strings.g.dart';

/// Number of shell branches (dashboard, campaigns, wallet, invoices, chat).
const int kWayoShellTabCount = 5;

/// Height of the bottom nav bar.
const double kWayoBottomNavBarHeight = 72;

/// Gap between nav bottom and safe-area inset.
const double kWayoBottomNavOuterBottomGap = 0;

/// Bottom inset so tab bodies clear the nav bar.
double wayoFloatingBottomNavReserve(BuildContext context, {double extraGap = 12}) {
  return MediaQuery.viewPaddingOf(context).bottom +
      kWayoBottomNavOuterBottomGap +
      kWayoBottomNavBarHeight +
      extraGap;
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
  });

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
          child: Row(
            children: [
              Expanded(
                child: _ProNavItem(
                  tabKey: widget.dashboardTabKey,
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
                child: _ProNavItem(
                  tabKey: widget.campaignsTabKey,
                  icon: Icons.work_rounded,
                  label: t.nav.campaigns,
                  isSelected: idx == 1,
                  onTap: () => _goBranch(1),
                  showDot: widget.campaignsAttentionCount > 0,
                ),
              ),
              Expanded(
                child: _ProNavItem(
                  tabKey: widget.walletTabKey,
                  icon: Icons.account_balance_wallet_rounded,
                  label: t.nav.wallet,
                  isSelected: idx == 2,
                  onTap: () => _goBranch(2),
                ),
              ),
              if (widget.showInvoicesTab)
                Expanded(
                  child: _ProNavItem(
                    tabKey: widget.invoicesTabKey,
                    icon: Icons.receipt_long_rounded,
                    label: widget.invoicesNavLabel,
                    isSelected: idx == 3,
                    onTap: () => _goBranch(3),
                  ),
                ),
              Expanded(
                child: _ProNavItem(
                  tabKey: widget.chatTabKey,
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
        ),
      ),
    );
  }
}

class _ProNavItem extends StatelessWidget {
  const _ProNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.showDot = false,
    this.tabKey,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;
  final bool showDot;
  final GlobalKey? tabKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // GlobalKey must sit on a tight [RenderBox] (here [SizedBox.expand]), not on
    // [GestureDetector], so `tutorial_coach_mark` always gets a non-zero size for
    // the coach-mark hole on the first tab.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        key: tabKey,
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
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
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
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
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.4)),
                      letterSpacing: isSelected ? 0.3 : 0,
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
      ),
    );
  }
}
