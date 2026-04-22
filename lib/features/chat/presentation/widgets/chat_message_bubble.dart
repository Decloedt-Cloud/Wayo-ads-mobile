import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../theme/liquid_neural_palette.dart';
import '../../data/chat_media_utils.dart';
import '../../domain/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.reduceMotion,
    required this.apiBaseUrl,
    this.showRipple = false,
    this.attachmentLabel = 'Attachment',
    this.openPdfLabel = 'Open PDF',
    this.liquidNeural = false,
  });

  final ChatMessage message;
  final bool isMine;
  final bool reduceMotion;
  final String apiBaseUrl;
  final bool showRipple;
  final String attachmentLabel;
  final String openPdfLabel;
  final bool liquidNeural;

  @override
  Widget build(BuildContext context) {
    final ln = liquidNeural ? LiquidNeuralTheme.of(context) : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = _formatTime(message.createdAt);
    final mediaUrl = resolveChatMediaUrl(message.fileUrl, apiBaseUrl);
    final isImage = message.type == 'image' && mediaUrl.isNotEmpty;
    final isFile = message.type == 'file' && mediaUrl.isNotEmpty;
    final text = message.content.trim();

    final sentGradient = liquidNeural
        ? ln!.sentBubble
        : const LinearGradient(
            colors: [
              Color(0xFFFF8F42),
              AppColors.primary,
              AppColors.primaryDeep,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final receivedFill = liquidNeural
        ? ln!.ghostGlassStrong
        : const Color(0xFF1C1C1C);
    final borderColor = liquidNeural
        ? (isMine ? Colors.white.withValues(alpha: 0.12) : ln!.strokeSubtle)
        : (isMine
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.05));
    final shadowPlasma = liquidNeural && isMine
        ? [
            BoxShadow(
              color: ln!.plasma.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ]
        : <BoxShadow>[];

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(liquidNeural ? 22 : 18),
          topRight: Radius.circular(liquidNeural ? 22 : 18),
          bottomLeft: Radius.circular(
            isMine ? (liquidNeural ? 22 : 18) : (liquidNeural ? 8 : 4),
          ),
          bottomRight: Radius.circular(
            isMine ? (liquidNeural ? 8 : 4) : (liquidNeural ? 22 : 18),
          ),
        ),
        gradient: isMine ? sentGradient : null,
        color: isMine ? null : receivedFill,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: liquidNeural ? (isDark ? 0.45 : 0.10) : 0.35,
            ),
            blurRadius: liquidNeural ? 14 : 10,
            offset: const Offset(0, 4),
          ),
          ...shadowPlasma,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 220,
                  maxWidth: 260,
                ),
                child: _maybeDevelopPhoto(
                  liquidNeural: liquidNeural,
                  reduceMotion: reduceMotion,
                  child: CachedNetworkImage(
                    imageUrl: mediaUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: liquidNeural ? ln!.plasma : AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            if (text.isNotEmpty) const SizedBox(height: 8),
          ],
          if (isFile) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openUrl(mediaUrl),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: isMine ? Colors.black87 : AppColors.error,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.fileName?.trim().isNotEmpty == true
                                  ? message.fileName!
                                  : attachmentLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isMine
                                    ? Colors.black.withValues(alpha: 0.9)
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              openPdfLabel,
                              style: AppTextStyles.caption(context).copyWith(
                                color: isMine
                                    ? Colors.black54
                                    : AppColors.primary,
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
            if (text.isNotEmpty) const SizedBox(height: 8),
          ],
          if (text.isNotEmpty)
            Text(
              text,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isMine
                    ? Colors.black.withValues(alpha: 0.92)
                    : (liquidNeural ? ln!.textPrimary : AppColors.textPrimary),
                height: 1.35,
              ),
            )
          else if (!isImage && !isFile)
            Text(
              '[${message.type}]',
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 14,
                color: isMine ? Colors.black54 : AppColors.textMuted,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: AppTextStyles.caption(context).copyWith(
                  color: isMine
                      ? Colors.black.withValues(alpha: 0.45)
                      : AppColors.textMuted,
                ),
              ),
              if (message.pending) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.4,
                    color: isMine ? Colors.black54 : AppColors.textMuted,
                  ),
                ),
              ],
              if (message.failed) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: isMine ? Colors.black54 : AppColors.error,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (reduceMotion || !showRipple) {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      );
    }

    final anim = bubble.animate().fade(duration: 220.ms, curve: Curves.easeOut);
    if (liquidNeural) {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: isMine
            ? anim
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    curve: Curves.easeOutBack,
                    duration: 280.ms,
                  )
                  .moveX(
                    begin: 24,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  )
            : anim.moveX(
                begin: -18,
                end: 0,
                duration: 280.ms,
                curve: Curves.easeOutExpo,
              ),
      );
    }
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: anim.moveY(
        begin: 6,
        end: 0,
        duration: 240.ms,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  static Widget _maybeDevelopPhoto({
    required bool liquidNeural,
    required bool reduceMotion,
    required Widget child,
  }) {
    if (!liquidNeural || reduceMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .blur(
          begin: const Offset(14, 14),
          end: Offset.zero,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return DateFormat.Hm().format(d);
    } catch (_) {
      return '';
    }
  }
}
