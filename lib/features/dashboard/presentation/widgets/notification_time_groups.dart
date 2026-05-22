import '../../domain/entities/notification_item.dart';

enum NotificationTimeGroup { today, yesterday, earlier }

NotificationTimeGroup notificationTimeGroup(DateTime? createdAt) {
  if (createdAt == null) return NotificationTimeGroup.earlier;
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));
  final day = DateTime(local.year, local.month, local.day);
  if (!day.isBefore(todayStart)) return NotificationTimeGroup.today;
  if (!day.isBefore(yesterdayStart)) return NotificationTimeGroup.yesterday;
  return NotificationTimeGroup.earlier;
}

/// Unread first, then newest first (Wayo-ads web bell).
List<NotificationItem> sortNotificationsForDisplay(List<NotificationItem> list) {
  final copy = List<NotificationItem>.from(list);
  copy.sort((a, b) {
    final au = a.isRead ? 0 : 1;
    final bu = b.isRead ? 0 : 1;
    if (au != bu) return bu.compareTo(au);
    final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
    final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
    return bt.compareTo(at);
  });
  return copy;
}

class NotificationTimeGroupSection {
  const NotificationTimeGroupSection({
    required this.group,
    required this.items,
  });

  final NotificationTimeGroup group;
  final List<NotificationItem> items;
}

List<NotificationTimeGroupSection> groupNotificationsByTime(
  List<NotificationItem> list,
) {
  final sorted = sortNotificationsForDisplay(list);
  final map = <NotificationTimeGroup, List<NotificationItem>>{};
  for (final n in sorted) {
    final g = notificationTimeGroup(n.createdAt);
    map.putIfAbsent(g, () => []).add(n);
  }
  const order = [
    NotificationTimeGroup.today,
    NotificationTimeGroup.yesterday,
    NotificationTimeGroup.earlier,
  ];
  return [
    for (final g in order)
      if (map[g]?.isNotEmpty ?? false)
        NotificationTimeGroupSection(group: g, items: map[g]!),
  ];
}

String formatNotificationDate(DateTime? createdAt, String locale) {
  if (createdAt == null) return '';
  return '${createdAt.day.toString().padLeft(2, '0')}/'
      '${createdAt.month.toString().padLeft(2, '0')}/'
      '${createdAt.year}';
}

/// Relative label for list rows (web: "2h ago", same day → time).
String formatNotificationRelativeTime(DateTime? createdAt) {
  if (createdAt == null) return '';
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  final days = diff.inDays;
  if (days < 7) return '${days}d';
  return formatNotificationDate(createdAt, '');
}

String formatNotificationTimeOfDay(DateTime? createdAt) {
  if (createdAt == null) return '';
  final local = createdAt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

