import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/campaigns/campaign_detail_metadata.dart';
import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/push/mobile_push_route_utils.dart';
import '../../../../core/widgets/campaign_cover_image.dart';
import '../../../../core/widgets/campaign_detail/campaign_detail_assets_link.dart';
import '../../../../core/widgets/campaign_detail/campaign_detail_budget_usage_card.dart';
import '../../../../core/widgets/campaign_detail/campaign_detail_info_card.dart';
import '../../../../core/widgets/campaign_detail/campaign_detail_requirements.dart';
import '../../../../i18n/strings.g.dart';
import '../../../shell/widgets/wayo_bottom_nav.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../advertiser_campaigns/presentation/providers/advertiser_campaigns_providers.dart';
import '../../../advertiser_campaigns/domain/campaign_top_creator.dart';
import '../../../advertiser_campaigns/presentation/widgets/campaign_applications_section.dart';
import '../../../advertiser_campaigns/presentation/widgets/campaign_top_creators_section.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../domain/entities/campaign_platform.dart';
import '../../domain/entities/campaign_status.dart';
import '../theme/campaign_detail_premium_palette.dart';
import '../widgets/error_banner.dart';

String _moneyLocale(AppLocale l) => wayoPublicMoneyLocale(l);

String _advertiserCampaignDetailLocationLabel(Map<String, dynamic> json) {
  return campaignLocationFromCampaignJson(
        json,
        debugSource: 'advertiserCampaignDetail',
      ) ??
      '—';
}

final class _ParsedCampaignDetail {
  const _ParsedCampaignDetail({
    required this.title,
    required this.status,
    required this.platformLabel,
    required this.nicheLabel,
    required this.locationLabel,
    required this.objectiveLabel,
    required this.campaignKindLabel,
    required this.desc,
    required this.totalCents,
    required this.remainingCents,
    required this.spentCents,
    required this.lockedCents,
    required this.currency,
    required this.cpcCents,
    required this.cpmCents,
    required this.validViews,
    required this.validClicks,
    required this.approved,
    required this.isOwner,
    required this.campaignKind,
    required this.showCpmMetric,
    required this.topCreators,
    this.coverUrl,
    this.brandLogoUrl,
    this.assetsUrl,
    this.requiredPlatform,
    this.videoMinDurationMinutes,
    this.shortsMaxDurationSeconds,
    this.shortsRequireVertical,
  });

  final String title;
  final CampaignStatus status;
  final String platformLabel;
  final String nicheLabel;
  final String locationLabel;
  final String objectiveLabel;
  final String campaignKindLabel;
  final String? desc;
  final int totalCents;
  final int remainingCents;
  final int spentCents;
  final int lockedCents;
  final String currency;
  final int cpcCents;
  final int cpmCents;
  final int validViews;
  final int validClicks;
  final int approved;
  final bool isOwner;
  final CreatorCampaignType campaignKind;
  final bool showCpmMetric;
  final List<CampaignTopCreator> topCreators;
  final String? coverUrl;
  final String? brandLogoUrl;
  final String? assetsUrl;
  final String? requiredPlatform;
  final int? videoMinDurationMinutes;
  final int? shortsMaxDurationSeconds;
  final bool? shortsRequireVertical;

