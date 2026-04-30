import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../i18n/strings.g.dart';

/// Number of shell branches (dashboard, campaigns, wallet, chat).
const int kWayoShellTabCount = 4;

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
    this.dashboardTabKey,
    this.campaignsTabKey,
    this.walletTabKey,
    this.chatTabKey,
  });

  final StatefulNavigationShell navigationShell;
  final int notificationUnread;
  final int chatUnread;

  /// Brouillons / campagnes à traiter (badge rouge sur l’onglet Campagnes).
  final int campaignsAttentionCount;

  /// Optional [GlobalKey]s used by the first-login coach-mark tour to locate
  /// each bottom-nav tab. Attached on the tab's outer tappable so the
  /// TutorialCoachMark overlay highlights the whole pill, not just the icon.
  final GlobalKey? dashboardTabKey;
  final GlobalKey? campaignsTabKey;
  final GlobalKey? walletTabKey;
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
    _idx = widget.navigationShell.currentIndex;
    _slideFrom = _idx;
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
    final n = widget.navigationShell.currentIndex;
    if (n != _idx) {
      _slideFrom = _idx;
      _idx = n;
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

  void _go(int index) {
    HapticFeedback.lightImpact();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  double _tSlide() => _slideCurve.value;

  double _lerpTabX(double t, int from, int to) {
    if (kWayoShellTabCount <= 1) return 0.5;
    final a = (from + 0.5) / kWayoShellTabCount;
    final b = (to + 0.5) / kWayoShellTabCount;
    return a + (b - a) * t;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final idx = widget.navigationShell.currentIndex;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 14;

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

    final cx = _lerpTabX(_tSlide(), _slideFrom, _idx);

    return ColoredBox(
      color: outerBg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
        child: SizedBox(
          height: 76,
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
                      final seg = w / kWayoShellTabCount;
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
                                        _TabEntry(
                                          tabKey: widget.chatTabKey,
                                          selected: idx == 3,
                                          label: t.nav.chat,
                                          iconSelected:
                                              Icons.chat_bubble_rounded,
                                          iconIdle:
                                              Icons.chat_bubble_outline_rounded,
                                          accent: inactiveIcon,
                                          onTap: () => _go(3),
                                          badge:
                                              widget.chatUnread > 0 && idx != 3
                                              ? widget.chatUnread
                                              : null,
                                          badgeCap: 9,
                                          pulseScale: idx == 3
                                              ? _pulseScale.value
                                              : 1,
                                          pressed: _pressedTab == 3,
                                          onHighlight: (v) => setState(
                                            () => _pressedTab = v ? 3 : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 5,
                                      child: _HomeIndicator(
                                        activeIndex: idx,
                                        tabCount: kWayoShellTabCount,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 2),
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
              const SizedBox(height: 2),
              AnimatedScale(
                scale: pressed ? 1.1 : 1.0,
                alignment: Alignment.bottomCenter,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutBack,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: labelColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
