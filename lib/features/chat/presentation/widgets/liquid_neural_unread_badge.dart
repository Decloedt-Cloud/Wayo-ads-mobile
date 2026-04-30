import 'package:flutter/material.dart';

import '../formatting/chat_unread_badge_label.dart';
import '../theme/liquid_neural_palette.dart';

class LiquidNeuralUnreadBadge extends StatelessWidget {
  const LiquidNeuralUnreadBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ln = LiquidNeuralTheme.of(context);
    final label = formatChatUnreadBadgeLabel(count);
    return TweenAnimationBuilder<double>(
      key: ValueKey(label),
      tween: Tween(begin: 0.65, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: ln.sentBubble,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ln.plasma.withValues(alpha: 0.55),
              blurRadius: 14,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.2,
            height: 1,
          ),
        ),
      ),
    );
  }
}
