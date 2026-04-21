import 'package:equatable/equatable.dart';

final class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, title, body, isRead, createdAt];
}
