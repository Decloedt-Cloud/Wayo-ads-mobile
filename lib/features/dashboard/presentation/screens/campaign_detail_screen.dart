import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../advertiser_campaigns/presentation/providers/advertiser_campaigns_providers.dart';
import '../../../advertiser_campaigns/presentation/widgets/campaign_applications_section.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../domain/entities/campaign_platform.dart';
import '../../domain/entities/campaign_status.dart';
import '../theme/campaign_detail_premium_palette.dart';
import '../widgets/error_banner.dart';

String _moneyLocale(AppLocale l) => wayoPublicMoneyLocale(l);

String _campaignDetailPlatformKey(Map<String, dynamic> json) {
  final shorts = json['shortsPlatform'] as String?;
  if (shorts != null && shorts.trim().isNotEmpty) return shorts.trim();
  final platforms = json['platforms'] as String?;
  if (platforms != null && platforms.trim().isNotEmpty) {
    return platforms.split(',').first.trim();
  }
  final type = json['type'] as String?;
  if (type == 'VIDEO' || type == 'SHORTS') return 'youtube';
  return '';
}

String _platformLabel(Translations t, CampaignPlatform p) => switch (p) {
      CampaignPlatform.youtube => t.advertiser_campaigns.platform.youtube,
      CampaignPlatform.tiktok => t.advertiser_campaigns.platform.tiktok,
      CampaignPlatform.instagram => t.advertiser_campaigns.platform.instagram,
      CampaignPlatform.unknown => t.advertiser_campaigns.platform.other,
    };

