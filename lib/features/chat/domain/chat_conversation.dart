import 'chat_message.dart';
import 'chat_user_preview.dart';

/// Anonymized account emails from chat-service after soft-delete purge.
bool isDeletedChatUserEmail(String? email) {
  final e = email?.trim() ?? '';
  if (e.isEmpty) return false;
  return e.endsWith('@deleted.wayo.com') || e.endsWith('@deleted.wayo.local');
}

/// Fallback when the conversation row is not in [chatConversationsProvider] yet.
bool chatPeerUnavailableFromMessages(
  int myChatUserId,
  List<ChatMessage> messages,
) {
  for (final m in messages) {
    final uid = m.userId != 0 ? m.userId : (m.user?.id ?? 0);
    if (uid != 0 && uid != myChatUserId) {
      if (isDeletedChatUserEmail(m.user?.email)) return true;
    }
  }
  return false;
}

final class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.type,
    this.status,
    this.displayName,
    this.displayAvatar,
    this.unreadCount = 0,
    this.updatedAt,
    this.lastMessage,
    this.participants,
  });

  final int id;
  final String type;

  /// Laravel chat-service: `active` | `archived` | `closed` (peer deleted account).
  final String? status;
  final String? displayName;
  final String? displayAvatar;
  final int unreadCount;
  final String? updatedAt;
  final ChatMessage? lastMessage;
  final List<ChatParticipant>? participants;

  String title(String fallback) =>
      displayName?.trim().isNotEmpty == true ? displayName! : fallback;

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

  /// Direct thread with a soft-deleted / anonymized peer — composer must be hidden.
  bool isPeerUnavailable(int myChatUserId) {
    if (type != 'direct') return false;
    if (status == 'closed') return true;
    final parts = participants;
    if (parts == null) return false;
    for (final p in parts) {
      final uid = p.user?.id ?? p.userId;
      if (uid != 0 && uid != myChatUserId) {
        if (isDeletedChatUserEmail(p.user?.email)) return true;
      }
    }
    return false;
  }
}

final class ChatParticipant {
  const ChatParticipant({required this.userId, this.lastReadAt, this.user});

  final int userId;
  final String? lastReadAt;
  final ChatUserPreview? user;
}
