import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../theme/liquid_neural_palette.dart';

/// Premium typing indicator — three luminous segments with soft signal motion.
class SignalTypingIndicator extends StatefulWidget {
  const SignalTypingIndicator({super.key, this.useLiquidPalette = false});

  final bool useLiquidPalette;

  @override
  State<SignalTypingIndicator> createState() => _SignalTypingIndicatorState();
}

class _SignalTypingIndicatorState extends State<SignalTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Text(
          '…',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * math.pi * 2;
        final accent = widget.useLiquidPalette
            ? LiquidNeuralTheme.of(context).plasma
            : AppColors.primary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final wave = (math.sin(t + i * 0.85) + 1) / 2;
              final opacity = 0.35 + wave * 0.55;
              final scale = widget.useLiquidPalette ? 0.88 + wave * 0.28 : 1.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: widget.useLiquidPalette
                        ? (0.45 + wave * 0.5)
                        : 1.0,
                    child: Container(
                      width: 5,
                      height: 5 + wave * 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: accent.withValues(alpha: opacity),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.22 * wave),
                            blurRadius: 6,
                            spreadRadius: 0.2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
