import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

@immutable
abstract final class AppTextStyles {
  /// Marketing / auth hero only (e.g. wordmark). Not for in-app screen titles.
  static TextStyle displayLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -1.2,
    color: AppColors.textPrimaryOf(context),
  );

  /// **H1 — Single primary title per screen or tab** (Inter, semantic text color).
  ///
  /// Use once at the top of a full-screen route or shell tab. Section headings
  /// and card titles use [headlineMedium] or smaller tokens instead.
  static TextStyle pageTitle(BuildContext context) => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.textPrimaryOf(context),
  );

  /// Same metrics as [pageTitle], with an explicit color (for [ThemeData.appBarTheme]).
  static TextStyle pageTitleForTheme(Color onSurface) => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
    color: onSurface,
  );

  /// **H2 / sections** — in-page blocks (e.g. “Campaigns”, “History”).
  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
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
