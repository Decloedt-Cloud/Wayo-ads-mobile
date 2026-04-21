import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

InputDecoration loginPremiumInputDecoration(
  BuildContext context, {
  required String labelText,
  Widget? suffixIcon,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fill = isDark ? const Color(0xFF141414) : AppColors.surfaceElevatedOf(context);
  final border = isDark
      ? Colors.white.withValues(alpha: 0.08)
      : AppColors.borderOf(context);

  return InputDecoration(
    labelText: labelText,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    labelStyle: AppTextStyles.bodyLarge(context).copyWith(
      color: AppColors.textSecondaryOf(context),
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: border, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.error, width: 1.4),
    ),
    suffixIcon: suffixIcon,
  );
}
