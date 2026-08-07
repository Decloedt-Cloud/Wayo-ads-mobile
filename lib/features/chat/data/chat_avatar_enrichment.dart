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

/// Fetches Wayo-ads marketing profiles + roles and patches partner avatars/roles.
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

  Map<String, dynamic> byEmail = {};
  Map<String, dynamic> byUserId = {};
  Map<String, String> rolesByEmail = {};

  if (emails.isNotEmpty || marketingIds.isNotEmpty) {
    final q = <String>[];
    if (emails.isNotEmpty) {
      q.add('emails=${Uri.encodeQueryComponent(emails.join(','))}');
    }
    if (marketingIds.isNotEmpty) {
      q.add('userIds=${Uri.encodeQueryComponent(marketingIds.join(','))}');
    }
    final path =
        '${AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.chatUserProfiles)}?${q.join('&')}';
    try {
      final payload = await fetchWayoAdsJson(path);
      if (payload != null && payload['success'] == true) {
        final data = payload['data'];
        if (data is Map<String, dynamic>) {
          final byEmailRaw = data['byEmail'];
          final byUserIdRaw = data['byUserId'];
          byEmail = byEmailRaw is Map
              ? Map<String, dynamic>.from(byEmailRaw)
              : <String, dynamic>{};
          byUserId = byUserIdRaw is Map
              ? Map<String, dynamic>.from(byUserIdRaw)
              : <String, dynamic>{};
        }
      }
    } catch (_) {
      /* best effort */
    }
  }

  if (emails.isNotEmpty) {
    final rolesPath =
        '${AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.chatUserRoles)}'
        '?emails=${Uri.encodeQueryComponent(emails.join(','))}';
    try {
      final payload = await fetchWayoAdsJson(rolesPath);
      if (payload != null && payload['success'] == true) {
        final data = payload['data'];
        if (data is Map) {
          for (final e in data.entries) {
            final key = e.key.toString().trim().toLowerCase();
            final val = e.value?.toString();
            if (key.isNotEmpty && val != null && val.isNotEmpty) {
              rolesByEmail[key] = val;
            }
          }
        }
      }
    } catch (_) {
      /* best effort */
    }
  }

  if (byEmail.isEmpty && byUserId.isEmpty && rolesByEmail.isEmpty) {
    return conversations;
  }

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

  String? rolesForPartner(ChatParticipant p) {
    final email = p.user?.email?.trim().toLowerCase();
    if (email == null || _isPlaceholderChatEmail(email)) return p.user?.appRoles;
    return rolesByEmail[email] ?? p.user?.appRoles;
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

    final nextParticipants = parts.map((p) {
      final uid = p.user?.id ?? p.userId;
      final isPartner = uid != 0 && uid != myChatUserId;
      final u = p.user;
      if (u == null) return p;

      final roles = isPartner ? rolesForPartner(p) : u.appRoles;
      final needsAvatar = isPartner &&
          partnerPart != null &&
          p.userId == partnerPart.userId &&
          (u.avatar == null || u.avatar!.trim().isEmpty);
      final avatar = needsAvatar
          ? (_pickAvatarUrl(partnerImage, chatApiBaseUrl) ?? u.avatar)
          : u.avatar;

      if (roles == u.appRoles && avatar == u.avatar) return p;

      return ChatParticipant(
        userId: p.userId,
        lastReadAt: p.lastReadAt,
        user: ChatUserPreview(
          id: u.id,
          name: u.name,
          avatar: avatar,
          email: u.email,
          marketingUserId: u.marketingUserId,
          appRoles: roles,
        ),
      );
    }).toList();

    final resolvedDisplay = c.displayAvatar?.trim().isNotEmpty == true
        ? c.displayAvatar
        : _pickAvatarUrl(partnerImage, chatApiBaseUrl);

    return ChatConversation(
      id: c.id,
      type: c.type,
      status: c.status,
      displayName: c.displayName,
      displayAvatar: resolvedDisplay ?? c.displayAvatar,
      unreadCount: c.unreadCount,
      updatedAt: c.updatedAt,
      lastMessage: c.lastMessage,
      participants: nextParticipants,
      isPinned: c.isPinned,
      isArchived: c.isArchived,
      pinnedAt: c.pinnedAt,
      archivedAt: c.archivedAt,
    );
  }).toList();
}
