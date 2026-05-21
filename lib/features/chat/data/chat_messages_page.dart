import '../domain/chat_message.dart';

/// One page from `GET …/conversations/{id}/messages` (Laravel-style meta when present).
final class ChatMessagesPage {
  const ChatMessagesPage({
    required this.messages,
    required this.hasMore,
    required this.currentPage,
    required this.lastPage,
  });

  final List<ChatMessage> messages;
  final bool hasMore;
  final int currentPage;
  final int lastPage;
}

/// Reads `current_page` / `last_page` (top-level or under `meta`) or falls back to `next_page_url`.
ChatMessagesPageMeta readChatMessagesPaginationMeta(
  Map<String, dynamic>? payload,
  int requestedPage,
) {
  if (payload == null) {
    return ChatMessagesPageMeta.singlePage(requestedPage);
  }
  final nestedMeta = payload['meta'];
  final meta =
      nestedMeta is Map<String, dynamic> ? nestedMeta : payload;

  num? cp = meta['current_page'] ?? payload['current_page'];
  num? lp = meta['last_page'] ?? payload['last_page'];
  if (cp != null && lp != null) {
    final c = cp.toInt();
    final l = lp.toInt();
    return ChatMessagesPageMeta(
      currentPage: c,
      lastPage: l,
      hasMore: c < l,
    );
  }
  final next =
      meta['next_page_url'] ??
      payload['next_page_url'];
  final hasMore = next != null && next is String && next.toString().isNotEmpty;
  return ChatMessagesPageMeta(
    currentPage: requestedPage,
    lastPage: requestedPage,
    hasMore: hasMore,
  );
}

/// Normalized pagination slice from the `data` object of the list response.
final class ChatMessagesPageMeta {
  const ChatMessagesPageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
  });

  final int currentPage;
  final int lastPage;
  final bool hasMore;

  factory ChatMessagesPageMeta.singlePage(int page) => ChatMessagesPageMeta(
        currentPage: page,
        lastPage: page,
        hasMore: false,
      );
}
