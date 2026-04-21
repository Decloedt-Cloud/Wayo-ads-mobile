import 'package:flutter/material.dart';

/// Centralised brand colors for Wayo Ads Go.
@immutable
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFFF47A1F);
  static const Color primarySoft = Color(0xFFFF9A4D);
  static const Color primaryDeep = Color(0xFFD9650F);

  // Base (dark)
  static const Color black = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1A1A1A);
  static const Color border = Color(0xFF1F1F1F);

  // Text (dark defaults)
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF707070);

  // States
  static const Color error = Color(0xFFFF4D4F);
  static const Color success = Color(0xFF22C55E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primarySoft, primary, primaryDeep],
    stops: [0.0, 0.55, 1.0],
  );

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimary
          : const Color(0xFF0A0A0A);

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondary : const Color(0xFF525252);

  static Color textMutedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMuted : const Color(0xFF737373);

  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surface : Colors.white;

  static Color surfaceElevatedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceElevated : const Color(0xFFF5F5F5);

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? border : const Color(0xFFE5E5E5);
}
