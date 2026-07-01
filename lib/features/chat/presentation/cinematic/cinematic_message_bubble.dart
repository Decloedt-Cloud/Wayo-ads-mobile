import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/chat_attachment_share.dart';
import '../../data/chat_media_utils.dart';
import '../../data/chat_message_media.dart';
import '../../domain/chat_message.dart';
import '../formatting/chat_message_plain_body.dart';
import '../widgets/chat_fullscreen_image_page.dart';
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
    this.peerAvatarUrl = '',
    this.isReadByPeer = false,
    this.selected = false,
    this.onSelect,
    this.onDismissSelection,
    this.onReplyRequest,
    this.onEditRequest,
    this.onDeleteRequest,
    this.onCopyRequest,
    this.onForwardRequest,
    this.chatImageRequestHeaders,
  });

  final ChatMessage message;
  final bool isMine;
  final bool reduceMotion;
  final String apiBaseUrl;
  final bool showTimestampFooter;
  final String attachmentLabel;
  final String openPdfLabel;

  /// Conversation [display_avatar] résolu — repli si le message n’a pas `user.avatar`.
  final String peerAvatarUrl;

  /// Double-check "seen" state (only meaningful for [isMine] messages).
  final bool isReadByPeer;

  /// Currently selected (tapped) bubble → shows the inline Update / Delete bar
  /// below the bubble.
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onDismissSelection;

  /// Long-press on **others'** messages → reply composer. On **your** messages
  /// with edit/delete → shows the action bar (same as tap); swipe still starts reply.
  final VoidCallback? onReplyRequest;

  /// Tap the "edit" pill in the inline bar — thread screen switches composer to
  /// edit mode.
  final VoidCallback? onEditRequest;

  /// Tap the "delete" pill in the inline bar — thread screen opens the
  /// confirmation dialog.
  final VoidCallback? onDeleteRequest;

  /// Copies [plainBodyFromChatContent] via parent (clipboard + snackbar).
  final VoidCallback? onCopyRequest;

  /// Opens forward target picker (existing conversations only).
  final VoidCallback? onForwardRequest;

  /// Bearer + app id headers for protected chat media thumbnails (optional).
  final Map<String, String>? chatImageRequestHeaders;

  @override
  State<CinematicMessageBubble> createState() => _CinematicMessageBubbleState();
}

class _CinematicMessageBubbleState extends State<CinematicMessageBubble> {
  Future<void> _shareAttachment(
    BuildContext context,
    String url, {
    required bool isPdf,
  }) async {
    final u = url.trim();
    if (u.isEmpty) return;
    HapticFeedback.lightImpact();
    final ok = await shareChatAttachmentAsFile(
      mediaUrl: u,
      httpHeaders: widget.chatImageRequestHeaders,
      fileName: widget.message.fileName,
      isPdf: isPdf,
    );
    if (!ok && context.mounted) {
      WayoToast.error(context, context.t.chat.share_failed);
    }
  }

  /// ━━━ Horizontal inward drag (toward conversation center). WhatsApp-style reply.
  double _dragX = 0;

  static const double _swipeMaxShift = 64;
  static const double _replyTriggerDx = 40;

  @override
  void didUpdateWidget(covariant CinematicMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New server row / ack from optimistic replace — reset stray drag offset.
    if (widget.message.id != oldWidget.message.id ||
        widget.message.pending != oldWidget.message.pending) {
      _dragX = 0;
    }
  }

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

  bool _snapBackIfReducedMotion() {
    if (!widget.reduceMotion) return false;
    if (_dragX != 0) setState(() => _dragX = 0);
    return true;
  }

  void _horizontalDragReplyUpdate(double dx) {
    // Physical screen coords: inward = mine moves left (−dx), theirs moves right (+dx).
    final inward = widget.isMine ? dx < 0 : dx > 0;
    if (!inward) return;
    setState(() {
      final next = _dragX + dx;
      _dragX = widget.isMine
          ? next.clamp(-_swipeMaxShift, 0.0)
          : next.clamp(0.0, _swipeMaxShift);
    });
  }