  factory _ParsedCampaignDetail.fromJson(
    Map<String, dynamic> json,
    String? fallbackTitle,
    Translations t,
  ) {
    final rawTitle = (json['title'] as String?)?.trim();
    final rawName = (json['name'] as String?)?.trim();
    final title = (rawTitle != null && rawTitle.isNotEmpty)
        ? rawTitle
        : (rawName != null && rawName.isNotEmpty)
            ? rawName
            : (fallbackTitle ?? '');

    final status = CampaignStatus.fromString(json['status'] as String?);
    final platform = CampaignPlatform.fromString(campaignDetailPlatformKey(json));

    final videoReq = json['videoRequirements'];
    final videoReqMap = videoReq is Map
        ? Map<String, dynamic>.from(videoReq)
        : null;

    Map<String, dynamic>? f;
    final finance = json['finance'];
    if (finance is Map<String, dynamic>) f = finance;

    var validViews = (json['validViews'] as num?)?.toInt() ?? 0;
    var validClicks = (json['validClicks'] as num?)?.toInt() ?? 0;
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
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    int rootCents(String k) {
      final v = json[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final total = f != null ? cents('totalBudgetCents') : rootCents('totalBudgetCents');
    final remaining =
        f != null ? cents('remainingBudgetCents') : rootCents('remainingBudget');
    final spent = f != null ? cents('spentBudgetCents') : rootCents('spentBudget');
    int rootLocked() {
      final v = json['lockedBudgetCents'] ?? json['lockedBudget'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }
    final locked = f != null ? cents('lockedBudgetCents') : rootLocked();

    final currency = (json['currency'] as String?)?.toUpperCase() ?? 'USD';

    int readCpc() {
      if (f != null) {
        final c = f['cpcCents'] ?? f['cpc'];
        if (c is int) return c;
        if (c is num) return c.toInt();
      }
      return (json['cpcCents'] as num?)?.toInt() ?? 0;
    }

    int readCpm() {
      if (f != null) {
        final c = f['cpmCents'] ?? f['cpm'];
        if (c is int) return c;
        if (c is num) return c.toInt();
      }
      return (json['cpmCents'] as num?)?.toInt() ?? 0;
    }

    final campaignKind = CreatorCampaignType.fromApi(json['type']);
    final showCpmMetric =
        campaignKind == CreatorCampaignType.video ||
        campaignKind == CreatorCampaignType.shorts;

    return _ParsedCampaignDetail(
      title: title,
      status: status,
      platformLabel: campaignDetailPlatformLabel(t, platform),
      nicheLabel:
          ((json['niche'] as String?)?.trim().isNotEmpty ?? false)
              ? campaignNicheFallbackLabel((json['niche'] as String?)!.trim())
              : '—',
      locationLabel: _advertiserCampaignDetailLocationLabel(json),
      objectiveLabel: campaignDetailObjectiveLabel(
        t,
        json['campaignObjective'] as String?,
      ),
      campaignKindLabel: campaignDetailTypeLabel(t, campaignKind),
      desc: json['description'] as String?,
      totalCents: total,
      remainingCents: remaining,
      spentCents: spent,
      lockedCents: locked,
      currency: currency,
      cpcCents: readCpc(),
      cpmCents: readCpm(),
      validViews: validViews,
      validClicks: validClicks,
      approved: (json['approvedCreators'] as num?)?.toInt() ?? 0,
      isOwner: json['isOwner'] == true,
      campaignKind: campaignKind,
      showCpmMetric: showCpmMetric,
      topCreators: campaignTopCreatorsFromCampaignDetail(json) ?? const [],
      coverUrl: normalizeWayoAdsMediaUrl(parseCampaignCoverUrlFromJson(json)),
      brandLogoUrl: resolveWayoAdsPublicUrl(parseCampaignBrandLogoFromJson(json)),
      assetsUrl: json['assetsUrl'] as String?,
      requiredPlatform: videoReqMap?['requiredPlatform'] as String?,
      videoMinDurationMinutes:
          (json['videoMinDurationMinutes'] as num?)?.toInt(),
      shortsMaxDurationSeconds:
          (json['shortsMaxDurationSeconds'] as num?)?.toInt(),
      shortsRequireVertical: json['shortsRequireVertical'] as bool?,
    );
  }
}

/// Read-only campaign detail (`GET /api/campaigns/:id`).
class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({
    super.key,
    required this.id,
    this.title,
  });

  final String id;
  final String? title;

  String _msg(Translations t, Object e) {
    if (e is NetworkException) return t.errors.network;
    if (e is ServerException) {
      return e.message.isNotEmpty ? e.message : t.errors.server_generic;
    }
    return t.errors.server_generic;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final async = ref.watch(advertiserCampaignDetailProvider(id));
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final role = auth is AuthAuthenticated ? auth.user.wayoAdsRole : null;
    final showBlackBottomBar = role == WayoAdsAccountRole.superAdmin;

    return Scaffold(
      backgroundColor: CampaignDetailPremiumPalette.bg(context),
      bottomNavigationBar:
          showBlackBottomBar ? const WayoBlackBottomBar() : null,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: CampaignDetailPremiumPalette.bg(context),
        foregroundColor: CampaignDetailPremiumPalette.value(context),
        iconTheme: IconThemeData(
          color: CampaignDetailPremiumPalette.value(context),
        ),
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            popOrGoShellParent(context, '/campaigns/$id');
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          title ?? t.advertiser_campaigns.detail.fallback_title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CampaignDetailPremiumPalette.value(context),
          ),
        ),
      ),
      body: async.when(
        skipLoadingOnReload: true,
        data: (json) {
          final parsed = _ParsedCampaignDetail.fromJson(json, title, t);
          return _Body(
            id: id,
            parsed: parsed,
            moneyLocale: moneyLocale,
            t: t,
          );
        },
        loading: () => _CampaignDetailLoadingSkeleton(t: t),
        error: (e, _) => _CampaignDetailError(
          campaignId: id,
          message: _msg(t, e),
          retryLabel: t.dashboard.errors.retry,
          onRetry: () => ref.invalidate(advertiserCampaignDetailProvider(id)),
        ),
      ),
    );
  }
}

