import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/rate_limiter.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../data/creator_dashboard_remote_datasource.dart';
import '../../data/creator_dashboard_repository.dart';
import '../../domain/creator_application.dart';
import '../../domain/creator_stats.dart';

/// 2 s rate limiter (matches the advertiser dashboard cadence).
final creatorRateLimiterProvider = Provider<RateLimiter>((ref) {
  ref.keepAlive();
  return RateLimiter(minInterval: const Duration(seconds: 2));
});

final creatorDashboardRemoteProvider =
    Provider<CreatorDashboardRemoteDatasource>((ref) {
      return CreatorDashboardRemoteDatasource(ref.watch(wayoAdsDioProvider));
    });

final creatorDashboardRepositoryProvider = Provider<CreatorDashboardRepository>(
  (ref) {
    ref.keepAlive();
    return CreatorDashboardRepository(
      remote: ref.watch(creatorDashboardRemoteProvider),
      deduplicator: ref.watch(requestDeduplicatorProvider),
      rateLimiter: ref.watch(creatorRateLimiterProvider),
    );
  },
);

/// Creator KPIs (`GET /api/creator/stats`).
final creatorStatsProvider = FutureProvider<CreatorStats>((ref) async {
  ref.keepAlive();
  return ref.watch(creatorDashboardRepositoryProvider).fetchStats();
});

/// Creator applications (`GET /api/creator/applications`).
final creatorApplicationsProvider = FutureProvider<List<CreatorApplication>>((
  ref,
) async {
  ref.keepAlive();
  return ref.watch(creatorDashboardRepositoryProvider).fetchApplications();
});

/// Number of applications still waiting for approval — drives the red dot
/// on the Campaigns tab for the creator.
final creatorPendingApplicationsCountProvider = Provider<int>((ref) {
  final list =
      ref.watch(creatorApplicationsProvider).valueOrNull ??
      const <CreatorApplication>[];
  return list.where((a) => a.status == CreatorApplicationStatus.pending).length;
});
