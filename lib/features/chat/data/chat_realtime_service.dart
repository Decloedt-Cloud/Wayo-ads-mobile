import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';

import '../domain/chat_credentials.dart';

sealed class ChatRealtimeEvent {
  const ChatRealtimeEvent();
}

/// User channel `message.sent` — refresh inbox (same as web).
final class ChatInboxRefreshEvent extends ChatRealtimeEvent {
  const ChatInboxRefreshEvent();
}

final class ChatMessageSentEvent extends ChatRealtimeEvent {
  const ChatMessageSentEvent(this.conversationId, this.rawMessage);

  final int conversationId;
  final Map<String, dynamic> rawMessage;
}

final class ChatTypingEvent extends ChatRealtimeEvent {
  const ChatTypingEvent({
    required this.conversationId,
    required this.userName,
    required this.isTyping,
  });

  final int conversationId;
  final String userName;
  final bool isTyping;
}

final class ChatMessageReadEvent extends ChatRealtimeEvent {
  const ChatMessageReadEvent({
    required this.conversationId,
    required this.readerId,
    required this.readAt,
  });

  final int conversationId;
  final int readerId;
  final String readAt;
}

final class ChatMessageDeletedEvent extends ChatRealtimeEvent {
  const ChatMessageDeletedEvent({
    required this.conversationId,
    required this.messageId,
  });

  final int conversationId;
  final int messageId;
}

final class ChatMessageEditedEvent extends ChatRealtimeEvent {
  const ChatMessageEditedEvent({
    required this.conversationId,
    required this.rawMessage,
  });

  final int conversationId;
  final Map<String, dynamic> rawMessage;
}

/// Laravel Reverb / Pusher client for **chat-service** only (separate from [WayoReverbRealtime] singleton).
final class ChatRealtimeService {
  ChatRealtimeService({this.onConnectionError});

  /// Hook called whenever the WebSocket/Pusher layer reports a connection
  /// error (typically DNS / TCP / handshake failure). Wired by the Riverpod
  /// provider to `ConnectivityService.reportRemoteFailure` so the offline
  /// popup appears within ~1 s instead of waiting for the periodic probe.
  final void Function(Object error)? onConnectionError;

  /// Chat-service user ids currently seen on `presence-global.{appId}` (same as Wayo-ads `ChatPresenceContext`).
  final ValueNotifier<Set<int>> onlineChatUserIds = ValueNotifier<Set<int>>(
    <int>{},
  );

  PusherChannelsClient? _client;
  final List<StreamSubscription<dynamic>> _subs = [];
  final Set<String> _subscribedConversationChannels = {};
  String? _socketId;
  int? _boundChatUserId;
  String? _boundAppId;
  String? _boundToken;

  final StreamController<ChatRealtimeEvent> _events =
      StreamController<ChatRealtimeEvent>.broadcast();

  Stream<ChatRealtimeEvent> get events => _events.stream;

  String? get socketId => _socketId;

