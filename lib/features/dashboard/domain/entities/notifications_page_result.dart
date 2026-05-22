import 'package:equatable/equatable.dart';

import 'notification_item.dart';

final class NotificationsPageResult extends Equatable {
  const NotificationsPageResult({
    required this.notifications,
    this.nextCursor,
  });

  final List<NotificationItem> notifications;
  final String? nextCursor;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  @override
  List<Object?> get props => [notifications, nextCursor];
}

final class NotificationsUnreadCounts extends Equatable {
  const NotificationsUnreadCounts({
    required this.total,
    required this.important,
  });

  final int total;
  final int important;

  @override
  List<Object?> get props => [total, important];
}