String _campaignKindLabel(Translations t, CreatorCampaignType k) =>
    switch (k) {
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
    required this.campaignKind,
    required this.showCpmMetric,
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
  final CreatorCampaignType campaignKind;
  final bool showCpmMetric;

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
    final platform = CampaignPlatform.fromString(_campaignDetailPlatformKey(json));

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
      platformLabel: _platformLabel(t, platform),
      nicheLabel:
          ((json['niche'] as String?)?.trim().isNotEmpty ?? false)
              ? campaignNicheFallbackLabel((json['niche'] as String?)!.trim())
              : '—',
      locationLabel: _advertiserCampaignDetailLocationLabel(json),
      objectiveLabel: _campaignObjectiveDetailLabel(
        t,
        json['campaignObjective'] as String?,
      ),
      campaignKindLabel: _campaignKindLabel(t, campaignKind),
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
      campaignKind: campaignKind,
      showCpmMetric: showCpmMetric,
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
    final showBlackBottomBar =
        role == WayoAdsAccountRole.superAdmin ||
        role == WayoAdsAccountRole.advertiser;

    return Scaffold(
      backgroundColor: CampaignDetailPremiumPalette.bg(context),
      bottomNavigationBar:
          showBlackBottomBar ? const WayoBlackBottomBar() : null,
      body: async.when(
        data: (json) {
          final parsed = _ParsedCampaignDetail.fromJson(json, title, t);
          return _CampaignPremiumScrollBody(
            id: id,
            parsed: parsed,
            moneyLocale: moneyLocale,
            t: t,
          );
        },
        loading: () => _CampaignDetailLoadingSkeleton(t: t),
        error: (e, _) => _CampaignDetailError(
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
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

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
                context.pop();
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

  @override
  Widget build(BuildContext context) {
    final shimHint = CampaignDetailPremiumPalette.value(context).withValues(alpha: 0.12);
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _shine(
            context,
            Container(
              height: 164,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient:
                    CampaignDetailPremiumPalette.accentGradient.multiplyAlpha(0.35),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _shine(
                context,
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: CampaignDetailPremiumPalette.surfaceGlass(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _shine(
                context,
                Container(
                  height: 92,
                  decoration: BoxDecoration(
                    color: CampaignDetailPremiumPalette.surface1(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _shine(
                context,
                Container(height: 20, width: 160, color: shimHint),
              ),
              const SizedBox(height: 14),
              _shine(
                context,
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: CampaignDetailPremiumPalette.surface1(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _shine(
                context,
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: CampaignDetailPremiumPalette.surface1(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

extension _SoftLinearGradient on LinearGradient {
  LinearGradient multiplyAlpha(double a) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((c) {
        final blend = (c.a * a).clamp(0.0, 1.0);
        return c.withValues(alpha: blend);
      }).toList(),
      stops: stops,
    );
  }
}

enum _MetricDot { gray, amber, green }

class _CampaignPremiumScrollBody extends ConsumerStatefulWidget {
  const _CampaignPremiumScrollBody({
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
  ConsumerState<_CampaignPremiumScrollBody> createState() =>
      _CampaignPremiumScrollBodyState();
}

class _CampaignPremiumScrollBodyState extends ConsumerState<_CampaignPremiumScrollBody> {
  late final ScrollController _scroll;
  bool _showCollapsedTitle = false;
  static const double _titleRevealOffset = 96;
  static const double _appBarToolbarHeight = 52;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final next = _scroll.offset >= _titleRevealOffset;
    if (next != _showCollapsedTitle) {
      setState(() => _showCollapsedTitle = next);
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = widget.parsed;
    final t = widget.t;
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final role = auth is AuthAuthenticated ? auth.user.wayoAdsRole : null;
    final isSuperadmin = role == WayoAdsAccountRole.superAdmin;
    final showBlackBottomBar =
        isSuperadmin || role == WayoAdsAccountRole.advertiser;

    String moneyStr(int cents) => MoneyFormatter.format(
          cents / 100.0,
          currency: kWayoPublicCurrency,
          locale: widget.moneyLocale,
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

    final metricsRecords = <
        (IconData, String, String, _MetricDot, bool)>[
      (
        Icons.payments_outlined,
        t.advertiser_campaigns.card.budget_total,
        moneyStr(parsed.totalCents),
        parsed.totalCents > 0 ? _MetricDot.green : _MetricDot.gray,
        parsed.totalCents > 0,
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

    final toolbarOnLightCollapsed =
        Theme.of(context).brightness == Brightness.light && _showCollapsedTitle;
    final toolbarFg = toolbarOnLightCollapsed
        ? CampaignDetailPremiumPalette.value(context)
        : Colors.white.withValues(alpha: 0.95);

    final metrics = <
        (IconData, String, String, _MetricDot, bool)>[
      metricsRecords[0],
      metricsRecords[1],
      metricsRecords[2],
      metricsRecords[3],
      metricsRecords[4],
      metricsRecords[5],
      metricsRecords[6],
    ];

    return RefreshIndicator.adaptive(
      color: CampaignDetailPremiumPalette.amber,
      backgroundColor: CampaignDetailPremiumPalette.surface1(context),
      onRefresh: () async {
        HapticFeedback.lightImpact();
        ref.invalidate(advertiserCampaignDetailProvider(widget.id));
        if (!isSuperadmin) {
          ref.invalidate(campaignApplicationsProvider(widget.id));
        }
        await ref.read(advertiserCampaignDetailProvider(widget.id).future);
      },
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            toolbarHeight: _appBarToolbarHeight,
            backgroundColor: CampaignDetailPremiumPalette.bg(context),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
              icon: Icon(
                Icons.arrow_back_rounded,
                color: toolbarFg,
              ),
            ),
            titleSpacing: _showCollapsedTitle ? 0 : 8,
            title: AnimatedOpacity(
              opacity: _showCollapsedTitle ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_showCollapsedTitle,
                child: Text(
                  parsed.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: toolbarFg,
                  ),
                ),
              ),
            ),
            expandedHeight: 252,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [
                StretchMode.zoomBackground,
              ],
              background: DecoratedBox(
                decoration: BoxDecoration(gradient: CampaignDetailPremiumPalette.accentGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      _appBarToolbarHeight + 4,
                      20,
                      18,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedOpacity(
                            opacity: _showCollapsedTitle ? 0 : 1,
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              parsed.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sora(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    offset: const Offset(0, 2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _HeroCampaignStatusPulse(status: parsed.status, t: t),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HeroMetaChip(label: parsed.campaignKindLabel),
                              _HeroMetaChip(label: parsed.platformLabel),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: CampaignDetailPremiumPalette.kScreenPadding.copyWith(bottom: 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                const SizedBox(height: 10),
                _FrostedInfoCard(parsed: parsed, t: t),
                SizedBox(height: CampaignDetailPremiumPalette.kSectionGap),
                _DescriptionPremiumBlock(text: parsed.desc, t: t),
                SizedBox(height: CampaignDetailPremiumPalette.kSectionGap),
                _PerformanceTitle(t: t),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          SliverPadding(
            padding: CampaignDetailPremiumPalette.kScreenPadding,
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: metrics.length,
                (context, index) {
                  final m = metrics[index];
                  return _PremiumMetricTile(
                    icon: m.$1,
                    label: m.$2,
                    value: m.$3,
                    dot: m.$4,
                    leftAccent: m.$5,
                  )
                      .animate(delay: Duration(milliseconds: 60 * index))
                      .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
                      .slideY(
                          begin: 0.15, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            ),
          ),
          if (!isSuperadmin)
            SliverPadding(
              padding: CampaignDetailPremiumPalette.kScreenPadding
                  .copyWith(top: 12, bottom: 40),
              sliver: SliverToBoxAdapter(
                child: CampaignApplicationsSection(
                  campaignId: widget.id,
                  premiumChrome: true,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
                    .slideY(begin: 0.06, curve: Curves.easeOutCubic),
              ),
            ),
          if (showBlackBottomBar)
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
        ],
      ),
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  const _HeroMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeroCampaignStatusPulse extends StatelessWidget {
  const _HeroCampaignStatusPulse({
    required this.status,
    required this.t,
  });

  final CampaignStatus status;
  final Translations t;

  String _label() => switch (status) {
        CampaignStatus.active => t.advertiser_campaigns.status.active,
        CampaignStatus.paused => t.advertiser_campaigns.status.paused,
        CampaignStatus.completed => t.advertiser_campaigns.status.completed,
        CampaignStatus.draft => t.advertiser_campaigns.status.draft,
        CampaignStatus.unknown => t.advertiser_campaigns.status.other,
      };

  bool get _active => status == CampaignStatus.active;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: _active
            ? [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: status == CampaignStatus.active ? const Color(0xFFBBF7D0) : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            _label(),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (!_active) return pill;
    return pill
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.04, duration: 1200.ms, curve: Curves.easeInOut);
  }
}

class _FrostedInfoCard extends StatelessWidget {
  const _FrostedInfoCard({
    required this.parsed,
    required this.t,
  });

  final _ParsedCampaignDetail parsed;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        Icons.public_outlined,
        t.advertiser_campaigns.detail.platform_label,
        parsed.platformLabel,
      ),
      (
        Icons.category_outlined,
        t.advertiser_campaigns.detail.niche_label,
        parsed.nicheLabel,
      ),
      (
        Icons.place_outlined,
        t.advertiser_campaigns.detail.location_label,
        parsed.locationLabel,
      ),
      (
        Icons.flag_outlined,
        t.advertiser_campaigns.detail.objective_label,
        parsed.objectiveLabel,
      ),
      (
        Icons.interests_outlined,
        t.advertiser_campaigns.detail.campaign_type_label,
        parsed.campaignKindLabel,
      ),
    ];

    Widget buildBody(BoxConstraints constraints) {
      final twoCol = constraints.maxWidth >= 400;
      if (!twoCol) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: CampaignDetailPremiumPalette.rowSeparator(context),
                ),
              Padding(
                padding: EdgeInsets.only(top: i > 0 ? 10 : 0, bottom: 10),
                child: _MiniInfoTile(icon: rows[i].$1, label: rows[i].$2, value: rows[i].$3),
              ),
            ],
          ],
        );
      }

      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _MiniInfoTile(icon: rows[0].$1, label: rows[0].$2, value: rows[0].$3)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 1,
                  height: 44,
                  child: ColoredBox(color: CampaignDetailPremiumPalette.rowSeparator(context)),
                ),
              ),
              Expanded(child: _MiniInfoTile(icon: rows[1].$1, label: rows[1].$2, value: rows[1].$3)),
            ],
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: CampaignDetailPremiumPalette.rowSeparator(context),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _MiniInfoTile(icon: rows[2].$1, label: rows[2].$2, value: rows[2].$3)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 1,
                  height: 44,
                  child: ColoredBox(color: CampaignDetailPremiumPalette.rowSeparator(context)),
                ),
              ),
              Expanded(child: _MiniInfoTile(icon: rows[3].$1, label: rows[3].$2, value: rows[3].$3)),
            ],
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: CampaignDetailPremiumPalette.rowSeparator(context),
          ),
          const SizedBox(height: 10),
          _MiniInfoTile(icon: rows[4].$1, label: rows[4].$2, value: rows[4].$3),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: CampaignDetailPremiumPalette.surfaceGlass(context)
                .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.8 : 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CampaignDetailPremiumPalette.divider(context).withValues(alpha: 0.75),
            ),
            boxShadow: CampaignDetailPremiumPalette.cardShadow(context, 0.15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: LayoutBuilder(builder: (context, c) => buildBody(c)),
          ),
        ),
      ),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  const _MiniInfoTile({
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: CampaignDetailPremiumPalette.amber.withValues(alpha: 0.92)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CampaignDetailPremiumPalette.infoLabel(context),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: CampaignDetailPremiumPalette.infoValue(context),
        ),
      ],
    );
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
                          Icon(
                            icon,
                            size: 19,
                            color: CampaignDetailPremiumPalette.amber.withValues(alpha: 0.95),
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

