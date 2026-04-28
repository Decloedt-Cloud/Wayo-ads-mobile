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

  static const String _statsKey = 'creator_stats';
  static const String _applicationsKey = 'creator_applications';

  Future<CreatorStats> fetchStats({CreatorStats? fallback}) async {
    if (!_rate.canCall(_statsKey) && fallback != null) {
      return fallback;
    }
    _rate.mark(_statsKey);
    return _dedup.run<CreatorStats>(_statsKey, _remote.fetchStats);
  }

  Future<List<CreatorApplication>> fetchApplications({
    List<CreatorApplication>? fallback,
  }) async {
    if (!_rate.canCall(_applicationsKey) && fallback != null) {
      return fallback;
    }
    _rate.mark(_applicationsKey);
    return _dedup.run<List<CreatorApplication>>(
      _applicationsKey,
      _remote.fetchApplications,
    );
  }
}
