import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

@immutable
abstract final class AppTextStyles {
  static TextStyle displayLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.2,
        color: AppColors.textPrimaryOf(context),
      );

  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
        color: AppColors.textPrimaryOf(context),
      );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondaryOf(context),
      );

  static TextStyle labelLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.textPrimaryOf(context),
      );

  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: AppColors.textMutedOf(context),
      );
}
