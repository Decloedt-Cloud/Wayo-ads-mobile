import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_scaffold.dart';

/// Top creators by traffic velocity — `GET /api/admin/creator-velocity`.
class CreatorVelocityScreen extends ConsumerStatefulWidget {
  const CreatorVelocityScreen({super.key});

  @override
  ConsumerState<CreatorVelocityScreen> createState() =>
      _CreatorVelocityScreenState();
}

class _CreatorVelocityScreenState extends ConsumerState<CreatorVelocityScreen> {
  var _period = '7d';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(creatorVelocityProvider(_period));

    return SuperadminScaffold(
      title: 'Creator velocity',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '24h', label: Text('24h')),
                ButtonSegment(value: '7d', label: Text('7d')),
                ButtonSegment(value: '30d', label: Text('30d')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$e', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(creatorVelocityProvider(_period)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (snap) {
                if (snap.topCreators.isEmpty) {
                  return const Center(child: Text('No velocity data'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(creatorVelocityProvider(_period));
                    await ref.read(creatorVelocityProvider(_period).future);
                  },
                  child: ListView.separated(
                    padding: superadminPagePadding(context),
                    itemCount: snap.topCreators.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _VelocityCard(row: snap.topCreators[i]),
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

class _VelocityCard extends StatelessWidget {
  const _VelocityCard({required this.row});
  final CreatorVelocityRow row;

  @override
  Widget build(BuildContext context) {
    final change = row.velocityChangePercent;
    final up = change >= 0;
    final riskColor = switch (row.riskLevel.toUpperCase()) {
      'HIGH' => AppColors.error,
      'MEDIUM' => const Color(0xFFF59E0B),
      _ => const Color(0xFF22C55E),
    };

    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.creatorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trust ${row.trustScore ?? '—'} · ${row.riskLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 18,
                      color: up ? const Color(0xFF22C55E) : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: up ? const Color(0xFF22C55E) : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    row.riskLevel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: riskColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
