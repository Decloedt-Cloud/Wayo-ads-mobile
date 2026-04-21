import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class Particle {
  Particle({
    required this.origin,
    required this.target,
    required this.burstVelocity,
    required this.size,
    required this.seed,
  });

  final Offset origin;
  final Offset target;
  final Offset burstVelocity;
  final double size;
  final double seed;
}

class ParticleSystem {
  ParticleSystem({required this.count});

  final int count;
  final List<Particle> particles = [];
  final Random _rand = Random(42);

  void seed(Size size) {
    if (particles.isNotEmpty) {
      return;
    }
    final center = size.center(Offset.zero);
    const logoRadius = 44.0;

    for (var i = 0; i < count; i++) {
      final originX = center.dx + (_rand.nextDouble() - 0.5) * size.width * 0.4;
      final origin = Offset(originX, center.dy);

      final angle = (i / count) * 2 * pi;
      final target = center +
          Offset(
            cos(angle) * logoRadius,
            sin(angle) * logoRadius,
          );

      final burstAngle = _rand.nextDouble() * 2 * pi;
      final burstMagnitude = 80 + _rand.nextDouble() * 140;
      final burstVelocity = Offset(
        cos(burstAngle) * burstMagnitude,
        sin(burstAngle) * burstMagnitude,
      );

      particles.add(
        Particle(
          origin: origin,
          target: target,
          burstVelocity: burstVelocity,
          size: 1.5 + _rand.nextDouble() * 2.5,
          seed: _rand.nextDouble(),
        ),
      );
    }
  }
}

class ParticleSystemPainter extends CustomPainter {
  ParticleSystemPainter({
    required this.system,
    required this.burstProgress,
    required this.assemblyProgress,
  });

  final ParticleSystem system;
  final double burstProgress;
  final double assemblyProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (burstProgress == 0 && assemblyProgress == 0) {
      return;
    }

    final paint = Paint()..style = PaintingStyle.fill;
    const glowBlur = MaskFilter.blur(BlurStyle.normal, 8);

    for (final p in system.particles) {
      final burstPos = p.origin + p.burstVelocity * burstProgress;

      final t = assemblyProgress;
      final eased = Curves.easeOutCubic.transform(t);
      final assembled = Offset.lerp(burstPos, p.target, eased)!;

      final jitter = Offset(
        sin((t * 6 + p.seed * 10)) * (1 - t) * 3,
        cos((t * 6 + p.seed * 10)) * (1 - t) * 3,
      );
      final pos = assembled + jitter;

      final alpha = (1 - assemblyProgress * 0.3).clamp(0.2, 1.0);
      paint.color = AppColors.primary.withValues(alpha: alpha);
      final glow = Paint()
        ..color = AppColors.primary.withValues(alpha: alpha * 0.4)
        ..maskFilter = glowBlur;

      canvas.drawCircle(pos, p.size * 2.2, glow);
      canvas.drawCircle(pos, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleSystemPainter oldDelegate) =>
      oldDelegate.burstProgress != burstProgress ||
      oldDelegate.assemblyProgress != assemblyProgress;
}
