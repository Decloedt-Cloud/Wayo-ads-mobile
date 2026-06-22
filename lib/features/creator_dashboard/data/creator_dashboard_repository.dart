import '../../../core/network/rate_limiter.dart';
import '../../../core/network/request_deduplicator.dart';
import '../domain/creator_application.dart';
import '../domain/creator_stats.dart';
import 'creator_dashboard_remote_datasource.dart';

/// Repository for the creator dashboard — deduplicated + rate-limited.
///
/// Keeps the same conventions as [DashboardRepositoryImpl] so foreground
/// polling never spams the backend.
class CreatorDashboardRepository {
  CreatorDashboardRepository({
    required CreatorDashboardRemoteDatasource remote,
    required RequestDeduplicator deduplicator,
    required RateLimiter rateLimiter,
  }) : _remote = remote,
       _dedup = deduplicator,
       _rate = rateLimiter;

  final CreatorDashboardRemoteDatasource _remote;
  final RequestDeduplicator _dedup;
  final RateLimiter _rate;

  static String _statsKeyFor(int sessionUserId) => 'creator_stats_$sessionUserId';
  static String _applicationsKeyFor(int sessionUserId) =>
      'creator_applications_$sessionUserId';

  Future<CreatorStats> fetchStats({
    required int sessionUserId,
    CreatorStats? fallback,
  }) async {
    final key = _statsKeyFor(sessionUserId);
    if (!_rate.canCall(key) && fallback != null) {
      return fallback;
    }
    _rate.mark(key);
    return _dedup.run<CreatorStats>(key, _remote.fetchStats);
  }

  Future<List<CreatorApplication>> fetchApplications({
    required int sessionUserId,
    List<CreatorApplication>? fallback,
  }) async {
    final key = _applicationsKeyFor(sessionUserId);
    if (!_rate.canCall(key) && fallback != null) {
      return fallback;
    }
    _rate.mark(key);
    return _dedup.run<List<CreatorApplication>>(
      key,
      _remote.fetchApplications,
    );
  }
}
