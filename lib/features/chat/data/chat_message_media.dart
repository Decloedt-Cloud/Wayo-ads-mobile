import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../domain/chat_message.dart';
import 'chat_message_text.dart';
import 'chat_media_utils.dart';

/// Allowed chat attachment extensions (picker + share intent).
const Set<String> kChatAttachmentExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'pdf',
};

bool isChatImageExtension(String ext) {
  final e = ext.toLowerCase();
  return e != 'pdf' && kChatAttachmentExtensions.contains(e);
}

bool isChatPdfExtension(String ext) => ext.toLowerCase() == 'pdf';

String? extensionFromFilename(String name) {
  final n = name.trim();
  if (!n.contains('.')) return null;
  return n.split('.').last.toLowerCase();
}

bool looksLikeLocalMediaUri(String raw) {
  final t = raw.trim();
  if (t.startsWith('content://') || t.startsWith('file://')) return true;
  if (kIsWeb) return false;
  if (t.startsWith('/') && !t.startsWith('//') && t.contains('.')) {
    final ext = extensionFromFilename(t);
    if (ext != null && kChatAttachmentExtensions.contains(ext)) return true;
  }
  return false;
}

/// Laravel multi-image payloads embed JSON after this marker in [ChatMessage.content].
const String kChatGalleryContentMarker = '__WAYO_GALLERY__::';

bool looksLikeRemoteMediaUrl(String raw) {
  final t = raw.trim();
  if (t.startsWith('/storage/')) return true;
  if (!t.startsWith('http://') && !t.startsWith('https://')) return false;
  final lower = t.toLowerCase();
  if (lower.contains('/storage/') ||
      lower.contains('chat-files') ||
      lower.contains('chat-images') ||
      lower.contains('chat-audios') ||
      lower.contains('/chat/') ||
      lower.contains('/media/') ||
      lower.contains('/attachments/') ||
      lower.contains('/uploads/')) {
    return true;
  }
  return RegExp(
    r'\.(jpe?g|png|gif|webp|bmp|pdf)(\?|#|$)',
    caseSensitive: false,
  ).hasMatch(lower);
}

/// True when the composer text should be uploaded, not sent as plain text.
bool chatComposerTextLooksLikeMediaReference(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return false;
  if (looksLikeLocalMediaUri(t)) return true;
  if (looksLikeRemoteMediaUrl(t)) return true;
  if (t.contains(kChatGalleryContentMarker)) return true;
  return false;
}

String? firstUrlFromGalleryMarkerContent(String raw) {
  final idx = raw.indexOf(kChatGalleryContentMarker);
  if (idx < 0) return null;
  final jsonPart = raw.substring(idx + kChatGalleryContentMarker.length).trim();
  try {
    final decoded = jsonDecode(jsonPart);
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map) {
        final url = first['url'] ?? first['file_url'];
        if (url is String && url.trim().isNotEmpty) return url.trim();
      }
    }
  } catch (_) {}
  return null;
}

bool _sameMediaReference(String a, String b) {
  final x = a.trim();
  final y = b.trim();
  if (x.isEmpty || y.isEmpty) return false;
  if (x == y) return true;
  final pa = chatMediaStoragePath(x);
  final pb = chatMediaStoragePath(y);
  if (pa != null && pb != null && pa == pb) return true;
  try {
    final ua = Uri.parse(x);
    final ub = Uri.parse(y);
    if (ua.path.isNotEmpty && ua.path == ub.path) return true;
  } catch (_) {}
  final sa = x.split('/').where((s) => s.isNotEmpty).lastOrNull ?? x;
  final sb = y.split('/').where((s) => s.isNotEmpty).lastOrNull ?? y;
  return sa.isNotEmpty && sa == sb;
}

String _inferTypeFromReference(String ref) {
  final ext = extensionFromFilename(ref) ?? '';
  return isChatPdfExtension(ext) ? 'file' : 'image';
}

/// Fixes API rows where media was stored as plain text / URL in [ChatMessage.content].
ChatMessage normalizeChatMessage(ChatMessage m) {
  var content = m.content;
  var type = m.type;
  var fileUrl = (m.fileUrl ?? '').trim();

  var body = plainBodyFromChatContent(content).trim();
  final galleryUrl = firstUrlFromGalleryMarkerContent(content);
  if (galleryUrl != null) {
    if (fileUrl.isEmpty) fileUrl = galleryUrl;
    type = 'image';
    body = body.replaceAll(kChatGalleryContentMarker, '').trim();
    if (body.startsWith('[')) body = '';
  }

  if (fileUrl.isEmpty && body.isNotEmpty) {
    if (looksLikeRemoteMediaUrl(body) || looksLikeLocalMediaUri(body)) {
      fileUrl = body;
      type = _inferTypeFromReference(body);
      content = '';
    }
  } else if (fileUrl.isNotEmpty && body.isNotEmpty) {
    if (_sameMediaReference(body, fileUrl)) {
      content = '';
    }
  }

  if (fileUrl.isNotEmpty) {
    if (type == 'text' || type.isEmpty) {
      type = _inferTypeFromReference(fileUrl);
    }
    final caption = plainBodyFromChatContent(content).trim();
    if (caption.isEmpty ||
        _sameMediaReference(caption, fileUrl) ||
        looksLikeRemoteMediaUrl(caption)) {
      content = '';
    }
  }

  return ChatMessage(
    id: m.id,
    conversationId: m.conversationId,
    userId: m.userId,
    content: content,
    type: type,
    createdAt: m.createdAt,
    updatedAt: m.updatedAt,
    editedAt: m.editedAt,
    isEdited: m.isEdited,
    fileUrl: fileUrl.isEmpty ? null : fileUrl,
    fileName: m.fileName,
    fileSize: m.fileSize,
    user: m.user,
    pending: m.pending,
    failed: m.failed,
    replyTo: m.replyTo,
  );
}

