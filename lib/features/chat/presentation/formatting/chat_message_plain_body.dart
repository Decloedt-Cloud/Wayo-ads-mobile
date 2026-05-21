import '../../data/chat_message_text.dart';
import '../../domain/chat_message.dart';

export '../../data/chat_message_text.dart' show plainBodyFromChatContent;

/// Whether this message exposes a Copy action (captions count for media).
bool chatMessageHasCopyableText(ChatMessage m) {
  return plainBodyFromChatContent(m.content).isNotEmpty;
}

/// Text + image/pdf rows can be forwarded to another conversation.
bool chatMessageCanForward(ChatMessage m) {
  if (m.pending || m.failed || m.id <= 0) return false;
  if (chatMessageHasCopyableText(m)) return true;
  if ((m.fileUrl ?? '').trim().isEmpty) return false;
  return m.type == 'image' || m.type == 'file';
}