  Future<void> start(ChatCredentials creds, List<int> conversationIds) async {
    final canSoftResync =
        _client != null &&
        _boundChatUserId == creds.chatUserId &&
        _boundAppId == creds.appId &&
        _boundToken == creds.token;
    if (canSoftResync) {
      await _syncConversationChannels(
        creds,
        conversationIds,
        _delegateFor(creds),
      );
      return;
    }
    await stop();
    _boundChatUserId = creds.chatUserId;
    _boundAppId = creds.appId;
    _boundToken = creds.token;
    final rt = creds.realtime;
    if (rt.key.isEmpty || rt.wsHost.isEmpty || rt.authEndpoint.isEmpty) {
      return;
    }

    final scheme = rt.forceTLS ? 'wss' : 'ws';
    final port = rt.forceTLS ? rt.wssPort : rt.wsPort;
    final options = PusherChannelsOptions.fromHost(
      scheme: scheme,
      host: rt.wsHost,
      key: rt.key,
      port: port,
    );

    _client = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) {
        if (kDebugMode) {
          debugPrint('[ChatRealtime] connection error: $exception');
        }
        try {
          onConnectionError?.call(exception);
        } catch (_) {}
        Future<void>.delayed(const Duration(seconds: 2), refresh);
      },
    );

    _subs.add(
      _client!.eventStream.listen((PusherChannelsReadEvent e) {
        if (e.name == 'pusher:connection_established') {
          final map = e.tryGetDataAsMap();
          final sid = map?['socket_id']?.toString();
          if (sid != null && sid.isNotEmpty) {
            _socketId = sid;
          }
        }
      }),
    );

    await _client!.connect();

    final delegate = _delegateFor(creds);

    void bindUserChannel(String channelName) {
      final ch = _client!.privateChannel(
        channelName,
        authorizationDelegate: delegate,
      );
      ch.subscribe();
      _subs.add(
        ch.bind('message.sent').listen((_) {
          _events.add(const ChatInboxRefreshEvent());
        }),
      );
      _subs.add(
        ch.bind('user.updated').listen((_) {
          _events.add(const ChatInboxRefreshEvent());
        }),
      );
    }

    bindUserChannel('private-user.${creds.chatUserId}.${creds.appId}');
    bindUserChannel('private-user.${creds.chatUserId}.wayo');

    _subscribePresenceGlobal(creds);

    await _syncConversationChannels(creds, conversationIds, delegate);
  }

  void _subscribePresenceGlobal(ChatCredentials creds) {
    final client = _client;
    if (client == null) {
      return;
    }

    final presence = client.presenceChannel(
      'presence-global.${creds.appId}',
      authorizationDelegate: _presenceDelegateFor(creds),
    );
    presence.subscribe();

    _subs.add(
      presence
          .bind(Channel.subscriptionSucceededEventName)
          .listen(_onPresenceSubscriptionSucceeded),
    );
    _subs.add(presence.whenMemberAdded().listen(_onPresenceMemberAdded));
    _subs.add(presence.whenMemberRemoved().listen(_onPresenceMemberRemoved));
  }

  EndpointAuthorizableChannelTokenAuthorizationDelegate<
    PresenceChannelAuthorizationData
  >
  _presenceDelegateFor(ChatCredentials creds) {
    final rt = creds.realtime;
    return EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
      authorizationEndpoint: Uri.parse(rt.authEndpoint),
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer ${creds.token}',
        'X-Application-ID': creds.appId,
      },
    );
  }

  void _onPresenceSubscriptionSucceeded(ChannelReadEvent ev) {
    final data = ev.tryGetDataAsMap();
    if (data == null) {
      return;
    }
    onlineChatUserIds.value = _idsFromPresencePayload(data);
  }

  void _onPresenceMemberAdded(ChannelReadEvent ev) {
    final id = _userIdFromPresenceMemberMap(ev.tryGetDataAsMap());
    if (id == null) {
      return;
    }
    onlineChatUserIds.value = {...onlineChatUserIds.value, id};
  }

  void _onPresenceMemberRemoved(ChannelReadEvent ev) {
    final id = _userIdFromPresenceMemberMap(ev.tryGetDataAsMap());
    if (id == null) {
      return;
    }
    final next = {...onlineChatUserIds.value}..remove(id);
    onlineChatUserIds.value = next;
  }

  int? _userIdFromPresenceMemberMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final v = m['id'] ?? m['user_id'];
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  Set<int> _idsFromPresencePayload(Map<String, dynamic> data) {
    final out = <int>{};
    final presence = data['presence'];
    if (presence is Map) {
      final hash = presence['hash'];
      if (hash is Map) {
        for (final e in hash.entries) {
          final keyId = int.tryParse(e.key.toString());
          if (keyId != null) {
            out.add(keyId);
          }
          final val = e.value;
          if (val is Map) {
            final inner = _userIdFromPresenceMemberMap(
              Map<String, dynamic>.from(val),
            );
            if (inner != null) {
              out.add(inner);
            }
          }
        }
      }
    }
    return out;
  }

  Future<void> updateConversationSubscriptions(
    ChatCredentials creds,
    List<int> conversationIds,
  ) async {
    if (_client == null) {
      return;
    }
    await _syncConversationChannels(
      creds,
      conversationIds,
      _delegateFor(creds),
    );
  }

  EndpointAuthorizableChannelTokenAuthorizationDelegate<
    PrivateChannelAuthorizationData
  >
  _delegateFor(ChatCredentials creds) {
    final rt = creds.realtime;
    return EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
      authorizationEndpoint: Uri.parse(rt.authEndpoint),
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer ${creds.token}',
        'X-Application-ID': creds.appId,
      },
    );
  }

  Future<void> _syncConversationChannels(
    ChatCredentials creds,
    List<int> ids,
    EndpointAuthorizableChannelTokenAuthorizationDelegate<
      PrivateChannelAuthorizationData
    >
    delegate,
  ) async {
    final client = _client;
    if (client == null) {
      return;
    }

    final wanted = ids
        .map((id) => 'private-conversation.$id.${creds.appId}')
        .toSet();
    final toRemove = _subscribedConversationChannels.difference(wanted);
    for (final name in toRemove) {
      try {
        final ch = client.privateChannel(name, authorizationDelegate: delegate);
        ch.unsubscribe();
      } catch (_) {}
      _subscribedConversationChannels.remove(name);
    }

    for (final id in ids) {
      final name = 'private-conversation.$id.${creds.appId}';
      if (_subscribedConversationChannels.contains(name)) {
        continue;
      }

      final ch = client.privateChannel(name, authorizationDelegate: delegate);
      ch.subscribe();
      _subscribedConversationChannels.add(name);

      int convoId() => id;

      void emitMap(String eventName, Map<String, dynamic>? map) {
        if (map == null) {
          return;
        }
        switch (eventName) {
          case 'message.sent':
            final m = _unwrapMessage(map['message'] ?? map);
            if (m != null) {
              _events.add(ChatMessageSentEvent(convoId(), m));
            }
            _events.add(const ChatInboxRefreshEvent());
            return;
          case 'user.typing':
            final u = map['user'];
            final uid = u is Map<String, dynamic>
                ? (u['id'] as num?)?.toInt()
                : null;
            if (uid == null || uid == creds.chatUserId) {
              return;
            }
            final isTyping = map['is_typing'] == true;
            final n = u is Map<String, dynamic> ? '${u['name'] ?? ''}' : '';
            _events.add(
              ChatTypingEvent(
                conversationId: convoId(),
                userName: n,
                isTyping: isTyping,
              ),
            );
            return;
          case 'message.read':
            final reader = map['reader'];
            final rid = reader is Map<String, dynamic>
                ? (reader['id'] as num?)?.toInt()
                : null;
            final readAt = map['read_at'] as String?;
            if (rid == null || readAt == null || rid == creds.chatUserId) {
              return;
            }
            _events.add(
              ChatMessageReadEvent(
                conversationId: convoId(),
                readerId: rid,
                readAt: readAt,
              ),
            );
            return;
          case 'message.deleted':
            final mid = map['message_id'];
            if (mid is num) {
              _events.add(
                ChatMessageDeletedEvent(
                  conversationId: convoId(),
                  messageId: mid.toInt(),
                ),
              );
            }
            _events.add(const ChatInboxRefreshEvent());
            return;
          case 'message.edited':
            final m = _unwrapMessage(map['message'] ?? map);
            if (m != null) {
              _events.add(
                ChatMessageEditedEvent(
                  conversationId: convoId(),
                  rawMessage: m,
                ),
              );
            }
            return;
          default:
            return;
        }
      }

      for (final eventName in const [
        'message.sent',
        'user.typing',
        'message.read',
        'message.deleted',
        'message.edited',
      ]) {
        _subs.add(
          ch.bind(eventName).listen((ChannelReadEvent ev) {
            final raw = ev.data;
            Map<String, dynamic>? map;
            if (raw is String) {
              map = jsonDecode(raw) as Map<String, dynamic>?;
            } else if (raw is Map<String, dynamic>) {
              map = raw;
            } else if (raw is Map) {
              map = Map<String, dynamic>.from(raw);
            }
            emitMap(eventName, map);
          }),
        );
      }
    }
  }

  Map<String, dynamic>? _unwrapMessage(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String) {
      try {
        return jsonDecode(v) as Map<String, dynamic>?;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> stop() async {
    onlineChatUserIds.value = <int>{};
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _subscribedConversationChannels.clear();
    _socketId = null;
    _boundChatUserId = null;
    _boundAppId = null;
    _boundToken = null;
    final c = _client;
    _client = null;
    if (c != null) {
      try {
        await c.disconnect();
      } catch (_) {}
      try {
        c.dispose();
      } catch (_) {}
    }
  }

  Future<void> dispose() => stop();
}
