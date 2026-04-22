import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Mesh-style background with slowly drifting blurred orange blobs (single ticker).
class AnimatedMeshBackground extends StatefulWidget {
  const AnimatedMeshBackground({super.key});

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final blobAlphaPrimary = isLight ? 0.18 : 0.35;
    final blobAlphaDeep = isLight ? 0.14 : 0.28;
    final blobAlphaSoft = isLight ? 0.12 : 0.22;
    final vignetteMid = isLight ? 0.25 : 0.6;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) => CustomPaint(
              painter: _MeshPainter(
                progress: _controller.value,
                size: size,
                background: bg,
                blobAlphaPrimary: blobAlphaPrimary,
                blobAlphaDeep: blobAlphaDeep,
                blobAlphaSoft: blobAlphaSoft,
                vignetteMidAlpha: vignetteMid,
              ),
              size: size,
            ),
          ),
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.progress,
    required this.size,
    required this.background,
    required this.blobAlphaPrimary,
    required this.blobAlphaDeep,
    required this.blobAlphaSoft,
    required this.vignetteMidAlpha,
  });

  final double progress;
  final Size size;
  final Color background;
  final double blobAlphaPrimary;
  final double blobAlphaDeep;
  final double blobAlphaSoft;
  final double vignetteMidAlpha;

  @override
  void paint(Canvas canvas, Size _) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final t = progress * 2 * math.pi;

    final blobs = <_Blob>[
      _Blob(
        center: Offset(
          size.width * (0.25 + 0.08 * math.sin(t)),
          size.height * (0.25 + 0.06 * math.cos(t)),
        ),
        radius: size.width * 0.55,
        color: AppColors.primary.withValues(alpha: blobAlphaPrimary),
      ),
      _Blob(
        center: Offset(
          size.width * (0.85 + 0.05 * math.cos(t * 0.8)),
          size.height * (0.35 + 0.07 * math.sin(t * 0.9)),
        ),
        radius: size.width * 0.45,
        color: AppColors.primaryDeep.withValues(alpha: blobAlphaDeep),
      ),
      _Blob(
        center: Offset(
          size.width * (0.5 + 0.1 * math.sin(t * 0.6)),
          size.height * (0.95 + 0.04 * math.cos(t * 0.7)),
        ),
        radius: size.width * 0.65,
        color: AppColors.primarySoft.withValues(alpha: blobAlphaSoft),
      ),
    ];

    for (final blob in blobs) {
      final paint = Paint()
        ..shader =
            RadialGradient(
              colors: [blob.color, blob.color.withValues(alpha: 0)],
            ).createShader(
              Rect.fromCircle(center: blob.center, radius: blob.radius),
            )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
      canvas.drawCircle(blob.center, blob.radius, paint);
    }

    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color.lerp(Colors.transparent, background, vignetteMidAlpha)!,
          background,
        ],
        stops: const [0.5, 0.85, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) =>
      old.progress != progress ||
      old.size != size ||
      old.background != background ||
      old.blobAlphaPrimary != blobAlphaPrimary ||
      old.blobAlphaDeep != blobAlphaDeep ||
      old.blobAlphaSoft != blobAlphaSoft ||
      old.vignetteMidAlpha != vignetteMidAlpha;
}

class _Blob {
  _Blob({required this.center, required this.radius, required this.color});
  final Offset center;
  final double radius;
  final Color color;
}
