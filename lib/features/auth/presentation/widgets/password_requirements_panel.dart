import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/password_requirements.dart';

/// Live checklist + strength label (Auth_Wayo register / reset UI).
class PasswordRequirementsPanel extends StatelessWidget {
  const PasswordRequirementsPanel({
    super.key,
    required this.password,
    this.alwaysVisible = false,
  });

  final String password;
  final bool alwaysVisible;

  @override
  Widget build(BuildContext context) {
    if (!alwaysVisible && password.isEmpty) {
      return const SizedBox.shrink();
    }

    final t = context.t.password_req;
    final score = PasswordRequirements.score(password);
    final strengthLabel = _strengthLabel(t, score);
    final strengthColor = _strengthColor(context, score);

    final rules = <({String label, bool met})>[
      (label: t.length, met: PasswordRequirements.hasMinLength(password)),
      (label: t.uppercase, met: PasswordRequirements.hasUppercase(password)),
      (label: t.lowercase, met: PasswordRequirements.hasLowercase(password)),
      (label: t.number, met: PasswordRequirements.hasNumber(password)),
      (label: t.symbol, met: PasswordRequirements.hasSymbol(password)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (password.isNotEmpty) ...[
          Text(
            strengthLabel,
            style: AppTextStyles.labelLarge(context).copyWith(
              color: strengthColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          t.hint,
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: AppColors.textSecondaryOf(context),
            fontSize: 14,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        for (final rule in rules) ...[
          _RequirementRow(label: rule.label, met: rule.met),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  String _strengthLabel(dynamic t, int score) {
    return switch (score) {
      0 => t.very_weak,
      1 => t.weak,
      2 => t.fair,
      3 => t.good,
      _ => t.strong,
    };
  }

  Color _strengthColor(BuildContext context, int score) {
    if (score >= 3) return AppColors.success;
    if (score == 2) return AppColors.primary;
    return AppColors.textMutedOf(context);
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final active = AppColors.success;
    final inactive = AppColors.textMutedOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: met ? active : inactive,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge(context).copyWith(
              fontSize: 14,
              height: 1.35,
              color: met ? AppColors.textPrimaryOf(context) : inactive,
            ),
          ),
        ),
      ],
    );
  }
}

String? passwordRequirementsValidationError(String password, Translations t) {
  if (!PasswordRequirements.hasMinLength(password)) {
    return t.password_req.length;
  }
  if (!PasswordRequirements.hasUppercase(password)) {
    return t.password_req.uppercase;
  }
  if (!PasswordRequirements.hasLowercase(password)) {
    return t.password_req.lowercase;
  }
  if (!PasswordRequirements.hasNumber(password)) {
    return t.password_req.number;
  }
  if (!PasswordRequirements.hasSymbol(password)) {
    return t.password_req.symbol;
  }
  return null;
}
