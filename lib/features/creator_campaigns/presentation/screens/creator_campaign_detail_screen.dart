import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../domain/creator_browse_campaign.dart';
import '../../domain/creator_campaign_detail.dart';
import '../providers/creator_campaigns_providers.dart';
import '../widgets/creator_apply_sheet.dart';
import '../../../dashboard/presentation/theme/campaign_detail_premium_palette.dart';
import '../theme/creator_campaigns_chrome.dart';

/// Full campaign detail for the creator.
///
/// Shows:
/// - Rewards (CPM / payout per view) and budget state
/// - Campaign requirements (platform, min duration, assets link)
/// - Primary action bar that morphs based on the application status:
///   - no application yet → "Apply"
///   - PENDING → disabled "Application under review"
///   - APPROVED → "Submit a post" + "Chat with advertiser"
class CreatorCampaignDetailScreen extends ConsumerWidget {
  const CreatorCampaignDetailScreen({
    super.key,
    required this.id,
    this.title,
  });

  final String id;

  final String? title;

  String _moneyLocale(AppLocale l) => switch (l) {
    AppLocale.en => 'en_US',
    AppLocale.fr => 'fr_FR',
    AppLocale.ar => 'ar_SA',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final async = ref.watch(creatorCampaignDetailProvider(id));

    return Scaffold(
      backgroundColor: CreatorCampaignsChrome.bg(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: CreatorCampaignsChrome.bg(context),
        foregroundColor: CampaignDetailPremiumPalette.value(context),
        iconTheme: IconThemeData(
          color: CampaignDetailPremiumPalette.value(context),
        ),
        title: Text(
          title ?? t.creator.campaigns.details_title,
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CampaignDetailPremiumPalette.value(context),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: CreatorCampaignsChrome.amber(context),
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(creatorCampaignDetailProvider(id));
          await ref.read(creatorCampaignDetailProvider(id).future);
        },
        child: async.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
              child: CircularProgressIndicator(
                color: CreatorCampaignsChrome.amber(context),
              ),
              ),
            ],
          ),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 40),
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                t.creator.campaigns.load_error,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium(context),
              ),
              const SizedBox(height: 6),
              Text(
                '$err',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(color: AppColors.textSecondaryOf(context)),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(creatorCampaignDetailProvider(id)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(t.dashboard.errors.retry),
                ),
              ),
            ],
          ),
          data: (c) => _Body(
            campaign: c,
            moneyLocale: moneyLocale,
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.campaign,
    required this.moneyLocale,
  });

  final CreatorCampaignDetail campaign;
  final String moneyLocale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final c = campaign;

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      children: [
        _PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.advertiserName != null && c.advertiserName!.isNotEmpty)
                Text(
                  c.advertiserName!,
                  style: CreatorCampaignsChrome.bodyDm(context, size: 13),
                ),
              if (c.advertiserName != null && c.advertiserName!.isNotEmpty)
                const SizedBox(height: 6),
              Text(
                c.title,
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: CampaignDetailPremiumPalette.value(context),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    label: _typeLabel(t, c.type),
                    color: CreatorCampaignsChrome.amber(context),
                    icon: _typeIcon(c.type),
                  ),
                  _ApplicationStatusPill(status: c.myApplicationStatus),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PremiumCard(child: _CampaignNicheLocationSummary(campaign: c, t: t)),
        const SizedBox(height: 14),
        _PremiumCard(
          child: _RewardsBlock(campaign: c, moneyLocale: moneyLocale),
        ),
        if (c.description != null && c.description!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.creator.campaigns.description_title,
                  style: CampaignDetailPremiumPalette.sectionTitle(context),
                ),
                const SizedBox(height: 8),
                Text(
                  c.description!,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    height: 1.45,
                    color: CampaignDetailPremiumPalette.value(context)
                        .withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (c.type.requiresVideoSubmission) ...[
          const SizedBox(height: 14),
          _PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.creator.campaigns.requirements_title,
                  style: CampaignDetailPremiumPalette.sectionTitle(context),
                ),
                const SizedBox(height: 10),
                _RequirementsBlock(campaign: c),
              ],
            ),
          ),
        ],
        if (c.assetsUrl != null && c.assetsUrl!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _AssetsLink(url: c.assetsUrl!),
        ],
        const SizedBox(height: 18),
        _ActionBar(campaign: c),
      ],
    );
  }

  IconData _typeIcon(CreatorCampaignType t) => switch (t) {
    CreatorCampaignType.link => Icons.link_rounded,
    CreatorCampaignType.video => Icons.play_circle_fill_rounded,
    CreatorCampaignType.shorts => Icons.movie_filter_rounded,
    CreatorCampaignType.unknown => Icons.campaign_outlined,
  };

  String _typeLabel(Translations t, CreatorCampaignType type) => switch (type) {
    CreatorCampaignType.link => t.creator.campaigns.type_link,
    CreatorCampaignType.video => t.creator.campaigns.type_video,
    CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
    CreatorCampaignType.unknown => '—',
  };
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CampaignDetailPremiumPalette.surface1(context),
        borderRadius: BorderRadius.circular(
          CampaignDetailPremiumPalette.kCardRadius,
        ),
      ),
      child: child,
    );
  }
}

