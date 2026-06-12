import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/push/wayo_push_service.dart';
import '../../data/chat_active_conversation.dart';
import '../../data/chat_repository.dart';
import '../../data/chat_realtime_service.dart';
import '../../domain/chat_conversation.dart';
import '../../domain/chat_credentials.dart';
import '../../domain/chat_message.dart';

/// Set when a fresh login completes — chat HTTP must wait briefly so secure
/// storage + Dio interceptors see the new Wayo-ads access token.
final chatPostLoginGateProvider = StateProvider<DateTime?>(
  (ref) => null,
  name: 'chatPostLoginGateProvider',
);

const Duration _kChatPostLoginMinDelay = Duration(milliseconds: 550);

Future<void> awaitChatPostLoginGate(Ref ref) async {
  final at = ref.read(chatPostLoginGateProvider);
  if (at == null) return;
  final elapsed = DateTime.now().difference(at);
  if (elapsed < _kChatPostLoginMinDelay) {
    await Future<void>.delayed(_kChatPostLoginMinDelay - elapsed);
  }
}

/// Conversation ids treated as read locally until the server list confirms [unreadCount] is 0.
final chatReadConversationOverridesProvider = StateProvider<Set<int>>(
  (ref) => {},
  name: 'chatReadConversationOverridesProvider',
);

int chatEffectiveUnreadCount(ChatConversation c, Set<int> readOverrides) {
  if (readOverrides.contains(c.id)) return 0;
  return c.unreadCount;
}

/// Marks a thread read on chat-service and refreshes the inbox list.
Future<void> markChatConversationRead(
  WidgetRef ref,
  int conversationId, {
  bool optimistic = true,
}) async {
  unawaited(dismissWayoChatNotification('$conversationId'));

  if (optimistic) {
    ref.read(chatReadConversationOverridesProvider.notifier).update(
      (s) => {...s, conversationId},
    );
  }

  final rt = ref.read(chatRealtimeServiceProvider);
  final repo = ref.read(chatRepositoryProvider);
  try {
    final creds = await ref.read(chatBootstrapProvider.future);
    await repo.markRead(
      creds,
      conversationId,
      socketId: () => rt.socketId,
    );
  } catch (e) {
    if (optimistic) {
      ref.read(chatReadConversationOverridesProvider.notifier).update(
        (s) => {...s}..remove(conversationId),
      );
    }
    if (kDebugMode) {
      debugPrint('[Chat] markRead failed conv=$conversationId: $e');
    }
    return;
  }

  ref.invalidate(chatConversationsProvider);
  try {
    final list = await ref.read(chatConversationsProvider.future);
    for (final c in list) {
      if (c.id == conversationId && c.unreadCount == 0) {
        ref.read(chatReadConversationOverridesProvider.notifier).update(
          (s) => {...s}..remove(conversationId),
        );
        break;
      }
    }
  } catch (_) {}
}

/// Unread badge for shell — never throws; errors while chat warms up read as 0.
final chatUnreadCountProvider = Provider<int>((ref) {
  final overrides = ref.watch(chatReadConversationOverridesProvider);
  return ref.watch(chatConversationsProvider).maybeWhen(
    data: (list) => list.fold<int>(
      0,
      (sum, c) => sum + chatEffectiveUnreadCount(c, overrides),
    ),
    orElse: () => 0,
  );
});

final chatRealtimeServiceProvider = Provider.autoDispose<ChatRealtimeService>((
  ref,
) {
  // Chat Reverb errors must not trigger the global offline overlay — the user
  // can still use ads/auth while chat reconnects in the background.
  final s = ChatRealtimeService();
  ref.keepAlive();
  ref.onDispose(s.dispose);
  return s;
});

/// Chat HTTP + bootstrap. [ChatRepository] renews the short-lived chat JWT on
/// 401 by refetching Wayo-ads `GET /api/chat/token` and retrying once.
final Provider<ChatRepository> chatRepositoryProvider =
    Provider<ChatRepository>((ref) {
      return ChatRepository(
        ref.watch(wayoAdsDioProvider),
        refreshChatCredentials: () async {
          ref.invalidate(chatBootstrapProvider);
          return ref.read(chatBootstrapProvider.future);
        },
      );
    });

/// Wayo-ads bootstrap only (cached for session).
final FutureProvider<ChatCredentials> chatBootstrapProvider =
    FutureProvider<ChatCredentials>((ref) async {
      ref.keepAlive();
      await awaitChatPostLoginGate(ref);
      final repo = ref.watch(chatRepositoryProvider);
      return repo.fetchBootstrap();
    });

