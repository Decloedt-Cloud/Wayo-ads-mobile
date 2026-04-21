import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/liquid_neural_palette.dart';

/// Monogram disc + slowly rotating plasma sweep ring + optional online pulse.
class LiquidNeuralPlasmaAvatar extends StatefulWidget {
  const LiquidNeuralPlasmaAvatar({
    super.key,
    required this.letter,
    required this.unread,
    this.online = false,
    this.heroTag,
    this.imageUrl = '',
  });

  final String letter;
  final bool unread;
  final bool online;
  final Object? heroTag;

  /// Resolved absolute URL (e.g. via [resolveChatMediaUrl]); empty = letter only.
  final String imageUrl;

  @override
  State<LiquidNeuralPlasmaAvatar> createState() => _LiquidNeuralPlasmaAvatarState();
}

class _LiquidNeuralPlasmaAvatarState extends State<LiquidNeuralPlasmaAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ln = LiquidNeuralTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final core = SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!reduce)
            AnimatedBuilder(
              animation: _spin,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(52, 52),
                  painter: _PlasmaRingPainter(
                    rotation: _spin.value * math.pi * 2,
                    intense: widget.unread,
                    plasma: ln.plasma,
                    amberGlow: ln.amberGlow,
                  ),
                );
              },
            ),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.imageUrl.isEmpty
                  ? (widget.unread
                      ? ln.sentBubble
                      : ln.avatarMutedGradient)
                  : null,
              color: widget.imageUrl.isNotEmpty ? ln.avatarPhotoPlate : null,
              border: Border.all(color: ln.avatarBorder),
              boxShadow: [
                BoxShadow(
                  color: (widget.unread ? ln.plasma : Colors.black)
                      .withValues(alpha: widget.unread ? 0.35 : (isDark ? 0.5 : 0.12)),
                  blurRadius: widget.unread ? 16 : 10,
                ),
              ],
            ),
            child: widget.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, _) => Center(
                      child: Text(
                        widget.letter,
                        style: TextStyle(
                          color: widget.unread ? Colors.black54 : ln.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => Text(
                      widget.letter,
                      style: TextStyle(
                        color: widget.unread ? Colors.black : ln.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  )
                : Text(
                    widget.letter,
                    style: TextStyle(
                      color: widget.unread ? Colors.black : ln.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
          ),
          if (widget.online)
            Positioned(
              right: 2,
              bottom: 2,
              child: _PulsingOnlineDot(borderColor: ln.onlineBadgeBorder),
            ),
        ],
      ),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: Material(color: Colors.transparent, child: core));
    }
    return core;
  }
}

class _PlasmaRingPainter extends CustomPainter {
  _PlasmaRingPainter({
    required this.rotation,
    required this.intense,
    required this.plasma,
    required this.amberGlow,
  });

  final double rotation;
  final bool intense;
  final Color plasma;
  final Color amberGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2;
    final inner = outer - 3.2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        startAngle: rotation,
        endAngle: rotation + math.pi * 2,
        colors: [
          plasma.withValues(alpha: intense ? 0.95 : 0.55),
          amberGlow.withValues(alpha: 0.35),
          Colors.transparent,
          plasma.withValues(alpha: 0.75),
        ],
        stops: const [0.0, 0.22, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: outer));
    canvas.drawCircle(c, (outer + inner) / 2, paint);
  }

  @override
  bool shouldRepaint(covariant _PlasmaRingPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.intense != intense ||
      oldDelegate.plasma != plasma ||
      oldDelegate.amberGlow != amberGlow;
}

class _PulsingOnlineDot extends StatefulWidget {
  const _PulsingOnlineDot({required this.borderColor});

  final Color borderColor;

  @override
  State<_PulsingOnlineDot> createState() => _PulsingOnlineDotState();
}

class _PulsingOnlineDotState extends State<_PulsingOnlineDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: const Color(0xFF34C759),
          shape: BoxShape.circle,
          border: Border.all(color: widget.borderColor, width: 2),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final s = 1.0 + _c.value * 0.38;
        return Transform.scale(
          scale: s,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759),
              shape: BoxShape.circle,
              border: Border.all(color: widget.borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34C759).withValues(alpha: 0.45 + 0.2 * _c.value),
                  blurRadius: 6 + 4 * _c.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
