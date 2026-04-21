import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Dismissible error strip for a single dashboard section.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
  });

  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
            ),
          ),
          if (onRetry != null && retryLabel != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                retryLabel!,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
