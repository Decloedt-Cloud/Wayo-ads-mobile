import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ShockwavePainter extends CustomPainter {
  ShockwavePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) {
      return;
    }
    final center = size.center(Offset.zero);
    final radius = size.longestSide * progress * 0.9;
    final alpha = (1 - progress) * 0.6;

    final ring = Paint()
      ..color = AppColors.primary.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius, ring);

    final inner = Paint()
      ..color = AppColors.primary.withValues(alpha: alpha * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.85, inner);
  }

  @override
  bool shouldRepaint(covariant ShockwavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
