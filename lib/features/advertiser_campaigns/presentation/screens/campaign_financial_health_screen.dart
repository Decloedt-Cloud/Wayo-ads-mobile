import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/campaign_financial_summary.dart';

final campaignFinancialSummaryProvider = FutureProvider.autoDispose
    .family<CampaignFinancialSummary, String>((ref, campaignId) async {
      final repo = ref.watch(advertiserCampaignsRepositoryProvider);
      try {
        final json = await repo.loadCampaignFinancialSummary(campaignId);
        return CampaignFinancialSummary.fromJson(json);
      } catch (e) {
        throw AdvertiserCampaignsRepository.mapError(e);
      }
    });

/// Budget pacing / financial health — server cents are authoritative.
class CampaignFinancialHealthScreen extends ConsumerWidget {
  const CampaignFinancialHealthScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.advertiser_campaigns.insights;
    final retry = context.t.dashboard.errors.retry;
    final locale = wayoPublicMoneyLocale(LocaleSettings.currentLocale);
    final async = ref.watch(campaignFinancialSummaryProvider(campaignId));

    String money(int cents) => MoneyFormatter.format(
      cents / 100.0,
      currency: kWayoPublicCurrency,
      locale: locale,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(
          t.financial_title,
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
                onRetry: () => ref.invalidate(
                  campaignFinancialSummaryProvider(campaignId),
                ),
              ),
            ],
          );
        },
        data: (s) {
          final empty = s.totalBudget == 0 &&
              s.spentBillable == 0 &&
              s.dailySpend.isEmpty &&
              s.totalViews == 0;

          return RefreshIndicator.adaptive(
            onRefresh: () async {
              ref.invalidate(campaignFinancialSummaryProvider(campaignId));
              await ref.read(
                campaignFinancialSummaryProvider(campaignId).future,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  s.campaignTitle,
                  style: AppTextStyles.headlineMedium(context),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.campaign_status}: ${s.campaignStatus}',
                  style: AppTextStyles.caption(context),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.badge}: ${s.confidenceBadge} · ${t.score}: ${s.confidenceScore}',
                  style: AppTextStyles.caption(context),
                ),
                if (empty) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      t.empty,
                      style: AppTextStyles.bodyLarge(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                const SizedBox(height: 16),
                _row(t.total_budget, money(s.totalBudget)),
                _row(t.locked_budget, money(s.lockedBudget)),
                _row(t.spent_billable, money(s.spentBillable)),
                _row(t.remaining_budget, money(s.remainingBudget)),
                _row(t.reserved, money(s.reservedAmount)),
                _row(t.under_review, money(s.underReviewAmount)),
                _row(t.paid_creators, money(s.paidToCreators)),
                _row(t.pending_payouts, money(s.pendingPayouts)),
                const Divider(height: 28),
                _row(t.effective_cpm, money(s.effectiveCpm.round())),
                _row(
                  t.validation_rate,
                  '${(s.validationRate * 100).toStringAsFixed(1)}%',
                ),
                _row(
                  t.fraud_block_rate,
                  '${(s.fraudBlockRate * 100).toStringAsFixed(1)}%',
                ),
                const Divider(height: 28),
                _row(t.views, '${s.validatedViews} / ${s.totalViews}'),
                _row(t.clicks, '${s.validatedClicks} / ${s.totalClicks}'),
                _row(t.billable_views, '${s.billableViews}'),
                _row(t.billable_clicks, '${s.billableClicks}'),
                if (s.dailySpend.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(t.daily_spend, style: AppTextStyles.labelLarge(context)),
                  const SizedBox(height: 8),
                  ...s.dailySpend.map(
                    (d) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(d.date),
                      subtitle: Text('${d.views} views · ${d.clicks} clicks'),
                      trailing: Text(money(d.spend)),
                    ),
                  ),
                ],
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
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