  void _endHorizontalSwipeReply({required bool canceled}) {
    final cb = widget.onReplyRequest;
    if (_snapBackIfReducedMotion()) return;
    if (canceled || cb == null || widget.message.pending || widget.message.failed) {
      if (_dragX != 0) setState(() => _dragX = 0);
      return;
    }
    final abs = _dragX.abs();
    if (abs >= _replyTriggerDx) {
      HapticFeedback.mediumImpact();
      cb();
    }
    if (_dragX != 0) setState(() => _dragX = 0);
  }

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    final m = widget.message;
    final isMine = widget.isMine;
    final reduce = widget.reduceMotion;
    var media = resolveChatMessageMedia(m, widget.apiBaseUrl);
    var mediaUrl = media.url;
    var isImage = media.isImage || (m.pending && m.type == 'image');
    var isFile = media.isFile || (m.pending && m.type == 'file');
    if (!media.hasMedia) {
      final bodyOnly = plainBodyFromChatContent(m.content).trim();
      if (bodyOnly.isNotEmpty && looksLikeRemoteMediaUrl(bodyOnly)) {
        final url = resolveChatMediaUrl(bodyOnly, widget.apiBaseUrl);
        final ext = extensionFromFilename(bodyOnly) ?? '';
        final pdf = isChatPdfExtension(ext);
        if (url.isNotEmpty) {
          mediaUrl = url;
          isImage = !pdf;
          isFile = pdf;
          media = ChatMessageMediaView(url: url, isImage: isImage, isFile: isFile);
        }
      }
    }
    final text = chatMessageDisplayCaption(m, widget.apiBaseUrl);
    final pendingAttachment =
        m.pending && mediaUrl.isEmpty && (m.type == 'image' || m.type == 'file');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final threaded = m.replyTo;

