import 'package:equatable/equatable.dart';

final class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
    this.priority,
    this.type,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  /// e.g. `P0_CRITICAL`, `P1_HIGH` (Wayo-ads list API).
  final String? priority;

  /// e.g. `CREATOR_APPLIED`, `CAMPAIGN_PAUSED` (Wayo-ads list API).
  final String? type;

  @override
  List<Object?> get props => [id, title, body, isRead, createdAt, priority, type];
}
