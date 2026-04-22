import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/connectivity_providers.dart';
import '../../data/chat_repository.dart';
import '../../data/chat_realtime_service.dart';
import '../../domain/chat_conversation.dart';
import '../../domain/chat_credentials.dart';
import '../../domain/chat_message.dart';

final chatRealtimeServiceProvider = Provider.autoDispose<ChatRealtimeService>((
  ref,
) {
  final connectivity = ref.read(connectivityServiceProvider);
  final s = ChatRealtimeService(
    onConnectionError: connectivity.reportRemoteFailure,
  );
  ref.keepAlive();
  ref.onDispose(s.dispose);
  return s;
});

/// Wayo-ads bootstrap only (cached for session).
final chatBootstrapProvider = FutureProvider<ChatCredentials>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(chatRepositoryProvider);
  return repo.fetchBootstrap();
});

/// Conversation list from chat-service (Bearer chat JWT).
/// Not `autoDispose`: shell IndexedStack + login prefetch can cancel in-flight loads if disposed too early.
final chatConversationsProvider = FutureProvider<List<ChatConversation>>((
  ref,
) async {
  ref.keepAlive();
  final creds = await ref.watch(chatBootstrapProvider.future);
  final rt = ref.read(chatRealtimeServiceProvider);
  final repo = ref.read(chatRepositoryProvider);
  Object? lastError;
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      return await repo.fetchConversations(creds, socketId: () => rt.socketId);
    } catch (e) {
      lastError = e;
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 320 * (attempt + 1)));
      }
    }
  }
  throw lastError!;
});

/// Subscribes Pusher to user + conversation private channels (matches web).
/// Realtime is best-effort: a WebSocket failure must not surface as a failed conversation list.
final chatRealtimeBindingProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  final creds = await ref.watch(chatBootstrapProvider.future);
  final list = await ref.watch(chatConversationsProvider.future);
  final rt = ref.read(chatRealtimeServiceProvider);
  try {
    await rt.start(creds, list.map((e) => e.id).toList());
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[ChatRealtimeBinding] start failed: $e\n$st');
    }
  }
});

final chatMessagesFamilyProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, int>((ref, conversationId) async {
      final creds = await ref.watch(chatBootstrapProvider.future);
      final rt = ref.read(chatRealtimeServiceProvider);
      final repo = ref.read(chatRepositoryProvider);
      return repo.fetchMessages(
        creds,
        conversationId,
        socketId: () => rt.socketId,
      );
    });

/// Call on logout so chat tokens and sockets are dropped.
void invalidateChatProviders(Ref ref) {
  ref.invalidate(chatBootstrapProvider);
  ref.invalidate(chatConversationsProvider);
  ref.invalidate(chatRealtimeBindingProvider);
  ref.invalidate(chatRealtimeServiceProvider);
}
