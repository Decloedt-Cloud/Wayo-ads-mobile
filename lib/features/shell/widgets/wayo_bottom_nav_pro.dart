import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../i18n/strings.g.dart';

/// Number of shell branches (dashboard, campaigns, wallet, invoices, chat).
const int kWayoShellTabCount = 5;

/// Height of the floating nav inside [WayoBottomNavPro].
const double kWayoBottomNavProHeight = 72;

/// Gap between nav bottom and safe-area inset.
const double kWayoBottomNavProOuterGap = 16;

/// Bottom inset so tab bodies clear the floating nav.
double wayoFloatingBottomNavProReserve(BuildContext context, {double extraGap = 8}) {
  return MediaQuery.viewPaddingOf(context).bottom +
      kWayoBottomNavProOuterGap +
      kWayoBottomNavProHeight +
      extraGap;
}

/// Brand amber primary
const Color _kPrimaryAmber = Color(0xFFF47A1F);

/// Professional floating bottom nav 2026 — minimal, clean, with onboarding support.
class WayoBottomNavPro extends StatefulWidget {
  const WayoBottomNavPro({
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
    this.onboardingStep,
    this.showOnboardingHighlight = false,
  });

  final StatefulNavigationShell navigationShell;
  final int notificationUnread;
  final int chatUnread;
  final bool showInvoicesTab;
  final String invoicesNavLabel;
  final int campaignsAttentionCount;

  final GlobalKey? dashboardTabKey;
  final GlobalKey? campaignsTabKey;
  final GlobalKey? walletTabKey;
  final GlobalKey? invoicesTabKey;
  final GlobalKey? chatTabKey;
  
  /// Current onboarding step (0-4 for each tab, null if not in onboarding)
  final int? onboardingStep;
  final bool showOnboardingHighlight;

  @override
  State<WayoBottomNavPro> createState() => _WayoBottomNavProState();
}

