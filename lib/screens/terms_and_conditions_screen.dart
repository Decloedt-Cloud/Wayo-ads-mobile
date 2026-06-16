import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../i18n/strings.g.dart';
import '../shared/widgets/language_switcher.dart';
import '../shared/widgets/legal_document_widgets.dart';
import '../shared/widgets/theme_toggle_button.dart';

/// Native terms & conditions (EN / FR / AR) with light & dark theme support.
class TermsAndConditionsScreen extends ConsumerWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.terms_and_conditions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void goHome() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    }

    final company = LegalCompanyInfo(
      legalName: t.company_legal_name,
      operatorIntro: t.operator_intro,
      address: t.company_address,
      supportLabel: t.support_label,
      supportEmail: t.support_email,
      supportPhone: t.support_phone,
    );

    final contact = LegalContactInfo(
      controllerLabel: t.contact_controller_label,
      controller: t.contact_controller,
      emailLabel: t.contact_email_label,
      email: t.contact_email,
      addressLabel: t.contact_address_label,
      address: t.contact_address,
    );

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
          onPressed: goHome,
        ),
        title: Text(
          t.title,
          style: AppTextStyles.labelLarge(context).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: LegalHeroHeader(
                  title: t.title,
                  lastUpdated: t.last_updated,
                  isDark: isDark,
                  icon: Icons.description_outlined,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: LegalCompanyCard(info: company, isDark: isDark),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.info_outline_rounded,
                    title: t.intro_title,
                    child: LegalBodyText(text: t.intro_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.menu_book_outlined,
                    title: t.definitions_title,
                    child: LegalSubsection(
                      isDark: isDark,
                      title: '',
                      body: t.definitions_body,
                    ),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.login_outlined,
                    title: t.access_title,
                    child: LegalBodyText(text: t.access_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.shield_outlined,
                    title: t.content_protection_title,
                    child: LegalBodyText(text: t.content_protection_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.dashboard_customize_outlined,
                    title: t.features_title,
                    child: LegalBodyText(text: t.features_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.support_agent_outlined,
                    title: t.support_title,
                    child: LegalBodyText(text: t.support_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.verified_user_outlined,
                    title: t.rights_title,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LegalBodyText(text: t.rights_body),
                        const SizedBox(height: 12),
                        LegalSubsection(
                          isDark: isDark,
                          title: t.prohibited_title,
                          body: t.prohibited_body,
                          accentColor: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.copyright_outlined,
                    title: t.ip_title,
                    child: LegalBodyText(text: t.ip_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.person_outline_rounded,
                    title: t.privacy_title,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LegalBodyText(text: t.privacy_body),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => context.push('/privacy'),
                          icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                          label: Text(t.view_privacy_policy),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            alignment: AlignmentDirectional.centerStart,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.balance_outlined,
                    title: t.liability_title,
                    child: LegalBodyText(text: t.liability_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.block_outlined,
                    title: t.termination_title,
                    child: LegalBodyText(text: t.termination_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.gavel_outlined,
                    title: t.governing_law_title,
                    child: LegalBodyText(text: t.governing_law_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.update_outlined,
                    title: t.amendments_title,
                    child: LegalBodyText(text: t.amendments_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.fact_check_outlined,
                    title: t.waiver_title,
                    child: LegalBulletList(text: t.waiver_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.mail_outline_rounded,
                    title: t.contact_title,
                    child: LegalContactBlock(info: contact),
                  ),
                  LegalBackHomeFooter(label: t.back_home, onPressed: goHome),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
