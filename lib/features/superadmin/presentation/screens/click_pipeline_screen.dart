import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// Click billing pipeline (24h) — `GET /api/admin/click-pipeline`.
class ClickPipelineScreen extends ConsumerWidget {
  const ClickPipelineScreen({super.key});

  static const _order = [
    'PENDING',
    'PENDING_BUDGET',
    'VALIDATED',
    'PAID',
    'REJECTED_FRAUD',
    'REJECTED',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clickPipelineProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Click pipeline'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(clickPipelineProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SuperadminChromeActions(trailingPadding: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clickPipelineProvider);
          await ref.read(clickPipelineProvider.future);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$e', textAlign: TextAlign.center),
              ),
            ],
          ),
          data: (snap) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              AdminStatCard(
                title: 'Clicks (24h)',
                value: '${snap.totalClicks}',
                icon: Icons.ads_click_rounded,
                subtitle: snap.oldestPendingBudgetAgeMinutes == null
                    ? 'No pending budget backlog'
                    : 'Oldest PENDING_BUDGET: ${snap.oldestPendingBudgetAgeMinutes} min',
              ),
              const SizedBox(height: 16),
              Text(
                'Billing status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              for (final key in _orderedKeys(snap)) ...[
                _StatusRow(status: key, count: snap.countFor(key)),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<String> _orderedKeys(ClickPipelineSnapshot snap) {
    final keys = <String>[
      ..._order.where(snap.counts.containsKey),
      ...snap.counts.keys.where((k) => !_order.contains(k)),
    ];
    return keys;
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status, required this.count});
  final String status;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        title: Text(
          status,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        trailing: Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
    );
  }
}
