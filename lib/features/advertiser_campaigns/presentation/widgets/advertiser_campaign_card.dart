import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/domain/entities/campaign_platform.dart';
import '../../../dashboard/domain/entities/campaign_status.dart';
import '../../domain/advertiser_campaign.dart';

class AdvertiserCampaignCard extends StatelessWidget {
  const AdvertiserCampaignCard({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Thumb(url: c.coverUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge(
                              context,
                            ).copyWith(fontSize: 17, height: 1.25),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _StatusBadge(status: c.status),
                              _PlatformPill(platform: c.platform, t: t),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMutedOf(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricBlock(
                        label: t.advertiser_campaigns.card.budget_total,
                        value: MoneyFormatter.format(
                          c.totalBudgetCents / 100.0,
                          currency: c.currency,
                          locale: moneyLocale,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _MetricBlock(
                        label: _remainingOrSpentLabel(context, c),
                        value: _remainingOrSpentValue(context, c),
                      ),
                    ),
                    Expanded(
                      child: _MetricBlock(
                        label: t.advertiser_campaigns.card.cpc,
                        value: c.cpcCents > 0
                            ? MoneyFormatter.format(
                                c.cpcCents / 100.0,
                                currency: c.currency,
                                locale: moneyLocale,
                              )
                            : '—',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.ads_click_rounded,
                      size: 18,
                      color: AppColors.textMutedOf(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.advertiser_campaigns.card.valid_engagements.replaceAll(
                        '{count}',
                        '${c.validViews}',
                      ),
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _remainingOrSpentLabel(BuildContext context, AdvertiserCampaign c) {
    final t = context.t;
    if (c.status == CampaignStatus.completed) {
      return t.advertiser_campaigns.card.spent;
    }
    return t.advertiser_campaigns.card.remaining;
  }

  String _remainingOrSpentValue(BuildContext context, AdvertiserCampaign c) {
    final cents = c.status == CampaignStatus.completed
        ? c.spentBudgetCents
        : c.remainingBudgetCents;
    return MoneyFormatter.format(
      cents / 100.0,
      currency: c.currency,
      locale: moneyLocale,
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: 120,
                memCacheHeight: 120,
                errorWidget: (context, url, error) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceElevatedOf(context),
      child: Icon(
        Icons.campaign_outlined,
        color: AppColors.primary.withValues(alpha: 0.85),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (Color bg, Color fg, String label) = switch (status) {
      CampaignStatus.active => (
        const Color(0xFF10B981).withValues(alpha: 0.2),
        const Color(0xFF34D399),
        t.advertiser_campaigns.status.active,
      ),
      CampaignStatus.paused => (
        const Color(0xFFF59E0B).withValues(alpha: 0.18),
        const Color(0xFFFBBF24),
        t.advertiser_campaigns.status.paused,
      ),
      CampaignStatus.completed => (
        const Color(0xFF64748B).withValues(alpha: 0.25),
        const Color(0xFF94A3B8),
        t.advertiser_campaigns.status.completed,
      ),
      CampaignStatus.draft => (
        AppColors.textMuted.withValues(alpha: 0.2),
        AppColors.textMuted,
        t.advertiser_campaigns.status.draft,
      ),
      CampaignStatus.unknown => (
        AppColors.textMuted.withValues(alpha: 0.2),
        AppColors.textMuted,
        t.advertiser_campaigns.status.other,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _PlatformPill extends StatelessWidget {
  const _PlatformPill({required this.platform, required this.t});

  final CampaignPlatform platform;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final label = switch (platform) {
      CampaignPlatform.youtube => t.advertiser_campaigns.platform.youtube,
      CampaignPlatform.tiktok => t.advertiser_campaigns.platform.tiktok,
      CampaignPlatform.instagram => t.advertiser_campaigns.platform.instagram,
      CampaignPlatform.unknown => t.advertiser_campaigns.platform.other,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: AppColors.textSecondaryOf(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}
