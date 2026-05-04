import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../advertiser_campaigns/presentation/providers/advertiser_campaigns_providers.dart';
import '../../../advertiser_campaigns/presentation/widgets/campaign_applications_section.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../domain/entities/campaign_platform.dart';
import '../../domain/entities/campaign_status.dart';
import '../widgets/error_banner.dart';

String _moneyLocale(AppLocale l) => switch (l) {
  AppLocale.en => 'en_US',
  AppLocale.fr => 'fr_FR',
  AppLocale.ar => 'ar_SA',
};

/// Same platform inference as [AdvertiserCampaignsRemoteDatasource] list items.
String _campaignDetailPlatformKey(Map<String, dynamic> json) {
  final shorts = json['shortsPlatform'] as String?;
  if (shorts != null && shorts.trim().isNotEmpty) {
    return shorts.trim();
  }
  final platforms = json['platforms'] as String?;
  if (platforms != null && platforms.trim().isNotEmpty) {
    return platforms.split(',').first.trim();
  }
  final type = json['type'] as String?;
  if (type == 'VIDEO' || type == 'SHORTS') {
    return 'youtube';
  }
  return '';
}

String _platformLabel(Translations t, CampaignPlatform p) => switch (p) {
  CampaignPlatform.youtube => t.advertiser_campaigns.platform.youtube,
  CampaignPlatform.tiktok => t.advertiser_campaigns.platform.tiktok,
  CampaignPlatform.instagram => t.advertiser_campaigns.platform.instagram,
  CampaignPlatform.unknown => t.advertiser_campaigns.platform.other,
};

String _campaignKindLabel(Translations t, CreatorCampaignType k) => switch (k) {
  CreatorCampaignType.link => t.creator.campaigns.type_link,
  CreatorCampaignType.video => t.creator.campaigns.type_video,
  CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
  CreatorCampaignType.unknown => '—',
};

String _campaignObjectiveDetailLabel(Translations t, String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'AWARENESS':
      return t.advertiser_campaigns.detail.objective_awareness;
    case 'TRAFFIC':
      return t.advertiser_campaigns.detail.objective_traffic;
    case 'CONVERSION':
      return t.advertiser_campaigns.detail.objective_conversion;
    default:
      return '—';
  }
}

