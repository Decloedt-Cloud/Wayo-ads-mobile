import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Rotating conic-gradient border for premium cards.
class AnimatedGradientBorder extends StatefulWidget {
  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.strokeWidth = 1.5,
    this.duration = const Duration(seconds: 4),
  });

  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final Duration duration;

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          foregroundPainter: _BorderPainter(
            rotation: _c.value * 2 * math.pi,
            radius: widget.borderRadius,
            strokeWidth: widget.strokeWidth,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter({
    required this.rotation,
    required this.radius,
    required this.strokeWidth,
  });

  final double rotation;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: const [
          AppColors.primary,
          Color(0xFF8B5CF6),
          AppColors.success,
          AppColors.primarySoft,
          AppColors.primary,
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(strokeWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
