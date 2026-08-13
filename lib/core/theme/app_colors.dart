import 'package:flutter/material.dart';

/// Centralised brand colors for Wayo Ads Go.
///
/// Light canvas tokens are shared with Creator Studio for a consistent
/// warm off-white + orange brand look.
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

  // Base (light) — warm cream canvas (campaign wizard / shell parity)
  static const Color canvasLight = Color(0xFFF8F6F3);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF3F1EE);
  static const Color borderLight = Color(0xFFE8E4DF);
  static const Color textPrimaryLight = Color(0xFF0A0A0A);
  static const Color textSecondaryLight = Color(0xFF525252);
  static const Color textMutedLight = Color(0xFF737373);

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
      : textPrimaryLight;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textSecondary
      : textSecondaryLight;

  static Color textMutedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textMuted
      : textMutedLight;

  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? surface
      : surfaceLight;

  static Color surfaceElevatedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? surfaceElevated
      : surfaceElevatedLight;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? border
      : borderLight;

  static Color canvasOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? black : canvasLight;
}
