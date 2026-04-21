import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cinematic_chat_colors.dart';

/// Anneau dégradé ambre→corail (le texte au centre ne tourne pas).
class CinematicGradientRingPainter extends CustomPainter {
  CinematicGradientRingPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.shortestSide - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: const [
          CinematicChatColors.amber,
          CinematicChatColors.coral,
          CinematicChatColors.amber,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant CinematicGradientRingPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}
