import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../formatting/chat_partner_role.dart';
import '../formatting/chat_unread_badge_label.dart';
import '../theme/premium_chat_tokens.dart';
import 'chat_role_badge.dart';
import 'signal_typing_indicator.dart';

/// ━━━ PREMIUM CONVERSATION CARD ━━━
///
/// A refined, tactile conversation row that embodies the premium chat design
/// language:
///
/// * Large rounded radius (`radiusXL = 26`)
/// * Layered surface: gradient fill + glass highlight stroke + dual shadow
/// * Subtle warm peach/amber sheen when the conversation is unread
/// * Avatar with gradient photo plate + animated online halo
/// * Pinned chip (amber) and unread chip (numeric badge with glow)
/// * Typing indicator replaces preview text inline (with plasma accent)
///
/// Keeps all business logic out of the widget: parent screen is responsible
/// for providing resolved values.
class PremiumConversationCard extends StatefulWidget {
  const PremiumConversationCard({
    super.key,
    required this.title,
    required this.preview,
    required this.time,
    required this.initial,
    this.avatarUrl,
    this.unreadCount = 0,
    this.online = false,
    this.pinned = false,
    this.muted = false,
    this.typing = false,
    this.typingName,
    this.onTap,
    this.onLongPress,
    this.verified = false,
    this.partnerRole,
  });

  final String title;
  final String preview;
  final String time;
  final String initial;

  /// Resolved URL (empty string or null = render monogram).
  final String? avatarUrl;
  final int unreadCount;
  final bool online;
  final bool pinned;
  final bool muted;
  final bool typing;
  final String? typingName;
  final bool verified;

  /// Role badge (Creator / Advertiser) shown next to the title; null hides it.
  final ChatPartnerRole? partnerRole;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<PremiumConversationCard> createState() =>
      _PremiumConversationCardState();
}

