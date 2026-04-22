import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cinematic_chat_colors.dart';

/// Éclat de particules ambrées au tap envoi (burst court).
class CinematicSendBurst extends StatefulWidget {
  const CinematicSendBurst({super.key});

  @override
  State<CinematicSendBurst> createState() => CinematicSendBurstState();
}

class CinematicSendBurstState extends State<CinematicSendBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  void play() {
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          if (_c.value == 0) return const SizedBox.shrink();
          return CustomPaint(
            painter: _BurstPainter(
              t: Curves.easeOut.transform(_c.value),
              burstColor: CinematicChatTheme.of(context).amber,
            ),
            size: const Size(120, 120),
          );
        },
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.t, required this.burstColor});

  final double t;
  final Color burstColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rnd = math.Random(7);
    for (var i = 0; i < 14; i++) {
      final ang = rnd.nextDouble() * math.pi * 2;
      final dist = 8 + t * 48 * (0.6 + rnd.nextDouble() * 0.5);
      final p = c + Offset(math.cos(ang) * dist, math.sin(ang) * dist);
      final paint = Paint()
        ..color = burstColor.withValues(alpha: (1 - t) * 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, (1 - t) * 3.2 + 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.burstColor != burstColor;
}
