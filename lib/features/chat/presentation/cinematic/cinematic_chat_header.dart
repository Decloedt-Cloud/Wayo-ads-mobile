import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/wayo_popup_menu.dart';
import '../../../../i18n/strings.g.dart';
import '../formatting/chat_partner_role.dart';
import '../widgets/chat_role_badge.dart';
import 'cinematic_chat_colors.dart';
import 'cinematic_gradient_ring_painter.dart';

/// ━━━ [2] HEADER SIGNATURE ━━━
/// SliverPersistentHeader : avatar + titre Clash-like (Outfit) + pilule statut.
///
/// Presence / titre / frappe passent dans le délégué (immutable) pour que
/// [shouldRebuild] compare les valeurs : un [ChangeNotifier] seul était ignoré sur
/// mobile lorsque Flutter réutilisait le [SliverPersistentHeader] sans rejouer
/// ce delegate alors que les ids online changeaient dans [onlineChatUserIds].
class CinematicChatHeaderDelegate extends SliverPersistentHeaderDelegate {
  CinematicChatHeaderDelegate({
    required this.headerTitle,
    required this.statusLine,
    required this.typing,
    required this.partnerOnline,
    required this.onBack,
    required this.titleLetter,
    required this.topSafeInset,
    this.partnerAvatarUrl = '',
    this.partnerRole,
    this.onDeleteConversation,
  });

  final String headerTitle;
  final String statusLine;
  final bool typing;
  final bool partnerOnline;
  final VoidCallback onBack;
  final String titleLetter;

  /// Role badge (Creator / Advertiser) shown next to the title; null hides it.
  final ChatPartnerRole? partnerRole;

  /// Resolved URL ([resolveChatMediaUrl]); empty = monogram in avatar.
  final String partnerAvatarUrl;

  /// Opens delete-conversation flow (mobile-only; web deletes from inbox).
  final VoidCallback? onDeleteConversation;

  /// Must match [MediaQuery.paddingOf(context).top] so the sliver height includes
  /// the status bar inset (otherwise inner height ≈ minExtent − inset and overflows).
  final double topSafeInset;

  /// Collapsed content budget (below status bar). Title + role badge + status
  /// pill used to sit at ~50.6px vs a 50px budget → "BOTTOM OVERFLOWED BY 0.6".
  static const double _collapsedBody = 62;
  static const double _expandedBody = 108;
  static const double _bottomPad = 4;

  @override
  double get minExtent => _collapsedBody + topSafeInset;

  @override
  double get maxExtent => _expandedBody + topSafeInset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    /// Hauteur exacte imposée par le sliver (obligatoire pour [pinned: true] : sinon
    /// `layoutExtent` > `paintExtent` et le [CustomScrollView] ne layout plus).
    final extent = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    final ct = CinematicChatTheme.of(context);
    final u = Curves.easeOutExpo.transform(t.clamp(0.0, 1.0));
    final avatar = 64.0 - (64.0 - 36.0) * u;
    final titleSize = 22.0 - (22.0 - 14.0) * u;
    final bodyHeight = (extent - topSafeInset - _bottomPad).clamp(0.0, double.infinity);
    return SizedBox(
      height: extent,
      child: Material(
        color: ct.headerBarTint,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Padding(
              padding: EdgeInsets.fromLTRB(4, topSafeInset, 12, _bottomPad),
              child: SizedBox(
                height: bodyHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: onBack,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(40, 40),
                        padding: const EdgeInsets.all(8),
                      ),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: ct.textPrimary,
                      ),
                    ),
                    _AvatarRing(
                      letter: titleLetter,
                      diameter: avatar,
                      typing: typing,
                      imageUrl: partnerAvatarUrl,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  headerTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w700,
                                    color: ct.textPrimary,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                              if (partnerRole != null) ...[
                                const SizedBox(width: 8),
                                ChatRoleBadge(
                                  role: partnerRole!,
                                  compact: u > 0.55,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: u > 0.92 ? 1 : 3),
                          _StatusPill(
                            typing: typing,
                            online: partnerOnline,
                            line: statusLine,
                            compact: u > 0.55,
                          ),
                        ],
                      ),
                    ),
                    if (onDeleteConversation != null)
                      PopupMenuButton<String>(
                        tooltip: context.t.chat.menu_more,
                        offset: const Offset(0, 8),
                        shape: WayoPopupMenu.shape(context),
                        color: WayoPopupMenu.color(context),
                        elevation: 10,
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: ct.textPrimary,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            onDeleteConversation?.call();
                          }
                        },
                        itemBuilder: (context) {
                          final t = context.t;
                          return [
                            wayoPopupMenuItem(
                              value: 'delete',
                              icon: Icons.delete_outline_rounded,
                              label: t.chat.menu_delete,
                              destructive: true,
                            ),
                          ];
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CinematicChatHeaderDelegate oldDelegate) =>
      oldDelegate.headerTitle != headerTitle ||
      oldDelegate.statusLine != statusLine ||
      oldDelegate.typing != typing ||
      oldDelegate.partnerOnline != partnerOnline ||
      oldDelegate.topSafeInset != topSafeInset ||
      oldDelegate.titleLetter != titleLetter ||
      oldDelegate.onBack != onBack ||
      oldDelegate.partnerAvatarUrl != partnerAvatarUrl ||
      oldDelegate.partnerRole != partnerRole ||
      oldDelegate.onDeleteConversation != onDeleteConversation;
}

