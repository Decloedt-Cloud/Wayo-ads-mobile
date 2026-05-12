import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/campaign_grid_compact_parts.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../dashboard/domain/entities/campaign_platform.dart';
import '../../../dashboard/domain/entities/campaign_status.dart';
import '../../domain/advertiser_campaign.dart';
import '../../domain/campaign_niche_catalog.dart';

String? _advertiserGridRateCaption(
  AdvertiserCampaign c,
  Translations t,
  String moneyLocale,
) {
  String fmt(double major) => MoneyFormatter.format(
        major,
        currency: c.currency,
        locale: moneyLocale,
      );
  final type = c.campaignType;
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

IconData _platformIconData(CampaignPlatform p) => switch (p) {
  CampaignPlatform.youtube => Icons.play_circle_filled_rounded,
  CampaignPlatform.tiktok => Icons.music_note_rounded,
  CampaignPlatform.instagram => Icons.photo_camera_rounded,
  CampaignPlatform.unknown => Icons.public_rounded,
};

/// Compact card for advertiser catalog grid mode.
class AdvertiserCampaignGridTile extends StatelessWidget {
  const AdvertiserCampaignGridTile({
    super.key,
    required this.campaign,
    required this.moneyLocale,
    required this.onTap,
  });

  final AdvertiserCampaign campaign;
  final String moneyLocale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = campaign;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeLabel = switch (c.campaignType) {
      CreatorCampaignType.link => t.creator.campaigns.type_link,
      CreatorCampaignType.video => t.creator.campaigns.type_video,
      CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
      CreatorCampaignType.unknown => '—',
    };
    final platLabel = switch (c.platform) {
      CampaignPlatform.youtube => t.advertiser_campaigns.platform.youtube,
      CampaignPlatform.tiktok => t.advertiser_campaigns.platform.tiktok,
      CampaignPlatform.instagram => t.advertiser_campaigns.platform.instagram,
      CampaignPlatform.unknown => t.advertiser_campaigns.platform.other,
    };
    final rateCaption = _advertiserGridRateCaption(c, t, moneyLocale);
    final nicheLabel = c.niche != null && c.niche!.trim().isNotEmpty
        ? campaignNicheFallbackLabel(c.niche!)
        : null;
    final locLabel = c.location != null && c.location!.trim().isNotEmpty
        ? c.location!
        : '—';
    final spentFrac = c.totalBudgetCents > 0
        ? (c.spentBudgetCents / c.totalBudgetCents).clamp(0.0, 1.0)
        : 0.0;
    final linkMetric = c.campaignType == CreatorCampaignType.link;

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
                      _AdvertiserGridVisual(
                        coverUrl: normalizeWayoAdsMediaUrl(c.coverUrl),
                        brandLogoUrl: resolveWayoAdsPublicUrl(c.brandLogoUrl),
                      ),
                      if (rateCaption != null)
                        PositionedDirectional(
                          start: 8,
                          top: 8,
                          child: CampaignGridRateBadge(text: rateCaption),
                        ),
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: _StatusGlowChip(status: c.status, t: t),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 50,
                  child: ColoredBox(
                    color: footerBg,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge(context).copyWith(
                              fontSize: 13.5,
                              height: 1.18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _MiniPill(text: typeLabel),
                              _MiniPill(text: platLabel, muted: true),
                            ],
                          ),
                          if (nicheLabel != null) ...[
                            const SizedBox(height: 4),
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
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                _platformIconData(c.platform),
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
                          const SizedBox(height: 4),
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
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              value: spentFrac,
                              backgroundColor: AppColors.borderOf(
                                context,
                              ).withValues(alpha: 0.35),
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 5),
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

class _AdvertiserGridVisual extends StatelessWidget {
  const _AdvertiserGridVisual({this.coverUrl, this.brandLogoUrl});

  final String? coverUrl;
  final String? brandLogoUrl;

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      return ColoredBox(
        color: AppColors.surfaceElevatedOf(context),
        child: Icon(
          Icons.campaign_outlined,
          color: AppColors.primary.withValues(alpha: 0.85),
          size: 40,
        ),
      );
    }

    final cover = coverUrl;
    final logo = brandLogoUrl;
    final hasCover = cover != null && cover.isNotEmpty;
    final hasLogo = logo != null && logo.isNotEmpty;

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
            placeholder: (context, url) => fallback(),
            errorWidget: (context, url, err) => fallback(),
          ),
          if (hasLogo)
            Positioned(
              left: 10,
              bottom: 10,
              child: _LogoOverlayCard(imageUrl: logo),
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
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).colorScheme.surfaceContainerHigh,
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
              placeholder: (context, url) => fallback(),
              errorWidget: (context, url, err) => fallback(),
            ),
          ),
        ),
      );
    }

    return fallback();
  }
}

/// Compact status chip for hero corner (replaces full-width status row).
class _StatusGlowChip extends StatelessWidget {
  const _StatusGlowChip({required this.status, required this.t});

  final CampaignStatus status;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final (Color fg, String label) = switch (status) {
      CampaignStatus.active => (
        const Color(0xFF34D399),
        t.advertiser_campaigns.status.active,
      ),
      CampaignStatus.paused => (
        const Color(0xFFFBBF24),
        t.advertiser_campaigns.status.paused,
      ),
      CampaignStatus.completed => (
        const Color(0xFF94A3B8),
        t.advertiser_campaigns.status.completed,
      ),
      CampaignStatus.draft => (
        AppColors.textMuted,
        t.advertiser_campaigns.status.draft,
      ),
      CampaignStatus.unknown => (
        AppColors.textMuted,
        t.advertiser_campaigns.status.other,
      ),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(color: fg.withValues(alpha: 0.45)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoOverlayCard extends StatelessWidget {
  const _LogoOverlayCard({required this.imageUrl});

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
              color: AppColors.textMutedOf(context),
              size: 24,
            ),
          ),
          errorWidget: (context, url, err) => SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.business_rounded,
              color: AppColors.textMutedOf(context),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderOf(
            context,
          ).withValues(alpha: muted ? 0.65 : 0.9),
        ),
        gradient: muted
            ? null
            : LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
              ),
        color: muted
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.4)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          color: muted ? AppColors.textSecondaryOf(context) : AppColors.primary,
        ),
      ),
    );
  }
}
