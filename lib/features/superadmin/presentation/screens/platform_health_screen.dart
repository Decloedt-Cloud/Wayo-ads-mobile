import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// Platform KPIs + dependency health — `GET /api/admin/health(+services)`.
class PlatformHealthScreen extends ConsumerWidget {
  const PlatformHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(platformHealthProvider);
    final servicesAsync = ref.watch(adminServicesHealthProvider);
    final money = NumberFormat.currency(symbol: '€', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Platform health'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(platformHealthProvider);
              ref.invalidate(adminServicesHealthProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SuperadminChromeActions(trailingPadding: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(platformHealthProvider);
          ref.invalidate(adminServicesHealthProvider);
          await Future.wait([
            ref.read(platformHealthProvider.future),
            ref.read(adminServicesHealthProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            healthAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Health error: $e'),
              data: (h) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: [
                      AdminStatCard(
                        title: 'Active campaigns',
                        value: '${h.activeCampaigns}',
                        icon: Icons.campaign_rounded,
                      ),
                      AdminStatCard(
                        title: 'Creators',
                        value: '${h.totalCreators}',
                        icon: Icons.people_alt_rounded,
                      ),
                      AdminStatCard(
                        title: 'Clicks 24h',
                        value: '${h.clicks24h}',
                        icon: Icons.ads_click_rounded,
                      ),
                      AdminStatCard(
                        title: 'Fraud rate',
                        value: '${h.fraudRatePct}%',
                        icon: Icons.shield_rounded,
                      ),
                      AdminStatCard(
                        title: 'Pending withdrawals',
                        value: '${h.pendingWithdrawals}',
                        icon: Icons.payments_rounded,
                      ),
                      AdminStatCard(
                        title: 'Platform fees',
                        value: money.format(h.platformFeePayoutCents / 100),
                        icon: Icons.account_balance_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Validated ${h.validatedClicks} · Rejected fraud ${h.rejectedFraud}',
                    style: TextStyle(
                      color: AppColors.textMutedOf(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Services error: $e'),
              data: (services) {
                if (services.isEmpty) {
                  return const Text('No service probes returned');
                }
                return Column(
                  children: [
                    for (final s in services) ...[
                      _ServiceTile(service: s),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});
  final AdminServiceStatus service;

  @override
  Widget build(BuildContext context) {
    final ok = service.isOk;
    final degraded = service.isDegraded;
    final color = ok
        ? const Color(0xFF22C55E)
        : degraded
            ? const Color(0xFFF59E0B)
            : AppColors.error;
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        leading: Icon(
          ok
              ? Icons.check_circle_rounded
              : degraded
                  ? Icons.warning_rounded
                  : Icons.error_rounded,
          color: color,
        ),
        title: Text(
          service.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            service.status,
            if (service.latencyMs != null) '${service.latencyMs} ms',
            if (service.message != null && service.message!.isNotEmpty)
              service.message,
          ].join(' · '),
        ),
      ),
    );
  }
}
