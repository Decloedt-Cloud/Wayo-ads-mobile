import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Outlined auth CTA matching Google/Apple social buttons — passkey login.
class PremiumPasskeySignInButton extends StatelessWidget {
  const PremiumPasskeySignInButton({
    super.key,
    required this.busy,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.black.withValues(alpha: 0.1),
      width: 1.2,
    );
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.surfaceOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && !busy ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: fill,
            border: border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: isDark ? 20 : 16,
                offset: Offset(0, isDark ? 10 : 6),
              ),
            ],
          ),
          child: Center(
            child: busy
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.key_rounded,
                        size: 22,
                        color: AppColors.textPrimaryOf(context),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: AppTextStyles.labelLarge(context).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
