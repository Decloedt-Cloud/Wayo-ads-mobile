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
    scaffold: const Color(0xFFFAFAFA),
    surface: Colors.white,
    onSurface: const Color(0xFF0A0A0A),
    fill: const Color(0xFFF5F5F5),
    border: const Color(0xFFE5E5E5),
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
              : const Color(0xFF525252),
        ),
        hintStyle: TextStyle(
          color: brightness == Brightness.dark
              ? AppColors.textMuted
              : const Color(0xFF737373),
        ),
      ),
    );
  }
}
