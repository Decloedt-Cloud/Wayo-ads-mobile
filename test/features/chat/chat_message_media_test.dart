import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/chat/data/chat_message_media.dart';
import 'package:wayoadsgo/features/chat/domain/chat_message.dart';

void main() {
  test('normalize moves media URL from content to fileUrl', () {
    const raw = ChatMessage(
      id: 1,
      conversationId: 2,
      userId: 3,
      content: 'https://cdn.example.com/storage/chat/photo.jpg',
      type: 'text',
      createdAt: '2026-01-01T00:00:00Z',
    );
    final n = normalizeChatMessage(raw);
    expect(n.type, 'image');
    expect(n.fileUrl, contains('photo.jpg'));
    expect(n.content, isEmpty);
  });

  test('display caption hides duplicate attachment URL', () {
    const m = ChatMessage(
      id: 1,
      conversationId: 2,
      userId: 3,
      content: '/storage/chat/photo.jpg',
      type: 'image',
      createdAt: '2026-01-01T00:00:00Z',
      fileUrl: '/storage/chat/photo.jpg',
    );
    expect(
      chatMessageDisplayCaption(m, 'https://api.example.com'),
      isEmpty,
    );
  });

  test('detects chat-files URLs without file extension', () {
    expect(
      looksLikeRemoteMediaUrl(
        'https://api.wayo.test/storage/chat-files/2026/05/abc123',
      ),
      isTrue,
    );
  });

  test('resolveChatMessageMedia treats text+url as image', () {
    const m = ChatMessage(
      id: 1,
      conversationId: 2,
      userId: 3,
      content: 'https://api.example.com/uploads/a.png',
      type: 'text',
      createdAt: '2026-01-01T00:00:00Z',
    );
    final media = resolveChatMessageMedia(m, 'https://api.example.com');
    expect(media.isImage, isTrue);
    expect(media.url, contains('a.png'));
  });
}
