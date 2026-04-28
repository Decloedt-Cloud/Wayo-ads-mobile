import 'package:flutter/material.dart';

/// Creator-specific accent palette.
///
/// The Wayo-ads *advertiser* side uses an amber/orange gradient
/// ([AppColors.primaryGradient]). The creator side intentionally ships a
/// distinct **teal** accent so users can tell at a glance which role they're
/// operating as — while keeping the same surfaces, typography and layout.
@immutable
abstract final class CreatorColors {
  /// Primary teal (dark theme default).
  static const Color primary = Color(0xFF0FD3C4);

  /// Softer tint used in gradients and hover states.
  static const Color primarySoft = Color(0xFF34E5D4);

  /// Deeper tint used in gradients and pressed states.
  static const Color primaryDeep = Color(0xFF0A8A84);

  /// Primary teal (light theme — slightly darker for AA contrast).
  static const Color primaryLight = Color(0xFF0EA5A0);

  /// Signature creator gradient (hero / balance cards).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primarySoft, primary, primaryDeep],
    stops: [0.0, 0.55, 1.0],
  );

  /// Theme-aware primary (use this in creator widgets).
  static Color primaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primary : primaryLight;
}
