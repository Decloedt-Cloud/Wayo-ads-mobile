import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../i18n/strings.g.dart';

/// Number of shell branches (dashboard, campaigns, wallet, invoices, chat).
const int kWayoShellTabCount = 5;

/// Height of the floating pill row inside [WayoBottomNav] (excluding outer bottom padding).
const double kWayoBottomNavBarHeight = 88;

/// Gap between pill bottom and safe-area inset inside [WayoBottomNav].
const double kWayoBottomNavOuterBottomGap = 22;

/// Bottom inset so tab bodies clear the floating pill while [Scaffold.extendBody] is true.
///
/// Keep this formula aligned with [WayoBottomNav] layout (`OuterBottomGap` + pill height).
double wayoFloatingBottomNavReserve(BuildContext context, {double extraGap = 12}) {
  return MediaQuery.paddingOf(context).bottom +
      kWayoBottomNavOuterBottomGap +
      kWayoBottomNavBarHeight +
      extraGap;
}

/// Brand ambre 2026 (header ciné / spec).
const Color _kNavAmber = Color(0xFFF4A237);
const Color _kPillDark = Color(0xFF1C1C1E);
const Color _kPillLight = Color(0xFFF2F2F4);

/// Floating pill 2026 — spring [Curves.easeOutBack], pulse icône, badge campagnes, indicateur home.
class WayoBottomNav extends StatefulWidget {
  const WayoBottomNav({
    super.key,
    required this.navigationShell,
    required this.notificationUnread,
    required this.chatUnread,
    required this.campaignsAttentionCount,
    this.showInvoicesTab = true,
    this.dashboardTabKey,
    this.campaignsTabKey,
    this.walletTabKey,
    this.invoicesTabKey,
    this.chatTabKey,
  });

  final StatefulNavigationShell navigationShell;
  final int notificationUnread;
  final int chatUnread;

  /// When `false` (e.g. creator), hides the invoices tab and maps taps to shell
  /// branches `0,1,2,4` (skips branch `3`).
  final bool showInvoicesTab;

  /// Brouillons / campagnes à traiter (badge rouge sur l’onglet Campagnes).
  final int campaignsAttentionCount;

  /// Optional [GlobalKey]s used by the first-login coach-mark tour to locate
  /// each bottom-nav tab. Attached on the tab's outer tappable so the
  /// TutorialCoachMark overlay highlights the whole pill, not just the icon.
  final GlobalKey? dashboardTabKey;
  final GlobalKey? campaignsTabKey;
  final GlobalKey? walletTabKey;
  final GlobalKey? invoicesTabKey;
  final GlobalKey? chatTabKey;

  @override
  State<WayoBottomNav> createState() => _WayoBottomNavState();
}