/// Read-only campaign detail (Wayo-ads `GET /api/campaigns/:id`). No edit actions.
class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({
    super.key,
    required this.id,
    this.coverUrl,
    this.brandLogoUrl,
    this.title,
  });

  final String id;
  final String? coverUrl;
  final String? brandLogoUrl;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final async = ref.watch(advertiserCampaignDetailProvider(id));
    String msg(Object e) {
      if (e is NetworkException) {
        return t.errors.network;
      }
      if (e is ServerException) {
        return e.message.isNotEmpty ? e.message : t.errors.server_generic;
      }
      return t.errors.server_generic;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: Text(
          async.maybeWhen(
            data: (m) {
              final a = (m['title'] as String?)?.trim();
              final b = (m['name'] as String?)?.trim();
              if (a != null && a.isNotEmpty) {
                return a;
              }
              if (b != null && b.isNotEmpty) {
                return b;
              }
              return title ?? t.advertiser_campaigns.detail.fallback_title;
            },
            orElse: () => title ?? t.advertiser_campaigns.detail.fallback_title,
          ),
        ),
      ),
      body: async.when(
        data: (json) => _DetailContent(
          id: id,
          json: json,
          heroCoverUrl: coverUrl,
          heroBrandLogoUrl: brandLogoUrl,
          fallbackTitle: title,
          moneyLocale: moneyLocale,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ErrorBanner(
              message: msg(e),
              retryLabel: t.dashboard.errors.retry,
              onRetry: () =>
                  ref.invalidate(advertiserCampaignDetailProvider(id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.id,
    required this.json,
    required this.heroCoverUrl,
    required this.heroBrandLogoUrl,
    required this.fallbackTitle,
    required this.moneyLocale,
  });

  final String id;
  final Map<String, dynamic> json;
  final String? heroCoverUrl;
  final String? heroBrandLogoUrl;
  final String? fallbackTitle;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rawTitle = (json['title'] as String?)?.trim();
    final rawName = (json['name'] as String?)?.trim();
    final title = (rawTitle != null && rawTitle.isNotEmpty)
        ? rawTitle
        : (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (fallbackTitle ?? '');
    final status = CampaignStatus.fromString(json['status'] as String?);
    final platform = CampaignPlatform.fromString(
      _campaignDetailPlatformKey(json),
    );
    final desc = json['description'] as String?;
    final finance = json['finance'];
    var validViews = (json['validViews'] as num?)?.toInt() ?? 0;
    var validClicks = (json['validClicks'] as num?)?.toInt() ?? 0;
    final approved = (json['approvedCreators'] as num?)?.toInt() ?? 0;
    Map<String, dynamic>? f;
    if (finance is Map<String, dynamic>) {
      f = finance;
    }
    if (f != null) {
      if (validViews == 0) {
        validViews = (f['validViews'] as num?)?.toInt() ?? 0;
      }
      if (validClicks == 0) {
        validClicks = (f['validClicks'] as num?)?.toInt() ?? 0;
      }
    }
    int cents(dynamic k) {
      final v = f?[k];
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return int.tryParse('$v') ?? 0;
    }

    int rootCents(String k) {
      final v = json[k];
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return int.tryParse('$v') ?? 0;
    }

    final total = f != null
        ? cents('totalBudgetCents')
        : rootCents('totalBudgetCents');
    final remaining = f != null
        ? cents('remainingBudgetCents')
        : rootCents('remainingBudget');
    final spent = f != null
        ? cents('spentBudgetCents')
        : rootCents('spentBudget');
    int rootLocked() {
      final v = json['lockedBudgetCents'] ?? json['lockedBudget'];
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return int.tryParse('$v') ?? 0;
    }

    final locked = f != null ? cents('lockedBudgetCents') : rootLocked();

    final currency = (json['currency'] as String?)?.toUpperCase() ?? 'EUR';
    // Prefer nested finance.cpcCents; otherwise root; default 0 (never "—" in UI).
    int cpcCents() {
      if (f != null) {
        final c = f['cpcCents'] ?? f['cpc'];
        if (c is int) {
          return c;
        }
        if (c is num) {
          return c.toInt();
        }
      }
      return (json['cpcCents'] as num?)?.toInt() ?? 0;
    }

    final cpcRoot = cpcCents();

    int cpmCents() {
      if (f != null) {
        final c = f['cpmCents'] ?? f['cpm'];
        if (c is int) {
          return c;
        }
        if (c is num) {
          return c.toInt();
        }
      }
      return (json['cpmCents'] as num?)?.toInt() ?? 0;
    }

    final cpmRoot = cpmCents();

    final thumbRaw =
        heroCoverUrl ?? parseCampaignCoverUrlFromJson(json);

    final thumb = normalizeWayoAdsMediaUrl(thumbRaw) ?? thumbRaw;

    final brandFromJson = parseCampaignBrandLogoFromJson(json);
    final resolvedBrand = resolveWayoAdsPublicUrl(
      heroBrandLogoUrl ?? brandFromJson,
    );

    final campaignKind = CreatorCampaignType.fromApi(json['type']);
    final kindLabel = _campaignKindLabel(t, campaignKind);
    final showCpmMetric =
        campaignKind == CreatorCampaignType.video ||
        campaignKind == CreatorCampaignType.shorts;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasThumb = thumb != null && thumb!.trim().isNotEmpty;

    Widget coverChild;
    if (hasThumb) {
      coverChild = CachedNetworkImage(
        imageUrl: thumb!,
        fit: BoxFit.cover,
        memCacheWidth: 800,
        errorWidget: (context, url, error) {
          if (resolvedBrand != null && resolvedBrand.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(36),
              child: CachedNetworkImage(
                imageUrl: resolvedBrand,
                fit: BoxFit.contain,
                errorWidget: (context, u, _) => _coverFallback(context),
              ),
            );
          }
          return _coverFallback(context);
        },
      );
    } else if (resolvedBrand != null && resolvedBrand.isNotEmpty) {
      coverChild = ColoredBox(
        color: AppColors.surfaceElevatedOf(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: CachedNetworkImage(
            imageUrl: resolvedBrand,
            fit: BoxFit.contain,
            memCacheWidth: 800,
            memCacheHeight: 450,
            errorWidget: (context, url, error) => _coverFallback(context),
          ),
        ),
      );
    } else {
      coverChild = _coverFallback(context);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      children: [
        _CoverFrame(isDark: isDark, child: coverChild),
        const SizedBox(height: 20),
        _SummaryCard(
          isDark: isDark,
          title: title,
          status: status,
          platformLabel: _platformLabel(t, platform),
          campaignKindLabel: kindLabel,
          nicheLabel:
              ((json['niche'] as String?)?.trim().isNotEmpty ?? false)
                  ? campaignNicheFallbackLabel(
                      (json['niche'] as String?)!.trim(),
                    )
                  : '—',
          objectiveLabel: _campaignObjectiveDetailLabel(
            t,
            json['campaignObjective'] as String?,
          ),
          desc: desc,
          t: t,
        ),
        const SizedBox(height: 20),
        Text(
          t.advertiser_campaigns.detail.metrics_title,
          style: AppTextStyles.labelLarge(context).copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: AppColors.textMutedOf(context),
          ),
        ),
        const SizedBox(height: 12),
        _MetricsCard(
          isDark: isDark,
          child: Column(
            children: [
              _MetricTile(
                isDark: isDark,
                icon: Icons.payments_outlined,
                label: t.advertiser_campaigns.card.budget_total,
                value: MoneyFormatter.format(
                  total / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                ),
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.savings_outlined,
                label: t.advertiser_campaigns.card.remaining,
                value: MoneyFormatter.format(
                  remaining / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                ),
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.lock_clock_outlined,
                label: t.advertiser_campaigns.card.locked,
                value: MoneyFormatter.format(
                  locked / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                ),
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.trending_down_rounded,
                label: t.advertiser_campaigns.card.spent,
                value: MoneyFormatter.format(
                  spent / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                ),
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.toll_outlined,
                label: t.advertiser_campaigns.card.cpc,
                value: MoneyFormatter.format(
                  cpcRoot / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                ),
              ),
              if (showCpmMetric) ...[
                _MetricDivider(isDark: isDark),
                _MetricTile(
                  isDark: isDark,
                  icon: Icons.movie_filter_outlined,
                  label: t.advertiser_campaigns.detail.cpm_metric,
                  value: MoneyFormatter.format(
                    cpmRoot / 100.0,
                    currency: currency,
                    locale: moneyLocale,
                  ),
                ),
              ],
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.visibility_outlined,
                label: t.advertiser_campaigns.detail.valid_views,
                value: '$validViews',
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.ads_click_outlined,
                label: t.advertiser_campaigns.detail.valid_clicks,
                value: '$validClicks',
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.groups_2_outlined,
                label: t.advertiser_campaigns.detail.approved_creators,
                value: '$approved',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CampaignApplicationsSection(campaignId: id),
      ],
    );
  }

  Widget _coverFallback(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceElevatedOf(context),
      child: Icon(
        Icons.campaign_outlined,
        size: 48,
        color: AppColors.textMutedOf(context),
      ),
    );
  }
}

class _CoverFrame extends StatelessWidget {
  const _CoverFrame({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 72,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: isDark ? 0.55 : 0.35),
                      ],
                    ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.isDark,
    required this.title,
    required this.status,
    required this.platformLabel,
    required this.campaignKindLabel,
    required this.nicheLabel,
    required this.objectiveLabel,
    required this.desc,
    required this.t,
  });

  final bool isDark;
  final String title;
  final CampaignStatus status;
  final String platformLabel;

  /// LINK / VIDEO / SHORTS localized label (same strings as creator).
  final String campaignKindLabel;

  /// Human-readable niche label (API enum).
  final String nicheLabel;

  /// Localized campaign objective.
  final String objectiveLabel;

  final String? desc;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevatedOf(context),
            AppColors.primary.withValues(alpha: isDark ? 0.07 : 0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.pageTitle(context),
                ),
              ),
              const SizedBox(width: 10),
              _DetailStatusChip(status: status, t: t),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.public_outlined,
                size: 18,
                color: AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                t.advertiser_campaigns.detail.platform_label,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textMutedOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  platformLabel,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 18,
                color: AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                t.advertiser_campaigns.detail.niche_label,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textMutedOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nicheLabel,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                t.advertiser_campaigns.detail.objective_label,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textMutedOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  objectiveLabel,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.interests_outlined,
                size: 18,
                color: AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                t.advertiser_campaigns.detail.campaign_type_label,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textMutedOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  campaignKindLabel,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (desc != null && desc!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              desc!.trim(),
              style: AppTextStyles.bodyLarge(context).copyWith(
                height: 1.45,
                color: AppColors.textPrimaryOf(context).withValues(alpha: 0.88),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.surfaceElevatedOf(
          context,
        ).withValues(alpha: isDark ? 0.92 : 0.98),
        border: Border.all(
          color: AppColors.borderOf(
            context,
          ).withValues(alpha: isDark ? 0.5 : 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: child,
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.borderOf(
          context,
        ).withValues(alpha: isDark ? 0.4 : 0.7),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
  });

  final bool isDark;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 15,
                color: AppColors.textMutedOf(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTextStyles.labelLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip({required this.status, required this.t});

  final CampaignStatus status;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      CampaignStatus.active => t.advertiser_campaigns.status.active,
      CampaignStatus.paused => t.advertiser_campaigns.status.paused,
      CampaignStatus.completed => t.advertiser_campaigns.status.completed,
      CampaignStatus.draft => t.advertiser_campaigns.status.draft,
      CampaignStatus.unknown => t.advertiser_campaigns.status.other,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