/// Resolved media URL + bubble kind (handles mis-typed API payloads).
class ChatMessageMediaView {
  const ChatMessageMediaView({
    required this.url,
    this.isImage = false,
    this.isFile = false,
  });

  final String url;
  final bool isImage;
  final bool isFile;

  bool get hasMedia => url.isNotEmpty && (isImage || isFile);
}

ChatMessageMediaView resolveChatMessageMedia(ChatMessage m, String apiBaseUrl) {
  final normalized = normalizeChatMessage(m);
  var fileRef = (normalized.fileUrl ?? '').trim();
  var type = normalized.type;

  if (fileRef.isEmpty) {
    final body = plainBodyFromChatContent(normalized.content).trim();
    if (body.isNotEmpty &&
        (looksLikeRemoteMediaUrl(body) || looksLikeLocalMediaUri(body))) {
      fileRef = body;
      type = _inferTypeFromReference(body);
    }
  }

  final url = resolveChatMediaUrl(fileRef.isEmpty ? null : fileRef, apiBaseUrl);
  if (url.isEmpty) {
    return const ChatMessageMediaView(url: '');
  }

  final ext = extensionFromFilename(fileRef) ??
      extensionFromFilename(normalized.fileName ?? '') ??
      '';
  final typeLower = type.toLowerCase();
  final isPdf = typeLower == 'file' || isChatPdfExtension(ext);
  final storageLike = fileRef.contains('/storage/') ||
      fileRef.contains('chat-files') ||
      fileRef.contains('chat-images') ||
      fileRef.contains('chat-audios');
  return ChatMessageMediaView(
    url: url,
    isImage: !isPdf &&
        (typeLower == 'image' ||
            isChatImageExtension(ext) ||
            (storageLike && !isChatPdfExtension(ext))),
    isFile: isPdf || typeLower == 'file',
  );
}

/// Caption under an image/file bubble — never repeat the attachment URL as text.
String chatMessageDisplayCaption(ChatMessage m, String apiBaseUrl) {
  final normalized = normalizeChatMessage(m);
  final body = plainBodyFromChatContent(normalized.content).trim();
  if (body.isEmpty) return '';

  final media = resolveChatMessageMedia(normalized, apiBaseUrl);
  if (!media.hasMedia) return body;

  final fileRef = (normalized.fileUrl ?? '').trim();
  if (fileRef.isNotEmpty && _sameMediaReference(body, fileRef)) return '';
  if (_sameMediaReference(body, media.url)) return '';
  if (looksLikeRemoteMediaUrl(body)) return '';
  if (body.contains(kChatGalleryContentMarker)) return '';

  return body;
}

String sanitizeOutgoingAttachmentCaption(String caption) {
  final t = caption.trim();
  if (t.isEmpty) return '';
  if (chatComposerTextLooksLikeMediaReference(t)) return '';
  return t;
}

String filenameFromMediaReference(String reference) {
  final t = reference.trim();
  final fromPath = extensionFromFilename(t);
  if (fromPath != null) {
    final base = t.split('/').where((s) => s.isNotEmpty).last;
    return base.isNotEmpty ? base : 'attachment.$fromPath';
  }
  try {
    final uri = Uri.parse(t);
    final seg = uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
    if (seg != null && seg.contains('.')) return seg;
  } catch (_) {}
  return 'photo.jpg';
}

/// Read bytes from a pasted or shared local reference (`content://`, `file://`, path).
Future<({List<int> bytes, String filename, String? path})?> readLocalChatAttachment(
  String reference,
) async {
  final ref = reference.trim();
  if (ref.isEmpty) return null;

  try {
    if (ref.startsWith('content://') || ref.startsWith('file://')) {
      final bytes = await XFile(ref).readAsBytes();
      if (bytes.isEmpty) return null;
      var name = ref.split('/').where((s) => s.isNotEmpty).lastOrNull ?? 'attachment';
      if (!name.contains('.')) {
        name = '$name.jpg';
      }
      return (bytes: bytes, filename: name, path: ref);
    }
    if (!kIsWeb && ref.startsWith('/')) {
      final file = File(ref);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      final name = ref.split(Platform.pathSeparator).last;
      return (bytes: bytes, filename: name, path: ref);
    }
  } catch (_) {
    return null;
  }
  return null;
}
