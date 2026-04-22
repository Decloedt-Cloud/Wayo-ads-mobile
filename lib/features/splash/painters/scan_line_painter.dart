import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ScanLinePainter extends CustomPainter {
  ScanLinePainter({required this.progress, required this.dotProgress});

  final double progress;
  final double dotProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    if (dotProgress > 0 && progress < 0.02) {
      final r = 6 * dotProgress;
      final glow = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.8 * dotProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawCircle(center, r * 3, glow);
      canvas.drawCircle(
        center,
        r,
        Paint()..color = AppColors.primary.withValues(alpha: dotProgress),
      );
    }

    if (progress > 0) {
      final halfLength = size.width * 0.5 * progress;
      final rect = Rect.fromLTWH(
        center.dx - halfLength,
        center.dy - 1.2,
        halfLength * 2,
        2.4,
      );
      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.primary,
            Colors.white,
            AppColors.primary,
            Colors.transparent,
          ],
          stops: [0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, paint);

      final glow = Paint()
        ..shader = paint.shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRect(rect, glow);
    }
  }

  @override
  bool shouldRepaint(covariant ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.dotProgress != dotProgress;
}
