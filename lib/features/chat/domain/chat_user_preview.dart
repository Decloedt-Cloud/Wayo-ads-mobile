final class ChatUserPreview {
  const ChatUserPreview({
    required this.id,
    this.name,
    this.avatar,
    this.email,
    this.marketingUserId,
  });

  final int id;
  final String? name;

  /// Relative path or absolute URL (same as chat-service `users.avatar`).
  final String? avatar;
  final String? email;

  /// Wayo-ads Prisma [User.id] when chat-service stores [marketing_user_id].
  final String? marketingUserId;
}
