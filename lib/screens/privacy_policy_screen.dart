import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../i18n/strings.g.dart';
import '../shared/widgets/language_switcher.dart';
import '../shared/widgets/theme_toggle_button.dart';

/// Localized privacy policy (Wayo Ads), respects app theme and locale.
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final pp = t.privacy_policy;
    final sections = <({String title, String body})>[
      (title: pp.intro_title, body: pp.intro_body),
      (title: pp.data_title, body: pp.data_body),
      (title: pp.purpose_title, body: pp.purpose_body),
      (title: pp.legal_bases_title, body: pp.legal_bases_body),
      (title: pp.sharing_title, body: pp.sharing_body),
      (title: pp.security_title, body: pp.security_body),
      (title: pp.content_title, body: pp.content_body),
      (title: pp.cookies_title, body: pp.cookies_body),
      (title: pp.retention_title, body: pp.retention_body),
      (title: pp.children_title, body: pp.children_body),
      (title: pp.changes_title, body: pp.changes_body),
      (title: pp.contact_title, body: pp.contact_body),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryOf(context),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          pp.title,
          style: AppTextStyles.pageTitle(context),
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 4),
          LanguageSwitcher(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: sections.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                pp.last_updated,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            final s = sections[index - 1];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.title,
                  style: AppTextStyles.labelLarge(context).copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.body,
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(height: 1.55, fontSize: 15),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
