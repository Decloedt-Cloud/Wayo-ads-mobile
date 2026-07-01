import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/campaigns/campaign_detail_metadata.dart';
import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../core/widgets/campaign_cover_image.dart';
import '../../../../core/widgets/campaign_detail/campaign_detail_assets_link.dart';
import '../../../../core/widgets/campaign_detail/campaign_detail_budget_usage_card.dart';
import '../../../../core/widgets/campaign_detail/campaign_detail_info_card.dart';
import '../../../../core/widgets/campaign_detail/campaign_detail_requirements.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../domain/creator_browse_campaign.dart';
import '../../domain/creator_campaign_detail.dart';
import '../providers/creator_campaigns_providers.dart';
import '../widgets/creator_apply_sheet.dart';
import '../widgets/creator_tracking_link_section.dart';
import '../../../dashboard/domain/entities/campaign_status.dart';
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

  String _moneyLocale(AppLocale l) => wayoPublicMoneyLocale(l);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final async = ref.watch(creatorCampaignDetailProvider(id));

    return Scaffold(
      backgroundColor: CreatorCampaignsChrome.bg(context),
      bottomNavigationBar: const WayoBlackBottomBar(),
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
          skipLoadingOnReload: true,
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
            campaignId: id,
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
    required this.campaignId,
  });

  final CreatorCampaignDetail campaign;
  final String moneyLocale;
  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final c = campaign;
    final linksAsync = c.type == CreatorCampaignType.link && c.isApproved
        ? ref.watch(creatorTrackingLinksProvider(campaignId))
        : null;

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      children: [
        CampaignCoverImage(
          coverUrl: normalizeWayoAdsMediaUrl(c.coverUrl),
          brandLogoUrl: resolveWayoAdsPublicUrl(c.brandLogoUrl),
          fallbackIcon: _typeIcon(c.type),
          accent: CreatorCampaignsChrome.amber(context),
        ),
        const SizedBox(height: 14),
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
                  _CampaignStatusPill(status: CampaignStatus.fromString(c.status)),
                  _Pill(
                    label: _typeLabel(t, c.type),
                    color: CreatorCampaignsChrome.amber(context),
                    icon: _typeIcon(c.type),
                  ),
                  _Pill(
                    label: campaignDetailPlatformLabel(t, c.platform),
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.public_outlined,
                  ),
                  _ApplicationStatusPill(status: c.myApplicationStatus),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CampaignDetailInfoCard(
          platformLabel: campaignDetailPlatformLabel(t, c.platform),
          nicheLabel: (c.niche != null && c.niche!.trim().isNotEmpty)
              ? campaignNicheFallbackLabel(c.niche!)
              : '—',
          locationLabel:
              (c.location != null && c.location!.trim().isNotEmpty)
                  ? c.location!
                  : '—',
          objectiveLabel: campaignDetailObjectiveLabel(t, c.campaignObjective),
          campaignTypeLabel: campaignDetailTypeLabel(t, c.type),
        ),
        if (c.totalBudgetCents > 0) ...[
          const SizedBox(height: 14),
          CampaignDetailBudgetUsageCard(
            totalCents: c.totalBudgetCents,
            spentCents: c.spentBudgetCents,
            remainingCents: c.remainingBudgetCents,
            moneyLocale: moneyLocale,
            approvedCreators: c.approvedCreators,
          ),
        ],
        const SizedBox(height: 14),
        _PremiumCard(
          child: _RewardsBlock(campaign: c, moneyLocale: moneyLocale),
        ),
        if (c.isApproved) ...[
          const SizedBox(height: 14),
          _PremiumCard(
            child: _EarningsBlock(campaign: c, moneyLocale: moneyLocale),
          ),
        ],
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
            child: CampaignDetailRequirements(
              type: c.type,
              requiredPlatform: c.requiredPlatform,
              videoMinDurationMinutes: c.videoMinDurationMinutes,
              shortsMaxDurationSeconds: c.shortsMaxDurationSeconds,
              shortsRequireVertical: c.shortsRequireVertical,
            ),
          ),
        ],
        const SizedBox(height: 14),
        _PremiumCard(
          child: _CampaignPerformanceBlock(campaign: c, moneyLocale: moneyLocale),
        ),
        if (c.assetsUrl != null && c.assetsUrl!.isNotEmpty) ...[
          const SizedBox(height: 14),
          CampaignDetailAssetsLink(url: c.assetsUrl!),
        ],
        if (linksAsync != null) ...[
          const SizedBox(height: 14),
          _PremiumCard(
            child: linksAsync.when(
              skipLoadingOnReload: true,
              loading: () => const CreatorTrackingLinkSection(
                links: [],
                loading: true,
              ),
              error: (e, _) => CreatorTrackingLinkSection(
                links: const [],
                error: e,
                onRetry: () =>
                    ref.invalidate(creatorTrackingLinksProvider(campaignId)),
              ),
              data: (links) => CreatorTrackingLinkSection(links: links),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _ActionBar(campaign: _campaignForActions(ref, c)),
      ],
    );
  }

  /// Merges live submissions so the action bar hides "Submit" after upload.
  CreatorCampaignDetail _campaignForActions(WidgetRef ref, CreatorCampaignDetail c) {
    if (!c.isApproved || !c.type.requiresVideoSubmission) return c;
    final posts = ref.watch(creatorMySubmissionsProvider(campaignId)).valueOrNull;
    if (posts == null) return c;
    return c.mergeSocialPosts(posts);
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

class _CampaignStatusPill extends StatelessWidget {
  const _CampaignStatusPill({required this.status});

  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final label = switch (status) {
      CampaignStatus.active => t.advertiser_campaigns.status.active,
      CampaignStatus.paused => t.advertiser_campaigns.status.paused,
      CampaignStatus.completed => t.advertiser_campaigns.status.completed,
      CampaignStatus.draft => t.advertiser_campaigns.status.draft,
      CampaignStatus.unknown => t.advertiser_campaigns.status.other,
    };
    final color = switch (status) {
      CampaignStatus.active => const Color(0xFF22C55E),
      CampaignStatus.paused => const Color(0xFFF59E0B),
      CampaignStatus.completed => const Color(0xFF8B5CF6),
      CampaignStatus.draft => CampaignDetailPremiumPalette.muted(context),
      CampaignStatus.unknown => CampaignDetailPremiumPalette.muted(context),
    };
    final icon = switch (status) {
      CampaignStatus.active => Icons.circle,
      CampaignStatus.paused => Icons.pause_circle_outline,
      CampaignStatus.completed => Icons.check_circle_outline,
      CampaignStatus.draft => Icons.edit_note_rounded,
      CampaignStatus.unknown => Icons.help_outline,
    };
    return _Pill(label: label, color: color, icon: icon);
  }
}

