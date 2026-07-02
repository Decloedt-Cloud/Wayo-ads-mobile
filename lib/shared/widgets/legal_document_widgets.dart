import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Shared chrome for in-app legal pages (privacy, terms, etc.).
class LegalCompanyInfo {
  const LegalCompanyInfo({
    required this.legalName,
    required this.operatorIntro,
    required this.address,
    required this.supportLabel,
    required this.supportEmail,
    required this.supportPhone,
  });

  final String legalName;
  final String operatorIntro;
  final String address;
  final String supportLabel;
  final String supportEmail;
  final String supportPhone;
}

class LegalContactInfo {
  const LegalContactInfo({
    required this.controllerLabel,
    required this.controller,
    required this.emailLabel,
    required this.email,
    required this.addressLabel,
    required this.address,
  });

  final String controllerLabel;
  final String controller;
  final String emailLabel;
  final String email;
  final String addressLabel;
  final String address;
}

class LegalHeroHeader extends StatelessWidget {
  const LegalHeroHeader({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.isDark,
    this.icon = Icons.privacy_tip_outlined,
  });

  final String title;
  final String lastUpdated;
  final bool isDark;
  final IconData icon;

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
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
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
            lastUpdated,
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

class LegalCompanyCard extends StatelessWidget {
  const LegalCompanyCard({
    super.key,
    required this.info,
    required this.isDark,
  });

  final LegalCompanyInfo info;
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
            info.legalName,
            style: AppTextStyles.labelLarge(context).copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            info.operatorIntro,
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
                  info.address,
                  style: AppTextStyles.bodyLarge(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.borderOf(context), height: 1),
          const SizedBox(height: 14),
          Text(
            info.supportLabel,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMutedOf(context),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          LegalContactLinkRow(
            icon: Icons.email_outlined,
            label: info.supportEmail,
            onTap: () => launchLegalUri(
              Uri(scheme: 'mailto', path: info.supportEmail),
            ),
          ),
          const SizedBox(height: 6),
          LegalContactLinkRow(
            icon: Icons.phone_outlined,
            label: info.supportPhone,
            onTap: () => launchLegalUri(
              Uri(
                scheme: 'tel',
                path: info.supportPhone.replaceAll(' ', ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LegalSectionCard extends StatelessWidget {
  const LegalSectionCard({
    super.key,
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

class LegalSubsection extends StatelessWidget {
  const LegalSubsection({
    super.key,
    required this.isDark,
    required this.title,
    required this.body,
    this.accentColor,
  });

  final bool isDark;
  final String title;
  final String body;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final lines = body.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final accent = accentColor ?? AppColors.primary;

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
            if (title.trim().isNotEmpty) ...[
              Text(
                title,
                style: AppTextStyles.labelLarge(context).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
            ],
            for (final line in lines) _SubsectionLine(line: line),
          ],
        ),
      ),
    );
  }
}

class _SubsectionLine extends StatelessWidget {
  const _SubsectionLine({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    final parts = line.split(' — ');
    final hasTerm = parts.length >= 2;

    return Padding(
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
            child: hasTerm
                ? RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textSecondaryOf(context),
                      ),
                      children: [
                        TextSpan(
                          text: '${parts.first} — ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: parts.sublist(1).join(' — ')),
                      ],
                    ),
                  )
                : Text(
                    line,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class LegalBulletList extends StatelessWidget {
  const LegalBulletList({super.key, required this.text});

  final String text;

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

class LegalHighlightNote extends StatelessWidget {
  const LegalHighlightNote({
    super.key,
    required this.text,
    required this.isDark,
    this.icon = Icons.lock_outline_rounded,
    this.tone = LegalNoteTone.info,
  });

  final String text;
  final bool isDark;
  final IconData icon;
  final LegalNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = switch (tone) {
      LegalNoteTone.info => AppColors.primary.withValues(
          alpha: isDark ? 0.14 : 0.1,
        ),
      LegalNoteTone.warning => AppColors.error.withValues(
          alpha: isDark ? 0.16 : 0.08,
        ),
    };
    final border = switch (tone) {
      LegalNoteTone.info => AppColors.primary.withValues(alpha: 0.35),
      LegalNoteTone.warning => AppColors.error.withValues(alpha: 0.35),
    };
    final iconColor =
        tone == LegalNoteTone.warning ? AppColors.error : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
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

enum LegalNoteTone { info, warning }

class LegalContactBlock extends StatelessWidget {
  const LegalContactBlock({super.key, required this.info});

  final LegalContactInfo info;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LegalContactField(
          label: info.controllerLabel,
          value: info.controller,
        ),
        const SizedBox(height: 12),
        LegalContactField(
          label: info.emailLabel,
          value: info.email,
          onTap: () => launchLegalUri(
            Uri(scheme: 'mailto', path: info.email),
          ),
          isLink: true,
        ),
        const SizedBox(height: 12),
        LegalContactField(
          label: info.addressLabel,
          value: info.address,
        ),
      ],
    );
  }
}

class LegalContactField extends StatelessWidget {
  const LegalContactField({
    super.key,
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

class LegalContactLinkRow extends StatelessWidget {
  const LegalContactLinkRow({
    super.key,
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

class LegalBodyText extends StatelessWidget {
  const LegalBodyText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.bodyLarge(context));
  }
}

class LegalCookieRow {
  const LegalCookieRow({
    required this.name,
    required this.purpose,
    required this.duration,
  });

  final String name;
  final String purpose;
  final String duration;
}

class LegalCookieInventoryTable extends StatelessWidget {
  const LegalCookieInventoryTable({
    super.key,
    required this.isDark,
    required this.colName,
    required this.colPurpose,
    required this.colDuration,
    required this.rows,
  });

  final bool isDark;
  final String colName;
  final String colPurpose;
  final String colDuration;
  final List<LegalCookieRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _CookieRowCard(
            isDark: isDark,
            colName: colName,
            colPurpose: colPurpose,
            colDuration: colDuration,
            row: rows[i],
          ),
        ],
      ],
    );
  }
}

class _CookieRowCard extends StatelessWidget {
  const _CookieRowCard({
    required this.isDark,
    required this.colName,
    required this.colPurpose,
    required this.colDuration,
    required this.row,
  });

  final bool isDark;
  final String colName;
  final String colPurpose;
  final String colDuration;
  final LegalCookieRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _CookieField(label: colName, value: row.name, monospace: true),
          const SizedBox(height: 10),
          _CookieField(label: colPurpose, value: row.purpose),
          const SizedBox(height: 10),
          _CookieField(label: colDuration, value: row.duration),
        ],
      ),
    );
  }
}

class _CookieField extends StatelessWidget {
  const _CookieField({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
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
        Text(
          value,
          style: AppTextStyles.bodyLarge(context).copyWith(
            fontSize: 14,
            height: 1.45,
            fontFamily: monospace ? 'monospace' : null,
            fontWeight: monospace ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

class LegalBackHomeFooter extends StatelessWidget {
  const LegalBackHomeFooter({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          side: BorderSide(color: AppColors.borderOf(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(
          Icons.home_outlined,
          color: AppColors.textPrimaryOf(context),
        ),
        label: Text(
          label,
          style: AppTextStyles.labelLarge(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Future<void> launchLegalUri(Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    await launchUrl(uri);
  }
}
