import '../../../../core/network/rate_limiter.dart';
import '../../../../core/network/request_deduplicator.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../../domain/entities/notification_item.dart';

/// Notifications list + mark-as-read (Wayo-ads API).
final class NotificationsRepository {
  NotificationsRepository({
    required DashboardRemote remote,
    required RequestDeduplicator deduplicator,
    required RateLimiter rateLimiter,
  })  : _remote = remote,
        _deduplicator = deduplicator,
        _rate = rateLimiter;

  final DashboardRemote _remote;
  final RequestDeduplicator _deduplicator;
  final RateLimiter _rate;

  Future<List<NotificationItem>> fetchNotifications({bool unreadOnly = false}) async {
    if (!_rate.canCall('notifications_list')) {
      return const [];
    }
    _rate.mark('notifications_list');
    return _deduplicator.run(
      'notifications_list',
      () => _remote.fetchNotifications(unreadOnly: unreadOnly),
    );
  }

  Future<void> markRead(String id) async {
    await _deduplicator.run(
      'notification_read_$id',
      () => _remote.markNotificationRead(id),
    );
  }
}
