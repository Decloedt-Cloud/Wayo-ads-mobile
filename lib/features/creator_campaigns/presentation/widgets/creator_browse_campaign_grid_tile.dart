import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../core/widgets/campaign_grid_compact_parts.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../../dashboard/domain/entities/campaign_platform.dart';
import '../../domain/creator_browse_campaign.dart';

String? _creatorBrowseGridRateCaption(
  CreatorBrowseCampaign c,
  Translations t,
  String moneyLocale,
) {
  String fmt(double major) => MoneyFormatter.format(
        major,
        currency: c.currency,
        locale: moneyLocale,
      );
  final type = c.type;
  if (type == CreatorCampaignType.link && c.cpcCents > 0) {
    return t.creator.campaigns.reward_per_click(
      amount: fmt(c.cpcCents / 100.0),
    );
  }
  if ((type == CreatorCampaignType.video ||
          type == CreatorCampaignType.shorts) &&
      c.cpmCents > 0) {
    final perViewMajor = c.cpmCents / 1000.0 / 100.0;
    return t.creator.campaigns.reward_per_view(amount: fmt(perViewMajor));
  }
  if (c.cpcCents > 0) {
    return t.creator.campaigns.reward_per_click(
      amount: fmt(c.cpcCents / 100.0),
    );
  }
  if (c.cpmCents > 0) {
    final perViewMajor = c.cpmCents / 1000.0 / 100.0;
    return t.creator.campaigns.reward_per_view(amount: fmt(perViewMajor));
  }
  return null;
}

IconData _browsePlatformIcon(CampaignPlatform p) => switch (p) {
  CampaignPlatform.youtube => Icons.play_circle_filled_rounded,
  CampaignPlatform.tiktok => Icons.music_note_rounded,
  CampaignPlatform.instagram => Icons.photo_camera_rounded,
  CampaignPlatform.unknown => Icons.public_rounded,
};

/// Dense 2-column tile for [CampaignExplorerLayout.grid] (creator browse).
class CreatorBrowseCampaignGridTile extends StatelessWidget {
  const CreatorBrowseCampaignGridTile({
    super.key,
    required this.campaign,
    required this.moneyLocale,
    required this.onTap,
    this.applicationStatus,
  });

  final CreatorBrowseCampaign campaign;
  final String moneyLocale;
  final VoidCallback onTap;
  final CreatorApplicationStatus? applicationStatus;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = campaign;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeLabel = switch (c.type) {
      CreatorCampaignType.link => t.creator.campaigns.type_link,
      CreatorCampaignType.video => t.creator.campaigns.type_video,
      CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
      CreatorCampaignType.unknown => '—',
    };
    final platEnum = CampaignPlatform.fromString(
      (c.requiredPlatform ?? '').toLowerCase(),
    );
    final platLabel = switch (platEnum) {
      CampaignPlatform.youtube => t.advertiser_campaigns.platform.youtube,
      CampaignPlatform.tiktok => t.advertiser_campaigns.platform.tiktok,
      CampaignPlatform.instagram => t.advertiser_campaigns.platform.instagram,
      CampaignPlatform.unknown => t.advertiser_campaigns.platform.other,
    };
    final rateCaption = _creatorBrowseGridRateCaption(c, t, moneyLocale);
    final nicheLabel = c.niche != null && c.niche!.trim().isNotEmpty
        ? campaignNicheFallbackLabel(c.niche!)
        : null;
    final locLabel = c.location != null && c.location!.trim().isNotEmpty
        ? c.location!
        : '—';
    final spentFrac = c.totalBudgetCents > 0
        ? (c.spentBudgetCents / c.totalBudgetCents).clamp(0.0, 1.0)
        : 0.0;
    final linkMetric = c.type == CreatorCampaignType.link;

