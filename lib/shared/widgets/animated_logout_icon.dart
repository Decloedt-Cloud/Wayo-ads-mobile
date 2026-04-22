import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Subtle looping animation for logout (tilt + slight horizontal nudge).
class AnimatedLogoutIcon extends StatefulWidget {
  const AnimatedLogoutIcon({super.key, this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  State<AnimatedLogoutIcon> createState() => _AnimatedLogoutIconState();
}

class _AnimatedLogoutIconState extends State<AnimatedLogoutIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final Animation<double> _tilt = Tween<double>(
    begin: -0.06,
    end: 0.06,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

  late final Animation<double> _slide = Tween<double>(
    begin: 0,
    end: 2,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved =
        widget.color ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_slide.value, 0),
            child: Transform.rotate(angle: _tilt.value, child: child),
          );
        },
        child: Icon(
          Icons.logout_rounded,
          size: widget.size,
          color: resolved,
          shadows: Theme.of(context).brightness == Brightness.dark
              ? [
                  Shadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
