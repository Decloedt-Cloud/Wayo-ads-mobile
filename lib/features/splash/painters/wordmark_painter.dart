import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Pre-built [TextPainter] for `'wayo ads'` — created once outside [CustomPainter.paint].
class SplashWordmarkLayout {
  SplashWordmarkLayout(this.textPainter);

  final TextPainter textPainter;

  double get width => textPainter.width;

  double get height => textPainter.height;

  void paintAt(Canvas canvas, Offset origin) {
    textPainter.paint(canvas, origin);
  }
}

class WordmarkPainter extends CustomPainter {
  WordmarkPainter({required this.layout, required this.progress});

  final SplashWordmarkLayout layout;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) {
      return;
    }

    final center = size.center(Offset.zero);
    final textOrigin = Offset(center.dx - layout.width / 2, center.dy + 70);

    final revealWidth = layout.width * progress;
    final glowX = textOrigin.dx + revealWidth;
    canvas.drawRect(
      Rect.fromLTWH(glowX - 6, textOrigin.dy, 12, layout.height),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        textOrigin.dx,
        textOrigin.dy - 4,
        revealWidth,
        layout.height + 8,
      ),
    );
    layout.paintAt(canvas, textOrigin);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WordmarkPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.layout != layout;
}
