import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mobile_push_route_utils.dart';

/// Prefs keys for navigation / mark-read deferred from push (incl. notification action taps).
const kWayoPushPendingRouteKey = 'wayo.push.pending_route';
const kWayoPushPendingMarkReadKey = 'wayo.push.pending_mark_read';
const kWayoPushPendingQuickReplyKey = 'wayo.push.pending_quick_reply';

/// Short-lived hint so we don't show a tray notification when FCM echoes back the
/// user's own inline reply from the notification shade (same conversation + body).
const kWayoPushInlineReplyEchoGuardKey = 'wayo.push.inline_reply_echo_guard';

/// Normalizes body text for comparing tray payloads with stored inline replies.
String normalizeTrayEchoText(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Strips trailing ellipsis markers often added by notification previews (`…`, `...`).
String stripNotificationPreviewEllipsis(String s) {
  var t = s.trimRight();
  for (;;) {
    final before = t;
    if (t.endsWith('…')) {
      t = t.substring(0, t.length - 1).trimRight();
    } else if (t.endsWith('...')) {
      t = t.substring(0, t.length - 3).trimRight();
    }
    if (t == before) break;
  }
  return t;
}

/// Loose match between FCM/chat preview body and the text just sent from the composer / tray.
bool trayEchoBodiesMatch(String incomingRaw, String storedNormalized) {
  final incoming =
      normalizeTrayEchoText(stripNotificationPreviewEllipsis(incomingRaw));
  if (incoming.isEmpty) return false;

  if (incoming == storedNormalized) return true;

  final lcIn = incoming.toLowerCase();
  final lcStored = storedNormalized.toLowerCase();
  if (lcIn == lcStored) return true;

  /// Preview often truncates longer bodies to an initial substring.
  if (incoming.length >= 3 && lcStored.startsWith(lcIn)) return true;
  if (storedNormalized.length >= 3 && lcIn.startsWith(lcStored)) return true;

  return false;
}

/// Clears the echo guard after a failed send so a later unrelated banner is not swallowed.
Future<void> clearInlineReplyEchoGuard() async {
  final p = await SharedPreferences.getInstance();
  await p.remove(kWayoPushInlineReplyEchoGuardKey);
}

/// Records outgoing message text so [shouldSuppressChatTrayEcho] can hide FCM echoes
/// (notification shade reply **or** composer sends inside the thread).
Future<void> recordInlineReplyEchoGuard({
  required String conversationId,
  required String messageText,
}) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(
    kWayoPushInlineReplyEchoGuardKey,
    jsonEncode(<String, dynamic>{
      'conversationId': conversationId.trim(),
      'text': normalizeTrayEchoText(messageText),
      'sentAtMs': DateTime.now().millisecondsSinceEpoch,
    }),
  );
}

/// Returns true when this incoming chat notification should not open/update the tray
/// because it matches a reply the user just sent from [Répondre] on Android.
Future<bool> shouldSuppressChatTrayEcho(
  WayoChatPushPayload chat,
  String incomingBody,
) async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(kWayoPushInlineReplyEchoGuardKey);
  if (raw == null || raw.isEmpty) return false;

  Map<String, dynamic>? map;
  try {
    final d = jsonDecode(raw);
    if (d is Map) {
      map = Map<String, dynamic>.from(d);
    }
  } catch (_) {}

  if (map == null) {
    await p.remove(kWayoPushInlineReplyEchoGuardKey);
    return false;
  }

  final storedConv = map['conversationId']?.toString().trim() ?? '';
  final storedText = map['text']?.toString() ?? '';
  final sentMs = map['sentAtMs'];
  final sentAt = sentMs is num ? sentMs.toInt() : int.tryParse('$sentMs') ?? 0;

  final ageMs = DateTime.now().millisecondsSinceEpoch - sentAt;
  /// FCM latency can exceed a few seconds; keep a generous window.
  const maxEchoGuardAgeMs = 120000;
  if (sentAt <= 0 || ageMs > maxEchoGuardAgeMs || storedConv.isEmpty) {
    await p.remove(kWayoPushInlineReplyEchoGuardKey);
    return false;
  }

  if (storedConv != chat.conversationId.trim()) {
    return false;
  }

  if (!trayEchoBodiesMatch(incomingBody, storedText)) {
    return false;
  }

  await p.remove(kWayoPushInlineReplyEchoGuardKey);
  return true;
}

