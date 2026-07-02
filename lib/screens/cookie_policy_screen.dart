import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../i18n/strings.g.dart';
import '../shared/widgets/language_switcher.dart';
import '../shared/widgets/legal_document_widgets.dart';
import '../shared/widgets/theme_toggle_button.dart';

/// Native cookie policy (EN / FR / AR) with light & dark theme support.
class CookiePolicyScreen extends ConsumerWidget {
  const CookiePolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.cookie_policy;
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

    final cookieRows = [
      LegalCookieRow(
        name: t.row_cookie_consent_name,
        purpose: t.row_cookie_consent_purpose,
        duration: t.row_cookie_consent_duration,
      ),
      LegalCookieRow(
        name: t.row_cookie_preferences_name,
        purpose: t.row_cookie_preferences_purpose,
        duration: t.row_cookie_preferences_duration,
      ),
      LegalCookieRow(
        name: t.row_session_token_name,
        purpose: t.row_session_token_purpose,
        duration: t.row_session_token_duration,
      ),
      LegalCookieRow(
        name: t.row_callback_url_name,
        purpose: t.row_callback_url_purpose,
        duration: t.row_callback_url_duration,
      ),
      LegalCookieRow(
        name: t.row_csrf_token_name,
        purpose: t.row_csrf_token_purpose,
        duration: t.row_csrf_token_duration,
      ),
      LegalCookieRow(
        name: t.row_pkce_name,
        purpose: t.row_pkce_purpose,
        duration: t.row_pkce_duration,
      ),
      LegalCookieRow(
        name: t.row_oauth_state_name,
        purpose: t.row_oauth_state_purpose,
        duration: t.row_oauth_state_duration,
      ),
      LegalCookieRow(
        name: t.row_oauth_reauth_name,
        purpose: t.row_oauth_reauth_purpose,
        duration: t.row_oauth_reauth_duration,
      ),
      LegalCookieRow(
        name: t.row_yt_pkce_name,
        purpose: t.row_yt_pkce_purpose,
        duration: t.row_yt_pkce_duration,
      ),
      LegalCookieRow(
        name: t.row_locale_name,
        purpose: t.row_locale_purpose,
        duration: t.row_locale_duration,
      ),
      LegalCookieRow(
        name: t.row_sidebar_name,
        purpose: t.row_sidebar_purpose,
        duration: t.row_sidebar_duration,
      ),
      LegalCookieRow(
        name: t.row_iab_dismissed_name,
        purpose: t.row_iab_dismissed_purpose,
        duration: t.row_iab_dismissed_duration,
      ),
      LegalCookieRow(
        name: t.row_app_install_name,
        purpose: t.row_app_install_purpose,
        duration: t.row_app_install_duration,
      ),
      LegalCookieRow(
        name: t.row_analytics_name,
        purpose: t.row_analytics_purpose,
        duration: t.row_analytics_duration,
      ),
      LegalCookieRow(
        name: t.row_stripe_name,
        purpose: t.row_stripe_purpose,
        duration: t.row_stripe_duration,
      ),
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
                  icon: Icons.cookie_outlined,
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
                    icon: Icons.help_outline_rounded,
                    title: t.what_are_title,
                    child: LegalBodyText(text: t.what_are_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.category_outlined,
                    title: t.types_title,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LegalSubsection(
                          isDark: isDark,
                          title: t.types_essential_title,
                          body: t.types_essential_body,
                        ),
                        LegalSubsection(
                          isDark: isDark,
                          title: t.types_analytics_title,
                          body: t.types_analytics_body,
                        ),
                        LegalSubsection(
                          isDark: isDark,
                          title: t.types_preferences_title,
                          body: t.types_preferences_body,
                        ),
                      ],
                    ),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.table_chart_outlined,
                    title: t.table_title,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LegalBodyText(text: t.table_description),
                        const SizedBox(height: 14),
                        LegalCookieInventoryTable(
                          isDark: isDark,
                          colName: t.table_col_name,
                          colPurpose: t.table_col_purpose,
                          colDuration: t.table_col_duration,
                          rows: cookieRows,
                        ),
                      ],
                    ),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.tune_outlined,
                    title: t.manage_title,
                    child: LegalBodyText(text: t.manage_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.update_outlined,
                    title: t.changes_title,
                    child: LegalBodyText(text: t.changes_body),
                  ),
                  LegalSectionCard(
                    isDark: isDark,
                    icon: Icons.mail_outline_rounded,
                    title: t.contact_title,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LegalBodyText(text: t.contact_body),
                        const SizedBox(height: 12),
                        LegalContactLinkRow(
                          icon: Icons.email_outlined,
                          label: 'info@wayo.cloud',
                          onTap: () => launchLegalUri(
                            Uri(scheme: 'mailto', path: 'info@wayo.cloud'),
                          ),
                        ),
                      ],
                    ),
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
