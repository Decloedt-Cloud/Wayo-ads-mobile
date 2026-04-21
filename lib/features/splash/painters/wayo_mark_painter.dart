import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class WayoMarkPainter extends CustomPainter {
  WayoMarkPainter({
    required this.snapProgress,
    required this.flashProgress,
    required this.assemblyProgress,
  });

  final double snapProgress;
  final double flashProgress;
  final double assemblyProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (assemblyProgress < 0.5) {
      return;
    }
    final center = size.center(Offset.zero);
    const radius = 44.0;

    final scale = 0.8 + snapProgress * 0.2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        colors: [
          AppColors.primarySoft,
          AppColors.primary,
          AppColors.primaryDeep,
          AppColors.primary,
          AppColors.primarySoft,
        ],
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ring);

    final path = Path();
    final s = radius * 0.45;
    path.moveTo(center.dx - s * 0.4, center.dy - s * 0.6);
    path.lineTo(center.dx + s * 0.6, center.dy);
    path.lineTo(center.dx - s * 0.4, center.dy + s * 0.6);
    path.close();
    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primarySoft, AppColors.primary],
      ).createShader(Rect.fromCircle(center: center, radius: s));
    canvas.drawPath(path, fill);

    canvas.restore();

    if (flashProgress > 0 && flashProgress < 1) {
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: (1 - flashProgress) * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(center, radius * 2.5, flashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WayoMarkPainter oldDelegate) =>
      oldDelegate.snapProgress != snapProgress ||
      oldDelegate.flashProgress != flashProgress ||
      oldDelegate.assemblyProgress != assemblyProgress;
}
