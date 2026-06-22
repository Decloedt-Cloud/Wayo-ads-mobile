import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_user_preview.dart';
import 'chat_media_utils.dart';

bool _isPlaceholderChatEmail(String? email) {
  if (email == null || email.trim().isEmpty) return true;
  final e = email.trim().toLowerCase();
  return e.endsWith('@temp.local') || e.contains('@users.noreply.wayo.internal');
}

String? _pickAvatarUrl(String? raw, String chatApiBaseUrl) {
  if (raw == null || raw.trim().isEmpty) return null;
  return resolveChatAvatarUrl(raw.trim(), chatApiBaseUrl);
}

/// Fetches Wayo-ads marketing profiles and patches missing partner avatars.
Future<List<ChatConversation>> enrichChatConversationsWithMarketingAvatars(
  List<ChatConversation> conversations,
  int myChatUserId,
  String chatApiBaseUrl,
  Future<Map<String, dynamic>?> Function(String path) fetchWayoAdsJson,
) async {
  if (conversations.isEmpty) return conversations;

  final emails = <String>{};
  final marketingIds = <String>{};

  for (final c in conversations) {
    if (c.type != 'direct') continue;
    final parts = c.participants;
    if (parts == null) continue;
    for (final p in parts) {
      final uid = p.user?.id ?? p.userId;
      if (uid == 0 || uid == myChatUserId) continue;
      if (c.displayAvatar?.trim().isNotEmpty == true &&
          p.user?.avatar?.trim().isNotEmpty == true) {
        continue;
      }
      final email = p.user?.email;
      if (!_isPlaceholderChatEmail(email)) {
        emails.add(email!.trim().toLowerCase());
      }
      final mid = p.user?.marketingUserId;
      if (mid != null && mid.trim().isNotEmpty) {
        marketingIds.add(mid.trim());
      }
    }
  }

  if (emails.isEmpty && marketingIds.isEmpty) {
    return conversations;
  }

  final q = <String>[];
  if (emails.isNotEmpty) {
    q.add('emails=${Uri.encodeQueryComponent(emails.join(','))}');
  }
  if (marketingIds.isNotEmpty) {
    q.add('userIds=${Uri.encodeQueryComponent(marketingIds.join(','))}');
  }

  final path =
      '${AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.chatUserProfiles)}?${q.join('&')}';
  final payload = await fetchWayoAdsJson(path);
  if (payload == null || payload['success'] != true) {
    return conversations;
  }

  final data = payload['data'];
  if (data is! Map<String, dynamic>) return conversations;

  final byEmailRaw = data['byEmail'];
  final byUserIdRaw = data['byUserId'];
  final byEmail = byEmailRaw is Map
      ? Map<String, dynamic>.from(byEmailRaw)
      : <String, dynamic>{};
  final byUserId = byUserIdRaw is Map
      ? Map<String, dynamic>.from(byUserIdRaw)
      : <String, dynamic>{};

  String? imageForPartner(ChatParticipant p) {
    final email = p.user?.email?.trim().toLowerCase();
    if (email != null && !_isPlaceholderChatEmail(email)) {
      final row = byEmail[email];
      if (row is Map) {
        final img = row['image'] as String?;
        if (img != null && img.trim().isNotEmpty) return img.trim();
      }
    }
    final mid = p.user?.marketingUserId?.trim();
    if (mid != null && mid.isNotEmpty) {
      final row = byUserId[mid];
      if (row is Map) {
        final img = row['image'] as String?;
        if (img != null && img.trim().isNotEmpty) return img.trim();
      }
    }
    return null;
  }

  return conversations.map((c) {
    if (c.type != 'direct') return c;
    final parts = c.participants;
    if (parts == null) return c;

    String? partnerImage;
    ChatParticipant? partnerPart;
    for (final p in parts) {
      final uid = p.user?.id ?? p.userId;
      if (uid != 0 && uid != myChatUserId) {
        partnerPart = p;
        partnerImage = imageForPartner(p);
        break;
      }
    }
    if (partnerImage == null) return c;

    final resolvedDisplay = c.displayAvatar?.trim().isNotEmpty == true
        ? c.displayAvatar
        : _pickAvatarUrl(partnerImage, chatApiBaseUrl);

    final nextParticipants = parts.map((p) {
      if (p.user?.avatar?.trim().isNotEmpty == true) return p;
      if (partnerPart != null && p.userId != partnerPart.userId) return p;
      final u = p.user;
      if (u == null) return p;
      return ChatParticipant(
        userId: p.userId,
        lastReadAt: p.lastReadAt,
        user: ChatUserPreview(
          id: u.id,
          name: u.name,
          avatar: _pickAvatarUrl(partnerImage, chatApiBaseUrl) ?? u.avatar,
          email: u.email,
          marketingUserId: u.marketingUserId,
        ),
      );
    }).toList();

    return ChatConversation(
      id: c.id,
      type: c.type,
      displayName: c.displayName,
      displayAvatar: resolvedDisplay ?? c.displayAvatar,
      unreadCount: c.unreadCount,
      updatedAt: c.updatedAt,
      lastMessage: c.lastMessage,
      participants: nextParticipants,
    );
  }).toList();
}