class _CampaignPerformanceBlock extends StatelessWidget {
  const _CampaignPerformanceBlock({
    required this.campaign,
    required this.moneyLocale,
  });

  final CreatorCampaignDetail campaign;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = campaign;
    String fmt(int cents) => MoneyFormatter.format(
          cents / 100.0,
          currency: kWayoPublicCurrency,
          locale: moneyLocale,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.advertiser_campaigns.detail.metrics_title,
          style: CampaignDetailPremiumPalette.sectionTitle(context),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PerformanceStat(
                icon: Icons.visibility_outlined,
                label: t.advertiser_campaigns.detail.valid_views,
                value: '${c.validViews}',
              ),
            ),
            Expanded(
              child: _PerformanceStat(
                icon: Icons.ads_click_outlined,
                label: t.advertiser_campaigns.detail.valid_clicks,
                value: '${c.validClicks}',
              ),
            ),
          ],
        ),
        if (c.lockedBudgetCents > 0) ...[
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: CampaignDetailPremiumPalette.rowSeparator(context),
          ),
          const SizedBox(height: 10),
          _PerformanceStat(
            icon: Icons.lock_clock_outlined,
            label: t.advertiser_campaigns.card.locked,
            value: fmt(c.lockedBudgetCents),
          ),
        ],
      ],
    );
  }
}

