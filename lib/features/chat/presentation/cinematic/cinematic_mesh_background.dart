import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cinematic_chat_colors.dart';

/// ━━━ [1] FOND VIVANT ━━━
/// Mesh organique : 3 halos radiaux + bruit analogique (clair / sombre).
class CinematicMeshBackground extends StatefulWidget {
  const CinematicMeshBackground({super.key, required this.child});

  final Widget child;

  @override
  State<CinematicMeshBackground> createState() => _CinematicMeshBackgroundState();
}

class _CinematicMeshBackgroundState extends State<CinematicMeshBackground>
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
    final ct = CinematicChatTheme.of(context);
    if (MediaQuery.disableAnimationsOf(context)) {
      return ColoredBox(color: ct.bg, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          painter: _MeshNoisePainter(phase: _c.value, theme: ct),
          child: widget.child,
        );
      },
    );
  }
}

class _MeshNoisePainter extends CustomPainter {
  _MeshNoisePainter({required this.phase, required this.theme});

  final double phase;
  final CinematicChatTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = theme.bg);

    final t = phase * math.pi * 2;
    const amp = 60.0;

    void orb(Color c, double ax, double ay, double r, double op) {
      final ox = math.sin(t * ax + 0.4) * amp;
      final oy = math.cos(t * ay + 0.2) * amp;
      final g = Paint()
        ..shader = RadialGradient(
          colors: [c.withValues(alpha: op), Colors.transparent],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.35 + ox, size.height * 0.25 + oy),
            radius: r,
          ),
        );
      canvas.saveLayer(rect, Paint());
      canvas.drawCircle(Offset(size.width * 0.35 + ox, size.height * 0.25 + oy), r, g);
      canvas.restore();
    }

    canvas.saveLayer(rect, Paint()..blendMode = BlendMode.plus);
    orb(theme.amber, 1.0, 1.05, size.shortestSide * 0.55, theme.meshOrb1Opacity);
    orb(theme.coral, -0.95, 1.1, size.shortestSide * 0.42, theme.meshOrb2Opacity);
    orb(theme.meshDeep, 1.15, -0.9, size.shortestSide * 0.48, theme.meshOrb3Opacity);
    canvas.restore();

    final grainBase = theme.meshGrainIsDark ? const Color(0xFF000000) : Colors.white;
    final n = Paint()..color = grainBase.withValues(alpha: theme.meshNoiseAlpha);
    final rnd = math.Random((phase * 1000).round());
    for (var i = 0; i < 140; i++) {
      final x = (rnd.nextDouble() * size.width);
      final y = (rnd.nextDouble() * size.height);
      canvas.drawCircle(Offset(x, y), 0.55 + rnd.nextDouble() * 0.4, n);
    }
    for (var i = 0; i < 90; i++) {
      final x = ((i * 47 + phase * 80) % size.width);
      final y = ((i * 29 - phase * 60) % size.height);
      canvas.drawCircle(Offset(x, y), 0.45, n);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshNoisePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.theme != theme;
}
