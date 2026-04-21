import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class RippleRadarPainter extends CustomPainter {
  RippleRadarPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.6;

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      final radius = maxR * phase;
      final alpha = (1 - phase) * 0.15;
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RippleRadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