class _PerformanceStat extends StatelessWidget {
  const _PerformanceStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: CreatorCampaignsChrome.amber(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CampaignDetailPremiumPalette.value(context),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: CreatorCampaignsChrome.label(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EarningsBlock extends StatelessWidget {
  const _EarningsBlock({required this.campaign, required this.moneyLocale});

  final CreatorCampaignDetail campaign;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = campaign;
    final views = c.paidViews > 0 ? c.paidViews : c.earningsViews;

    String money(int cents) => MoneyFormatter.format(
      cents / 100.0,
      currency: kWayoPublicCurrency,
      locale: moneyLocale,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.creator.campaigns.earnings_card_title,
          style: CampaignDetailPremiumPalette.sectionTitle(context),
        ),
        const SizedBox(height: 4),
        Text(
          t.creator.campaigns.earnings_card_subtitle,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: CreatorCampaignsChrome.label(context),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _EarningsStat(
                label: t.creator.campaigns.earnings_net,
                value: money(c.netEarningsCents),
              ),
            ),
            Expanded(
              child: _EarningsStat(
                label: t.creator.campaigns.earnings_views,
                value: '$views',
                sub: c.type.requiresVideoSubmission
                    ? '${t.creator.campaigns.earnings_platform_views}: ${c.platformViews}'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EarningsStat(
                label: t.creator.campaigns.earnings_valid_clicks,
                value: '${c.validatedClicks}',
                sub:
                    '${t.creator.campaigns.earnings_recorded_clicks}: ${c.recordedClicks}',
              ),
            ),
            Expanded(
              child: _EarningsStat(
                label: t.creator.campaigns.earnings_available_balance,
                value: money(c.availableBalanceCents),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EarningsStat extends StatelessWidget {
  const _EarningsStat({
    required this.label,
    required this.value,
    this.sub,
  });

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: CampaignDetailPremiumPalette.value(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: CreatorCampaignsChrome.label(context),
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(
            sub!,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: CreatorCampaignsChrome.label(context),
            ),
          ),
        ],
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
    String fmt(int cents) => MoneyFormatter.format(
          cents / 100.0,
          currency: kWayoPublicCurrency,
          locale: moneyLocale,
        );
    final rate = resolveCampaignPayoutMetric(
      type: c.type,
      cpcCents: c.cpcCents,
      cpmCents: c.cpmCents,
      spentBudgetCents: c.spentBudgetCents,
      validViews: c.validViews,
    );
    if (rate.hasValue) {
      switch (rate.kind) {
        case CampaignPayoutMetricKind.cpc:
          items.add(
            _RewardTile(
              label: t.creator.campaigns.reward_cpc_label,
              value: fmt(rate.cents),
              icon: Icons.ads_click_rounded,
              accent: const Color(0xFF10B981),
            ),
          );
        case CampaignPayoutMetricKind.cpm:
          items.add(
            _RewardTile(
              label: t.creator.campaigns.reward_cpm_label,
              value: fmt(rate.cents),
              icon: Icons.visibility_rounded,
              accent: CreatorCampaignsChrome.amber(context),
            ),
          );
          if (c.payoutPerViewCents > 0) {
            items.add(
              _RewardTile(
                label: t.creator.campaigns.reward_per_view_label,
                value: fmt(c.payoutPerViewCents),
                icon: Icons.paid_rounded,
                accent: const Color(0xFF10B981),
              ),
            );
          }
        case CampaignPayoutMetricKind.consumedCpm:
          items.add(
            _RewardTile(
              label: t.advertiser_campaigns.detail.cpm_consumed,
              value: fmt(rate.cents),
              icon: Icons.visibility_rounded,
              accent: CreatorCampaignsChrome.amber(context),
            ),
          );
      }
    }
    if (items.isEmpty) {
      items.add(
        _RewardTile(
          label: t.creator.campaigns.requirement_none,
          value: '—',
          icon: Icons.paid_rounded,
          accent: CreatorCampaignsChrome.amber(context),
        ),
      );
    }
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
              WayoToast.success(context, t.creator.campaigns.apply_success);
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
      final isVideoCampaign = c.type.requiresVideoSubmission;
      final canSubmit = c.canSubmitVideoPost;

      return Column(
        children: [
          if (!isVideoCampaign || canSubmit)
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
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
                icon: Icon(
                  isVideoCampaign && canSubmit
                      ? Icons.upload_rounded
                      : Icons.folder_open_rounded,
                ),
                label: Text(
                  isVideoCampaign && canSubmit
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
          if (isVideoCampaign && !canSubmit) ...[
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    '/creator/campaigns/${c.id}/application',
                    extra: <String, Object?>{'title': c.title},
                  );
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
                icon: const Icon(Icons.folder_open_rounded),
                label: Text(
                  t.creator.campaigns.open_application_cta,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
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
