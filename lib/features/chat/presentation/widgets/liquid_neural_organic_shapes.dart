import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/liquid_neural_palette.dart';

/// Asymmetric rounded rect — reads “morphic” while staying clip-safe.
class LiquidNeuralBlobClipper extends CustomClipper<Path> {
  LiquidNeuralBlobClipper({required this.seed});

  final int seed;

  @override
  Path getClip(Size size) {
    final rnd = math.Random(seed);
    final tl = 18.0 + rnd.nextDouble() * 8;
    final tr = 22.0 + rnd.nextDouble() * 10;
    final br = 16.0 + rnd.nextDouble() * 8;
    final bl = 20.0 + rnd.nextDouble() * 8;
    return Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          topLeft: Radius.circular(tl),
          topRight: Radius.circular(tr),
          bottomRight: Radius.circular(br),
          bottomLeft: Radius.circular(bl),
        ),
      );
  }

  @override
  bool shouldReclip(covariant LiquidNeuralBlobClipper oldClipper) => oldClipper.seed != seed;
}

/// Expanding ring pulse (neural pulse signature). Re-run when [pulseToken] increments.
class LiquidNeuralPulseLayer extends StatefulWidget {
  const LiquidNeuralPulseLayer({
    super.key,
    required this.pulseToken,
    required this.child,
  });

  final int pulseToken;
  final Widget child;

  @override
  State<LiquidNeuralPulseLayer> createState() => _LiquidNeuralPulseLayerState();
}

class _LiquidNeuralPulseLayerState extends State<LiquidNeuralPulseLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulseToken > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _c.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant LiquidNeuralPulseLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseToken != oldWidget.pulseToken && widget.pulseToken > 0) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                if (_c.value == 0 && widget.pulseToken == 0) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _PulsePainter(
                    progress: Curves.easeOut.transform(_c.value),
                    plasma: LiquidNeuralTheme.of(context).plasma,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.progress, required this.plasma});

  final double progress;
  final Color plasma;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width * 0.22;
    final cy = size.height * 0.5;
    final maxR = size.shortestSide * 0.95;
    final r = maxR * progress;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = plasma.withValues(alpha: 0.15 * (1 - progress));
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.plasma != plasma;
}