class _AvatarRing extends StatefulWidget {
  const _AvatarRing({
    required this.letter,
    required this.diameter,
    required this.typing,
    this.imageUrl = '',
  });

  final String letter;
  final double diameter;
  final bool typing;
  final String imageUrl;

  @override
  State<_AvatarRing> createState() => _AvatarRingState();
}

class _AvatarRingState extends State<_AvatarRing>
    with SingleTickerProviderStateMixin {
  AnimationController? _spin;

  @override
  void didUpdateWidget(covariant _AvatarRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  @override
  void initState() {
    super.initState();
    _syncSpin();
  }

  void _syncSpin() {
    if (widget.typing) {
      _spin ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 60),
      )..repeat();
    } else {
      _spin?.dispose();
      _spin = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    final d = widget.diameter.clamp(36.0, 64.0);
    final inner = d - 4;
    final hasPhoto = widget.imageUrl.isNotEmpty;
    final core = ClipOval(
      child: Container(
        width: inner,
        height: inner,
        alignment: Alignment.center,
        color: ct.surface,
        child: hasPhoto
            ? CachedNetworkImage(
                imageUrl: widget.imageUrl,
                width: inner,
                height: inner,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, _) => Text(
                  widget.letter,
                  style: GoogleFonts.outfit(
                    fontSize: inner * 0.38,
                    fontWeight: FontWeight.w800,
                    color: ct.textPrimary,
                  ),
                ),
                errorWidget: (context, url, error) => Text(
                  widget.letter,
                  style: GoogleFonts.outfit(
                    fontSize: inner * 0.38,
                    fontWeight: FontWeight.w800,
                    color: ct.textPrimary,
                  ),
                ),
              )
            : Text(
                widget.letter,
                style: GoogleFonts.outfit(
                  fontSize: inner * 0.38,
                  fontWeight: FontWeight.w800,
                  color: ct.textPrimary,
                ),
              ),
      ),
    );

    final ringPaint = CustomPaint(
      size: Size(d, d),
      painter: CinematicGradientRingPainter(strokeWidth: 2.4),
    );

    final ring = _spin != null
        ? RotationTransition(turns: _spin!, child: ringPaint)
        : ringPaint;

    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.typing)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ct.amber.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ring,
          core,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.typing,
    required this.online,
    required this.line,
    this.compact = false,
  });

  final bool typing;
  final bool online;
  final String line;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (line.isEmpty && !typing) return const SizedBox.shrink();
    final ct = CinematicChatTheme.of(context);
    final t = context.t;
    final label = typing ? t.chat.typing_status : line;
    final border = typing ? ct.amber : ct.borderSoft;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: ct.textPrimary.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.08,
        ),
        border: Border.all(color: border.withValues(alpha: typing ? 0.9 : 0.4)),
        boxShadow: typing
            ? [
                BoxShadow(
                  color: ct.amber.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: compact ? 10.5 : 11,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: typing
              ? ct.amber
              : online
              ? const Color(0xFF34C759)
              : ct.muted,
        ),
      ),
    );
  }
}
