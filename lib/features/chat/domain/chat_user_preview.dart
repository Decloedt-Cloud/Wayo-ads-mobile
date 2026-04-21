final class ChatUserPreview {
  const ChatUserPreview({required this.id, this.name, this.avatar});

  final int id;
  final String? name;

  /// Relative path or absolute URL (same as chat-service `users.avatar`).
  final String? avatar;
}
