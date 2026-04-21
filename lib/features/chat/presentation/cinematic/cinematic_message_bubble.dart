import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../i18n/strings.g.dart';
import '../../data/chat_media_utils.dart';
import '../../domain/chat_message.dart';
import 'cinematic_chat_colors.dart';

/// ━━━ [3] BULLES + [4] MICRO-INTERACTIONS ━━━
class CinematicMessageBubble extends StatefulWidget {
  const CinematicMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.reduceMotion,
    required this.apiBaseUrl,
    required this.showTimestampFooter,
    this.attachmentLabel = 'Attachment',
    this.openPdfLabel = 'Open PDF',
    this.onReplyInsert,
    this.onReactAppend,
    this.peerAvatarUrl = '',
  });

  final ChatMessage message;
  final bool isMine;
  final bool reduceMotion;
  final String apiBaseUrl;
  final bool showTimestampFooter;
  final String attachmentLabel;
  final String openPdfLabel;
  final ValueChanged<String>? onReplyInsert;
  final ValueChanged<String>? onReactAppend;

  /// Conversation [display_avatar] résolu — repli si le message n’a pas `user.avatar`.
  final String peerAvatarUrl;

  @override
  State<CinematicMessageBubble> createState() => _CinematicMessageBubbleState();
}

class _CinematicMessageBubbleState extends State<CinematicMessageBubble> {
  double _dragDx = 0;