/// Parse FCM / local-notification payload (JSON) for chat deep links.
final class WayoChatPushPayload {
  const WayoChatPushPayload({
    required this.conversationId,
    required this.notificationId,
    this.title,
    this.body,
  });

  final String conversationId;
  final String notificationId;
  final String? title;
  final String? body;

  static String? _trimmed(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Shared parsing for tray JSON + FCM data maps (camelCase / snake_case).
  static WayoChatPushPayload? _fromKeyedMap(Map<String, dynamic> m) {
    final conv =
        _trimmed(m['conversationId']) ?? _trimmed(m['conversation_id']);
    final nid =
        _trimmed(m['notificationId']) ?? _trimmed(m['notification_id']);
    if (conv == null || nid == null) return null;

    final kind = _trimmed(m['kind'])?.toLowerCase();
    final type = _trimmed(m['type'])?.toLowerCase();
    if (kind != null &&
        kind.isNotEmpty &&
        kind != 'chat' &&
        type != 'chat') {
      return null;
    }

    return WayoChatPushPayload(
      conversationId: conv,
      notificationId: nid,
      title: _trimmed(m['title']),
      body: _trimmed(m['body']),
    );
  }

  static WayoChatPushPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return _fromKeyedMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  /// Accepts [RemoteMessage.data] (`Map<String, dynamic>` on current [firebase_messaging]).
  static WayoChatPushPayload? fromMessageData(Map<String, dynamic> data) {
    final m = Map<String, dynamic>.from(data);
    return _fromKeyedMap(m);
  }

  String toLocalNotificationPayload() => jsonEncode({
        'kind': 'chat',
        'conversationId': conversationId,
        'notificationId': notificationId,
        if (title != null && title!.isNotEmpty) 'title': title,
        if (body != null && body!.isNotEmpty) 'body': body,
      });

  /// Opens thread; [forReply] focuses composer (after credentials load).
  /// [peer] in query mirrors push title so the header shows the sender before inbox loads.
  String route({bool forReply = false}) {
    final params = <String, String>{};
    if (forReply) params['reply'] = '1';
    final peer = title?.trim();
    if (peer != null && peer.isNotEmpty) {
      params['peer'] = peer;
    }
    return Uri(
      path: '/chat/thread/$conversationId',
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }
}

/// Superadmin payouts tab deep link (FCM + in-app navigation).
const kSuperadminWithdrawalsRoute = '/superadmin/withdrawals';

/// FCM / tray payloads with a deep-link [route] (withdrawals, admin alerts, etc.).
final class WayoRoutePushPayload {
  const WayoRoutePushPayload({
    required this.route,
    this.title,
    this.body,
  });

  final String route;
  final String? title;
  final String? body;

  static String? _trimmed(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static Map<String, dynamic> _flattenFcmData(Map<String, dynamic> data) {
    final m = Map<String, dynamic>.from(data);
    final nested = m['data'];
    if (nested is String) {
      try {
        final d = jsonDecode(nested);
        if (d is Map) m.addAll(Map<String, dynamic>.from(d));
      } catch (_) {}
    } else if (nested is Map) {
      m.addAll(Map<String, dynamic>.from(nested));
    }
    final meta = m['metadata'];
    if (meta is String && meta.trim().isNotEmpty) {
      try {
        final d = jsonDecode(meta);
        if (d is Map) m.addAll(Map<String, dynamic>.from(d));
      } catch (_) {}
    } else if (meta is Map) {
      m.addAll(Map<String, dynamic>.from(meta));
    }
    return m;
  }

  static String? _resolveRoute(Map<String, dynamic> m) {
    final direct = _trimmed(m['route']);
    if (direct != null && direct.startsWith('/')) return direct;

    final type = (_trimmed(m['type']) ??
            _trimmed(m['notificationType']) ??
            _trimmed(m['notification_type']) ??
            '')
        .toLowerCase();
    if (type.contains('withdraw')) return kSuperadminWithdrawalsRoute;

    final actionUrl =
        _trimmed(m['actionUrl']) ?? _trimmed(m['action_url']);
    if (actionUrl != null) {
      final normalized = normalizeMobilePushRoute(
        actionUrl.startsWith('/')
            ? actionUrl
            : (() {
                try {
                  return Uri.parse(actionUrl).path;
                } catch (_) {
                  return actionUrl;
                }
              })(),
      );
      if (normalized != null) return normalized;
    }

    final campId =
        _trimmed(m['campaignId']) ?? _trimmed(m['campaign_id']);
    if (campId != null && campId.isNotEmpty) {
      if (type.contains('campaign_activated') || type.contains('new_campaign')) {
        return '/creator/campaigns/$campId';
      }
      if (type.contains('application') || type.contains('creator_applied')) {
        final appId =
            _trimmed(m['applicationId']) ?? _trimmed(m['application_id']);
        if (appId != null && appId.isNotEmpty) {
          return '/creator/campaigns/$campId/application';
        }
      }
      if (type.contains('creator')) {
        return '/creator/campaigns/$campId';
      }
      return '/campaigns/$campId';
    }

    if (type.contains('wallet') ||
        type.contains('deposit') ||
        type.contains('credit')) {
      return '/wallet';
    }
    if (type.contains('invoice')) return '/invoices';
    if (type.contains('chat') || type.contains('message')) return '/chat';
    if (type.contains('campaign')) return '/campaigns';

    return null;
  }

  static WayoRoutePushPayload? fromMessageData(Map<String, dynamic> data) {
    final flat = _flattenFcmData(data);
    if (WayoChatPushPayload.fromMessageData(flat) != null) return null;
    final route = _resolveRoute(flat);
    if (route == null) return null;
    return WayoRoutePushPayload(
      route: route,
      title: _trimmed(flat['title']),
      body: _trimmed(flat['body']),
    );
  }

  static WayoRoutePushPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final trimmed = raw.trim();
    if (trimmed.startsWith('/')) {
      return WayoRoutePushPayload(route: trimmed);
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded);
        final route = _resolveRoute(m);
        if (route == null) return null;
        return WayoRoutePushPayload(
          route: route,
          title: _trimmed(m['title']),
          body: _trimmed(m['body']),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Payload stored on the local notification for tap handling.
  String toLocalNotificationPayload() => route;
}

/// Resolves a navigation route from FCM data or a raw tray payload string.
String? resolveWayoPushRoute({
  Map<String, dynamic>? data,
  String? payload,
}) {
  if (data != null) {
    final fromData = WayoRoutePushPayload.fromMessageData(data);
    if (fromData != null) return fromData.route;
  }
  final fromPayload = WayoRoutePushPayload.tryParse(payload);
  if (fromPayload != null) return fromPayload.route;
  final p = payload?.trim();
  if (p != null && p.startsWith('/')) return p;
  return null;
}

Map<String, dynamic> _flattenFcmPayloadMap(Map<String, dynamic> data) {
  final m = Map<String, dynamic>.from(data);
  final nested = m['data'];
  if (nested is String) {
    try {
      final d = jsonDecode(nested);
      if (d is Map) m.addAll(Map<String, dynamic>.from(d));
    } catch (_) {}
  } else if (nested is Map) {
    m.addAll(Map<String, dynamic>.from(nested));
  }
  final meta = m['metadata'];
  if (meta is String && meta.trim().isNotEmpty) {
    try {
      final d = jsonDecode(meta);
      if (d is Map) m.addAll(Map<String, dynamic>.from(d));
    } catch (_) {}
  } else if (meta is Map) {
    m.addAll(Map<String, dynamic>.from(meta));
  }
  return m;
}

String? _trimmedPayloadField(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// Creator YouTube OAuth / connect alerts (`YOUTUBE_DISCONNECTED`, etc.) — no mobile FCM tray.
bool isCreatorYoutubeConnectFcmPayload(Map<String, dynamic> data) {
  final flat = _flattenFcmPayloadMap(data);

  final type = (_trimmedPayloadField(flat['type']) ??
          _trimmedPayloadField(flat['notificationType']) ??
          _trimmedPayloadField(flat['notification_type']) ??
          '')
      .toUpperCase();
  if (type == 'YOUTUBE_DISCONNECTED' || type.contains('YOUTUBE')) {
    return true;
  }

  final actionUrl = (_trimmedPayloadField(flat['actionUrl']) ??
          _trimmedPayloadField(flat['action_url']) ??
          '')
      .toLowerCase();
  if (actionUrl.contains('youtube') || actionUrl.contains('connect-youtube')) {
    return true;
  }

  final route =
      (_trimmedPayloadField(flat['route']) ?? '').toLowerCase();
  if (route.contains('youtube') || route.contains('connect-youtube')) {
    return true;
  }

  final platform =
      (_trimmedPayloadField(flat['platform']) ?? '').toUpperCase();
  if (platform == 'YOUTUBE' && type.contains('CREDENTIAL')) {
    return true;
  }

  final title = (_trimmedPayloadField(flat['title']) ?? '').toLowerCase();
  if (title.contains('youtube') &&
      (title.contains('disconnect') ||
          title.contains('connect') ||
          title.contains('channel'))) {
    return true;
  }

  return false;
}

/// Whether a Reverb / notification payload refers to a creator withdrawal.
bool isWithdrawalNotificationPayload(Object? raw) {
  Map<String, dynamic>? map;
  if (raw is Map<String, dynamic>) {
    map = raw;
  } else if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty) return false;
    try {
      final d = jsonDecode(s);
      if (d is Map) map = Map<String, dynamic>.from(d);
    } catch (_) {
      return false;
    }
  }
  if (map == null) return false;

  final nested = map['notification'];
  if (nested is Map) {
    map = {...map, ...Map<String, dynamic>.from(nested)};
  }

  final type = (map['type'] ??
          map['notificationType'] ??
          map['notification_type'] ??
          map['eventType'] ??
          '')
      .toString()
      .toLowerCase();
  if (type.contains('withdraw')) return true;

  final actionUrl =
      (map['actionUrl'] ?? map['action_url'] ?? '').toString().toLowerCase();
  if (actionUrl.contains('withdraw')) return true;

  final route = (map['route'] ?? '').toString().toLowerCase();
  if (route.contains('withdraw')) return true;

  return false;
}

/// Defer [GoRouter.go] until authenticated shell is ready (e.g. cold start).
Future<void> persistPendingChatRoute(String route) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(kWayoPushPendingRouteKey, route);
}

Future<void> persistPendingMarkRead({
  required String notificationId,
  String? conversationId,
}) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(
    kWayoPushPendingMarkReadKey,
    jsonEncode({
      'notificationId': notificationId,
      if (conversationId != null && conversationId.isNotEmpty)
        'conversationId': conversationId,
    }),
  );
}

Future<void> persistPendingChatQuickReply({
  required String conversationId,
  required String text,
}) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(
    kWayoPushPendingQuickReplyKey,
    jsonEncode({'conversationId': conversationId, 'text': text}),
  );
}

/// Clears deferred navigation / mark-read / quick-reply from push taps (logout).
Future<void> clearWayoPushPendingIntents() async {
  final p = await SharedPreferences.getInstance();
  await p.remove(kWayoPushPendingRouteKey);
  await p.remove(kWayoPushPendingMarkReadKey);
  await p.remove(kWayoPushPendingQuickReplyKey);
}
