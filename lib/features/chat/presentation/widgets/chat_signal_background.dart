import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Very subtle animated “signal mesh” — opacity kept low for readability.
class ChatSignalBackground extends StatefulWidget {
  const ChatSignalBackground({super.key, this.child});

  final Widget? child;

  @override
  State<ChatSignalBackground> createState() => _ChatSignalBackgroundState();
}

class _ChatSignalBackgroundState extends State<ChatSignalBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      return ColoredBox(color: AppColors.black, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          painter: _SignalMeshPainter(phase: _c.value),
          child: widget.child,
        );
      },
    );
  }
}

class _SignalMeshPainter extends CustomPainter {
  _SignalMeshPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-0.2 + phase * 0.15, -0.3),
        end: Alignment(1.1, 1.0),
        colors: const [Color(0xFF070707), Color(0xFF0E0E0E), Color(0xFF0A0A0A)],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    final glow = Paint()
      ..color = AppColors.primary.withValues(
        alpha: 0.045 + 0.02 * math.sin(phase * math.pi * 2),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);

    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.12), 120, glow);

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.white.withValues(alpha: 0.028);

    const step = 42.0;
    final ox = phase * step * 0.35;
    for (double x = -step; x < size.width + step; x += step) {
      canvas.drawLine(
        Offset(x + ox, 0),
        Offset(x + ox + step * 0.25, size.height),
        grid,
      );
    }
    for (double y = -step; y < size.height + step; y += step) {
      canvas.drawLine(
        Offset(0, y - ox * 0.2),
        Offset(size.width, y - ox * 0.2 + step * 0.15),
        grid,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalMeshPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