  String _timeLabel() {
    try {
      final d = DateTime.parse(widget.message.createdAt).toLocal();
      return DateFormat.Hm().format(d);
    } catch (_) {
      return '';
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showGlassMenu(BuildContext context) {
    final t = context.t;
    final m = widget.message;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final sheetTheme = CinematicChatTheme.of(ctx);
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: sheetTheme.surface.withValues(alpha: 0.96),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(ctx).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuTile(ctx, Icons.reply_rounded, t.chat.bubble_reply, () {
                    Navigator.pop(ctx);
                    widget.onReplyInsert?.call('> ${m.content}\n\n');
                  }),
                  _menuTile(ctx, Icons.copy_rounded, t.chat.bubble_copy, () async {
                    Navigator.pop(ctx);
                    await Clipboard.setData(ClipboardData(text: m.content));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.chat.bubble_copied)));
                    }
                  }),
                  _menuTile(ctx, Icons.emoji_emotions_outlined, t.chat.bubble_react, () {
                    Navigator.pop(ctx);
                    _pickEmojiFan(context);
                  }),
                  _menuTile(ctx, Icons.delete_outline_rounded, t.chat.bubble_delete, () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.chat.bubble_delete_unavailable)));
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _menuTile(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    final ct = CinematicChatTheme.of(ctx);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: ct.amber, size: 22),
              const SizedBox(width: 14),
              Text(label, style: GoogleFonts.inter(fontSize: 16, color: ct.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  void _pickEmojiFan(BuildContext context) {
    final overlay = Overlay.of(context);
    const emojis = ['❤️', '👍', '🔥', '😂', '🙏', '✨'];
    late OverlayEntry entry;
    final overlayTheme = CinematicChatTheme.of(context);
    entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => entry.remove(),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black26),
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                builder: (context, v, _) {
                  return SizedBox(
                    width: 220,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: List.generate(emojis.length, (i) {
                        final angle = -0.55 + i * 0.22;
                        final dist = 52.0 * v;
                        return Transform.translate(
                          offset: Offset(
                            math.cos(angle) * dist,
                            math.sin(angle) * dist - 10,
                          ),
                          child: Opacity(
                            opacity: v,
                            child: Material(
                              color: overlayTheme.surface,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  widget.onReactAppend?.call('${emojis[i]} ');
                                  entry.remove();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(emojis[i], style: const TextStyle(fontSize: 22)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    final m = widget.message;
    final isMine = widget.isMine;
    final reduce = widget.reduceMotion;
    final mediaUrl = resolveChatMediaUrl(m.fileUrl, widget.apiBaseUrl);
    final isImage = m.type == 'image' && mediaUrl.isNotEmpty;
    final isFile = m.type == 'file' && mediaUrl.isNotEmpty;
    final text = m.content.trim();

    final bubbleDecoration = BoxDecoration(
      borderRadius: isMine
          ? const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(4),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(22),
            ),
      gradient: isMine ? ct.sentBubble : null,
      color: isMine ? null : ct.surface,
      border: Border.all(
        color: isMine ? Colors.white.withValues(alpha: 0.08) : ct.borderSoft,
        width: 0.5,
      ),
      boxShadow: isMine ? ct.sentGlow : null,
    );

    final bubbleCore = Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
      decoration: bubbleDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 260),
                child: CachedNetworkImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: ct.amber)),
                  ),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.broken_image_outlined, color: ct.muted),
                ),
              ),
            ),
          if (isImage && text.isNotEmpty) const SizedBox(height: 8),
          if (isFile)
            InkWell(
              onTap: () => _openUrl(mediaUrl),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: isMine ? Colors.black87 : ct.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.fileName?.trim().isNotEmpty == true ? m.fileName! : widget.attachmentLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isMine ? Colors.black.withValues(alpha: 0.9) : ct.textPrimary,
                            ),
                          ),
                          Text(
                            widget.openPdfLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isMine ? Colors.black54 : ct.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isFile && text.isNotEmpty) const SizedBox(height: 8),
          if (text.isNotEmpty)
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.45,
                color: isMine ? Colors.white : ct.textPrimary,
              ),
            )
          else if (!isImage && !isFile)
            Text(
              '[${m.type}]',
              style: GoogleFonts.inter(fontSize: 14, color: isMine ? Colors.black54 : ct.muted),
            ),
          if (isMine) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(),
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.black54),
                ),
                const SizedBox(width: 6),
                _ReceiptSwitcher(pending: m.pending, failed: m.failed),
              ],
            ),
          ],
        ],
      ),
    );

    final bubbleStack = GestureDetector(
      onHorizontalDragUpdate: (d) {
        if (!isMine) return;
        setState(() => _dragDx = (_dragDx + d.delta.dx).clamp(0.0, 72.0));
      },
      onHorizontalDragEnd: (_) {
        if (_dragDx > 36) {
          widget.onReplyInsert?.call('> ${m.content}\n\n');
          HapticFeedback.lightImpact();
        }
        setState(() => _dragDx = 0);
      },
      onLongPress: () => _showGlassMenu(context),
      onDoubleTap: () {
        HapticFeedback.selectionClick();
        _pickEmojiFan(context);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_dragDx > 4 && isMine)
            Positioned(
              left: -3,
              top: 8,
              bottom: 8,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: ct.amber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(isMine ? _dragDx * 0.15 : 0, 0),
            child: bubbleCore,
          ),
        ],
      ),
    );

    final column = Column(
      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubbleStack,
        if (widget.showTimestampFooter)
          Padding(
            padding: EdgeInsets.only(left: isMine ? 0 : 16, right: isMine ? 16 : 0, top: 2),
            child: Text(
              _timeLabel(),
              style: GoogleFonts.inter(fontSize: 10, color: ct.muted),
            ),
          ),
      ],
    );

    final peerPhoto = !isMine
        ? () {
            final fromMsg = resolveChatMediaUrl(m.user?.avatar, widget.apiBaseUrl);
            if (fromMsg.isNotEmpty) return fromMsg;
            return widget.peerAvatarUrl;
          }()
        : '';

    Widget aligned = isMine
        ? Align(alignment: Alignment.centerRight, child: column)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (peerPhoto.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 6, bottom: 6),
                  child: _CinematicPeerBubbleAvatar(url: peerPhoto, diameter: 30),
                ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: column,
                ),
              ),
            ],
          );

    if (reduce) return aligned;

    return aligned
        .animate()
        .fade(duration: 320.ms, curve: Curves.easeOut)
        .slideY(begin: 24 / MediaQuery.sizeOf(context).height, end: 0, duration: 320.ms, curve: Curves.easeOutBack);
  }
}

class _CinematicPeerBubbleAvatar extends StatelessWidget {
  const _CinematicPeerBubbleAvatar({required this.url, required this.diameter});

  final String url;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    return ClipOval(
      child: Container(
        width: diameter,
        height: diameter,
        color: ct.surface,
        alignment: Alignment.center,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: diameter,
          height: diameter,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (_, _) => SizedBox(
            width: diameter,
            height: diameter,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: ct.amber),
              ),
            ),
          ),
          errorWidget: (_, _, _) => Icon(
            Icons.person_rounded,
            size: diameter * 0.55,
            color: ct.muted,
          ),
        ),
      ),
    );
  }
}

/// ━━━ [9] RECEIPTS (simplifié) ━━━
class _ReceiptSwitcher extends StatelessWidget {
  const _ReceiptSwitcher({required this.pending, required this.failed});

  final bool pending;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    if (failed) {
      return const Icon(Icons.error_outline, size: 14, color: Colors.black54);
    }
    if (pending) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.4,
          color: Colors.black.withValues(alpha: 0.45),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: Icon(
        Icons.done_all_rounded,
        key: const ValueKey('done'),
        size: 14,
        color: ct.amber.withValues(alpha: 0.95),
      ),
    );
  }
}
