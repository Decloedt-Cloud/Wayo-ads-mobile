import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/premium_chat_tokens.dart';

/// ━━━ PREMIUM INBOX HEADER ━━━
///
/// Large editorial heading + elegant subtitle, optional trailing pill action
/// (typically "new message"). Designed to live inside a [SliverToBoxAdapter]
/// or a [Column] above a scroll view.
class PremiumInboxHeader extends StatelessWidget {
  const PremiumInboxHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(22, 10, 22, 14),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = PremiumChatTokens.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accent rail (tiny gradient bar — editorial magazine feel).
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8, top: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: p.accentGradient,
                        boxShadow: [
                          BoxShadow(
                            color: p.accentWarm.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        (subtitle ?? '').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.accentWarm,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 14), trailing!],
        ],
      ),
    );
  }
}

/// Circular action button with an amber gradient — primary inbox action.
class PremiumHeaderActionButton extends StatelessWidget {
  const PremiumHeaderActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = PremiumChatTokens.of(context);
    final btn = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: p.accentGradient,
        boxShadow: p.warmGlow,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          child: Icon(icon, color: Colors.white, size: size * 0.44),
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

/// ━━━ PREMIUM SEARCH FIELD ━━━
///
/// Glassy rounded search pill with amber focus halo and leading icon.
/// The caller supplies the controller and callbacks — totally stateless shell
/// so it slots into any existing search provider / implementation.
class PremiumSearchField extends StatefulWidget {
  const PremiumSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Widget? trailing;

  @override
  State<PremiumSearchField> createState() => _PremiumSearchFieldState();
}

class _PremiumSearchFieldState extends State<PremiumSearchField> {
  late FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PremiumChatTokens.of(context);
    final radius = BorderRadius.circular(p.radiusLG);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: p.accentWarm.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ]
            : p.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: p.isDark
                  ? p.surfaceElevated.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: radius,
              border: Border.all(
                color: _focused
                    ? p.accentWarm.withValues(alpha: 0.8)
                    : p.borderHairline,
                width: _focused ? 1.2 : 0.6,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _focused ? p.accentWarm : p.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    cursorColor: p.accentWarm,
                    cursorRadius: const Radius.circular(2),
                    cursorWidth: 2,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: p.textPrimary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.hint,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: p.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (widget.controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      widget.onChanged?.call('');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: p.textTertiary,
                    ),
                  )
                else if (widget.trailing != null)
                  widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium empty/error state card for the inbox.
class PremiumStateCard extends StatelessWidget {
  const PremiumStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = PremiumChatTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    p.accentWarm.withValues(alpha: p.isDark ? 0.22 : 0.18),
                    p.accentWarm.withValues(alpha: 0.02),
                  ],
                ),
                border: Border.all(
                  color: p.accentWarm.withValues(alpha: 0.28),
                  width: 0.6,
                ),
              ),
              child: Icon(icon, size: 34, color: p.accentWarm),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: p.textSecondary,
                height: 1.45,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
