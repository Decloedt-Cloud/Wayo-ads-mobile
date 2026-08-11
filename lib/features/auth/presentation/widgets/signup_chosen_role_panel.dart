import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';

/// Displays the signup role (Creator / Advertiser), matching Auth_Wayo register UI.
class SignupChosenRolePanel extends StatelessWidget {
  const SignupChosenRolePanel({
    super.key,
    required this.selectedRole,
    this.onRoleSelected,
    this.allowAdvertiser = true,
  });

  /// `CREATOR` or `ADVERTISER`.
  final String selectedRole;
  final ValueChanged<String>? onRoleSelected;
  final bool allowAdvertiser;

  static const _orange = Color(0xFFF97316);

  bool get _isCreator => selectedRole.toUpperCase() == 'CREATOR';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.signup.your_role.toUpperCase(),
          style: AppTextStyles.labelLarge(context).copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: AppColors.textMutedOf(context),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleOptionCard(
                selected: _isCreator,
                icon: Icons.palette_outlined,
                title: t.signup.role_creator_label,
                subtitle: t.signup.role_creator_blurb,
                isDark: isDark,
                accent: _orange,
                onTap: onRoleSelected == null
                    ? null
                    : () => onRoleSelected!('CREATOR'),
              ),
            ),
            if (allowAdvertiser) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _RoleOptionCard(
                  selected: !_isCreator,
                  icon: Icons.trending_up_rounded,
                  title: t.signup.role_advertiser_label,
                  subtitle: t.signup.role_advertiser_blurb,
                  isDark: isDark,
                  accent: _orange,
                  onTap: onRoleSelected == null
                      ? null
                      : () => onRoleSelected!('ADVERTISER'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.accent,
    this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? accent
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08));
    final fill = selected
        ? accent.withValues(alpha: isDark ? 0.12 : 0.08)
        : (isDark ? const Color(0xFF27272A) : Colors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.16)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: selected ? accent : AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: 11.5,
                        height: 1.25,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
