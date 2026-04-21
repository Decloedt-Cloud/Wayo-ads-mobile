import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';

/// Back + theme + language for password-reset flow (matches login chrome).
class PasswordResetTopBar extends ConsumerWidget {
  const PasswordResetTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const Spacer(),
        const ThemeToggleButton(),
        const SizedBox(width: 8),
        const LanguageSwitcher(),
      ],
    );
  }
}