class _CampaignDetailError extends StatelessWidget {
  const _CampaignDetailError({
    required this.campaignId,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String campaignId;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                popOrGoShellParent(context, '/campaigns/$campaignId');
              },
              icon: Icon(
                Icons.arrow_back_rounded,
                color: CampaignDetailPremiumPalette.value(context),
              ),
            ),
            const SizedBox(height: 24),
            ErrorBanner(message: message, retryLabel: retryLabel, onRetry: onRetry),
            const SizedBox(height: 20),
            Text(
              t.advertiser_campaigns.detail.metrics_title,
              style: CampaignDetailPremiumPalette.labelStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignDetailLoadingSkeleton extends StatelessWidget {
  const _CampaignDetailLoadingSkeleton({required this.t});

  final Translations t;

  Widget _shine(BuildContext cx, Widget child) => Shimmer.fromColors(
        period: const Duration(milliseconds: 1100),
        baseColor: CampaignDetailPremiumPalette.surface1(cx),
        highlightColor:
            CampaignDetailPremiumPalette.surfaceGlass(cx).withValues(alpha: 0.55),
        child: child,
      );

  Widget _block(BuildContext context, double height, {double radius = 20}) =>
      _shine(
        context,
        Container(
          height: height,
          decoration: BoxDecoration(
            color: CampaignDetailPremiumPalette.surface1(context),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final shimHint =
        CampaignDetailPremiumPalette.value(context).withValues(alpha: 0.12);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // Cover image placeholder (16:9).
        _shine(
          context,
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: CampaignDetailPremiumPalette.surfaceGlass(context),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _block(context, 110),
        const SizedBox(height: 14),
        _block(context, 180),
        const SizedBox(height: 20),
        _shine(
          context,
          Container(height: 20, width: 160, color: shimHint),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _block(context, 90, radius: 16)),
            const SizedBox(width: 10),
            Expanded(child: _block(context, 90, radius: 16)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _block(context, 90, radius: 16)),
            const SizedBox(width: 10),
            Expanded(child: _block(context, 90, radius: 16)),
          ],
        ),
      ],
    );
  }
}

enum _MetricDot { gray, amber, green }

class _Body extends ConsumerWidget {
  const _Body({
    required this.id,
    required this.parsed,
    required this.moneyLocale,
    required this.t,
  });

