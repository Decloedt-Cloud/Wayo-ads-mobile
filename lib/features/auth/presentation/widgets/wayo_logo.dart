import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// Header / login mark — même fichier que les icônes launcher
/// [`assets/wayo ads mobile new.png`].
///
/// [BoxFit.contain] + marge évite tout rognage gauche/droite sous les coins arrondis.
class WayoLogo extends StatelessWidget {
  const WayoLogo({super.key, this.size = 72, this.enableMotion = true});

  static const String _assetPath = 'assets/wayo ads mobile new.png';

  /// Marge dans le cadre (plus petite = logo plus grand).
  static double _innerPad(double size) => size * 0.055;

  final double size;
  final bool enableMotion;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    final inset = _innerPad(size);
    final inner = size - 2 * inset;
    final logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: Colors.black,
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: Center(
              child: Image.asset(
                _assetPath,
                width: inner,
                height: inner,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
    if (!enableMotion) {
      return logo;
    }
    return logo
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1,
          end: 1.03,
          duration: 2500.ms,
          curve: Curves.easeInOut,
        );
  }
}