class _CampaignNicheLocationSummary extends StatelessWidget {
  const _CampaignNicheLocationSummary({
    required this.campaign,
    required this.t,
  });

  final CreatorCampaignDetail campaign;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final nicheLabel =
        (campaign.niche != null && campaign.niche!.trim().isNotEmpty)
            ? campaignNicheFallbackLabel(campaign.niche!)
            : '—';
    final locationLabel =
        (campaign.location != null && campaign.location!.trim().isNotEmpty)
            ? campaign.location!
            : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: 18,
              color: CreatorCampaignsChrome.amber(context).withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            Text(
              t.advertiser_campaigns.detail.niche_label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: CreatorCampaignsChrome.label(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nicheLabel,
                textAlign: TextAlign.end,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CampaignDetailPremiumPalette.value(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 18,
              color: CreatorCampaignsChrome.amber(context).withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            Text(
              t.advertiser_campaigns.detail.location_label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: CreatorCampaignsChrome.label(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locationLabel,
                textAlign: TextAlign.end,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CampaignDetailPremiumPalette.value(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RewardsBlock extends StatelessWidget {
  const _RewardsBlock({required this.campaign, required this.moneyLocale});

  final CreatorCampaignDetail campaign;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = campaign;
    final items = <Widget>[];
    if (c.type.requiresVideoSubmission && c.cpmCents > 0) {
      items.add(
        _RewardTile(
          label: t.creator.campaigns.reward_cpm_label,
          value: MoneyFormatter.format(
            c.cpmCents / 100.0,
            currency: c.currency,
            locale: moneyLocale,
          ),
          icon: Icons.visibility_rounded,
          accent: CreatorCampaignsChrome.amber(context),
        ),
      );
      items.add(
        _RewardTile(
          label: t.creator.campaigns.reward_per_view_label,
          value: MoneyFormatter.format(
            c.payoutPerViewCents / 100.0,
            currency: c.currency,
            locale: moneyLocale,
          ),
          icon: Icons.paid_rounded,
          accent: const Color(0xFF10B981),
        ),
      );
    } else if (c.type == CreatorCampaignType.link && c.cpcCents > 0) {
      items.add(
        _RewardTile(
          label: t.creator.campaigns.reward_cpc_label,
          value: MoneyFormatter.format(
            c.cpcCents / 100.0,
            currency: c.currency,
            locale: moneyLocale,
          ),
          icon: Icons.ads_click_rounded,
          accent: const Color(0xFF10B981),
        ),
      );
    }
    items.add(
      _RewardTile(
        label: t.creator.campaigns.budget_remaining_label,
        value: MoneyFormatter.format(
          c.remainingBudgetCents / 100.0,
          currency: c.currency,
          locale: moneyLocale,
        ),
        icon: Icons.account_balance_wallet_outlined,
        accent: const Color(0xFF8B5CF6),
      ),
    );
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          items[i],
          if (i < items.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              color: CampaignDetailPremiumPalette.rowSeparator(context),
            ),
        ],
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: CreatorCampaignsChrome.label(context),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: CampaignDetailPremiumPalette.value(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementsBlock extends StatelessWidget {
  const _RequirementsBlock({required this.campaign});

  final CreatorCampaignDetail campaign;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rows = <Widget>[];
    if (campaign.requiredPlatform != null) {
      rows.add(
        _RequirementRow(
          icon: Icons.videocam_outlined,
          label: t.creator.campaigns.requirement_platform(
            platform: campaign.requiredPlatform!,
          ),
        ),
      );
    }
    if (campaign.videoMinDurationMinutes != null &&
        campaign.videoMinDurationMinutes! > 0) {
      rows.add(
        _RequirementRow(
          icon: Icons.timer_outlined,
          label: t.creator.campaigns.requirement_min_duration(
            minutes: campaign.videoMinDurationMinutes!,
          ),
        ),
      );
    }
    if (campaign.type == CreatorCampaignType.shorts &&
        campaign.shortsMaxDurationSeconds != null) {
      rows.add(
        _RequirementRow(
          icon: Icons.short_text_rounded,
          label: t.creator.campaigns.requirement_shorts_max(
            seconds: campaign.shortsMaxDurationSeconds!,
          ),
        ),
      );
    }
    if (campaign.shortsRequireVertical == true) {
      rows.add(
        _RequirementRow(
          icon: Icons.crop_portrait_rounded,
          label: t.creator.campaigns.requirement_vertical,
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(
        _RequirementRow(
          icon: Icons.check_circle_outline,
          label: t.creator.campaigns.requirement_none,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows) ...[r, const SizedBox(height: 6)],
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: CreatorCampaignsChrome.amber(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.35,
              color: CampaignDetailPremiumPalette.value(context)
                  .withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssetsLink extends StatelessWidget {
  const _AssetsLink({required this.url});

  final String url;

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          _open();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: CreatorCampaignsChrome.amber(context).withValues(alpha: 0.08),
            border: Border.all(
              color: CreatorCampaignsChrome.amber(context).withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.folder_open_rounded,
                color: CreatorCampaignsChrome.amber(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.creator.campaigns.assets_title,
                      style: AppTextStyles.labelLarge(
                        context,
                      ).copyWith(fontSize: 14),
                    ),
                    Text(
                      t.creator.campaigns.assets_subtitle,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                color: CreatorCampaignsChrome.amber(context),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationStatusPill extends StatelessWidget {
  const _ApplicationStatusPill({required this.status});

  final CreatorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (status == CreatorApplicationStatus.unknown) {
      return const SizedBox.shrink();
    }
    final label = switch (status) {
      CreatorApplicationStatus.approved =>
        t.creator.applications.status_approved,
      CreatorApplicationStatus.pending => t.creator.applications.status_pending,
      CreatorApplicationStatus.rejected =>
        t.creator.applications.status_rejected,
      CreatorApplicationStatus.withdrawn =>
        t.creator.applications.status_withdrawn,
      CreatorApplicationStatus.unknown => '',
    };
    final color = switch (status) {
      CreatorApplicationStatus.approved => const Color(0xFF10B981),
      CreatorApplicationStatus.pending => const Color(0xFFF59E0B),
      CreatorApplicationStatus.rejected => Colors.red,
      CreatorApplicationStatus.withdrawn => AppColors.textSecondaryOf(context),
      CreatorApplicationStatus.unknown => AppColors.textSecondaryOf(context),
    };
    final icon = switch (status) {
      CreatorApplicationStatus.approved => Icons.verified_rounded,
      CreatorApplicationStatus.pending => Icons.timelapse_rounded,
      CreatorApplicationStatus.rejected => Icons.block_rounded,
      CreatorApplicationStatus.withdrawn => Icons.remove_circle_outline,
      CreatorApplicationStatus.unknown => Icons.help_outline,
    };
    return _Pill(label: label, color: color, icon: icon);
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.campaign});

  final CreatorCampaignDetail campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final c = campaign;

    if (c.canApply) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () async {
            final ok = await showCreatorApplySheet(
              context,
              campaignId: c.id,
              campaignTitle: c.title,
            );
            if (ok == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.creator.campaigns.apply_success),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: CreatorCampaignsChrome.amber(context),
            foregroundColor: const Color(0xFF0A0A0F),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.send_rounded),
          label: Text(
            t.creator.campaigns.apply_cta,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
    }

    if (c.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.creator.campaigns.apply_pending_title,
                    style: AppTextStyles.labelLarge(
                      context,
                    ).copyWith(fontSize: 14),
                  ),
                  Text(
                    t.creator.campaigns.apply_pending_subtitle,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: AppColors.textSecondaryOf(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (c.isApproved) {
      return Column(
        children: [
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                context.pushReplacement(
                  '/creator/campaigns/${c.id}/application',
                  extra: <String, Object?>{'title': c.title},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CreatorCampaignsChrome.amber(context),
                foregroundColor: const Color(0xFF0A0A0F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.upload_rounded),
              label: Text(
                c.type.requiresVideoSubmission
                    ? t.creator.campaigns.submit_cta
                    : t.creator.campaigns.open_application_cta,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/chat');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: CreatorCampaignsChrome.amber(context),
                side: BorderSide(
                  color: CreatorCampaignsChrome.amber(context)
                      .withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(
                t.creator.campaigns.chat_with_advertiser,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // REJECTED / WITHDRAWN / UNKNOWN — read-only state, no primary CTA.
    return const SizedBox.shrink();
  }
}
