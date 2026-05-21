import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../i18n/strings.g.dart';
import '../cinematic/cinematic_chat_colors.dart';

/// Animated anti-spam card: countdown + progress slider until send is allowed again.
class ChatSpamCooldownBanner extends StatelessWidget {
  const ChatSpamCooldownBanner({
    super.key,
    required this.remaining,
    required this.total,
    this.reduceMotion = false,
  });

  final Duration remaining;
  final Duration total;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final ct = CinematicChatTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalMs = total.inMilliseconds.clamp(1, 1 << 31);
    final leftMs = remaining.inMilliseconds.clamp(0, totalMs);
    final progress = 1 - (leftMs / totalMs);
    final secondsLeft = (remaining.inMilliseconds / 1000).ceil().clamp(0, 9999);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ct.amber.withValues(alpha: isDark ? 0.28 : 0.2),
            ct.coral.withValues(alpha: isDark ? 0.14 : 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ct.amber.withValues(alpha: 0.45),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: ct.amber.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 20,
                  color: ct.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.chat.spam_cooldown_title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ct.textPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.chat.spam_cooldown_body(seconds: secondsLeft),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.3,
                        color: ct.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                t.chat.spam_cooldown_seconds(seconds: secondsLeft),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ct.amber,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: ct.amber,
                  inactiveTrackColor: ct.textPrimary.withValues(alpha: 0.12),
                  disabledActiveTrackColor: ct.amber,
                  disabledInactiveTrackColor:
                      ct.textPrimary.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: null,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) return card;

    return card
        .animate()
        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.12, duration: 320.ms, curve: Curves.easeOutCubic);
  }
}
