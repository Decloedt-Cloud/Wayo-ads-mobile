import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../data/creator_analytics_remote.dart';
import '../../domain/creator_analytics_snapshot.dart';
import '../../../creator_trust/presentation/widgets/creator_trust_score_card.dart';
import '../../../creator_trust/presentation/widgets/creator_trust_breakdown_panel.dart';

/// Creator performance analytics — server cents are authoritative.
class CreatorAnalyticsScreen extends ConsumerStatefulWidget {
  const CreatorAnalyticsScreen({super.key});

  @override
  ConsumerState<CreatorAnalyticsScreen> createState() =>
      _CreatorAnalyticsScreenState();
}

class _CreatorAnalyticsScreenState
    extends ConsumerState<CreatorAnalyticsScreen> {
  String _period = '30d';

  @override
  Widget build(BuildContext context) {
    final t = context.t.creator.analytics;
    final retry = context.t.dashboard.errors.retry;
    final locale = wayoPublicMoneyLocale(LocaleSettings.currentLocale);
    final async = ref.watch(creatorAnalyticsProvider(_period));

    String money(int cents) => MoneyFormatter.format(
      cents / 100.0,
      currency: kWayoPublicCurrency,
      locale: locale,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(t.title, style: AppTextStyles.headlineMedium(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: '7d', label: Text(t.period_7d)),
                ButtonSegment(value: '30d', label: Text(t.period_30d)),
                ButtonSegment(value: '90d', label: Text(t.period_90d)),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ErrorBanner(
                    message: t.load_error,
                    retryLabel: retry,
                    onRetry: () =>
                        ref.invalidate(creatorAnalyticsProvider(_period)),
                  ),
                ],
              ),
              data: (snap) {
                final hasDaily = snap.data.isNotEmpty;
                final hasBreakdown = snap.campaignBreakdown.isNotEmpty;
                final isEmpty = !hasDaily &&
                    !hasBreakdown &&
                    snap.summary.totalEarnings == 0 &&
                    snap.summary.totalValidatedViews == 0;

                return RefreshIndicator.adaptive(
                onRefresh: () async {
                  ref.invalidate(creatorAnalyticsProvider(_period));
                  await ref.read(creatorAnalyticsProvider(_period).future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      t.period_meta(
                        days: snap.days,
                        currency: snap.currency,
                      ),
                      style: AppTextStyles.caption(context),
                    ),
                    const SizedBox(height: 12),
                    _KpiGrid(
                      summary: snap.summary,
                      money: money,
                      earningsLabel: t.earnings,
                      pendingLabel: t.pending,
                      viewsLabel: t.validated_views,
                      clicksLabel: t.validated_clicks,
                      recordedViewsLabel: t.recorded_views,
                      recordedClicksLabel: t.recorded_clicks,
                      viewRateLabel: t.view_validation_rate,
                      clickRateLabel: t.click_validation_rate,
                    ),
                    const SizedBox(height: 16),
                    const CreatorTrustScoreCard(),
                    const SizedBox(height: 12),
                    const CreatorTrustBreakdownPanel(),
                    if (snap.campaigns.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        t.active_campaigns,
                        style: AppTextStyles.labelLarge(context),
                      ),
                      const SizedBox(height: 8),
                      ...snap.campaigns.map(
                        (c) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.title),
                          subtitle: Text('${c.type} · ${c.status}'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      t.daily_title,
                      style: AppTextStyles.labelLarge(context),
                    ),
                    const SizedBox(height: 8),
                    if (isEmpty)
                      _AnalyticsEmptyState(message: t.empty)
                    else if (!hasDaily)
                      Text(t.empty, style: AppTextStyles.bodyLarge(context))
                    else
                      ...snap.data.reversed
                          .take(14)
                          .map(
                            (d) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(d.date),
                              subtitle: Text(
                                '${d.validatedViews}/${d.recordedViews} views · '
                                '${d.validatedClicks}/${d.recordedClicks} clicks',
                              ),
                            ),
                          ),
                    if (snap.campaignBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        t.by_campaign,
                        style: AppTextStyles.labelLarge(context),
                      ),
                      const SizedBox(height: 8),
                      ...snap.campaignBreakdown.map(
                        (c) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.campaignName),
                          subtitle: Text(
                            '${c.campaignType} · ${c.validatedViews} views · '
                            '${c.validatedClicks} clicks',
                          ),
                          trailing: Text(money(c.earnings)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      t.server_authority_note,
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.summary,
    required this.money,
    required this.earningsLabel,
    required this.pendingLabel,
    required this.viewsLabel,
    required this.clicksLabel,
    required this.recordedViewsLabel,
    required this.recordedClicksLabel,
    required this.viewRateLabel,
    required this.clickRateLabel,
  });

  final CreatorAnalyticsSummary summary;
  final String Function(int cents) money;
  final String earningsLabel;
  final String pendingLabel;
  final String viewsLabel;
  final String clicksLabel;
  final String recordedViewsLabel;
  final String recordedClicksLabel;
  final String viewRateLabel;
  final String clickRateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Kpi(
                label: earningsLabel,
                value: money(summary.totalEarnings),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Kpi(
                label: pendingLabel,
                value: money(summary.pendingAmount),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Kpi(
                label: viewsLabel,
                value: '${summary.totalValidatedViews}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Kpi(
                label: clicksLabel,
                value: '${summary.totalValidatedClicks}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Kpi(
                label: recordedViewsLabel,
                value: '${summary.totalRecordedViews}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Kpi(
                label: recordedClicksLabel,
                value: '${summary.totalRecordedClicks}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Kpi(
                label: viewRateLabel,
                value: '${summary.viewValidationRate.toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Kpi(
                label: clickRateLabel,
                value: '${summary.clickValidationRate.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption(context)),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.headlineMedium(context)),
        ],
      ),
    );
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  const _AnalyticsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: 36,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: scheme.onSurfaceVariant,
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