class _WayoBottomNavProState extends State<WayoBottomNavPro>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late final AnimationController _indicatorController;
  late final AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = _shellToVisual(widget.navigationShell.currentIndex);
    
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.showOnboardingHighlight) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WayoBottomNavPro oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = _shellToVisual(widget.navigationShell.currentIndex);
    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
    }
    
    if (widget.showOnboardingHighlight && !oldWidget.showOnboardingHighlight) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.showOnboardingHighlight && oldWidget.showOnboardingHighlight) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  int get _visibleTabCount =>
      widget.showInvoicesTab ? kWayoShellTabCount : kWayoShellTabCount - 1;

  int _shellToVisual(int shell) {
    if (widget.showInvoicesTab) return shell;
    if (shell < 3) return shell;
    if (shell == 3) return 2;
    return shell - 1;
  }

  int _visualToShell(int visual) {
    if (widget.showInvoicesTab) return visual;
    if (visual < 3) return visual;
    return visual + 1;
  }

  void _onTap(int visualIndex) {
    HapticFeedback.lightImpact();
    final shell = _visualToShell(visualIndex);
    widget.navigationShell.goBranch(
      shell,
      initialLocation: shell == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idx = widget.navigationShell.currentIndex;
    final chatShellIndex = widget.showInvoicesTab ? 4 : 3;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom + kWayoBottomNavProOuterGap;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
      child: Container(
        height: kWayoBottomNavProHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1C) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.08) 
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? _kPrimaryAmber.withOpacity(0.08) 
                  : Colors.black.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ProTabItem(
                  key: widget.dashboardTabKey,
                  icon: Icons.space_dashboard_rounded,
                  iconOutlined: Icons.space_dashboard_outlined,
                  label: t.nav.dashboard,
                  isSelected: idx == 0,
                  onTap: () => _onTap(0),
                  badge: widget.notificationUnread > 0 && idx != 0 
                      ? widget.notificationUnread 
                      : null,
                  isOnboardingTarget: widget.onboardingStep == 0,
                  pulseAnimation: _pulseAnimation,
                  isDark: isDark,
                ),
                _ProTabItem(
                  key: widget.campaignsTabKey,
                  icon: Icons.work_rounded,
                  iconOutlined: Icons.work_outline_rounded,
                  label: t.nav.campaigns,
                  isSelected: idx == 1,
                  onTap: () => _onTap(1),
                  showDot: widget.campaignsAttentionCount > 0,
                  isOnboardingTarget: widget.onboardingStep == 1,
                  pulseAnimation: _pulseAnimation,
                  isDark: isDark,
                ),
                _ProTabItem(
                  key: widget.walletTabKey,
                  icon: Icons.account_balance_wallet_rounded,
                  iconOutlined: Icons.account_balance_wallet_outlined,
                  label: t.nav.wallet,
                  isSelected: idx == 2,
                  onTap: () => _onTap(2),
                  isOnboardingTarget: widget.onboardingStep == 2,
                  pulseAnimation: _pulseAnimation,
                  isDark: isDark,
                ),
                if (widget.showInvoicesTab)
                  _ProTabItem(
                    key: widget.invoicesTabKey,
                    icon: Icons.receipt_long_rounded,
                    iconOutlined: Icons.receipt_long_outlined,
                    label: widget.invoicesNavLabel,
                    isSelected: idx == 3,
                    onTap: () => _onTap(3),
                    isOnboardingTarget: widget.onboardingStep == 3,
                    pulseAnimation: _pulseAnimation,
                    isDark: isDark,
                  ),
                _ProTabItem(
                  key: widget.chatTabKey,
                  icon: Icons.forum_rounded,
                  iconOutlined: Icons.forum_outlined,
                  label: t.nav.chat,
                  isSelected: idx == chatShellIndex,
                  onTap: () => _onTap(chatShellIndex),
                  badge: widget.chatUnread > 0 && idx != chatShellIndex 
                      ? widget.chatUnread 
                      : null,
                  isOnboardingTarget: widget.onboardingStep == 4,
                  pulseAnimation: _pulseAnimation,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProTabItem extends StatefulWidget {
  const _ProTabItem({
    super.key,
    required this.icon,
    required this.iconOutlined,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.badge,
    this.showDot = false,
    this.isOnboardingTarget = false,
    this.pulseAnimation,
  });

  final IconData icon;
  final IconData iconOutlined;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final int? badge;
  final bool showDot;
  final bool isOnboardingTarget;
  final Animation<double>? pulseAnimation;

  @override
  State<_ProTabItem> createState() => _ProTabItemState();
}

class _ProTabItemState extends State<_ProTabItem> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _kPrimaryAmber;
    final unselectedColor = widget.isDark 
        ? Colors.white.withOpacity(0.45) 
        : Colors.black.withOpacity(0.4);
    final color = widget.isSelected ? selectedColor : unselectedColor;

    Widget child = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isSelected 
                          ? selectedColor.withOpacity(widget.isDark ? 0.2 : 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.isSelected ? widget.icon : widget.iconOutlined,
                      size: 22,
                      color: color,
                    ),
                  ),
                  // Badge
                  if (widget.badge != null && widget.badge! > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.badge! > 99 ? '99+' : '${widget.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  // Dot indicator
                  if (widget.showDot && !widget.isSelected)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isDark 
                                ? const Color(0xFF1A1A1C) 
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  letterSpacing: widget.isSelected ? 0.2 : 0,
                ),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with pulse animation for onboarding
    if (widget.isOnboardingTarget && widget.pulseAnimation != null) {
      child = AnimatedBuilder(
        animation: widget.pulseAnimation!,
        builder: (context, c) {
          return Transform.scale(
            scale: widget.pulseAnimation!.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimaryAmber.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: c,
            ),
          );
        },
        child: child,
      );
    }

    return child;
  }
}
