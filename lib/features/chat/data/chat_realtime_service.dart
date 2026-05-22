import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';

import '../../../core/observability/app_log.dart';
import 'chat_pusher_dio_authorization_delegate.dart';
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

  /// Optional hook when the WebSocket/Pusher layer reports a connection error.
  /// Not wired to the global offline overlay (chat can fail while ads API works).
  final void Function(Object error)? onConnectionError;

  /// Chat-service user ids on **`presence-chat.{appId}`** — same presence channel as
  /// Wayo-ads web (`ChatPresenceContext`). Legacy `presence-global` must not be used
  /// for product UI; it splits online state between clients.
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
        } else if (e.name == 'pusher:error') {
          final d = e.tryGetDataAsMap();
          if (kDebugMode) {
            debugPrint('[ChatRealtime] pusher:error data=$d');
          }
          wayoDiagPrint('[ChatRealtime] pusher:error data=$d', name: 'wayo.chat');
        }
      }),
    );

    // Private/presence auth needs a non-null `socket_id` (dart_pusher_channels
    // returns early otherwise). Wait for `pusher:connection_established`; we
    // subscribe to [eventStream] *before* [connect] so the broadcast stream
    // does not drop the first frame.
    final connectionEstablishedFuture = _client!.eventStream.firstWhere(
      (e) => e.name == 'pusher:connection_established',
    );

    await _client!.connect();

    try {
      await connectionEstablishedFuture.timeout(const Duration(seconds: 35));
    } on TimeoutException catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[ChatRealtime] $e — continuing subscribe attempts.\n$st',
        );
      }
    }

    // Let downstream microtasks settle (socket id is set synchronously inside
    // the client before [connect] resolves, but authorize calls are async).
    await Future<void>.delayed(Duration.zero);

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
      'presence-chat.${creds.appId}',
      authorizationDelegate: _presenceDelegateFor(creds),
    );
    presence.subscribe();

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!identical(_client, client)) return;
        presence.subscribe();
      }),
    );
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 2000), () {
        if (!identical(_client, client)) return;
        presence.subscribe();
      }),
    );

    _subs.add(
      presence.bind(Channel.subscriptionErrorEventName).listen((ev) {
        final d = ev.data;
        if (kDebugMode) {
          debugPrint(
            '[ChatRealtime] presence subscription_error (${ev.channelName}) data=$d',
          );
        }
        wayoDiagPrint(
          '[ChatRealtime] presence subscription_error (${ev.channelName}) data=$d',
          name: 'wayo.chat',
        );
      }),
    );
    _subs.add(
      presence
          .bind(Channel.subscriptionSucceededEventName)
          .listen(_onPresenceSubscriptionSucceeded),
    );
    _subs.add(presence.whenMemberAdded().listen(_onPresenceMemberAdded));
    _subs.add(presence.whenMemberRemoved().listen(_onPresenceMemberRemoved));
  }

  EndpointAuthorizableChannelAuthorizationDelegate<
      PresenceChannelAuthorizationData>
      _presenceDelegateFor(ChatCredentials creds) {
    final rt = creds.realtime;
    return ChatPusherPresenceDioAuthDelegate(
      authorizationEndpoint: Uri.parse(rt.authEndpoint),
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer ${creds.token}',
        'X-Application-ID': creds.appId,
      },
      onAuthFailed: (ex, st) => _emitBroadcastAuthDiag(
        'presence /broadcasting/auth',
        ex,
        st,
      ),
    );
  }

  void _onPresenceSubscriptionSucceeded(ChannelReadEvent ev) {
    final data = _presenceEventRoot(ev.tryGetDataAsMap()) ??
        _presenceEventRoot(ev.data);
    if (data == null) {
      return;
    }
    final next = _idsFromPresencePayload(data);
    onlineChatUserIds.value = next;
  }

  void _onPresenceMemberAdded(ChannelReadEvent ev) {
    final raw =
        _presenceEventRoot(ev.tryGetDataAsMap()) ?? _presenceEventRoot(ev.data);
    final id = _userIdFromPresenceMemberMap(raw);
    if (id == null) {
      return;
    }
    onlineChatUserIds.value = {...onlineChatUserIds.value, id};
  }

  void _onPresenceMemberRemoved(ChannelReadEvent ev) {
    final raw =
        _presenceEventRoot(ev.tryGetDataAsMap()) ?? _presenceEventRoot(ev.data);
    final id = _userIdFromPresenceMemberMap(raw);
    if (id == null) {
      return;
    }
    final next = {...onlineChatUserIds.value}..remove(id);
    onlineChatUserIds.value = next;
  }

  int? _userIdFromPresenceMemberMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    dynamic v =
        m['user_id'] ??
        m['userId'] ??
        m['id'] ??
        m['chat_user_id'] ??
        m['chatUserId'] ??
        m['wayo_external_user_id'] ??
        m['external_user_id'];
    if (v is num) return v.toInt();
    final fromRoot = int.tryParse('$v');
    if (fromRoot != null) {
      return fromRoot;
    }
    final info = _mapFromDynamic(m['user_info'] ?? m['userInfo']);
    if (info == null || identical(info, m)) return null;
    return _userIdFromPresenceMemberMap(info);
  }

  Map<String, dynamic>? _mapFromDynamic(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  /// Repeatedly decodes JSON text into a map when servers double-encode payloads.
  Map<String, dynamic>? _jsonMapRecursive(dynamic raw, [int depth = 0]) {
    const maxDepth = 10;
    if (depth > maxDepth || raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      try {
        final decoded = jsonDecode(t);
        return _jsonMapRecursive(decoded, depth + 1);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _mapLooksLikePresenceSnapshot(Map<String, dynamic> x) =>
      x.containsKey('presence') ||
      x.containsKey('Presence') ||
      x.containsKey('hash') ||
      x.containsKey('Hash') ||
      x.containsKey('ids') ||
      x.containsKey('Ids');

  /// Normalizes `{ presence/hash/… }`, nested JSON strings, and `{ data: "…encoded…" }` shells.
  Map<String, dynamic>? _presenceEventRoot(dynamic raw, [int unwrapShell = 0]) {
    if (unwrapShell > 8 || raw == null) return null;
    Map<String, dynamic>? root = _jsonMapRecursive(raw);
    root ??= _mapFromDynamic(raw);
    if (root == null) return null;
    var m = Map<String, dynamic>.from(root);

    if (!_mapLooksLikePresenceSnapshot(m)) {
      final nested = m['data'] ?? m['Data'];
      if (nested != null) {
        final inner = _presenceEventRoot(nested, unwrapShell + 1);
        if (inner != null) {
          m = inner;
        }
      }
    }

    for (final pk in ['presence', 'Presence']) {
      final v = m[pk];
      if (v is String) {
        final decoded = _jsonMapRecursive(v);
        if (decoded != null) {
          m[pk] = decoded;
        }
      }
    }

    dynamic presDyn = m['presence'] ?? m['Presence'];
    String? presKey = m.containsKey('presence')
        ? 'presence'
        : (m.containsKey('Presence') ? 'Presence' : null);
    Map<String, dynamic>? pres;
    if (presDyn is Map<String, dynamic>) {
      pres = Map<String, dynamic>.from(presDyn);
    } else if (presDyn is Map) {
      pres = Map<String, dynamic>.from(presDyn);
    }

    if (pres != null && presKey != null) {
      for (final hk in ['hash', 'Hash']) {
        final h = pres[hk];
        if (h is String) {
          final decoded = _jsonMapRecursive(h);
          if (decoded != null) {
            pres[hk] = decoded;
          }
        }
      }
      m[presKey] = pres;
    }

    return m;
  }

  Set<int> _idsFromPresencePayload(Map<String, dynamic> data) {
    final rooted = _presenceEventRoot(Map<String, dynamic>.from(data)) ??
        Map<String, dynamic>.from(data);

    final out = <int>{};
    Map<String, dynamic>? presence =
        _mapFromDynamic(rooted['presence'] ?? rooted['Presence']);

    presence ??=
        rooted.containsKey('hash') ||
            rooted.containsKey('Hash') ||
            rooted.containsKey('ids') ||
            rooted.containsKey('Ids')
        ? rooted
        : null;

    if (presence != null) {
      final ids = presence['ids'] ?? presence['Ids'];
      if (ids is List) {
        for (final e in ids) {
          if (e is num) {
            out.add(e.toInt());
          } else {
            final p = int.tryParse('$e');
            if (p != null) {
              out.add(p);
            }
          }
        }
      }

      final hashRaw = presence['hash'] ?? presence['Hash'];
      final hash = _mapFromDynamic(hashRaw);
      if (hash != null) {
        for (final e in hash.entries) {
          final keyId = int.tryParse(e.key.toString());
          if (keyId != null) {
            out.add(keyId);
          }
          final nested = _mapFromDynamic(e.value);
          if (nested != null) {
            final inner = _userIdFromPresenceMemberMap(nested);
            if (inner != null) {
              out.add(inner);
            }
          }
        }
      }
    }

    // Some Reverb payloads expose ids only at the root (no `presence` wrapper).
    if (out.isEmpty) {
      final rootHash = _mapFromDynamic(rooted['hash'] ?? rooted['Hash']);
      if (rootHash != null &&
          rootHash != _mapFromDynamic(rooted['presence'] ?? rooted['Presence'])) {
        for (final e in rootHash.entries) {
          final keyId = int.tryParse(e.key.toString());
          if (keyId != null) {
            out.add(keyId);
          }
          final nested = _mapFromDynamic(e.value);
          if (nested != null) {
            final inner = _userIdFromPresenceMemberMap(nested);
            if (inner != null) {
              out.add(inner);
            }
          }
        }
      }
      final ids = rooted['ids'] ?? rooted['Ids'];
      if (ids is List) {
        for (final e in ids) {
          if (e is num) {
            out.add(e.toInt());
          } else {
            final p = int.tryParse('$e');
            if (p != null) {
              out.add(p);
            }
          }
        }
      }
    }

    return out;
  }

  Map<String, dynamic>? _enrichConversationBroadcastPayload(
    Map<String, dynamic> map,
  ) {
    final innerRaw = map['message'];
    if (innerRaw is! Map) {
      return null;
    }
    final enriched = Map<String, dynamic>.from(innerRaw);
    final sender = map['sender'];
    final hasUserEnvelope =
        enriched['user'] != null || enriched['sender'] != null;
    if (!hasUserEnvelope && sender is Map<String, dynamic>) {
      // chat-service puts `sender` next to `message` (REST embeds `user` on the row).
      enriched['user'] = sender;
    }
    return enriched;
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

  EndpointAuthorizableChannelAuthorizationDelegate<
      PrivateChannelAuthorizationData>
      _delegateFor(ChatCredentials creds) {
    final rt = creds.realtime;
    return ChatPusherPrivateDioAuthDelegate(
      authorizationEndpoint: Uri.parse(rt.authEndpoint),
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer ${creds.token}',
        'X-Application-ID': creds.appId,
      },
      onAuthFailed: (ex, st) => _emitBroadcastAuthDiag(
        'private /broadcasting/auth',
        ex,
        st,
      ),
    );
  }

  static void _emitBroadcastAuthDiag(
    String context,
    Object exception,
    StackTrace trace,
  ) {
    final msg =
        '[ChatRealtime] broadcasting auth FAILED ($context): $exception '
        '| stack: $trace';
    if (kDebugMode) {
      debugPrint(msg);
    }
    wayoDiagPrint(msg, name: 'wayo.chat');
  }

  Future<void> _syncConversationChannels(
    ChatCredentials creds,
    List<int> ids,
    EndpointAuthorizableChannelAuthorizationDelegate<
        PrivateChannelAuthorizationData>
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
            final m =
                _unwrapMessage(
                  _enrichConversationBroadcastPayload(map) ??
                      map['message'] ??
                      map,
                );
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
            final m =
                _unwrapMessage(
                  _enrichConversationBroadcastPayload(map) ??
                      map['message'] ??
                      map,
                );
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
