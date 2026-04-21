import 'package:flutter/material.dart';

import 'cinematic_chat_colors.dart';

/// ━━━ [5] TYPING INDICATOR — CINÉMATIQUE ━━━
/// 3 points en bulle sombre, hauteurs animées décalées (easeInOutSine).
class CinematicTypingDots extends StatefulWidget {
  const CinematicTypingDots({super.key});

  @override
  State<CinematicTypingDots> createState() => _CinematicTypingDotsState();
}

class _CinematicTypingDotsState extends State<CinematicTypingDots> with TickerProviderStateMixin {
  late final List<AnimationController> _c = List.generate(
    3,
    (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true),
  );

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) {
      Future<void>.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _c[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final x in _c) {
      x.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ct.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(22),
          ),
          border: Border.all(color: ct.borderSoft.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _c[i],
                builder: (context, _) {
                  final h = 6 + _c[i].value * 4;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeInOutSine,
                        width: 6,
                        height: h,
                        decoration: BoxDecoration(
                          color: ct.amber,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
