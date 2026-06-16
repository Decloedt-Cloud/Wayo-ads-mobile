import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../providers/superadmin_providers.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/superadmin_chrome_actions.dart';

class SuperadminDashboardScreen extends ConsumerWidget {
  const SuperadminDashboardScreen({super.key});

  static final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _numberFormat = NumberFormat.compact();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardStatsProvider);
    final payoutAsync = ref.watch(payoutStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(payoutStatsProvider);
          ref.invalidate(notificationsListProvider);
          ref.invalidate(notificationsUnreadCountsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildHeader(context, ref),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _buildQuickActions(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: payoutAsync.when(
                  data: (stats) => _buildPayoutStats(context, stats),
                  loading: () => const _StatsLoadingGrid(),
                  error: (e, _) => _ErrorCard(
                    message: 'Erreur stats payouts: $e',
                    onRetry: () => ref.invalidate(payoutStatsProvider),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: dashboardAsync.when(
                  data: (stats) => _buildTransactionStats(context, stats),
                  loading: () => const _StatsLoadingGrid(),
                  error: (e, _) => _ErrorCard(
                    message: 'Erreur transactions: $e',
                    onRetry: () => ref.invalidate(dashboardStatsProvider),
                  ),
                ),
              ),
            ),
            ..._topCampaignSlivers(dashboardAsync, _currencyFormat),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.paddingOf(context).top;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        'Platform overview & management',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SuperadminChromeActions(showNotifications: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('Withdrawals', Icons.account_balance_wallet_rounded, '/superadmin/withdrawals'),
      ('Banned Users', Icons.block_rounded, '/superadmin/banned-users'),
      ('Announcements', Icons.campaign_rounded, '/superadmin/announcements'),
      ('AI Usage', Icons.auto_awesome_rounded, '/superadmin/ai-usage'),
      ('Ledger', Icons.receipt_long_rounded, '/superadmin/ledger'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMutedOf(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (label, icon, route) = actions[index];
              return _QuickActionButton(
                label: label,
                icon: icon,
                onTap: () => context.push(route),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutStats(BuildContext context, PayoutStats stats) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'Payout Statistics',
          subtitle: 'Overview of all platform payouts',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                title: 'Pending',
                value: _numberFormat.format(stats.totalPending),
                icon: Icons.hourglass_bottom_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatCard(
                title: 'Frozen',
                value: _numberFormat.format(stats.totalFrozen),
                icon: Icons.ac_unit_rounded,
                iconColor: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                title: 'Released',
                value: _numberFormat.format(stats.totalReleased),
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatCard(
                title: 'Eligible Now',
                value: _numberFormat.format(stats.eligibleNow),
                icon: Icons.schedule_rounded,
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionStats(BuildContext context, DashboardStats stats) {
    final viewPayout = _reasonSummary(stats, const [
      'VIEW_PAYOUT',
      'VIEW',
    ]);
    final conversion = _reasonSummary(stats, const [
      'CONVERSION_PAYOUT',
      'CONVERSION_FEE',
      'CONVERSION',
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'Transaction Summary',
          subtitle: 'Views, conversions, and revenue breakdown',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        AdminStatCard(
          title: 'Total Transactions',
          value: _currencyFormat.format(stats.totalAmountUsd),
          subtitle: '${_numberFormat.format(stats.totalTransactions)} transactions',
          icon: Icons.receipt_rounded,
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                title: 'View Payouts',
                value: _currencyFormat.format(viewPayout?.totalUsd ?? 0),
                subtitle: '${viewPayout?.count ?? 0} payouts',
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF14B8A6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatCard(
                title: 'Conversions',
                value: _currencyFormat.format(conversion?.totalUsd ?? 0),
                subtitle: '${conversion?.count ?? 0} conversions',
                icon: Icons.sync_alt_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                AppColors.primarySoft.withValues(alpha: isDark ? 0.05 : 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
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
  final list = stats.topCampaigns.take(5).toList(growable: false);
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
