import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/chat/data/chat_media_utils.dart';

void main() {
  test('resolveChatMediaUrl rewrites storage URL to api base host', () {
    final resolved = resolveChatMediaUrl(
      'http://127.0.0.1:8000/storage/chat-files/2026/05/photo.jpg',
      'https://chat.wayo.test',
    );
    expect(resolved, 'https://chat.wayo.test/storage/chat-files/2026/05/photo.jpg');
  });

  test('resolveChatMediaUrl joins relative storage path', () {
    expect(
      resolveChatMediaUrl('/storage/chat-files/x.png', 'https://chat.wayo.test'),
      'https://chat.wayo.test/storage/chat-files/x.png',
    );
  });
}