    final bubbleRadius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(22),
          );

    final bubbleDecoration = BoxDecoration(
      borderRadius: bubbleRadius,
      gradient: isMine ? ct.sentBubble : null,
      color: isMine
          ? null
          : (isDark
                ? ct.surface.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.94)),
      border: Border.all(
        color: isMine
            ? Colors.white.withValues(alpha: 0.18)
            : ct.borderSoft.withValues(alpha: isDark ? 0.55 : 0.5),
        width: 0.6,
      ),
      boxShadow: isMine
          ? [
              BoxShadow(
                color: ct.amber.withValues(alpha: isDark ? 0.28 : 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
    );

    final canEdit =
        isMine && m.type == 'text' && !m.pending && !m.failed && !m.isDeleted;
    final canDelete = isMine && !m.pending && !m.isDeleted;
    final showCopy =
        chatMessageHasCopyableText(m) && widget.onCopyRequest != null;
    final showForward =
        chatMessageCanForward(m) && widget.onForwardRequest != null;

    final bubbleContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: m.isDeleted
          ? Text(
              context.t.chat.message_deleted,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isMine
                    ? Colors.white.withValues(alpha: 0.72)
                    : ct.muted,
              ),
            )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (threaded != null) ...[
            _ThreadedReplyPreview(
              quote: threaded.preview,
              senderLabel: threaded.senderName,
              isMine: isMine,
              amber: ct.amber,
              textPrimary: ct.textPrimary,
              muted: ct.muted,
              isDark: isDark,
            ),
            if (pendingAttachment ||
                isImage ||
                isFile ||
                text.isNotEmpty)
              const SizedBox(height: 8),
          ],
          if (pendingAttachment)
            _PendingAttachmentPreview(
              isPdf: m.type == 'file',
              label: m.fileName?.trim().isNotEmpty == true
                  ? m.fileName!
                  : (m.type == 'file'
                        ? widget.attachmentLabel
                        : widget.openPdfLabel),
              accent: ct.amber,
              muted: ct.muted,
              isMine: isMine,
            )
          else if (isImage)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: isMine
                  ? [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            openChatFullscreenImage(
                              context,
                              imageUrl: mediaUrl,
                              httpHeaders: widget.chatImageRequestHeaders,
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 420,
                                maxWidth: 280,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: mediaUrl,
                                httpHeaders: widget.chatImageRequestHeaders,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                fadeInDuration: const Duration(milliseconds: 140),
                                placeholder: (context, url) => SizedBox(
                                  height: 140,
                                  width: double.infinity,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ct.amber,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.broken_image_outlined, color: ct.muted),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ShareAttachmentCircle(
                        tooltip: context.t.chat.share_media_tooltip,
                        enabled: !m.pending && !m.failed,
                        accent: ct.amber,
                        surface: ct.surface,
                        muted: ct.muted,
                        onTap: () => _shareAttachment(
                          context,
                          mediaUrl,
                          isPdf: false,
                        ),
                      ),
                    ]
                  : [
                      _ShareAttachmentCircle(
                        tooltip: context.t.chat.share_media_tooltip,
                        enabled: !m.pending && !m.failed,
                        accent: ct.amber,
                        surface: ct.surface,
                        muted: ct.muted,
                        onTap: () => _shareAttachment(
                          context,
                          mediaUrl,
                          isPdf: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            openChatFullscreenImage(
                              context,
                              imageUrl: mediaUrl,
                              httpHeaders: widget.chatImageRequestHeaders,
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 420,
                                maxWidth: 280,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: mediaUrl,
                                httpHeaders: widget.chatImageRequestHeaders,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                fadeInDuration: const Duration(milliseconds: 140),
                                placeholder: (context, url) => SizedBox(
                                  height: 140,
                                  width: double.infinity,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ct.amber,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.broken_image_outlined, color: ct.muted),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
            ),
          if (isImage && text.isNotEmpty) const SizedBox(height: 8),
          if (isFile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: isMine
                  ? [
                      Expanded(
                        child: InkWell(
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
                                        m.fileName?.trim().isNotEmpty == true
                                            ? m.fileName!
                                            : widget.attachmentLabel,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isMine
                                              ? Colors.black.withValues(alpha: 0.9)
                                              : ct.textPrimary,
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
                      ),
                      const SizedBox(width: 8),
                      _ShareAttachmentCircle(
                        tooltip: context.t.chat.share_media_tooltip,
                        enabled: !m.pending && !m.failed,
                        accent: ct.amber,
                        surface: ct.surface,
                        muted: ct.muted,
                        onTap: () => _shareAttachment(
                          context,
                          mediaUrl,
                          isPdf: true,
                        ),
                      ),
                    ]
                  : [
                      _ShareAttachmentCircle(
                        tooltip: context.t.chat.share_media_tooltip,
                        enabled: !m.pending && !m.failed,
                        accent: ct.amber,
                        surface: ct.surface,
                        muted: ct.muted,
                        onTap: () => _shareAttachment(
                          context,
                          mediaUrl,
                          isPdf: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
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
                                        m.fileName?.trim().isNotEmpty == true
                                            ? m.fileName!
                                            : widget.attachmentLabel,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isMine
                                              ? Colors.black.withValues(alpha: 0.9)
                                              : ct.textPrimary,
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
                      ),
                    ],
            ),
          if (isFile && text.isNotEmpty) const SizedBox(height: 8),
          if (text.isNotEmpty)
            ...(() {
              final parsed = threaded != null
                  ? _ParsedReply(body: text)
                  : _parseReplyQuote(text);
              return [
                if (parsed.quote != null) ...[
                  _ReplyQuoteBlock(
                    quote: parsed.quote!,
                    isMine: isMine,
                    amber: ct.amber,
                    textPrimary: ct.textPrimary,
                    muted: ct.muted,
                    isDark: isDark,
                  ),
                  if (parsed.body.isNotEmpty) const SizedBox(height: 8),
                ],
                if (parsed.body.isNotEmpty)
                  Text(
                    parsed.body,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.4,
                      letterSpacing: -0.1,
                      color: isMine ? Colors.white : ct.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ];
            }())
          else if (!isImage && !isFile)
            Text(
              '[${m.type}]',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isMine ? Colors.white.withValues(alpha: 0.7) : ct.muted,
              ),
            ),
          if (isMine) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m.isEdited || (m.editedAt?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      context.t.chat.edited,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                Text(
                  _timeLabel(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.82),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                _ReceiptSwitcher(
                  pending: m.pending,
                  failed: m.failed,
                  seen: widget.isReadByPeer,
                ),
              ],
            ),
          ] else if (m.isEdited || (m.editedAt?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 2),
            Text(
              context.t.chat.edited,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: ct.muted,
              ),
            ),
          ],
        ],
      ),
    );

    final bubbleCore = Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      decoration: bubbleDecoration,
      child: ClipRRect(
        borderRadius: bubbleRadius,
        child: Stack(
          children: [
            // Inner gloss highlight — top light sheen for premium look.
            if (isMine)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 28,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            bubbleContent,
          ],
        ),
      ),
    );

    final bubbleStack = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (m.pending || m.failed || m.isDeleted) return;
        HapticFeedback.selectionClick();
        if (widget.selected) {
          widget.onDismissSelection?.call();
        } else {
          widget.onSelect?.call();
        }
      },
      onLongPress:
          (!m.pending && !m.failed && !m.isDeleted)
              ? () {
                  HapticFeedback.mediumImpact();
                  if (isMine &&
                      (canEdit || canDelete || showCopy || showForward)) {
                    if (!widget.selected) {
                      widget.onSelect?.call();
                    }
                  } else if (!isMine && widget.onReplyRequest != null) {
                    widget.onReplyRequest!.call();
                  }
                }
              : null,
      /// Glissement vers le centre du fil : tes bulles à droite → vers la gauche ; reçues à gauche → vers la droite.
      onHorizontalDragUpdate:
          widget.onReplyRequest != null &&
                  !widget.reduceMotion &&
                  !m.pending &&
                  !m.failed
              ? (d) => _horizontalDragReplyUpdate(d.delta.dx)
              : null,
      onHorizontalDragCancel: widget.onReplyRequest != null &&
              !widget.reduceMotion &&
              !m.pending &&
              !m.failed
          ? () => _endHorizontalSwipeReply(canceled: true)
          : null,
      onHorizontalDragEnd: widget.onReplyRequest != null &&
              !widget.reduceMotion &&
              !m.pending &&
              !m.failed
          ? (_) => _endHorizontalSwipeReply(canceled: false)
          : null,
      child: AnimatedScale(
        scale: widget.selected ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Transform.translate(
          offset: Offset(_dragX, 0),
          child: bubbleCore,
        ),
      ),
    );

    final showActionBar =
        widget.selected &&
        !m.pending &&
        !m.failed &&
        (showCopy ||
            showForward ||
            (isMine && (canEdit || canDelete)));

    final actionBar = showActionBar
        ? Padding(
            padding: EdgeInsets.only(
              left: isMine ? 0 : 12,
              right: isMine ? 12 : 0,
              top: 6,
            ),
            child: Align(
              alignment: isMine
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: _CinematicMessageActionBar(
                showEdit: isMine && canEdit,
                showDelete: isMine && canDelete,
                showCopy: showCopy,
                showForward: showForward,
                editLabel: context.t.chat.bubble_update,
                deleteLabel: context.t.chat.bubble_delete,
                copyLabel: context.t.chat.bubble_copy,
                forwardLabel: context.t.chat.bubble_forward,
                onEdit: () {
                  widget.onDismissSelection?.call();
                  widget.onEditRequest?.call();
                },
                onDelete: () {
                  widget.onDismissSelection?.call();
                  widget.onDeleteRequest?.call();
                },
                onCopy: () {
                  widget.onDismissSelection?.call();
                  widget.onCopyRequest?.call();
                },
                onForward: () {
                  widget.onDismissSelection?.call();
                  widget.onForwardRequest?.call();
                },
              ),
            ),
          )
        : const SizedBox.shrink();

    final column = Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubbleStack,
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: isMine ? Alignment.topRight : Alignment.topLeft,
          child: actionBar,
        ),
        if (widget.showTimestampFooter)
          Padding(
            padding: EdgeInsets.only(
              left: isMine ? 0 : 16,
              right: isMine ? 16 : 0,
              top: 2,
            ),
            child: Text(
              _timeLabel(),
              style: GoogleFonts.inter(fontSize: 10, color: ct.muted),
            ),
          ),
      ],
    );

    final peerPhoto = !isMine
        ? () {
            final fromMsg = resolveChatAvatarUrl(
              m.user?.avatar,
              widget.apiBaseUrl,
            );
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
                  child: _CinematicPeerBubbleAvatar(
                    url: peerPhoto,
                    diameter: 30,
                  ),
                ),
              Flexible(
                child: Align(alignment: Alignment.centerLeft, child: column),
              ),
            ],
          );

    if (reduce) return aligned;

    return aligned
        .animate()
        .fade(duration: 320.ms, curve: Curves.easeOut)
        .slideY(
          begin: 24 / MediaQuery.sizeOf(context).height,
          end: 0,
          duration: 320.ms,
          curve: Curves.easeOutBack,
        );
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
          memCacheWidth: (diameter * 2).toInt(),
          memCacheHeight: (diameter * 2).toInt(),
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (_, _) => SizedBox(
            width: diameter,
            height: diameter,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: ct.amber,
                ),
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

