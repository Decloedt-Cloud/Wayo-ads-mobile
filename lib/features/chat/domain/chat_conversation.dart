import 'chat_message.dart';
import 'chat_user_preview.dart';

const Object _chatConversationUnset = Object();

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
    this.isPinned = false,
    this.isArchived = false,
    this.pinnedAt,
    this.archivedAt,
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

  /// Per-participant inbox flags (`conversation_participants` pivot).
  final bool isPinned;
  final bool isArchived;
  final String? pinnedAt;
  final String? archivedAt;

  ChatConversation copyWith({
    int? id,
    String? type,
    String? status,
    String? displayName,
    String? displayAvatar,
    int? unreadCount,
    String? updatedAt,
    ChatMessage? lastMessage,
    List<ChatParticipant>? participants,
    bool? isPinned,
    bool? isArchived,
    Object? pinnedAt = _chatConversationUnset,
    Object? archivedAt = _chatConversationUnset,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      displayAvatar: displayAvatar ?? this.displayAvatar,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      participants: participants ?? this.participants,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      pinnedAt: identical(pinnedAt, _chatConversationUnset)
          ? this.pinnedAt
          : pinnedAt as String?,
      archivedAt: identical(archivedAt, _chatConversationUnset)
          ? this.archivedAt
          : archivedAt as String?,
    );
  }

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

  /// Marketing roles string for the other participant (after enrichment).
  String? partnerAppRoles(int myChatUserId) {
    final parts = participants;
    if (parts == null) return null;
    for (final p in parts) {
      final uid = p.user?.id ?? p.userId;
      if (uid != 0 && uid != myChatUserId) {
        return p.user?.appRoles;
      }
    }
    return null;
  }

  /// Email of the other participant (for role lookup).
  String? partnerEmail(int myChatUserId) {
    final parts = participants;
    if (parts == null) return null;
    for (final p in parts) {
      final uid = p.user?.id ?? p.userId;
      if (uid != 0 && uid != myChatUserId) {
        return p.user?.email;
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
