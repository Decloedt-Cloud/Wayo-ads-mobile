import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../i18n/strings.g.dart';
import '../shared/widgets/language_switcher.dart';
import '../shared/widgets/theme_toggle_button.dart';

/// Native privacy policy (EN / FR / AR) with light & dark theme support.
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.privacy_policy;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              context.go('/login');
            }
          },
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
                child: _HeroHeader(t: t, isDark: isDark),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _CompanyCard(t: t, isDark: isDark),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.info_outline_rounded,
                    title: t.intro_title,
                    child: Text(
                      t.intro_body,
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.inventory_2_outlined,
                    title: t.data_title,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t.data_intro,
                          style: AppTextStyles.bodyLarge(context),
                        ),
                        const SizedBox(height: 14),
                        _DataSubsection(
                          isDark: isDark,
                          title: t.data_advertisers_title,
                          body: t.data_advertisers_body,
                        ),
                        _DataSubsection(
                          isDark: isDark,
                          title: t.data_creators_title,
                          body: t.data_creators_body,
                        ),
                        _DataSubsection(
                          isDark: isDark,
                          title: t.data_technical_title,
                          body: t.data_technical_body,
                        ),
                        _DataSubsection(
                          isDark: isDark,
                          title: t.data_payment_title,
                          body: t.data_payment_body,
                        ),
                        const SizedBox(height: 10),
                        _HighlightNote(text: t.data_payment_note, isDark: isDark),
                      ],
                    ),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.track_changes_outlined,
                    title: t.purpose_title,
                    child: Text(
                      t.purpose_body,
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.gavel_outlined,
                    title: t.legal_bases_title,
                    child: Text(
                      t.legal_bases_body,
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.groups_outlined,
                    title: t.sharing_title,
                    child: Text(
                      t.sharing_body,
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.shield_outlined,
                    title: t.security_title,
                    child: _BulletList(text: t.security_body, isDark: isDark),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.copyright_outlined,
                    title: t.content_title,
                    child: Text(
                      t.content_body,
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.cookie_outlined,
                    title: t.cookies_title,
                    child: _BulletList(text: t.cookies_body, isDark: isDark),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.schedule_outlined,
                    title: t.retention_title,
                    child: Text(
                      t.retention_body,
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.child_care_outlined,
                    title: t.children_title,
                    child: Text(
                      t.children_body,
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.update_outlined,
                    title: t.changes_title,
                    child: Text(
                      t.changes_body,
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ),
                  _SectionCard(
                    isDark: isDark,
                    icon: Icons.mail_outline_rounded,
                    title: t.contact_title,
                    child: _ContactBlock(t: t, isDark: isDark),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.t, required this.isDark});

  final TranslationsPrivacyPolicyEn t;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2A1A0A),
                  const Color(0xFF1A1208),
                  AppColors.surfaceElevated,
                ]
              : [
                  const Color(0xFFFFF4E8),
                  const Color(0xFFFFE8CC),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t.title,
                  style: AppTextStyles.headlineMedium(context).copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.last_updated,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textMutedOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.t, required this.isDark});

  final TranslationsPrivacyPolicyEn t;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF181818) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.company_legal_name,
            style: AppTextStyles.labelLarge(context).copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t.operator_intro,
            style: AppTextStyles.bodyLarge(context).copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.company_address,
                  style: AppTextStyles.bodyLarge(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.borderOf(context), height: 1),
          const SizedBox(height: 14),
          Text(
            t.support_label,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMutedOf(context),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          _ContactLinkRow(
            icon: Icons.email_outlined,
            label: t.support_email,
            onTap: () => _launchUri(Uri(
              scheme: 'mailto',
              path: t.support_email,
            )),
          ),
          const SizedBox(height: 6),
          _ContactLinkRow(
            icon: Icons.phone_outlined,
            label: t.support_phone,
            onTap: () => _launchUri(Uri(
              scheme: 'tel',
              path: t.support_phone.replaceAll(' ', ''),
            )),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.child,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF181818) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.18 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.labelLarge(context).copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      child,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataSubsection extends StatelessWidget {
  const _DataSubsection({
    required this.isDark,
    required this.title,
    required this.body,
  });

  final bool isDark;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final lines = body.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F0F0F)
              : AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderOf(context).withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.labelLarge(context).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.textMutedOf(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        line,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HighlightNote extends StatelessWidget {
  const _HighlightNote({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({required this.t, required this.isDark});

  final TranslationsPrivacyPolicyEn t;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContactField(
          label: t.contact_controller_label,
          value: t.contact_controller,
        ),
        const SizedBox(height: 12),
        _ContactField(
          label: t.contact_email_label,
          value: t.contact_email,
          onTap: () => _launchUri(Uri(scheme: 'mailto', path: t.contact_email)),
          isLink: true,
        ),
        const SizedBox(height: 12),
        _ContactField(
          label: t.contact_address_label,
          value: t.contact_address,
        ),
      ],
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.label,
    required this.value,
    this.onTap,
    this.isLink = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTextStyles.bodyLarge(context).copyWith(
      fontWeight: FontWeight.w600,
      color: isLink ? AppColors.primary : AppColors.textPrimaryOf(context),
      decoration: isLink ? TextDecoration.underline : null,
      decorationColor: AppColors.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textMutedOf(context),
          ),
        ),
        const SizedBox(height: 4),
        if (onTap != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Text(value, style: valueStyle),
          )
        else
          Text(value, style: valueStyle),
      ],
    );
  }
}

class _ContactLinkRow extends StatelessWidget {
  const _ContactLinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchUri(Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    await launchUrl(uri);
  }
}
