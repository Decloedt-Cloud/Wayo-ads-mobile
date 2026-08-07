import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/campaign_analytics_snapshot.dart';

final campaignAnalyticsProvider = FutureProvider.autoDispose
    .family<CampaignAnalyticsSnapshot, String>((ref, campaignId) async {
      final repo = ref.watch(advertiserCampaignsRepositoryProvider);
      try {
        final json = await repo.loadCampaignAnalytics(campaignId);
        return CampaignAnalyticsSnapshot.fromJson(json);
      } catch (e) {
        throw AdvertiserCampaignsRepository.mapError(e);
      }
    });

/// Visitor / traffic insights for an advertiser-owned campaign.
class CampaignAnalyticsScreen extends ConsumerWidget {
  const CampaignAnalyticsScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.advertiser_campaigns.insights;
    final retry = context.t.dashboard.errors.retry;
    final async = ref.watch(campaignAnalyticsProvider(campaignId));

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(
          t.analytics_title,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg = e is AuthException ? e.toString() : t.load_error;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ErrorBanner(
                message: msg,
                retryLabel: retry,
                onRetry: () =>
                    ref.invalidate(campaignAnalyticsProvider(campaignId)),
              ),
            ],
          );
        },
        data: (snap) {
          final empty = snap.trafficTotal == 0 && snap.submissionsTotal == 0;
          return RefreshIndicator.adaptive(
            onRefresh: () async {
              ref.invalidate(campaignAnalyticsProvider(campaignId));
              await ref.read(campaignAnalyticsProvider(campaignId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (snap.activeSince != null)
                  Text(
                    '${t.active_since}: ${snap.activeSince!.toLocal()}',
                    style: AppTextStyles.caption(context),
                  ),
                Text(
                  '${t.campaign_type}: ${snap.campaignType}',
                  style: AppTextStyles.caption(context),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        label: t.traffic_total,
                        value: '${snap.trafficTotal}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _KpiCard(
                        label: t.submissions_total,
                        value: '${snap.submissionsTotal}',
                      ),
                    ),
                  ],
                ),
                if (empty) ...[
                  const SizedBox(height: 24),
                  Text(
                    t.analytics_empty,
                    style: AppTextStyles.bodyLarge(context),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Text(
                    t.daily_traffic,
                    style: AppTextStyles.labelLarge(context),
                  ),
                  const SizedBox(height: 8),
                  ...snap.dailyTraffic.reversed
                      .take(14)
                      .map(
                        (p) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.dayKey),
                          trailing: Text('${p.value}'),
                        ),
                      ),
                  const SizedBox(height: 12),
                  Text(
                    t.daily_submissions,
                    style: AppTextStyles.labelLarge(context),
                  ),
                  const SizedBox(height: 8),
                  ...snap.dailySubmissions.reversed
                      .take(14)
                      .map(
                        (p) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.dayKey),
                          trailing: Text('${p.value}'),
                        ),
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption(context)),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.headlineMedium(context)),
          ],
        ),
      ),
    );
  }
}
