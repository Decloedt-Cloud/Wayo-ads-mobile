import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/liquid_neural_palette.dart';

/// Slow “breathing” mesh — three radial nodes drifting on smooth paths.
class LiquidNeuralMeshBackdrop extends StatefulWidget {
  const LiquidNeuralMeshBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<LiquidNeuralMeshBackdrop> createState() =>
      _LiquidNeuralMeshBackdropState();
}

class _LiquidNeuralMeshBackdropState extends State<LiquidNeuralMeshBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ln = LiquidNeuralTheme.of(context);
    if (MediaQuery.disableAnimationsOf(context)) {
      return ColoredBox(color: ln.canvas, child: widget.child);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return CustomPaint(
                painter: _MeshPainter(phase: _c.value, theme: ln),
                size: Size.infinite,
              );
            },
          ),
        ),
        RepaintBoundary(child: widget.child),
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.phase, required this.theme});

  final double phase;
  final LiquidNeuralTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = theme.canvas);

    final t = phase * math.pi * 2;
    final cx = size.width * 0.52;
    final cy = size.height * 0.32;

    void radial(double ox, double oy, double r, double a) {
      final center = Offset(cx + ox, cy + oy);
      final p = Paint()
        ..shader = RadialGradient(
          colors: [
            theme.plasma.withValues(alpha: a),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, p);
    }

    radial(
      math.sin(t) * 80,
      math.cos(t * 0.9) * 70,
      size.shortestSide * 0.5,
      theme.meshPlasmaAlpha1,
    );
    radial(
      math.sin(t * 1.1 + 2) * 100,
      math.cos(t * 1.3) * 90,
      size.shortestSide * 0.38,
      theme.meshPlasmaAlpha2,
    );
    radial(
      math.sin(t * 0.85 + 4) * 60,
      math.cos(t * 1.05 + 1) * 120,
      size.shortestSide * 0.33,
      theme.meshPlasmaAlpha3,
    );

    final grain = Paint()..color = theme.meshGrain;
    for (var i = 0; i < 40; i++) {
      final x = ((i * 73) % size.width).toDouble();
      final y = ((i * 41 + phase * 600) % size.height).toDouble();
      canvas.drawCircle(Offset(x, y), 0.8, grain);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.theme != theme;
}
