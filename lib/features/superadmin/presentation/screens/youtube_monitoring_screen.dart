import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/admin_api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// YouTube post monitoring — `GET|POST /api/admin/jobs/check-post-views`.
class YoutubeMonitoringScreen extends ConsumerStatefulWidget {
  const YoutubeMonitoringScreen({super.key});

  @override
  ConsumerState<YoutubeMonitoringScreen> createState() =>
      _YoutubeMonitoringScreenState();
}

class _YoutubeMonitoringScreenState
    extends ConsumerState<YoutubeMonitoringScreen> {
  var _running = false;
  String? _lastRun;

  Future<void> _runCheck() async {
    setState(() {
      _running = true;
      _lastRun = null;
    });
    try {
      final remote = ref.read(superadminOpsRemoteProvider);
      final result = await remote.runJob(AdminApiEndpoints.youtubeCheckPostViews);
      if (!mounted) return;
      setState(() => _lastRun = result.summary);
      ref.invalidate(youtubeMonitoringProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.ok ? result.summary : 'Failed: ${result.summary}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(youtubeMonitoringProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('YouTube monitoring'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(youtubeMonitoringProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SuperadminChromeActions(trailingPadding: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _running ? null : _runCheck,
        icon: _running
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(_running ? 'Running…' : 'Check views'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(youtubeMonitoringProvider);
          await ref.read(youtubeMonitoringProvider.future);
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
          data: (s) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              if (_lastRun != null) ...[
                Text(
                  'Last run: $_lastRun',
                  style: TextStyle(color: AppColors.textMutedOf(context)),
                ),
                const SizedBox(height: 12),
              ],
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [
                  AdminStatCard(
                    title: 'Total posts',
                    value: '${s.totalPosts}',
                    icon: Icons.smart_display_rounded,
                  ),
                  AdminStatCard(
                    title: 'Active',
                    value: '${s.countFor('ACTIVE')}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  AdminStatCard(
                    title: 'Flagged',
                    value: '${s.countFor('FLAGGED')}',
                    icon: Icons.flag_rounded,
                  ),
                  AdminStatCard(
                    title: 'API quota',
                    value: '${s.quotaPercentUsed.toStringAsFixed(0)}%',
                    subtitle: '${s.quotaUsed}/${s.quotaLimit}',
                    icon: Icons.speed_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'By status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              for (final e in s.postsByStatus.entries) ...[
                ListTile(
                  title: Text(e.key),
                  trailing: Text(
                    '${e.value}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
              Text(
                'Snapshots (24h): ${s.recentSnapshotCount}',
                style: TextStyle(color: AppColors.textMutedOf(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