  final String id;
  final _ParsedCampaignDetail parsed;
  final String moneyLocale;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final role = auth is AuthAuthenticated ? auth.user.wayoAdsRole : null;
    final isSuperadmin = role == WayoAdsAccountRole.superAdmin;

    String moneyStr(int cents) => MoneyFormatter.format(
          cents / 100.0,
          currency: kWayoPublicCurrency,
          locale: moneyLocale,
        );

    final primaryRate = resolveCampaignPayoutMetric(
      type: parsed.campaignKind,
      cpcCents: parsed.cpcCents,
      cpmCents: parsed.cpmCents,
      spentBudgetCents: parsed.spentCents,
      validViews: parsed.validViews,
    );
    final rateIcon = switch (primaryRate.kind) {
      CampaignPayoutMetricKind.cpc => Icons.toll_outlined,
      _ => Icons.movie_filter_outlined,
    };

    final total = parsed.totalCents;
    final rem = parsed.remainingCents;
    final spent = parsed.spentCents;
    final locked = parsed.lockedCents;

    _MetricDot dotRemaining() {
      if (total <= 0) return _MetricDot.gray;
      if (rem <= 0) return _MetricDot.gray;
      if (rem < total) return _MetricDot.amber;
      return _MetricDot.green;
    }

    _MetricDot dotLocked() {
      if (total <= 0) return _MetricDot.gray;
      if (locked <= 0) return _MetricDot.gray;
      if (locked < total) return _MetricDot.amber;
      return _MetricDot.green;
    }

    final metrics = <(IconData, String, String, _MetricDot, bool)>[
      (
        Icons.payments_outlined,
        t.advertiser_campaigns.card.budget_total,
        moneyStr(total),
        total > 0 ? _MetricDot.green : _MetricDot.gray,
        total > 0,
      ),
      (
        Icons.savings_outlined,
        t.advertiser_campaigns.card.remaining,
        moneyStr(rem),
        dotRemaining(),
        rem > 0,
      ),
      (
        Icons.lock_clock_outlined,
        t.advertiser_campaigns.card.locked,
        moneyStr(locked),
        dotLocked(),
        locked > 0,
      ),
      (
        Icons.trending_down_rounded,
        t.advertiser_campaigns.card.spent,
        moneyStr(spent),
        spent > 0 ? _MetricDot.green : _MetricDot.gray,
        spent > 0,
      ),
      (
        rateIcon,
        campaignPayoutMetricLabel(t, primaryRate.kind),
        primaryRate.hasValue ? moneyStr(primaryRate.cents) : '—',
        primaryRate.hasValue ? _MetricDot.green : _MetricDot.gray,
        primaryRate.hasValue,
      ),
      (
        Icons.visibility_outlined,
        t.advertiser_campaigns.detail.valid_views,
        '${parsed.validViews}',
        parsed.validViews > 0 ? _MetricDot.green : _MetricDot.gray,
        parsed.validViews > 0,
      ),
      (
        Icons.ads_click_outlined,
        t.advertiser_campaigns.detail.valid_clicks,
        '${parsed.validClicks}',
        parsed.validClicks > 0 ? _MetricDot.green : _MetricDot.gray,
        parsed.validClicks > 0,
      ),
    ];

    final hasDesc = parsed.desc != null && parsed.desc!.trim().isNotEmpty;
    final showOwnerSections = !isSuperadmin && parsed.isOwner;

