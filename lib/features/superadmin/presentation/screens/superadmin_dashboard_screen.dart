import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_transaction.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../providers/superadmin_providers.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/superadmin_chrome_actions.dart';

class SuperadminDashboardScreen extends ConsumerStatefulWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  ConsumerState<SuperadminDashboardScreen> createState() =>
      _SuperadminDashboardScreenState();
}

class _SuperadminDashboardScreenState
    extends ConsumerState<SuperadminDashboardScreen> {
  static final _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _numberFormat = NumberFormat.compact();
  static final _dateFormat = DateFormat.yMMMd().add_jm();

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardStatsProvider);
    final trafficAsync = ref.watch(trafficQualitySummaryProvider);
    final txPageAsync = ref.watch(adminRecentTransactionsProvider);

    ref.listen(chatPostLoginGateProvider, (previous, gateAt) {
      if (gateAt == null) return;
      scheduleSessionRetryAfterBootstrap(ref, () {
        if (!mounted) return;
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(trafficQualitySummaryProvider);
        ref.invalidate(adminRecentTransactionsProvider);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildHeader(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _buildBusinessKpis(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              sliver: SliverToBoxAdapter(
                child: trafficAsync.when(
                  data: (tq) => _buildTrafficQualitySection(context, tq),
                  loading: () => const _StatsLoadingGrid(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              sliver: SliverToBoxAdapter(
                child: dashboardAsync.when(
                  data: (stats) => _buildTransactionStats(context, stats),
                  loading: () => const _StatsLoadingGrid(),
                  error: (e, _) {
                    if (shouldSuppressSessionLoadError(ref, e)) {
                      return const _StatsLoadingGrid();
                    }
                    return _ErrorCard(
                      message: 'Could not load transactions',
                      onRetry: () => ref.invalidate(dashboardStatsProvider),
                    );
                  },
                ),
              ),
            ),
            ..._topCampaignSlivers(dashboardAsync, _currencyFormat),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              sliver: SliverToBoxAdapter(
                child: txPageAsync.when(
                  data: (page) => _buildRecentTransactions(context, page),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(trafficQualitySummaryProvider);
    ref.invalidate(adminRecentTransactionsProvider);
    ref.invalidate(platformHealthProvider);
    ref.invalidate(advertiserDepositsProvider);
    ref.invalidate(notificationsListProvider);
    ref.invalidate(notificationsUnreadCountsProvider);
  }

  Widget _buildBusinessKpis(BuildContext context) {
    final healthAsync = ref.watch(platformHealthProvider);
    final depositsAsync = ref.watch(
      advertiserDepositsProvider((search: '', page: 1)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminSectionHeader(
          title: 'Platform overview',
          subtitle: 'Fees, payouts, fraud, campaigns, and deposits',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        healthAsync.when(
          data: (h) {
            final money = _currencyFormat;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AdminStatCard(
                        title: 'Total platform fees',
                        value: money.format(h.platformFeeTotalCents / 100),
                        subtitle:
                            'Payouts ${money.format(h.platformFeePayoutCents / 100)} · '
                            'Campaign activation ${money.format(h.platformFeeActivationCents / 100)}',
                        icon: Icons.monetization_on_outlined,
                        iconColor: const Color(0xFF84CC16),
                        onTap: () => context.push('/superadmin/ledger'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminStatCard(
                        title: 'Pending withdrawals',
                        value: '${h.pendingWithdrawals}',
                        subtitle: 'Requires processing',
                        icon: Icons.schedule_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        onTap: () => context.go('/superadmin?tab=withdrawals'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AdminStatCard(
                        title: 'Fraud rate',
                        value: '${h.fraudRatePct}%',
                        subtitle: '${h.rejectedFraud} rejected today',
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminStatCard(
                        title: 'Active campaigns',
                        value: '${h.activeCampaigns}',
                        subtitle: '${h.totalCreators} creators',
                        icon: Icons.campaign_rounded,
                        iconColor: const Color(0xFFF47A1F),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const _StatsLoadingGrid(),
          error: (e, _) {
            if (shouldSuppressSessionLoadError(ref, e)) {
              return const _StatsLoadingGrid();
            }
            return _ErrorCard(
              message: 'Could not load platform health',
              onRetry: () => ref.invalidate(platformHealthProvider),
            );
          },
        ),
        const SizedBox(height: 12),
        depositsAsync.when(
          data: (page) {
            final summary = page.preferredPlatformSummary;
            final charged = summary?.totalChargedCents ?? 0;
            final net = summary?.totalNetCents ?? 0;
            final count = summary?.depositCount ?? 0;
            final money = _currencyFormat;
            return Row(
              children: [
                Expanded(
                  child: AdminStatCard(
                    title: 'Total charged deposits',
                    value: money.format(charged / 100),
                    subtitle: '$count deposits',
                    icon: Icons.credit_card_rounded,
                    iconColor: const Color(0xFF10B981),
                    onTap: () => context.push('/superadmin/payment-audits'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminStatCard(
                    title: 'Total net deposits',
                    value: money.format(net / 100),
                    subtitle:
                        'Charged minus all Stripe fees (card + Radar/other)',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF14B8A6),
                    onTap: () => context.push('/superadmin/payment-audits'),
                  ),
                ),
              ],
            );
          },
          loading: () => const _StatsLoadingGrid(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.paddingOf(context).top;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
              AppColors.primarySoft.withValues(alpha: isDark ? 0.04 : 0.02),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Superadmin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOf(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Platform overview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Messages',
              onPressed: () => context.go('/superadmin?tab=chat'),
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SuperadminChromeActions(showNotifications: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficQualitySection(
    BuildContext context,
    TrafficQualitySummary tq,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          title: 'Traffic Quality Monitoring',
          subtitle: 'Creator traffic anomaly detection and risk assessment',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ColoredMetricCard(
                label: 'Flagged Creators',
                value: '${tq.flaggedCreators}',
                subtitle: 'of ${tq.totalCreators} total',
                color: const Color(0xFFF59E0B),
                icon: Icons.shield_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ColoredMetricCard(
                label: 'Avg Validation',
                value: '${tq.avgValidationRatePercent}%',
                subtitle: 'across all creators',
                color: const Color(0xFF2563EB),
                icon: Icons.people_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ColoredMetricCard(
                label: 'High Risk Score',
                value: '${tq.maxAnomalyScore}',
                subtitle: 'max anomaly score',
                color: const Color(0xFF16A34A),
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ColoredMetricCard(
                label: 'Avg Fraud Score',
                value: '${tq.avgFraudScore}',
                subtitle: 'lower is better',
                color: const Color(0xFF8B5CF6),
                icon: Icons.analytics_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionStats(BuildContext context, DashboardStats stats) {
    final viewStats = _reasonSummary(stats, const ['VIEW']);
    final conversionStats = _reasonSummary(stats, const ['CONVERSION']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'Transaction Summary',
          subtitle: 'Views, conversions, and revenue breakdown',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                title: 'Total Payouts',
                value: _currencyFormat.format(stats.totalAmountUsd),
                subtitle:
                    '${_numberFormat.format(stats.totalTransactions)} transactions',
                icon: Icons.receipt_rounded,
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatCard(
                title: 'View Payouts',
                value: _currencyFormat.format(viewStats?.totalUsd ?? 0),
                subtitle: '${viewStats?.count ?? 0} views',
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF14B8A6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                title: 'Conversions',
                value: _currencyFormat.format(conversionStats?.totalUsd ?? 0),
                subtitle: '${conversionStats?.count ?? 0} conversions',
                icon: Icons.sync_alt_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatCard(
                title: 'Active Campaigns',
                value: '${stats.topCampaigns.length}',
                subtitle: 'campaigns with payouts',
                icon: Icons.campaign_outlined,
                iconColor: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    AdminTransactionsPage page,
  ) {
    if (page.transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          title: 'Recent Transactions',
          subtitle: 'Latest platform payout events',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        ...page.transactions.map((tx) => _TransactionRow(
              tx: tx,
              dateFormat: _dateFormat,
              currencyFormat: _currencyFormat,
            )),
      ],
    );
  }
}

class _ColoredMetricCard extends StatelessWidget {
  const _ColoredMetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.tx,
    required this.dateFormat,
    required this.currencyFormat,
  });

  final AdminTransaction tx;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isView = tx.reason.toUpperCase() == 'VIEW';
    final badgeColor = isView ? const Color(0xFF2563EB) : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx.reason.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                currencyFormat.format(tx.amountUsd),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tx.campaignTitle?.isNotEmpty == true)
            Text(
              tx.campaignTitle!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(tx.createdAt.toLocal()),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMutedOf(context),
            ),
          ),
          if (tx.creatorName?.isNotEmpty == true ||
              tx.advertiserName?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (tx.advertiserName?.isNotEmpty == true)
                  'Adv: ${tx.advertiserName}',
                if (tx.creatorName?.isNotEmpty == true)
                  'Creator: ${tx.creatorName}',
              ].join(' · '),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryOf(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _TopCampaignCard extends StatelessWidget {
  const _TopCampaignCard({
    required this.rank,
    required this.title,
    required this.amount,
    required this.count,
  });

  final int rank;
  final String title;
  final String amount;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: rank <= 3
                  ? LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primarySoft.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
              color: rank <= 3
                  ? null
                  : AppColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? AppColors.primary : AppColors.textMutedOf(context),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count transactions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsLoadingGrid extends StatelessWidget {
  const _StatsLoadingGrid();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = isDark
        ? AppColors.surfaceElevated.withValues(alpha: 0.3)
        : Colors.grey.shade100;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _shimmerCard(shimmer)),
            const SizedBox(width: 12),
            Expanded(child: _shimmerCard(shimmer)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _shimmerCard(shimmer)),
            const SizedBox(width: 12),
            Expanded(child: _shimmerCard(shimmer)),
          ],
        ),
      ],
    );
  }

  Widget _shimmerCard(Color color) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ReasonSummary? _reasonSummary(DashboardStats stats, List<String> keys) {
  for (final k in keys) {
    final r = stats.byReason[k];
    if (r != null) return r;
  }
  for (final entry in stats.byReason.entries) {
    final uk = entry.key.toUpperCase();
    for (final k in keys) {
      if (uk.contains(k.toUpperCase())) return entry.value;
    }
  }
  return null;
}

List<Widget> _topCampaignSlivers(
  AsyncValue<DashboardStats> dashboardAsync,
  NumberFormat currencyFormat,
) {
  final stats = dashboardAsync.valueOrNull;
  if (stats == null || stats.topCampaigns.isEmpty) {
    return const <Widget>[];
  }
  final list = stats.topCampaigns.take(10).toList(growable: false);
  return <Widget>[
    SliverToBoxAdapter(
      child: AdminSectionHeader(
        title: 'Top Campaigns',
        subtitle: 'Highest performing campaigns by revenue',
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final campaign = list[index];
            return _TopCampaignCard(
              rank: index + 1,
              title: campaign.title.isEmpty ? campaign.campaignId : campaign.title,
              amount: currencyFormat.format(campaign.totalUsd),
              count: campaign.count,
            );
          },
          childCount: list.length,
        ),
      ),
    ),
  ];
}
