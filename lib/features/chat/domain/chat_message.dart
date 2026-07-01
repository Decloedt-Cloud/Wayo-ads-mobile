import 'chat_user_preview.dart';

/// Quoted reply target from chat-service (`reply_to`, `quoted_message`, etc.).
final class ChatReplyRef {
  const ChatReplyRef({
    required this.messageId,
    required this.preview,
    this.senderName,
  });

  final int messageId;
  final String preview;
  final String? senderName;
}

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    this.editedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.deletedAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.user,
    this.pending = false,
    this.failed = false,
    this.replyTo,
  });

  final int id;
  final int conversationId;
  final int userId;
  final String content;
  final String type;
  final String createdAt;
  final String? updatedAt;
  final String? editedAt;
  final bool isEdited;
  final bool isDeleted;
  final String? deletedAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final ChatUserPreview? user;

  /// Optimistic local row (negative id) until server ack.
  final bool pending;
  final bool failed;

  /// Quoted/thread parent when API returns structured reply metadata.
  final ChatReplyRef? replyTo;

  ChatMessage copyWith({
    int? id,
    bool? pending,
    bool? failed,
    String? content,
    String? type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? createdAt,
    String? updatedAt,
    String? editedAt,
    bool? isEdited,
    bool? isDeleted,
    String? deletedAt,
    ChatUserPreview? user,
    ChatReplyRef? replyTo,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId,
      userId: userId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      user: user ?? this.user,
      pending: pending ?? this.pending,
      failed: failed ?? this.failed,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
