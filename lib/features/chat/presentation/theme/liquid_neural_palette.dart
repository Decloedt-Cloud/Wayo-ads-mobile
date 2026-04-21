import 'package:flutter/material.dart';

/// Liquid Neural chat surfaces — **dark** and **light** (inbox, search, cards).
@immutable
class LiquidNeuralTheme {
  const LiquidNeuralTheme({
    required this.canvas,
    required this.plasma,
    required this.amberGlow,
    required this.textPrimary,
    required this.textSecondary,
    required this.ghostGlass,
    required this.ghostGlassStrong,
    required this.strokeSubtle,
    required this.plasmaStroke,
    required this.plasmaStrokeFocus,
    required this.sentBubble,
    required this.cardSheen,
    required this.avatarMutedGradient,
    required this.avatarPhotoPlate,
    required this.avatarBorder,
    required this.onlineBadgeBorder,
    required this.meshPlasmaAlpha1,
    required this.meshPlasmaAlpha2,
    required this.meshPlasmaAlpha3,
    required this.meshGrain,
  });

  final Color canvas;
  final Color plasma;
  final Color amberGlow;
  final Color textPrimary;
  final Color textSecondary;
  final Color ghostGlass;
  final Color ghostGlassStrong;
  final Color strokeSubtle;
  final Color plasmaStroke;
  final Color plasmaStrokeFocus;
  final LinearGradient sentBubble;
  final LinearGradient cardSheen;
  final LinearGradient avatarMutedGradient;
  final Color avatarPhotoPlate;
  final Color avatarBorder;
  final Color onlineBadgeBorder;
  final double meshPlasmaAlpha1;
  final double meshPlasmaAlpha2;
  final double meshPlasmaAlpha3;
  final Color meshGrain;

  static LiquidNeuralTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  List<BoxShadow> plasmaGlow({double blur = 28, double alpha = 0.22}) => [
        BoxShadow(
          color: plasma.withValues(alpha: alpha),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];

  static const Color _plasma = Color(0xFFFF6B00);
  static const Color _amberGlow = Color(0xFFFF9A3C);

  static final LiquidNeuralTheme dark = LiquidNeuralTheme(
    canvas: const Color(0xFF060608),
    plasma: _plasma,
    amberGlow: _amberGlow,
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: Color.fromRGBO(255, 255, 255, 0.45),
    ghostGlass: Color.fromRGBO(255, 255, 255, 0.03),
    ghostGlassStrong: Color.fromRGBO(255, 255, 255, 0.06),
    strokeSubtle: Color.fromRGBO(255, 255, 255, 0.10),
    plasmaStroke: Color.fromRGBO(255, 107, 0, 0.22),
    plasmaStrokeFocus: Color.fromRGBO(255, 107, 0, 0.75),
    sentBubble: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_plasma, _amberGlow],
    ),
    cardSheen: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromRGBO(255, 255, 255, 0.07),
        Color.fromRGBO(255, 255, 255, 0.02),
      ],
    ),
    avatarMutedGradient: const LinearGradient(
      colors: [Color(0xFF1A1A1C), Color(0xFF121214)],
    ),
    avatarPhotoPlate: const Color(0xFF121214),
    avatarBorder: Color.fromRGBO(255, 255, 255, 0.08),
    onlineBadgeBorder: const Color(0xFF060608),
    meshPlasmaAlpha1: 0.11,
    meshPlasmaAlpha2: 0.07,
    meshPlasmaAlpha3: 0.06,
    meshGrain: Color.fromRGBO(255, 255, 255, 0.012),
  );

  static final LiquidNeuralTheme light = LiquidNeuralTheme(
    canvas: const Color(0xFFF2F2F5),
    plasma: _plasma,
    amberGlow: _amberGlow,
    textPrimary: const Color(0xFF1C1C1E),
    textSecondary: Color.fromRGBO(0, 0, 0, 0.45),
    ghostGlass: Color.fromRGBO(0, 0, 0, 0.04),
    ghostGlassStrong: Color.fromRGBO(0, 0, 0, 0.07),
    strokeSubtle: Color.fromRGBO(0, 0, 0, 0.10),
    plasmaStroke: Color.fromRGBO(255, 107, 0, 0.35),
    plasmaStrokeFocus: Color.fromRGBO(255, 90, 0, 0.88),
    sentBubble: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_plasma, _amberGlow],
    ),
    cardSheen: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromRGBO(255, 107, 0, 0.08),
        Color.fromRGBO(255, 255, 255, 0.65),
      ],
    ),
    avatarMutedGradient: const LinearGradient(
      colors: [Color(0xFFE8E8EE), Color(0xFFD8D8E2)],
    ),
    avatarPhotoPlate: const Color(0xFFE4E4EA),
    avatarBorder: Color.fromRGBO(0, 0, 0, 0.08),
    onlineBadgeBorder: const Color(0xFFF2F2F5),
    meshPlasmaAlpha1: 0.07,
    meshPlasmaAlpha2: 0.045,
    meshPlasmaAlpha3: 0.038,
    meshGrain: Color.fromRGBO(0, 0, 0, 0.022),
  );
}

/// Kept for shared brand stops used where no [BuildContext] exists (e.g. tests).
abstract final class LiquidNeuralPalette {
  static const Color plasma = Color(0xFFFF6B00);
  static const Color amberGlow = Color(0xFFFF9A3C);
}
