import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../domain/creator_browse_campaign.dart';

/// Tappable card rendering a single browseable campaign.
///
/// If [applicationStatus] is set (because the creator already applied), a
/// small status pill is rendered **under the thumbnail** — never overlapping
/// the title.
class CreatorBrowseCampaignCard extends StatelessWidget {
  const CreatorBrowseCampaignCard({
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
    final payoutPerView = c.cpmCents / 1000.0;
    final payoutLabel = c.type == CreatorCampaignType.link
        ? t.creator.campaigns.reward_per_click(
            amount: MoneyFormatter.format(
              c.cpcCents / 100.0,
              currency: c.currency,
              locale: moneyLocale,
            ),
          )
        : t.creator.campaigns.reward_per_view(
            amount: MoneyFormatter.format(
              payoutPerView / 100.0,
              currency: c.currency,
              locale: moneyLocale,
            ),
          );

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
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Thumb(
                      url: normalizeWayoAdsMediaUrl(c.coverUrl),
                      brandLogoUrl: resolveWayoAdsPublicUrl(c.brandLogoUrl),
                      type: c.type,
                    ),
                    if (applicationStatus != null) ...[
                      const SizedBox(height: 6),
                      _ApplicationStatusPill(status: applicationStatus!),
                    ],
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: AppTextStyles.labelLarge(
                          context,
                        ).copyWith(fontSize: 16, height: 1.25),
                      ),
                      if (c.advertiserName != null &&
                          c.advertiserName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          c.advertiserName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondaryOf(context)),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _TypePill(type: c.type),
                          _RewardPill(label: payoutLabel),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondaryOf(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.type, this.brandLogoUrl});

  /// Cover image URL ([normalizeWayoAdsMediaUrl]); may be null.
  final String? url;

  final CreatorCampaignType type;

  /// Resolved absolute logo URL ([resolveWayoAdsPublicUrl]); may be null.
  final String? brandLogoUrl;

  Widget _typeIconPlaceholder(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            CreatorColors.primaryOf(context).withValues(alpha: 0.18),
            CreatorColors.primaryOf(context).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        switch (type) {
          CreatorCampaignType.link => Icons.link_rounded,
          CreatorCampaignType.video => Icons.play_circle_fill_rounded,
          CreatorCampaignType.shorts => Icons.movie_filter_rounded,
          CreatorCampaignType.unknown => Icons.campaign_outlined,
        },
        color: CreatorColors.primaryOf(context),
        size: 30,
      ),
    );
  }

  Widget _coverThumbnail(BuildContext context, Widget fallback) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        memCacheWidth: 144,
        memCacheHeight: 144,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = _typeIconPlaceholder(context);
    final logo = brandLogoUrl;

    /// Advertiser-uploaded logo replaces the generic link/video/shorts icon thumbnail.
    if (logo != null && logo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 72,
          height: 72,
          color: Theme.of(context).cardColor,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: CachedNetworkImage(
            imageUrl: logo,
            fit: BoxFit.contain,
            memCacheWidth: 144,
            memCacheHeight: 144,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => url != null && url!.trim().isNotEmpty
                ? _coverThumbnail(context, placeholder)
                : placeholder,
          ),
        ),
      );
    }

    if (url != null && url!.trim().isNotEmpty) {
      return _coverThumbnail(context, placeholder);
    }
    return placeholder;
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final CreatorCampaignType type;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final label = switch (type) {
      CreatorCampaignType.link => t.creator.campaigns.type_link,
      CreatorCampaignType.video => t.creator.campaigns.type_video,
      CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
      CreatorCampaignType.unknown => '—',
    };
    return _Pill(label: label, color: CreatorColors.primaryOf(context));
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _Pill(label: label, color: const Color(0xFF10B981));
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Compact status pill rendered under the thumbnail when the creator has
/// already applied to this campaign.
class _ApplicationStatusPill extends StatelessWidget {
  const _ApplicationStatusPill({required this.status});

  final CreatorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (label, color) = switch (status) {
      CreatorApplicationStatus.approved => (
        t.creator.applications.status_approved,
        const Color(0xFF10B981),
      ),
      CreatorApplicationStatus.pending => (
        t.creator.applications.status_pending,
        const Color(0xFFF59E0B),
      ),
      CreatorApplicationStatus.rejected => (
        t.creator.applications.status_rejected,
        const Color(0xFFEF4444),
      ),
      CreatorApplicationStatus.withdrawn => (
        t.creator.applications.status_withdrawn,
        AppColors.textMutedOf(context),
      ),
      CreatorApplicationStatus.unknown => (
        t.creator.applications.status_unknown,
        AppColors.textMutedOf(context),
      ),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
