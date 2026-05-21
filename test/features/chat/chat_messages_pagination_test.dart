import 'package:flutter_test/flutter_test.dart';

import 'package:wayoadsgo/features/chat/data/chat_messages_page.dart';

void main() {
  group('readChatMessagesPaginationMeta', () {
    test('uses top-level current_page and last_page', () {
      final m = readChatMessagesPaginationMeta(<String, dynamic>{
        'current_page': 1,
        'last_page': 4,
        'data': <dynamic>[],
      }, 1);
      expect(m.currentPage, 1);
      expect(m.lastPage, 4);
      expect(m.hasMore, true);
    });

    test('reads nested meta map when present', () {
      final m = readChatMessagesPaginationMeta(<String, dynamic>{
        'data': <dynamic>[],
        'meta': <String, dynamic>{
          'current_page': 3,
          'last_page': 3,
        },
      }, 3);
      expect(m.currentPage, 3);
      expect(m.lastPage, 3);
      expect(m.hasMore, false);
    });

    test('falls back to next_page_url string when pages absent', () {
      final withNext = readChatMessagesPaginationMeta(<String, dynamic>{
        'data': <dynamic>[],
        'next_page_url': 'https://example.test?page=2',
      }, 1);
      expect(withNext.hasMore, true);

      final done = readChatMessagesPaginationMeta(<String, dynamic>{
        'data': <dynamic>[],
        'next_page_url': null,
      }, 2);
      expect(done.hasMore, false);
    });

    test('single-page payload without hints', () {
      final m = readChatMessagesPaginationMeta(<String, dynamic>{
        'data': <dynamic>[],
      }, 1);
      expect(m.hasMore, false);
      expect(m.currentPage, 1);
      expect(m.lastPage, 1);
    });
  });
}
