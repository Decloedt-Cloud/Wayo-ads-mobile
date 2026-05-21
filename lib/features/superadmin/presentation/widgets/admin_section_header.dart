import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryOf(context),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          action ??
          (actionLabel != null && onAction != null
              ? TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(actionLabel!),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
