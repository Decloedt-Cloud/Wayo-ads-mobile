import 'package:shared_preferences/shared_preferences.dart';

/// Persisted so FCM background isolates can skip tray notifications while the user
/// is viewing a thread ([ChatThreadScreen]).
const kChatActiveConversationPrefKey = 'chat.active_conversation_id';

int? _memoryActiveChatConversationId;

/// In-process cache — updated together with [setActiveChatConversationId].
int? get memoryActiveChatConversationId => _memoryActiveChatConversationId;

Future<void> setActiveChatConversationId(int? id) async {
  _memoryActiveChatConversationId = id;
  final prefs = await SharedPreferences.getInstance();
  if (id == null) {
    await prefs.remove(kChatActiveConversationPrefKey);
  } else {
    await prefs.setString(kChatActiveConversationPrefKey, '$id');
  }
}

/// True when the user currently has [conversationId] open in [ChatThreadScreen].
Future<bool> isViewingChatConversation(String conversationId) async {
  final trimmed = conversationId.trim();
  if (trimmed.isEmpty) return false;
  final mem = _memoryActiveChatConversationId;
  if (mem != null && '$mem' == trimmed) return true;
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(kChatActiveConversationPrefKey)?.trim();
  return stored != null && stored.isNotEmpty && stored == trimmed;
}
