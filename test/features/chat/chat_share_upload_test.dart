import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:wayoadsgo/features/chat/data/chat_message_media.dart';

void main() {
  test('shared path http is treated as remote media reference', () {
    const path = 'https://cdn.example.com/photo.jpg';
    expect(path.startsWith('http://') || path.startsWith('https://'), isTrue);
    expect(looksLikeRemoteMediaUrl(path), isTrue);
  });

  test('shared file path with image mime is not a bare url', () {
    final sf = SharedMediaFile(
      path: '/data/user/0/ma.wayo.wayoadsgo/cache/IMG_1.jpg',
      type: SharedMediaType.image,
      mimeType: 'image/jpeg',
    );
    expect(sf.type, SharedMediaType.image);
    expect(looksLikeRemoteMediaUrl(sf.path), isFalse);
  });
}