class _ShareAttachmentCircle extends StatelessWidget {
  const _ShareAttachmentCircle({
    required this.tooltip,
    required this.enabled,
    required this.accent,
    required this.surface,
    required this.muted,
    required this.onTap,
  });

  final String tooltip;
  final bool enabled;
  final Color accent;
  final Color surface;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: surface.withValues(alpha: enabled ? 0.95 : 0.5),
        shape: const CircleBorder(),
        elevation: enabled ? 2 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(
              Icons.ios_share_rounded,
              size: 19,
              color: enabled ? accent : muted.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

/// ━━━ [9] RECEIPTS (pending → sent → delivered → seen) ━━━
class _ReceiptSwitcher extends StatelessWidget {
  const _ReceiptSwitcher({
    required this.pending,
    required this.failed,
    required this.seen,
  });

  final bool pending;
  final bool failed;
  final bool seen;

  @override
  Widget build(BuildContext context) {
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
    // Mine-bubble foreground is dark-on-amber; use near-black for "delivered"
    // and a bright cyan-ish blue for "seen" (WhatsApp-style feedback).
    const seenColor = Color(0xFF2B9CE6);
    final deliveredColor = Colors.black.withValues(alpha: 0.55);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: Icon(
        Icons.done_all_rounded,
        key: ValueKey(seen ? 'seen' : 'delivered'),
        size: 16,
        color: seen ? seenColor : deliveredColor,
      ),
    );
  }
}

/// ━━━ Copy / forward / edit / delete — horizontal glass bar ━━━
class _CinematicMessageActionBar extends StatelessWidget {
  const _CinematicMessageActionBar({
    required this.showEdit,
    required this.showDelete,
    required this.showCopy,
    required this.showForward,
    required this.editLabel,
    required this.deleteLabel,
    required this.copyLabel,
    required this.forwardLabel,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onForward,
  });

