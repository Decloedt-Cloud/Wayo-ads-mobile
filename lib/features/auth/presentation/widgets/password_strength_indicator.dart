import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Linear strength bar (0–1) from password rules.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  final String password;

  static double strengthFor(String p) {
    var score = 0.0;
    if (p.length >= 8) score += 1 / 3;
    if (RegExp(r'[A-Z]').hasMatch(p)) score += 1 / 3;
    if (RegExp(r'[0-9]').hasMatch(p)) score += 1 / 3;
    return score.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final v = strengthFor(password);
    final color = v >= 1
        ? AppColors.primary
        : v >= 0.66
            ? AppColors.primarySoft
            : AppColors.textMutedOf(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: v,
        minHeight: 4,
        backgroundColor: AppColors.surfaceElevatedOf(context),
        color: color,
      ),
    );
  }
}
