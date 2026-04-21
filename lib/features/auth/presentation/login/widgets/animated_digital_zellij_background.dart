import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'digital_zellij_painter.dart';

/// Layer 1–2: deep radial base + animated digital zellij field.
class AnimatedDigitalZellijBackground extends StatefulWidget {
  const AnimatedDigitalZellijBackground({
    super.key,
    required this.reduceMotion,
  });

  final bool reduceMotion;

  @override
  State<AnimatedDigitalZellijBackground> createState() =>
      _AnimatedDigitalZellijBackgroundState();
}

class _AnimatedDigitalZellijBackgroundState
    extends State<AnimatedDigitalZellijBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  List<ZellijCell>? _cells;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 28),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedDigitalZellijBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion != oldWidget.reduceMotion) {
      if (widget.reduceMotion) {
        _controller?.dispose();
        _controller = null;
      } else {
        _controller ??= AnimationController(
          vsync: this,
          duration: const Duration(seconds: 28),
        )..repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLight = !isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (_lastSize != size) {
          _lastSize = size;
          _cells = buildZellijCells(size);
        }
        final cells = _cells ?? const <ZellijCell>[];

        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.25),
                  radius: 1.35,
                  colors: isDark
                      ? const [
                          Color(0xFF161008),
                          Color(0xFF0C0C0C),
                          Color(0xFF0A0A0A),
                        ]
                      : const [
                          Color(0xFFFFF9F5),
                          Color(0xFFF5F0EB),
                          Color(0xFFEDE8E3),
                        ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.65, -0.55),
                  radius: 0.85,
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.09 : 0.065),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            RepaintBoundary(
              child: widget.reduceMotion
                  ? CustomPaint(
                      painter: DigitalZellijPainter(
                        cells: cells,
                        t: 0.37,
                        isLight: isLight,
                      ),
                      size: size,
                    )
                  : AnimatedBuilder(
                      animation: _controller!,
                      builder: (context, _) => CustomPaint(
                        painter: DigitalZellijPainter(
                          cells: cells,
                          t: _controller!.value,
                          isLight: isLight,
                        ),
                        size: size,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}