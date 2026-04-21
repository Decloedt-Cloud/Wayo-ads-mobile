import 'dart:math';

import 'package:flutter/material.dart';

/// Subtle film grain (static pattern, cheap paint).
class NoiseOverlay extends StatelessWidget {
  const NoiseOverlay({super.key, this.opacity});

  /// Defaults: slightly stronger in dark mode.
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effective = opacity ?? (isDark ? 0.04 : 0.026);
    final dotColor = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return IgnorePointer(
      child: Opacity(
        opacity: effective,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              painter: _NoisePainter(maxDots: 12000, dotColor: dotColor),
              size: constraints.biggest,
            );
          },
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({required this.maxDots, required this.dotColor});

  final int maxDots;
  final Color dotColor;
  final Random _rand = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    var count = (size.width * size.height / 80).toInt();
    if (count > maxDots) count = maxDots;
    for (var i = 0; i < count; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) =>
      oldDelegate.maxDots != maxDots || oldDelegate.dotColor != dotColor;
}