/// Conversation list from chat-service (Bearer chat JWT).
/// Not `autoDispose`: shell IndexedStack + login prefetch can cancel in-flight loads if disposed too early.
final chatConversationsProvider = FutureProvider<List<ChatConversation>>((
  ref,
) async {
  ref.keepAlive();
  final rt = ref.read(chatRealtimeServiceProvider);
  final repo = ref.read(chatRepositoryProvider);

  await awaitChatPostLoginGate(ref);

  Object? lastError;
  const maxAttempts = 5;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    // Always fetch fresh credentials on each attempt (handles expired tokens).
    final creds = await ref.read(chatBootstrapProvider.future);
    try {
      return await repo.fetchConversations(creds, socketId: () => rt.socketId);
    } on DioException catch (e) {
      lastError = e;
      final code = e.response?.statusCode;
      final is401 = code == 401;
      final isTransientServer =
          code == 500 || code == 502 || code == 503 || code == 504;
      if (is401 || isTransientServer) {
        ref.invalidate(chatBootstrapProvider);
        if (kDebugMode) {
          debugPrint(
            '[Chat] $code on conversations (attempt ${attempt + 1}); '
            'invalidated bootstrap, will retry.',
          );
        }
      }
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(
          Duration(milliseconds: 450 * (attempt + 1)),
        );
      }
    } catch (e) {
      lastError = e;
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(
          Duration(milliseconds: 400 * (attempt + 1)),
        );
      }
    }
  }
  throw lastError!;
});

/// Subscribes Pusher to user + conversation private channels (matches web).
/// Realtime is best-effort: a WebSocket failure must not surface as a failed conversation list.
Timer? _chatRealtimeBindingInvalidateCoalesceTimer;

/// Coalesce bursts of [chatRealtimeBindingProvider] invalidation (retry/reconnect storms).
void scheduleInvalidateChatRealtimeBinding(
  void Function() invalidateBinding, {
  Duration delay = const Duration(milliseconds: 440),
}) {
  _chatRealtimeBindingInvalidateCoalesceTimer?.cancel();
  _chatRealtimeBindingInvalidateCoalesceTimer = Timer(delay, () {
    _chatRealtimeBindingInvalidateCoalesceTimer = null;
    invalidateBinding();
  });
}

/// Cancels any pending coalesced invalidation and invalidates immediately (logout, new conversation).
void invalidateChatRealtimeBindingImmediate(void Function() invalidateBinding) {
  _chatRealtimeBindingInvalidateCoalesceTimer?.cancel();
  _chatRealtimeBindingInvalidateCoalesceTimer = null;
  invalidateBinding();
}

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
      final rt = ref.read(chatRealtimeServiceProvider);
      final repo = ref.read(chatRepositoryProvider);

      Object? lastError;
      for (var attempt = 0; attempt < 3; attempt++) {
        final creds = await ref.read(chatBootstrapProvider.future);
        try {
          return await repo.fetchMessages(
            creds,
            conversationId,
            socketId: () => rt.socketId,
          );
        } on DioException catch (e) {
          lastError = e;
          final is401 = e.response?.statusCode == 401;
          if (is401) {
            ref.invalidate(chatBootstrapProvider);
            if (kDebugMode) {
              debugPrint(
                '[Chat] 401 on messages (attempt ${attempt + 1}); '
                'invalidated bootstrap, will retry with fresh token.',
              );
            }
          }
          if (attempt < 2) {
            await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
          }
        } catch (e) {
          lastError = e;
          if (attempt < 2) {
            await Future<void>.delayed(Duration(milliseconds: 320 * (attempt + 1)));
          }
        }
      }
      throw lastError!;
    });

void _invalidateChatProvidersNow(Ref ref) {
  ref.read(chatPostLoginGateProvider.notifier).state = null;
  ref.read(chatReadConversationOverridesProvider.notifier).state = {};
  unawaited(setActiveChatConversationId(null));
  ref.invalidate(chatBootstrapProvider);
  ref.invalidate(chatConversationsProvider);
  invalidateChatRealtimeBindingImmediate(
    () => ref.invalidate(chatRealtimeBindingProvider),
  );
  ref.invalidate(chatRealtimeServiceProvider);
}

/// Immediate invalidation — use at login before setting [AuthAuthenticated].
void invalidateChatProvidersSync(Ref ref) {
  _invalidateChatProvidersNow(ref);
}

/// Call on logout so chat tokens and sockets are dropped.
///
/// Uses microtask scheduling to avoid [CircularDependencyError] when called
/// from within [AuthNotifier] (since chat providers may depend on auth state).
void invalidateChatProviders(Ref ref) {
  Future.microtask(() => _invalidateChatProvidersNow(ref));
}
