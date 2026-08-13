import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Material 3 themes for Wayo Ads Go (light + dark).
@immutable
abstract final class AppTheme {
  static ThemeData get dark => _base(
    brightness: Brightness.dark,
    scaffold: AppColors.black,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    fill: AppColors.surfaceElevated,
    border: AppColors.border,
  );

  static ThemeData get light => _base(
    brightness: Brightness.light,
    scaffold: AppColors.canvasLight,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    fill: AppColors.surfaceElevatedLight,
    border: AppColors.borderLight,
  );

  static ThemeData _base({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color fill,
    required Color border,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
          surface: surface,
          error: AppColors.error,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          onSurface: onSurface,
        );

    final baseText = ThemeData(brightness: brightness).textTheme;
    final textTheme = GoogleFonts.interTextTheme(
      baseText,
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: scheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      // Default [AppBar] titles use the same H1 as body headers (see [AppTextStyles.pageTitle]).
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.pageTitleForTheme(onSurface),
        iconTheme: IconThemeData(color: onSurface),
      ),
      // Baseline for any remaining raw SnackBars; WayoToast renders its own card.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF17171F)
            : const Color(0xFF1F2430),
        contentTextStyle: GoogleFonts.dmSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        actionTextColor: AppColors.primarySoft,
        insetPadding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Premium baseline for every [AlertDialog] / [Dialog] (WayoAlertDialog
      // adds icon badge + action button polish on top of this).
      dialogTheme: DialogThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF1C1816)
            : const Color(0xFFFFFBF8),
        surfaceTintColor: Colors.transparent,
        elevation: 28,
        shadowColor: Colors.black.withValues(
          alpha: brightness == Brightness.dark ? 0.55 : 0.22,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: (brightness == Brightness.dark ? Colors.white : Colors.black)
                .withValues(alpha: 0.06),
          ),
        ),
        titleTextStyle: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.25,
          color: onSurface,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: brightness == Brightness.dark
              ? AppColors.textSecondary
              : AppColors.textSecondaryLight,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brightness == Brightness.dark
              ? AppColors.textSecondary
              : AppColors.textSecondaryLight,
          textStyle: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: TextStyle(
          color: brightness == Brightness.dark
              ? AppColors.textSecondary
              : AppColors.textSecondaryLight,
        ),
        hintStyle: TextStyle(
          color: brightness == Brightness.dark
              ? AppColors.textMuted
              : AppColors.textMutedLight,
        ),
      ),
    );
  }
}