    final borderColor = AppColors.borderOf(context);
    final footerBg = Theme.of(context).colorScheme.surfaceContainerLowest;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 50,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _GridHeroImage(
                        coverUrl: normalizeWayoAdsMediaUrl(c.coverUrl),
                        brandLogoUrl: resolveWayoAdsPublicUrl(c.brandLogoUrl),
                        type: c.type,
                      ),
                      if (rateCaption != null)
                        PositionedDirectional(
                          start: 8,
                          top: 8,
                          child: CampaignGridRateBadge(text: rateCaption),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.42),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (applicationStatus != null)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: _MiniAppBadge(status: applicationStatus!),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 50,
                  child: ColoredBox(
                    color: footerBg,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge(context).copyWith(
                              fontSize: 13.5,
                              height: 1.16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (c.advertiserName != null &&
                              c.advertiserName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              c.advertiserName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(context).copyWith(
                                color: AppColors.textSecondaryOf(context),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _MiniTypePill(label: typeLabel),
                              _MiniTypePill(label: platLabel, muted: true),
                            ],
                          ),
                          if (nicheLabel != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${t.advertiser_campaigns.create.field_niche}: $nicheLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(context).copyWith(
                                fontSize: 10.5,
                                color: AppColors.textSecondaryOf(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                _browsePlatformIcon(platEnum),
                                size: 13,
                                color: AppColors.textSecondaryOf(context),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  platLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption(context).copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.place_outlined,
                                size: 13,
                                color: AppColors.textSecondaryOf(context),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  locLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.caption(context).copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            t.creator.campaigns.budget_remaining_label,
                            style: AppTextStyles.caption(context).copyWith(
                              fontSize: 9.5,
                              color: AppColors.textMutedOf(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            MoneyFormatter.format(
                              c.remainingBudgetCents / 100.0,
                              currency: c.currency,
                              locale: moneyLocale,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge(context).copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: CreatorColors.primaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 1),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              value: spentFrac,
                              backgroundColor: AppColors.borderOf(
                                context,
                              ).withValues(alpha: 0.35),
                              color: CreatorColors.primaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: CampaignGridMicroStat(
                                  icon: linkMetric
                                      ? Icons.ads_click_rounded
                                      : Icons.visibility_outlined,
                                  value:
                                      '${linkMetric ? c.validClicks : c.validViews}',
                                  tooltip: linkMetric
                                      ? t.advertiser_campaigns.detail.valid_clicks
                                      : t.advertiser_campaigns.detail.valid_views,
                                ),
                              ),
                              Expanded(
                                child: CampaignGridMicroStat(
                                  icon: Icons.groups_2_outlined,
                                  value: '${c.approvedCreators}',
                                  tooltip: t
                                      .advertiser_campaigns.detail.approved_creators,
                                ),
                              ),
                              Expanded(
                                child: CampaignGridMicroStat(
                                  icon: Icons.payments_outlined,
                                  value: MoneyFormatter.format(
                                    c.totalBudgetCents / 100.0,
                                    currency: c.currency,
                                    locale: moneyLocale,
                                  ),
                                  tooltip: t.advertiser_campaigns.card.budget_total,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTypePill extends StatelessWidget {
  const _MiniTypePill({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CreatorColors.primaryOf(context).withValues(
            alpha: muted ? 0.22 : 0.4,
          ),
        ),
        gradient: muted
            ? null
            : LinearGradient(
                colors: [
                  CreatorColors.primaryOf(context).withValues(alpha: 0.12),
                  CreatorColors.primaryOf(context).withValues(alpha: 0.04),
                ],
              ),
        color: muted
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.35)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          color: muted
              ? AppColors.textSecondaryOf(context)
              : CreatorColors.primaryOf(context),
        ),
      ),
    );
  }
}

class _GridHeroImage extends StatelessWidget {
  const _GridHeroImage({
    required this.coverUrl,
    required this.brandLogoUrl,
    required this.type,
  });

  final String? coverUrl;
  final String? brandLogoUrl;
  final CreatorCampaignType type;

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: CreatorColors.primaryOf(context).withValues(alpha: 0.12),
      child: Icon(
        switch (type) {
          CreatorCampaignType.link => Icons.link_rounded,
          CreatorCampaignType.video => Icons.play_circle_fill_rounded,
          CreatorCampaignType.shorts => Icons.movie_filter_rounded,
          CreatorCampaignType.unknown => Icons.campaign_outlined,
        },
        color: CreatorColors.primaryOf(context),
        size: 36,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = coverUrl;
    final logo = brandLogoUrl;
    final hasCover = cover != null && cover.trim().isNotEmpty;
    final hasLogo = logo != null && logo.trim().isNotEmpty;

    if (hasCover) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: cover,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: 600,
            memCacheHeight: 720,
            placeholder: (context, url) => _fallback(context),
            errorWidget: (context, url, err) => _fallback(context),
          ),
          if (hasLogo)
            Positioned(
              left: 10,
              bottom: 10,
              child: _CreatorLogoOverlay(imageUrl: logo),
            ),
        ],
      );
    }

    if (hasLogo) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CreatorColors.primaryOf(context).withValues(alpha: 0.14),
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FittedBox(
            fit: BoxFit.contain,
            child: CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.contain,
              memCacheWidth: 400,
              memCacheHeight: 400,
              placeholder: (context, url) => _fallback(context),
              errorWidget: (context, url, err) => _fallback(context),
            ),
          ),
        ),
      );
    }

    return _fallback(context);
  }
}

class _CreatorLogoOverlay extends StatelessWidget {
  const _CreatorLogoOverlay({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.contain,
          memCacheWidth: 120,
          memCacheHeight: 120,
          placeholder: (context, url) => SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.business_rounded,
              size: 24,
              color: CreatorColors.primaryOf(context),
            ),
          ),
          errorWidget: (context, url, err) => SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.business_rounded,
              size: 24,
              color: CreatorColors.primaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniAppBadge extends StatelessWidget {
  const _MiniAppBadge({required this.status});

  final CreatorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      CreatorApplicationStatus.approved => Icons.verified_rounded,
      CreatorApplicationStatus.pending => Icons.schedule_rounded,
      CreatorApplicationStatus.rejected => Icons.block_rounded,
      _ => Icons.info_outline_rounded,
    };
    final color = switch (status) {
      CreatorApplicationStatus.approved => const Color(0xFF10B981),
      CreatorApplicationStatus.pending => const Color(0xFFF59E0B),
      CreatorApplicationStatus.rejected => Colors.red,
      _ => AppColors.textMutedOf(context),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
