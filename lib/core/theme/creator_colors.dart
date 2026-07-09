import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Creator accent palette — aligned with the advertiser orange ([AppColors]).
abstract final class CreatorColors {
  static const Color primary = AppColors.primary;
  static const Color primarySoft = AppColors.primarySoft;
  static const Color primaryDeep = AppColors.primaryDeep;

  /// Slightly deeper orange in light mode for contrast on pale surfaces.
  static const Color primaryLight = AppColors.primaryDeep;

  static const LinearGradient primaryGradient = AppColors.primaryGradient;

  /// Theme-aware primary accent for creator screens.
  static Color primaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primary : primaryLight;
}