    return RefreshIndicator.adaptive(
      color: CampaignDetailPremiumPalette.amber,
      backgroundColor: CampaignDetailPremiumPalette.surface1(context),
      onRefresh: () async {
        HapticFeedback.lightImpact();
        ref.invalidate(advertiserCampaignDetailProvider(id));
        if (!isSuperadmin) {
          ref.invalidate(campaignApplicationsProvider(id));
        }
        await ref.read(advertiserCampaignDetailProvider(id).future);
      },
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          40 + wayoShellBodyBottomPadding(context),
        ),
        children: [
          CampaignCoverImage(
            coverUrl: parsed.coverUrl,
            brandLogoUrl: parsed.brandLogoUrl,
            fallbackIcon: Icons.campaign_outlined,
            accent: CampaignDetailPremiumPalette.amber,
          ),
          const SizedBox(height: 14),
          _PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parsed.title,
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
                    _StatusPill(status: parsed.status, t: t),
                    _Pill(
                      label: parsed.campaignKindLabel,
                      color: CampaignDetailPremiumPalette.amber,
                      icon: Icons.interests_outlined,
                    ),
                    _Pill(
                      label: parsed.platformLabel,
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.public_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CampaignDetailInfoCard(
            platformLabel: parsed.platformLabel,
            nicheLabel: parsed.nicheLabel,
            locationLabel: parsed.locationLabel,
            objectiveLabel: parsed.objectiveLabel,
            campaignTypeLabel: parsed.campaignKindLabel,
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            CampaignDetailBudgetUsageCard(
              totalCents: total,
              spentCents: spent,
              remainingCents: rem,
              moneyLocale: moneyLocale,
              approvedCreators: parsed.approved,
            ),
          ],
          if (hasDesc) ...[
            const SizedBox(height: 14),
            _DescriptionPremiumBlock(text: parsed.desc, t: t),
          ],
          if (parsed.campaignKind.requiresVideoSubmission) ...[
            const SizedBox(height: 14),
            _PremiumCard(
              child: CampaignDetailRequirements(
                type: parsed.campaignKind,
                requiredPlatform: parsed.requiredPlatform,
                videoMinDurationMinutes: parsed.videoMinDurationMinutes,
                shortsMaxDurationSeconds: parsed.shortsMaxDurationSeconds,
                shortsRequireVertical: parsed.shortsRequireVertical,
              ),
            ),
          ],
          if (parsed.assetsUrl != null && parsed.assetsUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            CampaignDetailAssetsLink(url: parsed.assetsUrl!.trim()),
          ],
          const SizedBox(height: 18),
          _PerformanceTitle(t: t),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              for (var i = 0; i < metrics.length; i++)
                _PremiumMetricTile(
                  icon: metrics[i].$1,
                  label: metrics[i].$2,
                  value: metrics[i].$3,
                  dot: metrics[i].$4,
                  leftAccent: metrics[i].$5,
                ),
            ],
          ),
          if (showOwnerSections) ...[
            const SizedBox(height: 24),
            CampaignTopCreatorsSection(
              creators: parsed.topCreators,
              moneyLocale: moneyLocale,
            ),
            const SizedBox(height: 24),
            CampaignApplicationsSection(
              campaignId: id,
              premiumChrome: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Flat surface card matching the creator campaign detail layout.
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CampaignDetailPremiumPalette.kCardPadding),
      decoration: BoxDecoration(
        color: CampaignDetailPremiumPalette.surface1(context),
        borderRadius:
            BorderRadius.circular(CampaignDetailPremiumPalette.kCardRadius),
        border: Border.all(
          color: CampaignDetailPremiumPalette.divider(context)
              .withValues(alpha: 0.9),
        ),
        boxShadow: CampaignDetailPremiumPalette.cardShadow(context, 0.12),
      ),
      child: child,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.t});

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

class _DescriptionPremiumBlock extends StatefulWidget {
  const _DescriptionPremiumBlock({required this.text, required this.t});

  final String? text;
  final Translations t;

  @override
  State<_DescriptionPremiumBlock> createState() => _DescriptionPremiumBlockState();
}

class _DescriptionPremiumBlockState extends State<_DescriptionPremiumBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final raw = widget.text?.trim();
    if (raw == null || raw.isEmpty) return const SizedBox.shrink();

