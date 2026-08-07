import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/chat/domain/chat_conversation.dart';

void main() {
  group('ChatConversation inbox flags', () {
    test('copyWith toggles pin/archive', () {
      const base = ChatConversation(
        id: 7,
        type: 'direct',
        displayName: 'Maya',
      );
      final pinned = base.copyWith(isPinned: true, pinnedAt: '2026-08-05T10:00:00Z');
      expect(pinned.isPinned, isTrue);
      expect(pinned.isArchived, isFalse);
      expect(pinned.pinnedAt, '2026-08-05T10:00:00Z');

      final archived = pinned.copyWith(
        isArchived: true,
        isPinned: false,
        pinnedAt: null,
        archivedAt: '2026-08-05T11:00:00Z',
      );
      expect(archived.isPinned, isFalse);
      expect(archived.isArchived, isTrue);
      expect(archived.pinnedAt, isNull);
      expect(archived.archivedAt, '2026-08-05T11:00:00Z');
    });
  });
}