  final bool showEdit;
  final bool showDelete;
  final bool showCopy;
  final bool showForward;
  final String editLabel;
  final String deleteLabel;
  final String copyLabel;
  final String forwardLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    final parts = <Widget>[];

    void pushSep() {
      if (parts.isEmpty) return;
      parts.add(
        Container(
          height: 22,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          color: ct.borderSoft.withValues(alpha: 0.6),
        ),
      );
    }

    if (showEdit) {
      parts.add(
        _ActionChip(
          icon: Icons.edit_rounded,
          label: editLabel,
          tint: ct.amber,
          onTap: onEdit,
        ),
      );
    }
    if (showDelete) {
      pushSep();
      parts.add(
        _ActionChip(
          icon: Icons.delete_outline_rounded,
          label: deleteLabel,
          tint: const Color(0xFFEF4444),
          onTap: onDelete,
        ),
      );
    }
    if (showCopy) {
      pushSep();
      parts.add(
        _ActionChip(
          icon: Icons.copy_rounded,
          label: copyLabel,
          tint: ct.textPrimary,
          onTap: onCopy,
        ),
      );
    }
    if (showForward) {
      pushSep();
      parts.add(
        _ActionChip(
          icon: Icons.forward_rounded,
          label: forwardLabel,
          tint: ct.amber,
          onTap: onForward,
        ),
      );
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: ct.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: ct.amber.withValues(alpha: 0.35),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width - 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(mainAxisSize: MainAxisSize.min, children: parts),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ct.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParsedReply {
  const _ParsedReply({this.quote, required this.body});
  final String? quote;
  final String body;
}

_ParsedReply _parseReplyQuote(String raw) {
  if (!raw.startsWith('>')) {
    return _ParsedReply(body: raw);
  }
  final lines = raw.split('\n');
  final quoteLines = <String>[];
  var i = 0;
  while (i < lines.length && lines[i].startsWith('>')) {
    quoteLines.add(lines[i].replaceFirst(RegExp(r'^>\s?'), ''));
    i++;
  }
  while (i < lines.length && lines[i].trim().isEmpty) {
    i++;
  }
  final body = lines.sublist(i).join('\n').trim();
  final quote = quoteLines.join('\n').trim();
  if (quote.isEmpty) return _ParsedReply(body: raw);
  return _ParsedReply(quote: quote, body: body);
}

class _ReplyQuoteBlock extends StatelessWidget {
  const _ReplyQuoteBlock({
    required this.quote,
    required this.isMine,
    required this.amber,
    required this.textPrimary,
    required this.muted,
    required this.isDark,
  });

  final String quote;
  final bool isMine;
  final Color amber;
  final Color textPrimary;
  final Color muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final barColor = isMine ? Colors.white.withValues(alpha: 0.95) : amber;
    final surface = isMine
        ? Colors.white.withValues(alpha: 0.16)
        : (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : amber.withValues(alpha: 0.08));
    final labelColor = isMine ? Colors.white.withValues(alpha: 0.95) : amber;
    final textColor = isMine
        ? Colors.white.withValues(alpha: 0.9)
        : textPrimary.withValues(alpha: 0.85);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isMine ? Colors.white : amber).withValues(alpha: 0.18),
            width: 0.6,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply_rounded,
                            size: 13,
                            color: labelColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.t.chat.bubble_reply.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        quote,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.3,
                          color: textColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Structured `reply_to` from API (distinct from Markdown `>` fallback).
class _ThreadedReplyPreview extends StatelessWidget {
  const _ThreadedReplyPreview({
    required this.quote,
    required this.senderLabel,
    required this.isMine,
    required this.amber,
    required this.textPrimary,
    required this.muted,
    required this.isDark,
  });

  final String quote;
  final String? senderLabel;
  final bool isMine;
  final Color amber;
  final Color textPrimary;
  final Color muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final barColor = isMine ? Colors.white.withValues(alpha: 0.95) : amber;
    final surface = isMine
        ? Colors.white.withValues(alpha: 0.14)
        : (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : amber.withValues(alpha: 0.08));
    final labelColor = isMine ? Colors.white.withValues(alpha: 0.96) : amber;
    final textColor = isMine
        ? Colors.white.withValues(alpha: 0.9)
        : textPrimary.withValues(alpha: 0.85);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isMine ? Colors.white : amber).withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.reply_rounded, size: 14, color: labelColor),
                          const SizedBox(width: 6),
                          Text(
                            context.t.chat.bubble_reply.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.75,
                              color: labelColor,
                            ),
                          ),
                          if (senderLabel != null &&
                              senderLabel!.trim().isNotEmpty)
                            Expanded(
                              child: Text(
                                senderLabel!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isMine ? labelColor : muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quote.trim(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.3,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingAttachmentPreview extends StatelessWidget {
  const _PendingAttachmentPreview({
    required this.isPdf,
    required this.label,
    required this.accent,
    required this.muted,
    required this.isMine,
  });

  final bool isPdf;
  final String label;
  final Color accent;
  final Color muted;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: isPdf ? 52 : 120,
        maxWidth: 260,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (isMine ? Colors.white : muted).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.image_outlined,
                size: isPdf ? 32 : 40,
                color: isPdf
                    ? (isMine ? Colors.black87 : accent)
                    : accent.withValues(alpha: 0.9),
              ),
              if (isPdf) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMine ? Colors.black87 : muted,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
