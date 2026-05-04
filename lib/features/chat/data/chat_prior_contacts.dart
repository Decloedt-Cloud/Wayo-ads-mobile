import '../domain/chat_conversation.dart';
import '../domain/chat_directory_user.dart';
import '../domain/chat_user_preview.dart';

/// Builds a deduplicated contact list from existing threads (creator inbox search).
///
/// Uses conversation participants only — no [`GET api/v1/users`].
List<ChatDirectoryUser> chatDirectoryUsersFromPriorConversations({
  required List<ChatConversation> conversations,
  required int myChatUserId,
  required String fallbackName,
}) {
  final merged = <int, ChatDirectoryUser>{};

  for (final c in conversations) {
    final pid = c.partnerChatUserId(myChatUserId);
    if (pid == null || pid == 0 || pid == myChatUserId) continue;

    final parts = c.participants ?? const <ChatParticipant>[];
    ChatUserPreview? partnerPreview;
    for (final p in parts) {
      final uid = p.user?.id ?? p.userId;
      if (uid == pid) {
        partnerPreview = p.user;
        break;
      }
    }

    final avatar =
        partnerPreview?.avatar ??
        c.partnerAvatarFromParticipants(myChatUserId) ??
        c.displayAvatar;

    final fromDisplay =
        (c.displayName?.trim().isNotEmpty ?? false)
            ? c.displayName!.trim()
            : null;
    final fromUser =
        (partnerPreview?.name?.trim().isNotEmpty ?? false)
            ? partnerPreview!.name!.trim()
            : null;
    final name = fromUser ?? fromDisplay ?? fallbackName;

    final incoming = ChatDirectoryUser(
      id: pid,
      externalUserId: null,
      name: name,
      email: null,
      avatar: avatar,
    );

    final prev = merged[pid];
    if (prev == null) {
      merged[pid] = incoming;
      continue;
    }

    merged[pid] = ChatDirectoryUser(
      id: pid,
      externalUserId: null,
      name: _preferRicherName(prev.name, incoming.name, fallbackName),
      email: prev.email ?? incoming.email,
      avatar: prev.avatar ?? incoming.avatar,
    );
  }

  final out = merged.values.toList();
  out.sort(
    (a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return out;
}

bool chatPriorContactMatchesQuery(ChatDirectoryUser u, String queryLower) {
  if (queryLower.isEmpty) return false;
  final name = (u.name ?? '').toLowerCase();
  final email = (u.email ?? '').toLowerCase();
  return name.contains(queryLower) || email.contains(queryLower);
}

String _preferRicherName(String? a, String? b, String fallback) {
  bool isWeak(String? s) =>
      s == null || s.trim().isEmpty || s.trim() == fallback.trim();
  if (!isWeak(a)) return a!.trim();
  if (!isWeak(b)) return b!.trim();
  return (a ?? b ?? fallback).trim();
}