class _WayoBottomNavState extends State<WayoBottomNav>
    with TickerProviderStateMixin {
  late int _idx;
  late int _slideFrom;
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final Animation<double> _slideCurve = CurvedAnimation(
    parent: _slide,
    curve: Curves.easeOutBack,
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _pulseScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0), weight: 65),
  ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOutCubic));

  int? _pressedTab;

  @override
  void initState() {
    super.initState();
    final visual = _shellToVisual(widget.navigationShell.currentIndex);
    _idx = visual;
    _slideFrom = visual;
    _slide.value = 1;
    _slide.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _slideFrom = _idx;
      }
    });
    _pulse.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant WayoBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    final visual = _shellToVisual(widget.navigationShell.currentIndex);
    final layoutChanged = oldWidget.showInvoicesTab != widget.showInvoicesTab;
    if (visual != _idx || layoutChanged) {
      _slideFrom = _idx;
      _idx = visual;
      _slide.forward(from: 0);
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _go(int visualIndex) {
    HapticFeedback.lightImpact();
    final shell = _visualToShell(visualIndex);
    widget.navigationShell.goBranch(
      shell,
      initialLocation: shell == widget.navigationShell.currentIndex,
    );
  }

  double _tSlide() => _slideCurve.value;

  int get _visibleTabCount =>
      widget.showInvoicesTab ? kWayoShellTabCount : kWayoShellTabCount - 1;

  /// Maps shell branch index → visible tab index (for pill / home indicator).
  int _shellToVisual(int shell) {
    if (widget.showInvoicesTab) return shell;
    if (shell < 3) return shell;
    if (shell == 3) {
      // Should not happen for creators: router redirects `/invoices` away.
      return 2;
    }
    return shell - 1;
  }

  int _visualToShell(int visual) {
    if (widget.showInvoicesTab) return visual;
    if (visual < 3) return visual;
    return visual + 1;
  }

  double _lerpTabX(double t, int from, int to, int tabCount) {
    if (tabCount <= 1) return 0.5;
    final a = (from + 0.5) / tabCount;
    final b = (to + 0.5) / tabCount;
    return a + (b - a) * t;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final idx = widget.navigationShell.currentIndex;
    final tabCount = _visibleTabCount;
    final bottomPad =
        MediaQuery.paddingOf(context).bottom + kWayoBottomNavOuterBottomGap;

    final pillFill = isDark ? _kPillDark : _kPillLight;
    final outerBg = theme.scaffoldBackgroundColor;
    final inactiveIcon = isDark
        ? const Color(0xFF888888)
        : const Color(0xFF6B6B6B);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final shadowColor = isDark
        ? _kNavAmber.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final cx = _lerpTabX(_tSlide(), _slideFrom, _idx, tabCount);

    return ColoredBox(
      color: outerBg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
        child: SizedBox(
          height: kWayoBottomNavBarHeight,
          width: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedBuilder(
                animation: _slideCurve,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final seg = w / tabCount;
                      const pillHMargin = 5.0;
                      final pillW = seg - pillHMargin * 2;
                      final pillLeft = cx * w - pillW / 2;

                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: pillFill,
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: shadowColor,
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 18,
                                  sigmaY: 18,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Tabs must stay LTR so tap index matches [StatefulNavigationShell.goBranch].
                                    // In RTL locales, a bare [Row] mirrors children and breaks icon ↔ branch mapping
                                    // (and the sliding pill math, which is LTR-based).
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                    Positioned(
                                      left: pillLeft.clamp(
                                        4.0,
                                        w - pillW - 4.0,
                                      ),
                                      top: 7,
                                      bottom: 7,
                                      width: pillW,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: _kNavAmber,
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _kNavAmber.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 18,
                                              spreadRadius: -2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _TabEntry(
                                          tabKey: widget.dashboardTabKey,
                                          selected: idx == 0,
                                          label: t.nav.dashboard,
                                          iconSelected: Icons.dashboard_rounded,
                                          iconIdle: Icons.dashboard_outlined,
                                          accent: inactiveIcon,
                                          onTap: () => _go(0),
                                          badge:
                                              widget.notificationUnread > 0 &&
                                                  idx != 0
                                              ? widget.notificationUnread
                                              : null,
                                          pulseScale: idx == 0
                                              ? _pulseScale.value
                                              : 1,
                                          pressed: _pressedTab == 0,
                                          onHighlight: (v) => setState(
                                            () => _pressedTab = v ? 0 : null,
                                          ),
                                        ),
                                        _TabEntry(
                                          tabKey: widget.campaignsTabKey,
                                          selected: idx == 1,
                                          label: t.nav.campaigns,
                                          iconSelected: Icons.work_rounded,
                                          iconIdle: Icons.work_outline,
                                          accent: inactiveIcon,
                                          onTap: () => _go(1),
                                          showRedDot:
                                              widget.campaignsAttentionCount >
                                              0,
                                          pulseScale: idx == 1
                                              ? _pulseScale.value
                                              : 1,
                                          pressed: _pressedTab == 1,
                                          onHighlight: (v) => setState(
                                            () => _pressedTab = v ? 1 : null,
                                          ),
                                        ),
                                        _TabEntry(
                                          tabKey: widget.walletTabKey,
                                          selected: idx == 2,
                                          label: t.nav.wallet,
                                          iconSelected: Icons
                                              .account_balance_wallet_rounded,
                                          iconIdle: Icons
                                              .account_balance_wallet_outlined,
                                          accent: inactiveIcon,
                                          onTap: () => _go(2),
                                          pulseScale: idx == 2
                                              ? _pulseScale.value
                                              : 1,
                                          pressed: _pressedTab == 2,
                                          onHighlight: (v) => setState(
                                            () => _pressedTab = v ? 2 : null,
                                          ),
                                        ),
                                        if (widget.showInvoicesTab)
                                          _TabEntry(
                                            tabKey: widget.invoicesTabKey,
                                            selected: idx == 3,
                                            label: t.nav.invoices,
                                            iconSelected:
                                                Icons.receipt_long_rounded,
                                            iconIdle:
                                                Icons.receipt_long_outlined,
                                            accent: inactiveIcon,
                                            onTap: () => _go(3),
                                            pulseScale: idx == 3
                                                ? _pulseScale.value
                                                : 1,
                                            pressed: _pressedTab == 3,
                                            onHighlight: (v) => setState(
                                              () => _pressedTab = v ? 3 : null,
                                            ),
                                          ),
                                        _TabEntry(
                                          tabKey: widget.chatTabKey,
                                          selected: idx == 4,
                                          label: t.nav.chat,
                                          iconSelected:
                                              Icons.chat_bubble_rounded,
                                          iconIdle:
                                              Icons.chat_bubble_outline_rounded,
                                          accent: inactiveIcon,
                                          onTap: () =>
                                              _go(widget.showInvoicesTab ? 4 : 3),
                                          badge:
                                              widget.chatUnread > 0 && idx != 4
                                              ? widget.chatUnread
                                              : null,
                                          badgeCap: 9,
                                          pulseScale: idx == 4
                                              ? _pulseScale.value
                                              : 1,
                                          pressed: _pressedTab ==
                                              (widget.showInvoicesTab ? 4 : 3),
                                          onHighlight: (v) => setState(
                                            () => _pressedTab = v
                                                ? (widget.showInvoicesTab
                                                      ? 4
                                                      : 3)
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 5,
                                      child: _HomeIndicator(
                                        activeIndex: _shellToVisual(idx),
                                        tabCount: tabCount,
                                        isDark: isDark,
                                      ),
                                    ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator({
    required this.activeIndex,
    required this.tabCount,
    required this.isDark,
  });

  final int activeIndex;
  final int tabCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        alignment: Alignment(
          tabCount > 1 ? -1.0 + (activeIndex / (tabCount - 1)) * 2.0 : 0,
          1,
        ),
        child: FractionallySizedBox(
          widthFactor: 1 / tabCount,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              width: 26,
              height: 3,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabEntry extends StatelessWidget {
  const _TabEntry({
    required this.selected,
    required this.label,
    required this.iconSelected,
    required this.iconIdle,
    required this.accent,
    required this.onTap,
    required this.pulseScale,
    required this.pressed,
    required this.onHighlight,
    this.badge,
    /// Above this value the label becomes `"${badgeCap}+"` (default `99` for notifications).
    this.badgeCap = 99,
    this.showRedDot = false,
    this.tabKey,
  });

  final bool selected;
  final String label;
  final IconData iconSelected;
  final IconData iconIdle;
  final Color accent;
  final VoidCallback onTap;
  final double pulseScale;
  final bool pressed;
  final void Function(bool highlighted) onHighlight;
  final int? badge;
  final int badgeCap;
  final bool showRedDot;

  /// Coach-mark anchor (see [WayoBottomNav.dashboardTabKey] and siblings).
  final GlobalKey? tabKey;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : accent;
    final labelColor = selected ? Colors.white : accent;
    final icon = selected ? iconSelected : iconIdle;

    return Expanded(
      child: Material(
        key: tabKey,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: onHighlight,
          splashColor: _kNavAmber.withValues(alpha: 0.22),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 1),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: selected ? pulseScale : 1,
                    child: Icon(
                      icon,
                      size: selected ? 26 : 24,
                      color: iconColor,
                    ),
                  ),
                  if (badge != null && badge! > 0)
                    Positioned(
                      right: -2,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.35),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          badge! > badgeCap ? '$badgeCap+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (showRedDot && !selected)
                    Positioned(
                      right: -1,
                      top: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? _kPillDark
                                : _kPillLight,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 1),
              AnimatedScale(
                scale: pressed ? 1.1 : 1.0,
                alignment: Alignment.bottomCenter,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutBack,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: labelColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}
