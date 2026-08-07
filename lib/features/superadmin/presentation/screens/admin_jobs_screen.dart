import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/admin_api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../widgets/superadmin_chrome_actions.dart';

class _JobDef {
  const _JobDef({
    required this.title,
    required this.subtitle,
    required this.endpoint,
    this.query,
    this.body,
  });

  final String title;
  final String subtitle;
  final String endpoint;
  final Map<String, dynamic>? query;
  final Object? body;
}

const _jobs = <_JobDef>[
  _JobDef(
    title: 'Check YouTube views',
    subtitle: 'Snapshot view counts and flag anomalies',
    endpoint: AdminApiEndpoints.youtubeCheckPostViews,
  ),
  _JobDef(
    title: 'Refresh YouTube status',
    subtitle: 'Sync privacy / availability for pending posts',
    endpoint: AdminApiEndpoints.youtubeRefreshStatus,
  ),
  _JobDef(
    title: 'Aggregate creator metrics',
    subtitle: 'Rebuild traffic metrics for today',
    endpoint: AdminApiEndpoints.jobAggregateMetrics,
    body: <String, dynamic>{},
  ),
  _JobDef(
    title: 'Compute trust scores',
    subtitle: 'Batch recompute creator trust scores',
    endpoint: AdminApiEndpoints.jobTrustScores,
  ),
  _JobDef(
    title: 'Campaign financials',
    subtitle: 'Recompute financials for all active campaigns',
    endpoint: AdminApiEndpoints.jobCampaignFinancials,
    body: <String, dynamic>{},
  ),
  _JobDef(
    title: 'Release payouts',
    subtitle: 'Release eligible payout queue items',
    endpoint: AdminApiEndpoints.jobReleasePayouts,
    query: {'action': 'release'},
  ),
  _JobDef(
    title: 'Release reserves',
    subtitle: 'Release expired reserve holds',
    endpoint: AdminApiEndpoints.jobReleasePayouts,
    query: {'action': 'release-reserves'},
  ),
  _JobDef(
    title: 'Sync creator balances',
    subtitle: 'Rebuild withdrawable balances from ledger',
    endpoint: AdminApiEndpoints.jobReleasePayouts,
    query: {'action': 'sync-creator-balances'},
  ),
];

/// Manual admin jobs runner (Bearer-compatible).
class AdminJobsScreen extends ConsumerStatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  ConsumerState<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends ConsumerState<AdminJobsScreen> {
  final _busy = <String>{};
  final _last = <String, String>{};

  Future<void> _run(_JobDef job) async {
    setState(() => _busy.add(job.title));
    try {
      final remote = ref.read(superadminOpsRemoteProvider);
      final result = await remote.runJob(
        job.endpoint,
        query: job.query,
        body: job.body,
      );
      if (!mounted) return;
      setState(() => _last[job.title] = result.summary);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.ok ? result.summary : 'Failed: ${result.summary}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _last[job.title] = '$e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy.remove(job.title));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Admin jobs'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: const [SuperadminChromeActions(trailingPadding: 12)],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final job = _jobs[i];
          final busy = _busy.contains(job.title);
          final last = _last[job.title];
          return Material(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  if (last != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      last,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: busy ? null : () => _run(job),
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(busy ? 'Running…' : 'Run'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