class _PremiumConversationCardState extends State<PremiumConversationCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = PremiumChatTokens.of(context);
    final hasUnread = widget.unreadCount > 0;
    final radius = BorderRadius.circular(p.radiusXL);

    final gradient = hasUnread ? p.cardGradientUnread : p.cardGradient;

    return Semantics(
      button: true,
      label: widget.title,
      hint: widget.preview,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: _pressed
                ? p.pressedShadow
                : (hasUnread ? [...p.cardShadow, ...p.warmGlow] : p.cardShadow),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // Base layer: gradient + solid card color.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      gradient: gradient,
                    ),
                  ),
                ),
                // Glass sheen (top) for a ceramic look.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 44,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: p.sheen),
                    ),
                  ),
                ),
                // Hairline border (glass).
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: hasUnread
                              ? p.accentWarm.withValues(alpha: 0.28)
                              : p.borderHairline,
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                // Ambient warm orb (only unread).
                if (hasUnread)
                  Positioned(
                    top: -40,
                    right: -40,
                    child: IgnorePointer(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              p.accentWarm.withValues(
                                alpha: p.isDark ? 0.32 : 0.22,
                              ),
                              p.accentWarm.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Content
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap == null
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            widget.onTap!.call();
                          },
                    onLongPress: widget.onLongPress,
                    onHighlightChanged: (v) => setState(() => _pressed = v),
                    splashColor: p.accentWarm.withValues(alpha: 0.1),
                    highlightColor: p.accentWarm.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _PremiumAvatar(
                            initial: widget.initial,
                            imageUrl: widget.avatarUrl,
                            online: widget.online,
                            unread: hasUnread,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title row — Expanded title + fixed right
                                // column so every date sits on the exact same
                                // vertical gridline across every card.
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              widget.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w700,
                                                color: p.textPrimary,
                                                letterSpacing: -0.3,
                                                height: 1.15,
                                              ),
                                            ),
                                          ),
                                          if (widget.verified) ...[
                                            const SizedBox(width: 5),
                                            Icon(
                                              Icons.verified_rounded,
                                              size: 13,
                                              color: p.accentWarm,
                                            ),
                                          ],
                                          if (widget.partnerRole != null) ...[
                                            const SizedBox(width: 6),
                                            ChatRoleBadge(
                                              role: widget.partnerRole!,
                                              compact: true,
                                            ),
                                          ],
                                          if (widget.muted) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.notifications_off_rounded,
                                              size: 12,
                                              color: p.textTertiary,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 64,
                                      child: Text(
                                        widget.time,
                                        maxLines: 1,
                                        textAlign: TextAlign.right,
                                        softWrap: false,
                                        overflow: TextOverflow.visible,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: hasUnread
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: hasUnread
                                              ? p.accentWarm
                                              : p.textTertiary,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Preview row — same Expanded + 64px pattern
                                // keeps badge/pin perfectly under the date.
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: widget.typing
                                          ? _TypingPreview(
                                              name: widget.typingName,
                                            )
                                          : Text(
                                              widget.preview,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                height: 1.3,
                                                fontWeight: hasUnread
                                                    ? FontWeight.w500
                                                    : FontWeight.w400,
                                                color: hasUnread
                                                    ? p.textPrimary.withValues(
                                                        alpha: 0.82,
                                                      )
                                                    : p.textSecondary,
                                                letterSpacing: -0.05,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 64,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (widget.pinned)
                                            _PinnedChip(tokens: p),
                                          if (widget.pinned && hasUnread)
                                            const SizedBox(width: 6),
                                          if (hasUnread)
                                            _UnreadBadge(
                                              count: widget.unreadCount,
                                              tokens: p,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumAvatar extends StatelessWidget {
  const _PremiumAvatar({
    required this.initial,
    required this.size,
    this.imageUrl,
    this.online = false,
    this.unread = false,
  });

  final String initial;
  final double size;
  final String? imageUrl;
  final bool online;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final p = PremiumChatTokens.of(context);
    final d = size;
    final hasPhoto = (imageUrl ?? '').isNotEmpty;
    return SizedBox(
      width: d + 4,
      height: d + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer gradient ring (only for unread — acts as selection halo).
          if (unread)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: p.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: p.accentWarm.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ),
          // Core avatar.
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: d,
              height: d,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasPhoto
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          p.accentWarm.withValues(alpha: 0.22),
                          p.accentWarmDeep.withValues(alpha: 0.12),
                        ],
                      ),
                color: hasPhoto ? p.surfaceCrown : null,
                border: Border.all(color: p.borderHairline, width: 0.8),
              ),
              child: ClipOval(
                child: hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        width: d,
                        height: d,
                        memCacheWidth: (d * 2).toInt(),
                        memCacheHeight: (d * 2).toInt(),
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 180),
                        placeholder: (_, _) =>
                            _Monogram(initial: initial, p: p),
                        errorWidget: (context, url, error) =>
                            _Monogram(initial: initial, p: p),
                      )
                    : _Monogram(initial: initial, p: p),
              ),
            ),
          ),
          // Online dot (bottom-right) with a halo ring.
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.success,
                  border: Border.all(color: p.surfaceElevated, width: 2.4),
                  boxShadow: [
                    BoxShadow(
                      color: p.success.withValues(alpha: 0.55),
                      blurRadius: 8,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.initial, required this.p});
  final String initial;
  final PremiumChatTokens p;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: p.accentWarm,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _PinnedChip extends StatelessWidget {
  const _PinnedChip({required this.tokens});
  final PremiumChatTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.pinnedTint,
        border: Border.all(
          color: tokens.accentWarm.withValues(alpha: 0.28),
          width: 0.6,
        ),
      ),
      child: Icon(Icons.push_pin_rounded, size: 11, color: tokens.accentWarm),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count, required this.tokens});

  final int count;
  final PremiumChatTokens tokens;

  @override
  Widget build(BuildContext context) {
    final label = formatChatUnreadBadgeLabel(count);
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: tokens.accentGradient,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: tokens.accentWarm.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.0,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _TypingPreview extends StatelessWidget {
  const _TypingPreview({this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final p = PremiumChatTokens.of(context);
    final displayName = (name ?? '').trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SignalTypingIndicator(useLiquidPalette: true),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            displayName.isEmpty ? 'typing…' : '$displayName · typing…',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: p.accentWarm,
              height: 1.3,
              letterSpacing: -0.05,
            ),
          ),
        ),
      ],
    );
  }
}

/// Glass backdrop filter pill — reusable helper (for sheets, context menus).
class PremiumGlassSurface extends StatelessWidget {
  const PremiumGlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.blur = 20,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final p = PremiumChatTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: p.surfaceElevated.withValues(alpha: p.isDark ? 0.82 : 0.88),
            border: Border.all(color: p.borderHairline, width: 0.6),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}
