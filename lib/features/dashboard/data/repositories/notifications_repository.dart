import '../../../../core/network/rate_limiter.dart';
import '../../../../core/network/request_deduplicator.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notifications_page_result.dart';

/// Notifications list + mark-as-read (Wayo-ads API).
final class NotificationsRepository {
  NotificationsRepository({
    required DashboardRemote remote,
    required RequestDeduplicator deduplicator,
    required RateLimiter rateLimiter,
  }) : _remote = remote,
       _deduplicator = deduplicator,
       _rate = rateLimiter;

  final DashboardRemote _remote;
  final RequestDeduplicator _deduplicator;
  final RateLimiter _rate;

  /// Always hits the network when called (or joins an in-flight request via [RequestDeduplicator]).
  ///
  /// We **do not** throttle with an empty return: Reverb can invalidate several times
  /// in a row; returning `[]` would clear the UI and look like "realtime is broken".
  Future<List<NotificationItem>> fetchNotifications({
    bool unreadOnly = false,
  }) async {
    if (_rate.canCall('notifications_list')) {
      _rate.mark('notifications_list');
    }
    return _deduplicator.run(
      'notifications_list',
      () => _remote.fetchNotifications(unreadOnly: unreadOnly),
    );
  }

  Future<void> markRead(String id, {String? conversationId}) async {
    await _deduplicator.run(
      'notification_read_$id',
      () => _remote.markNotificationRead(id, conversationId: conversationId),
    );
  }

  Future<void> markAllRead() async {
    await _deduplicator.run(
      'notifications_mark_all',
      () => _remote.markAllNotificationsRead(),
    );
  }

  Future<void> dismiss(String id) async {
    await _deduplicator.run(
      'notification_dismiss_$id',
      () => _remote.dismissNotification(id),
    );
  }

  Future<NotificationsPageResult> fetchPage({
    int limit = 20,
    String? cursor,
    String? status,
    bool importantOnly = false,
    String? type,
    String? priority,
    String? search,
  }) async {
    final key =
        'notifications_page_${status ?? ''}_${importantOnly}_${type ?? ''}_'
        '${priority ?? ''}_${search ?? ''}_${cursor ?? '0'}';
    if (_rate.canCall('notifications_list')) {
      _rate.mark('notifications_list');
    }
    return _deduplicator.run(
      key,
      () => _remote.fetchNotificationsPage(
        limit: limit,
        cursor: cursor,
        status: status,
        importantOnly: importantOnly,
        type: type,
        priority: priority,
        search: search,
      ),
    );
  }

  Future<NotificationsUnreadCounts> fetchUnreadCounts() async {
    return _deduplicator.run(
      'notifications_unread_counts',
      () => _remote.fetchUnreadCounts(),
    );
  }

  Future<void> archive(String id) async {
    await _deduplicator.run(
      'notification_archive_$id',
      () => _remote.archiveNotification(id),
    );
  }
}
