import 'chat_message.dart';
import 'chat_user_preview.dart';

final class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.type,
    this.displayName,
    this.displayAvatar,
    this.unreadCount = 0,
    this.updatedAt,
    this.lastMessage,
    this.participants,
  });

  final int id;
  final String type;
  final String? displayName;
  final String? displayAvatar;
  final int unreadCount;
  final String? updatedAt;
  final ChatMessage? lastMessage;
  final List<ChatParticipant>? participants;

  String title(String fallback) => displayName?.trim().isNotEmpty == true ? displayName! : fallback;

  /// Chat-service user id of the other participant (for presence), or `null`.
  int? partnerChatUserId(int myChatUserId) {
    final parts = participants;
    if (parts == null) return null;
    for (final p in parts) {
      final uid = p.user?.id ?? p.userId;
      if (uid != 0 && uid != myChatUserId) {
        return uid;
      }
    }
    return null;
  }

  /// Avatar path/url of the other participant when API embeds it on `participants[].user`.
  String? partnerAvatarFromParticipants(int myChatUserId) {
    final parts = participants;
    if (parts == null) return null;
    for (final p in parts) {
      final uid = p.user?.id ?? p.userId;
      if (uid != 0 && uid != myChatUserId) {
        return p.user?.avatar;
      }
    }
    return null;
  }
}

final class ChatParticipant {
  const ChatParticipant({
    required this.userId,
    this.lastReadAt,
    this.user,
  });

  final int userId;
  final String? lastReadAt;
  final ChatUserPreview? user;
}
