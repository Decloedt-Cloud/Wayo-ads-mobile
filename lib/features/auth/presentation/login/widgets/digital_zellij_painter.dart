import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// One geometric module in the digital zellij field (square / diamond / outline).
@immutable
final class ZellijCell {
  const ZellijCell({
    required this.center,
    required this.halfExtent,
    required this.phase,
    required this.kind,
    required this.seed,
  });

  final Offset center;
  final double halfExtent;
  final double phase;
  final int kind;
  final double seed;
}

/// Builds a sparse zellij-inspired field (top-right + bottom-left clusters).
List<ZellijCell> buildZellijCells(Size size) {
  final rnd = math.Random(42);
  final cells = <ZellijCell>[];
  const spacing = 24.0;

  void sprinkle(Rect bounds) {
    for (var y = bounds.top; y < bounds.bottom; y += spacing) {
      for (var x = bounds.left; x < bounds.right; x += spacing) {
        if (rnd.nextDouble() > 0.52) {
          continue;
        }
        final cx = x + rnd.nextDouble() * 6;
        final cy = y + rnd.nextDouble() * 6;
        final h = spacing * (0.32 + rnd.nextDouble() * 0.28);
        final center = Offset(cx, cy);
        if (!bounds.inflate(8).contains(center)) {
          continue;
        }
        cells.add(
          ZellijCell(
            center: center,
            halfExtent: h,
            phase: rnd.nextDouble() * math.pi * 2,
            kind: rnd.nextInt(3),
            seed: rnd.nextDouble(),
          ),
        );
      }
    }
  }

  sprinkle(Rect.fromLTWH(size.width * 0.52, -20, size.width * 0.5, size.height * 0.48));
  sprinkle(Rect.fromLTWH(-12, size.height * 0.56, size.width * 0.46, size.height * 0.48));

  return cells;
}

/// "Magnetic Zellij Drift" — slow drift, breathing cells, rare signal chains, diagonal pulse.
class DigitalZellijPainter extends CustomPainter {
  DigitalZellijPainter({
    required this.cells,
    required this.t,
    this.isLight = false,
  });

  final List<ZellijCell> cells;
  final double t;
  final bool isLight;

  static const _kTau = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLight ? 1.15 : 1.1;

    final drift = t * _kTau * 0.08;
    final chainWave = math.sin(t * _kTau * 1.7 + 1.1);
    final vis = isLight ? 1.45 : 1.0;
    final maxA = isLight ? 0.26 : 0.22;

    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      final ox = math.sin(drift + c.phase) * 1.8;
      final oy = math.cos(drift * 0.9 + c.phase * 0.7) * 1.8;
      final p = c.center.translate(ox, oy);

      final breath = 0.45 + 0.55 * math.sin(t * _kTau * 0.35 + c.phase);
      final chain = ((c.seed + t * 5) % 1.0 < 0.04 && chainWave > 0.35) ? 1.35 : 1.0;
      final a = (0.045 + 0.11 * breath * chain * vis).clamp(0.03, maxA);

      if (c.kind == 0) {
        base.color = AppColors.primary.withValues(alpha: a);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: c.halfExtent * 2, height: c.halfExtent * 2),
            const Radius.circular(2.5),
          ),
          base,
        );
      } else if (c.kind == 1) {
        final strokeColor = isLight ? AppColors.primaryDeep : AppColors.primarySoft;
        stroke.color = strokeColor.withValues(alpha: a * (isLight ? 1.05 : 0.95));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: c.halfExtent * 2, height: c.halfExtent * 2),
            const Radius.circular(2),
          ),
          stroke,
        );
      } else {
        final path = Path()
          ..moveTo(p.dx, p.dy - c.halfExtent * 1.15)
          ..lineTo(p.dx + c.halfExtent * 1.15, p.dy)
          ..lineTo(p.dx, p.dy + c.halfExtent * 1.15)
          ..lineTo(p.dx - c.halfExtent * 1.15, p.dy)
          ..close();
        stroke.color = (isLight ? AppColors.primaryDeep : AppColors.primary).withValues(alpha: a * 1.1);
        canvas.drawPath(path, stroke);
      }
    }

    final sweep = (t + 0.12) % 1.0;
    final sweepA = isLight ? 0.055 : 0.07;
    final sweepMid = isLight ? 0.09 : 0.12;
    final diagPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + sweep * 2, -1),
        end: Alignment(1, 1),
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: sweepA),
          AppColors.primarySoft.withValues(alpha: sweepMid),
          AppColors.primary.withValues(alpha: sweepA),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, diagPaint);

    if (cells.length > 8 && chainWave > 0.55) {
      final link = Paint()
        ..color = AppColors.primary.withValues(alpha: isLight ? 0.11 : 0.14)
        ..strokeWidth = isLight ? 1.0 : 0.9;
      final n = math.min(cells.length - 1, 40);
      final start = (t * n).floor() % (cells.length - 1);
      for (var k = 0; k < 4; k++) {
        final i = (start + k * 3) % (cells.length - 1);
        final a = cells[i].center;
        final b = cells[i + 1].center;
        canvas.drawLine(a, b, link);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DigitalZellijPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.cells != cells ||
      oldDelegate.isLight != isLight;
}