    final bodyStyle = GoogleFonts.dmSans(
      fontStyle: FontStyle.italic,
      fontSize: 14,
      height: 1.45,
      color: CampaignDetailPremiumPalette.muted(context),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final tp = TextPainter(
          text: TextSpan(text: raw, style: bodyStyle),
          textDirection: Directionality.of(context),
          maxLines: 2,
        )..layout(maxWidth: c.maxWidth);

        final exceeds = tp.didExceedMaxLines;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(CampaignDetailPremiumPalette.kCardPadding),
          decoration: BoxDecoration(
            color: CampaignDetailPremiumPalette.surface1(context),
            borderRadius: BorderRadius.circular(CampaignDetailPremiumPalette.kCardRadius),
            border: Border.all(
              color:
                  CampaignDetailPremiumPalette.divider(context).withValues(alpha: 0.9),
            ),
            boxShadow: CampaignDetailPremiumPalette.cardShadow(context, 0.12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.t.advertiser_campaigns.detail.description_title,
                style:
                    CampaignDetailPremiumPalette.sectionTitle(context).copyWith(fontSize: 16),
              ),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 320),
                crossFadeState:
                    _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstCurve: Curves.easeOutCubic,
                secondCurve: Curves.easeOutCubic,
                sizeCurve: Curves.easeOutCubic,
                firstChild: Text(
                  raw,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle,
                ),
                secondChild: Text(raw, style: bodyStyle),
              ),
              if (exceeds) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _expanded = !_expanded);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: CampaignDetailPremiumPalette.amber,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _expanded
                              ? widget.t.advertiser_campaigns.detail.show_less
                              : widget.t.advertiser_campaigns.detail.show_more,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            color: CampaignDetailPremiumPalette.amber,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PerformanceTitle extends StatefulWidget {
  const _PerformanceTitle({required this.t});

  final Translations t;

  @override
  State<_PerformanceTitle> createState() => _PerformanceTitleState();
}

class _PerformanceTitleState extends State<_PerformanceTitle> {
  bool _shimmerPhase = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _shimmerPhase = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.t.advertiser_campaigns.detail.metrics_title,
      style: CampaignDetailPremiumPalette.sectionTitle(context),
    );
    if (_shimmerPhase) return text;
    return Shimmer.fromColors(
      period: const Duration(milliseconds: 900),
      baseColor: CampaignDetailPremiumPalette.surface1(context),
      highlightColor:
          CampaignDetailPremiumPalette.surfaceGlass(context).withValues(alpha: 0.9),
      child: text,
    );
  }
}

class _PremiumMetricTile extends StatelessWidget {
  const _PremiumMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.dot,
    required this.leftAccent,
  });

  final IconData icon;
  final String label;
  final String value;
  final _MetricDot dot;
  final bool leftAccent;

  Color _dotColor(BuildContext context) => switch (dot) {
        _MetricDot.gray => CampaignDetailPremiumPalette.divider(context),
        _MetricDot.amber => CampaignDetailPremiumPalette.amber,
        _MetricDot.green => const Color(0xFF22C55E),
      };

  @override
  Widget build(BuildContext context) {
    final borderSide = Border.all(
      color: CampaignDetailPremiumPalette.divider(context).withValues(alpha: 0.95),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: CampaignDetailPremiumPalette.surface1(context),
        borderRadius: BorderRadius.circular(CampaignDetailPremiumPalette.kCardRadius),
        border: borderSide,
        boxShadow: CampaignDetailPremiumPalette.cardShadow(context, 0.08),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CampaignDetailPremiumPalette.kCardRadius),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leftAccent)
                Container(
                  width: 3,
                  color: CampaignDetailPremiumPalette.amber,
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: leftAccent ? 9 : 12,
                    right: 12,
                    top: 11,
                    bottom: 11,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: CampaignDetailPremiumPalette.amber
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              icon,
                              size: 17,
                              color: CampaignDetailPremiumPalette.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CampaignDetailPremiumPalette.bodyLabel(context),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _dotColor(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CampaignDetailPremiumPalette.metricMono(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

