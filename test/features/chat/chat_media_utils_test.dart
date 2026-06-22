import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/chat/data/chat_media_utils.dart';

void main() {
  test('resolveChatMediaUrl rewrites loopback storage URL to api base host', () {
    final resolved = resolveChatMediaUrl(
      'http://127.0.0.1:8000/storage/chat-files/2026/05/photo.jpg',
      'https://chat.wayo.test',
    );
    expect(resolved, 'https://chat.wayo.test/storage/chat-files/2026/05/photo.jpg');
  });

  test('resolveChatMediaUrl keeps Auth host for avatar storage URLs', () {
    const authAvatar =
        'https://preprodauth.wayo.ac/storage/avatars/user.jpg';
    expect(
      resolveChatMediaUrl(authAvatar, 'https://wayochat.wayo.ac'),
      authAvatar,
    );
  });

  test('resolveChatAvatarUrl resolves Wayo-ads uploads path', () {
    expect(
      resolveChatAvatarUrl('/uploads/avatars/x.png', 'https://wayochat.wayo.ac'),
      isNotEmpty,
    );
  });

  test('resolveChatMediaUrl joins relative storage path', () {
    expect(
      resolveChatMediaUrl('/storage/chat-files/x.png', 'https://chat.wayo.test'),
      'https://chat.wayo.test/storage/chat-files/x.png',
    );
  });
}
