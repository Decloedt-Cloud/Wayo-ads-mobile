/// Row from chat-service `GET /api/v1/users` (Wayo-ads parity).
final class ChatDirectoryUser {
  const ChatDirectoryUser({
    required this.id,
    this.externalUserId,
    this.name,
    this.email,
    this.avatar,
  });

  final int id;
  final int? externalUserId;
  final String? name;
  final String? email;
  final String? avatar;

  factory ChatDirectoryUser.fromJson(Map<String, dynamic> m) {
    return ChatDirectoryUser(
      id: (m['id'] as num).toInt(),
      externalUserId: (m['user_id'] as num?)?.toInt(),
      name: m['name'] as String?,
      email: m['email'] as String?,
      avatar: m['avatar'] as String?,
    );
  }
}
