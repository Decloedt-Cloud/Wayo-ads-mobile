import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' show IsolateNameServer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../../features/chat/data/chat_active_conversation.dart';
import '../../features/auth/domain/wayo_ads_account_role.dart';
import '../../features/auth/presentation/providers/current_account_providers.dart';
import '../../features/dashboard/presentation/utils/notification_route_resolver.dart';
import '../../router/app_router.dart';
import '../observability/app_log.dart';
import '../storage/app_prefs.dart';
import '../maintenance/maintenance_recovery_hub.dart';
import '../maintenance/maintenance_service.dart';
import 'wayo_background_chat_quick_reply.dart';
import 'push_registration_debug.dart';
import 'user_push_notifications_preference.dart';
import 'account_deletion_refresh_hub.dart';
import 'wayo_push_intent.dart';
import 'mobile_push_route_utils.dart';
import 'session_revocation_refresh_hub.dart';
import 'superadmin_withdrawals_refresh_hub.dart';

void _logPush(String message, {Object? error, StackTrace? stackTrace}) {
  if (error != null) {
    developer.log(
      message,
      name: 'wayo.push',
      error: error,
      stackTrace: stackTrace,
    );
  } else {
    developer.log(message, name: 'wayo.push');
  }
  wayoDiagPrint(message, name: 'wayo.push');
  if (kReleaseMode &&
      kWayoConfigDiagnosticLogging &&
      !kWayoDiagnosticsLogging) {
    debugPrint('[wayo.push] $message');
  }
}

/// Shared lifecycle logger for push modules (permission, register, enable).
void logPushLifecycle(
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  _logPush(message, error: error, stackTrace: stackTrace);
}

typedef FcmTokenBackendRegistrationCallback = Future<void> Function(
  String token,
);

FcmTokenBackendRegistrationCallback? _fcmTokenBackendRegistrationCallback;

Timer? _pushRegistrationRetryTimer;
var _pushRegistrationRetryCoalesced = false;

/// When FCM rotates the device token, re-register with Wayo-ads (wired from [AuthNotifier]).
void setFcmTokenBackendRegistrationCallback(
  FcmTokenBackendRegistrationCallback? callback,
) {
  _fcmTokenBackendRegistrationCallback = callback;
}

/// Debounced backend re-register when FCM arrives before POST /api/user/push-device completes.
void schedulePushRegistrationRetry({
  Duration delay = const Duration(seconds: 2),
}) {
  if (_pushRegistrationRetryCoalesced) return;
  _pushRegistrationRetryCoalesced = true;
  _pushRegistrationRetryTimer?.cancel();
  _pushRegistrationRetryTimer = Timer(delay, () {
    _pushRegistrationRetryCoalesced = false;
    final hook = _fcmTokenBackendRegistrationCallback;
    if (hook == null) {
      logPushLifecycle('register retry: skipped — no backend hook');
      return;
    }
    logPushLifecycle('register retry: invoking backend sync');
    unawaited(
      hook('').catchError((Object e, StackTrace st) {
        _logPush(
          'register retry backend sync failed: $e',
          error: e,
          stackTrace: st,
        );
      }),
    );
  });
}

/// Android: one tray notification per conversation (MessagingStyle + stable id/tag).
int wayoAndroidChatNotificationId(String conversationId) =>
    conversationId.hashCode & 0x7fffffff;

/// Stable local-notification id per conversation (Android + iOS).
int wayoChatNotificationId(String conversationId) =>
    wayoAndroidChatNotificationId(conversationId);

String wayoAndroidChatNotificationTag(String conversationId) =>
    'wayo_chat_$conversationId';

/// iOS Notification Center thread — groups + dismiss by conversation.
String wayoChatThreadIdentifier(String conversationId) =>
    wayoAndroidChatNotificationTag(conversationId);

const MethodChannel _wayoPushDismissChannel =
    MethodChannel('ma.wayo.wayoadsgo/push_dismiss');

/// Android MessagingStyle requires a real user [Person]; a null/empty name can break the notif builder.
const Person _wayoChatMessagingStyleUser = Person(name: 'You', key: 'wayo_local_user');

String _chatPeerDisplayName(WayoChatPushPayload chat, String fcmTitle) {
  final fromPayload = chat.title?.trim();
  if (fromPayload != null && fromPayload.isNotEmpty) {
    return fromPayload;
  }
  final t = fcmTitle.trim();
  if (t.isNotEmpty && t != 'Wayo Ads') {
    return t;
  }
  return 'Wayo Ads';
}

/// Android inline actions for chat (stable ids).
const String kWayoChatReplyActionId = 'wayo_chat_reply';
const String kWayoChatMarkReadActionId = 'wayo_chat_mark_read';

/// iOS/macOS [DarwinNotificationCategory] identifier for chat tray actions.
const String kWayoIosChatNotificationCategoryId = 'wayo_chat';

bool get wayoFirebaseCoreReady => _firebaseCoreReady;
bool _firebaseCoreReady = false;

const _kFcmTokenPrefKey = 'push.fcm.token';

/// When true, FCM payloads are ignored locally (logout / until re-register).
const kPushSuppressExternalKey = 'push.suppress_external';

/// After mobile schedules account deletion, ignore the server echo FCM briefly.
const kPushSuppressAccountDeletionUntilKey = 'push.suppress_account_deletion_until';

/// Wayo-ads [User.id] (cuid) for whom [registerWayoPushDeviceIfTokenPresent] succeeded.
const kPushRegisteredWayoUserIdKey = 'push.session.wayo_user_id';

/// Legacy Auth_Wayo numeric id — cleared on activate; do not use for FCM filtering.
const kPushRegisteredSessionUserIdKey = 'push.session.user_id';

Future<bool> isPushExternalDeliverySuppressed() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(kPushSuppressExternalKey) ?? false;
}

Future<void> setPushExternalDeliverySuppressed(bool suppressed) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kPushSuppressExternalKey, suppressed);
}

Future<void> markAccountDeletionSelfInitiatedPushSuppress({
  Duration window = const Duration(minutes: 3),
}) async {
  final p = await SharedPreferences.getInstance();
  final until = DateTime.now().add(window).millisecondsSinceEpoch;
  await p.setInt(kPushSuppressAccountDeletionUntilKey, until);
}

Future<bool> isAccountDeletionSelfInitiatedPushSuppressed() async {
  final p = await SharedPreferences.getInstance();
  final until = p.getInt(kPushSuppressAccountDeletionUntilKey);
  if (until == null) return false;
  if (DateTime.now().millisecondsSinceEpoch > until) {
    await p.remove(kPushSuppressAccountDeletionUntilKey);
    return false;
  }
  return true;
}

Future<void> clearRegisteredPushWayoUserId() async {
  final p = await SharedPreferences.getInstance();
  await p.remove(kPushRegisteredWayoUserIdKey);
  await p.remove(kPushRegisteredSessionUserIdKey);
}

Future<void> setRegisteredPushWayoUserId(String wayoUserId) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(kPushRegisteredWayoUserIdKey, wayoUserId);
  await p.remove(kPushRegisteredSessionUserIdKey);
}

Future<String?> readRegisteredPushWayoUserId() async {
  final p = await SharedPreferences.getInstance();
  final id = p.getString(kPushRegisteredWayoUserIdKey)?.trim();
  if (id != null && id.isNotEmpty) {
    return id;
  }
  return null;
}

/// Whether this FCM [data] payload is for the account that registered push on this device.
Future<bool> shouldDeliverFcmData(Map<String, dynamic> data) async {
  if (!await isUserPushNotificationsEnabledFromDisk()) {
    return false;
  }
  if (await isPushExternalDeliverySuppressed()) {
    return false;
  }
  final registered = await readRegisteredPushWayoUserId();
  final recipient = data['recipientUserId']?.toString().trim();
  if (registered != null &&
      recipient != null &&
      recipient.isNotEmpty &&
      recipient != registered) {
    _logPush(
      'FCM recipient mismatch registered=$registered recipient=$recipient — '
      'clearing stale id and scheduling register retry',
    );
    await clearRegisteredPushWayoUserId();
    schedulePushRegistrationRetry();
  } else if (registered == null) {
    _logPush(
      'FCM before push-device register — delivering and scheduling register retry',
    );
    schedulePushRegistrationRetry();
  }
  if (isCreatorYoutubeConnectFcmPayload(data)) {
    _logPush('FCM ignored — creator YouTube connect notification suppressed');
    return false;
  }
  if (isSelfInitiatedWalletFcmPayload(data)) {
    _logPush('FCM ignored — self-initiated wallet action (deposit/withdraw) suppressed');
    return false;
  }
  if (isAccountDeletionScheduledNotificationPayload(data) &&
      await isAccountDeletionSelfInitiatedPushSuppressed()) {
    _logPush(
      'FCM ignored — self-initiated account deletion schedule suppressed',
    );
    return false;
  }
  // Legacy / not-yet-deployed server: no recipient field — trust token registration only.
  return true;
}

/// Call after successful POST /api/user/push-device (response `userId` = Wayo-ads cuid).
Future<void> activatePushDeliveryForWayoUser(String wayoUserId) async {
  final id = wayoUserId.trim();
  if (id.isEmpty) {
    return;
  }
  await setRegisteredPushWayoUserId(id);
  await setPushExternalDeliverySuppressed(false);
}

/// Account switch at login: drop stale recipient id; do not set suppress (register may retry).
Future<void> resetPushDeliveryForAccountSwitch() async {
  await clearRegisteredPushWayoUserId();
}

/// Logout: block FCM until the next user re-registers successfully.
Future<void> deactivatePushDelivery() async {
  await setPushExternalDeliverySuppressed(true);
  await clearRegisteredPushWayoUserId();
}

/// Revokes the FCM token on this device so Firebase stops routing to the old session.
Future<void> revokeLocalFcmToken(AppPrefs prefs) async {
  if (_firebaseCoreReady) {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      _logPush('FCM deleteToken failed: $e', error: e, stackTrace: st);
    }
    _tokenRefreshAttached = false;
  }
  final p = await SharedPreferences.getInstance();
  await p.remove(_kFcmTokenPrefKey);
  await prefs.setString(_kFcmTokenPrefKey, '');
}

/// Clears tray notifications created by [flutter_local_notifications].
Future<void> dismissAllWayoLocalPushNotifications() async {
  try {
    await _ensureLocalNotificationsInitialized();
    await _localNotifications.cancelAll();
  } catch (e, st) {
    _logPush(
      'cancelAll notifications failed: $e',
      error: e,
      stackTrace: st,
    );
  }
}

String? readCachedFcmToken(AppPrefs prefs) {
  final t = prefs.getString(_kFcmTokenPrefKey);
  if (t == null || t.isEmpty) {
    return null;
  }
  return t;
}

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'wayo_push_high',
  'Wayo Ads alerts',
  description: 'Campaign, chat and account notifications',
  importance: Importance.high,
);

bool _localInitDone = false;
bool _foregroundListenersAttached = false;
bool _androidNotificationLaunchDrainAttempted = false;

/// When the app starts **terminated** from a MessagingStyle action ([showsUserInterface]
/// / [SELECT_FOREGROUND_NOTIFICATION_ACTION]), the Android plugin does **not**
/// invoke [didReceiveNotificationResponse] via the channel—only [getNotificationAppLaunchDetails].
/// Without draining that intent, inline replies never persist and the OS spinner can hang.

Future<void> _drainAndroidNotificationLaunchIntentIfNeeded() async {
  if (!Platform.isAndroid) return;
  if (_androidNotificationLaunchDrainAttempted) return;
  _androidNotificationLaunchDrainAttempted = true;
  try {
    final details = await _localNotifications.getNotificationAppLaunchDetails();
    if (details == null || !(details.didNotificationLaunchApp)) return;
    final response = details.notificationResponse;
    if (response == null) return;
    await _handleNotificationResponse(
      response,
      fromBackgroundIsolate: false,
    );
  } catch (e, st) {
    _logPush(
      'getNotificationAppLaunchDetails / launch intent drain failed: $e',
      error: e,
      stackTrace: st,
    );
  }
}

/// [PushPermissionPromptHost] registers a [ReceivePort] under this name so the
/// notification **broadcast** isolate can wake the UI isolate (inline reply, mark-read, etc.).
const String kWayoDeferredPushPortName = 'wayo_deferred_push';

void _pingDeferredPushConsume() {
  IsolateNameServer.lookupPortByName(kWayoDeferredPushPortName)?.send(null);
}

@pragma('vm:entry-point')
void wayoNotificationTapBackground(NotificationResponse response) {
  unawaited(_handleNotificationResponse(response, fromBackgroundIsolate: true));
}

WayoAdsAccountRole _readCurrentPushRouteRole(BuildContext context) {
  try {
    return ProviderScope.containerOf(context)
        .read(currentWayoAdsAccountRoleProvider);
  } catch (_) {
    return WayoAdsAccountRole.unknown;
  }
}

String _resolvePushNavigationTarget({
  required String fallbackRoute,
  Map<String, dynamic>? payloadData,
  String? payload,
  WayoAdsAccountRole role = WayoAdsAccountRole.unknown,
}) {
  return resolvePushRouteForRole(
        data: payloadData,
        payload: payload,
        role: role,
      ) ??
      fallbackRoute;
}

Future<void> _navigateOrDeferPushRoute(
  String route, {
  required bool fromBackgroundIsolate,
  Map<String, dynamic>? payloadData,
  String? payload,
}) async {
  if (!fromBackgroundIsolate) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      final role = _readCurrentPushRouteRole(ctx);
      final target = _resolvePushNavigationTarget(
        fallbackRoute: route,
        payloadData: payloadData,
        payload: payload,
        role: role,
      );
      navigateWayoPushRoute(GoRouter.of(ctx), target);
      return;
    }
  }
  final dataToPersist = payloadData ??
      (payload != null ? wayoRoutePushPayloadDataFromLocalPayload(payload) : null);
  await persistPendingChatRoute(route, payloadData: dataToPersist);
  _pingDeferredPushConsume();
}

Future<void> _handleNotificationResponse(
  NotificationResponse response, {
  required bool fromBackgroundIsolate,
}) async {
  final chatPayload = WayoChatPushPayload.tryParse(response.payload);
  if (chatPayload != null) {
    if (response.actionId == kWayoChatMarkReadActionId) {
      await persistPendingMarkRead(
        notificationId: chatPayload.notificationId,
        conversationId: chatPayload.conversationId,
      );
      try {
        await dismissWayoChatNotification(chatPayload.conversationId);
      } catch (_) {}
      _pingDeferredPushConsume();
      return;
    }

    final forReply = response.actionId == kWayoChatReplyActionId;
    final replyText = response.input?.trim();
    if (forReply && replyText != null && replyText.isNotEmpty) {
      final convParsed = int.tryParse(chatPayload.conversationId.trim());
      if (convParsed != null) {
        final sent = await trySendWayoChatQuickReplySilently(
          conversationId: convParsed,
          text: replyText,
        );
        if (sent) {
          try {
            await dismissWayoChatNotification(chatPayload.conversationId);
          } catch (_) {}
          _pingDeferredPushConsume();
          return;
        }
      }

      await persistPendingChatQuickReply(
        conversationId: chatPayload.conversationId,
        text: replyText,
      );
      try {
        await dismissWayoChatNotification(chatPayload.conversationId);
      } catch (_) {}
      _pingDeferredPushConsume();
      return;
    }

    try {
      await dismissWayoChatNotification(chatPayload.conversationId);
    } catch (_) {}

    await _navigateOrDeferPushRoute(
      chatPayload.route(forReply: forReply),
      fromBackgroundIsolate: fromBackgroundIsolate,
    );
    return;
  }

  final payloadData = wayoRoutePushPayloadDataFromLocalPayload(response.payload);
  final route = resolveWayoPushRoute(payload: response.payload);
  if (route != null) {
    await _navigateOrDeferPushRoute(
      route,
      fromBackgroundIsolate: fromBackgroundIsolate,
      payloadData: payloadData,
      payload: response.payload,
    );
  }
}

Future<void> _persistOpenFromFcmData(Map<String, dynamic> data) async {
  final chat = WayoChatPushPayload.fromMessageData(data);
  if (chat != null) {
    await persistPendingChatRoute(chat.route(forReply: false));
    return;
  }
  final flat = flattenPushPayloadMap(data);
  final route = resolveWayoPushRoute(data: data);
  if (route != null) {
    await persistPendingChatRoute(route, payloadData: flat);
  }
}

Future<void> _presentWithdrawalOrAdminTray({
  required RemoteMessage message,
  required String title,
  required String body,
}) async {
  final routePayload = WayoRoutePushPayload.fromMessageData(message.data);
  final route = routePayload?.route ??
      resolveWayoPushRoute(data: message.data) ??
      kSuperadminWithdrawalsRoute;
  _notifySuperadminWithdrawalsRefreshFromFcm(message.data, route);
  final trayTitle = routePayload?.title ?? title;
  final trayBody = routePayload?.body ?? body;

  await _showLocalPush(
    id: wayoFcmTrayNotificationId(message.data),
    title: trayTitle,
    body: trayBody.isEmpty ? ' ' : trayBody,
    payload: encodeWayoRoutePushLocalPayload(
      route: route,
      fcmData: message.data,
    ),
  );
}

void _notifySuperadminWithdrawalsRefreshFromFcm(
  Map<String, dynamic> data,
  String? route,
) {
  if (isWithdrawalNotificationPayload(data) ||
      (route != null && isSuperadminWithdrawalsPushRoute(route))) {
    notifySuperadminWithdrawalsRefresh();
  }
}

List<AndroidNotificationAction>? _androidChatActions() => [
      AndroidNotificationAction(
        kWayoChatReplyActionId,
        'Répondre',
        inputs: const [
          AndroidNotificationActionInput(
            label: 'Message',
            allowFreeFormInput: true,
          ),
        ],
        /// Keeps users in the shade: no Flutter activity launch. RemoteInput is
        /// delivered to [wayoNotificationTapBackground], which POSTs immediately.
        cancelNotification: false,
      ),
      /// Same as reply: must launch the real Activity — broadcast actions run in a
      /// headless engine where deferred IsolateNameServer handoff is unreliable, so
      /// "Marquer comme lue" appeared to do nothing. Use Dart-side dismiss with tag.
      const AndroidNotificationAction(
        kWayoChatMarkReadActionId,
        'Marquer comme lue',
        showsUserInterface: true,
        cancelNotification: false,
      ),
    ];

Future<void> _ensureLocalNotificationsInitialized() async {
  if (_localInitDone) return;
  _localInitDone = true;

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  /// Same action ids as Android — [NotificationResponse.actionId] maps here.
  /// Omit [DarwinNotificationActionOption.foreground] on « Répondre » so iOS
  /// can deliver to [wayoNotificationTapBackground] without forcing the app foreground
  /// (parity with Android broadcast + silent HTTP send).
  final iosInit = DarwinInitializationSettings(
    notificationCategories: [
      DarwinNotificationCategory(
        kWayoIosChatNotificationCategoryId,
        actions: [
          DarwinNotificationAction.text(
            kWayoChatReplyActionId,
            'Répondre',
            buttonTitle: 'Envoyer',
            placeholder: 'Message',
          ),
          DarwinNotificationAction.plain(
            kWayoChatMarkReadActionId,
            'Marquer comme lue',
          ),
        ],
      ),
    ],
  );
  await _localNotifications.initialize(
    InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    ),
    onDidReceiveNotificationResponse: (NotificationResponse r) {
      unawaited(_handleNotificationResponse(r, fromBackgroundIsolate: false));
    },
    onDidReceiveBackgroundNotificationResponse: wayoNotificationTapBackground,
  );

  if (Platform.isIOS) {
    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  await _drainAndroidNotificationLaunchIntentIfNeeded();

  final androidPlugin = _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(_androidChannel);
}

const int _kMaxChatTrayMessages = 25;

Future<void> _presentIncomingChatTray({
  required WayoChatPushPayload chat,
  required String notificationTitle,
  required String messageBody,
  required bool mergeWithExisting,
}) async {
  if (await isViewingChatConversation(chat.conversationId)) {
    _logPush(
      'Skipped chat tray — user viewing conversation ${chat.conversationId}',
    );
    return;
  }
  if (await shouldSuppressChatTrayEcho(chat, messageBody)) {
    _logPush(
      'Skipped chat tray — matches recent notification inline reply (server echo)',
    );
    return;
  }
  await _showAndroidChatLocalNotification(
    chat: chat,
    notificationTitle: notificationTitle,
    messageBody: messageBody,
    mergeWithExisting: mergeWithExisting,
  );
}

/// One tray notification per conversation ([MessagingStyle] when supported).
///
/// [mergeWithExisting] should be **false** for FCM background isolate: on many devices,
/// [AndroidFlutterLocalNotificationsPlugin.getActiveNotificationMessagingStyle] is unreliable
/// there and can prevent any notification from appearing.
Future<void> _showAndroidChatLocalNotification({
  required WayoChatPushPayload chat,
  required String notificationTitle,
  required String messageBody,
  bool mergeWithExisting = true,
}) async {
  await _ensureLocalNotificationsInitialized();
  final android = _localNotifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  final id = wayoAndroidChatNotificationId(chat.conversationId);
  final tag = wayoAndroidChatNotificationTag(chat.conversationId);
  final peerName = _chatPeerDisplayName(chat, notificationTitle);
  final text = messageBody.trim().isEmpty ? ' ' : messageBody.trim();

  var messages = <Message>[];
  if (mergeWithExisting && android != null) {
    try {
      final active = await android.getActiveNotificationMessagingStyle(
        id,
        tag: tag,
      );
      final existing = active?.messages;
      if (existing != null && existing.isNotEmpty) {
        messages = List<Message>.from(existing);
        final keep = _kMaxChatTrayMessages - 1;
        if (messages.length > keep) {
          messages = messages.sublist(messages.length - keep);
        }
      }
    } catch (_) {}
  }

  final sender = Person(name: peerName, key: 'peer_${chat.conversationId}');
  messages = [...messages, Message(text, DateTime.now(), sender)];

  final style = MessagingStyleInformation(
    _wayoChatMessagingStyleUser,
    conversationTitle: peerName,
    groupConversation: false,
    messages: messages,
  );

  final androidDetails = AndroidNotificationDetails(
    _androidChannel.id,
    _androidChannel.name,
    channelDescription: _androidChannel.description,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    tag: tag,
    category: AndroidNotificationCategory.message,
    styleInformation: style,
    actions: _androidChatActions(),
  );

  try {
    await _localNotifications.show(
      id,
      peerName,
      text,
      NotificationDetails(android: androidDetails),
      payload: chat.toLocalNotificationPayload(),
    );
  } catch (e, st) {
    _logPush(
      'Android MessagingStyle chat tray failed, using BigText fallback: $e',
      error: e,
      stackTrace: st,
    );
    await _localNotifications.show(
      id,
      peerName,
      text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          tag: tag,
          category: AndroidNotificationCategory.message,
          styleInformation: BigTextStyleInformation(text),
          actions: _androidChatActions(),
        ),
      ),
      payload: chat.toLocalNotificationPayload(),
    );
  }
}

Future<void> _showLocalPush({
  required int id,
  required String title,
  required String body,
  required String payload,
  bool isAndroidChat = false,
  bool isIosChat = false,
  String? iosThreadIdentifier,
}) async {
  await _ensureLocalNotificationsInitialized();

  await _localNotifications.show(
    id,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: isAndroidChat
            ? AndroidNotificationCategory.message
            : AndroidNotificationCategory.status,
        actions: isAndroidChat && Platform.isAndroid ? _androidChatActions() : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier:
            isIosChat ? kWayoIosChatNotificationCategoryId : null,
        threadIdentifier: iosThreadIdentifier,
      ),
    ),
    payload: payload,
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (!await shouldDeliverFcmData(message.data)) {
    _logPush('FCM background ignored — wrong/missing recipient');
    return;
  }
  // Silent session-control message: never shows a tray. The actual logout is
  // performed by the foreground session watchdog's immediate re-check on resume
  // (the app must be reopened to do anything anyway).
  if (isSessionsChangedRealtimePayload(message.data)) {
    _logPush('FCM background sessions.changed — defer to resume re-check');
    return;
  }
  if (isMaintenanceRecoveryRealtimePayload(message.data)) {
    _logPush('FCM background maintenance recovery — defer to resume probe');
    return;
  }
  if (isMaintenanceStartedRealtimePayload(message.data)) {
    _logPush('FCM background maintenance started');
    MaintenanceServiceHolder.instance.enterMaintenance();
    return;
  }
  final chat = WayoChatPushPayload.fromMessageData(message.data);
  final title = message.notification?.title ??
      message.data['title']?.toString() ??
      'Wayo Ads';
  final body =
      message.notification?.body ?? message.data['body']?.toString() ?? '';

  _logPush(
    'FCM background id=${message.messageId} title=$title '
    'body=${body.isEmpty ? '(empty)' : '(len ${body.length})'} '
    'dataKeys=${message.data.keys.join(',')}',
  );

  if (chat != null) {
    if (await isViewingChatConversation(chat.conversationId)) {
      _logPush(
        'FCM background chat ignored — user viewing conversation ${chat.conversationId}',
      );
      return;
    }
    if (shouldSkipDuplicateFcmLocalTray(
      hasDisplayNotificationPayload: message.notification != null,
    )) {
      _logPush(
        'FCM background chat skipped local tray — system notification already shown',
      );
      return;
    }
    if (Platform.isAndroid) {
      try {
        await _presentIncomingChatTray(
          chat: chat,
          notificationTitle: title,
          messageBody: body,
          mergeWithExisting: false,
        );
      } catch (e, st) {
        _logPush(
          'FCM background chat tray failed entirely: $e',
          error: e,
          stackTrace: st,
        );
      }
      return;
    }
    try {
      await _showLocalPush(
        id: wayoChatNotificationId(chat.conversationId),
        title: title,
        body: body.isEmpty ? ' ' : body,
        payload: chat.toLocalNotificationPayload(),
        isIosChat: true,
        iosThreadIdentifier: wayoChatThreadIdentifier(chat.conversationId),
      );
    } catch (e, st) {
      _logPush(
        'FCM background iOS chat local failed: $e',
        error: e,
        stackTrace: st,
      );
    }
    return;
  }

  if (shouldSkipDuplicateFcmLocalTray(
    hasDisplayNotificationPayload: message.notification != null,
  )) {
    _logPush(
      'FCM background skipped local tray — system notification already shown',
    );
    return;
  }

  final adminRoute = WayoRoutePushPayload.fromMessageData(message.data) != null ||
      resolveWayoPushRoute(data: message.data) != null;

  // Withdrawals / admin: tray even for data-only FCM (route/type without title).
  if (adminRoute || title.isNotEmpty || body.isNotEmpty) {
    try {
      await _presentWithdrawalOrAdminTray(
        message: message,
        title: title.isNotEmpty ? title : 'Wayo Ads',
        body: body,
      );
    } catch (e, st) {
      _logPush(
        'FCM background admin/withdrawal tray failed: $e',
        error: e,
        stackTrace: st,
      );
    }
  }
}

Future<bool> initializeFirebaseForPush() async {
  if (_firebaseCoreReady) return true;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    logPushLifecycle(
      'Firebase.initializeApp start projectId=${options.projectId} '
      'appId=${options.appId} senderId=${options.messagingSenderId}',
    );
    await Firebase.initializeApp(options: options);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
    }
    _firebaseCoreReady = true;
    final platformLabel = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : defaultTargetPlatform.name;
    logPushLifecycle(
      'Firebase.initializeApp SUCCESS platform=$platformLabel '
      'projectId=${options.projectId} appId=${options.appId} '
      'senderId=${options.messagingSenderId} (expect wayo-ads-27cbf)',
    );
    if (options.projectId != 'wayo-ads-27cbf') {
      logPushLifecycle(
        'WARNING: Firebase projectId=${options.projectId} is not wayo-ads-27cbf — '
        'FCM tokens may not match backend ADC project',
      );
    }
    return true;
  } catch (e, st) {
    _logPush(
      'Firebase not ready (google-services / firebase_options / network): $e',
      error: e,
      stackTrace: st,
    );
    wayoConfigDiagPrint(
      'Push: Firebase.initializeApp failed — check android/app/google-services.json '
      '(wayo-ads-27cbf), SHA-1/SHA-256 in Firebase Console, and lib/firebase_options.dart.',
      name: 'wayo.push',
    );
    return false;
  }
}

Future<void> attachForegroundFcmHandlers() async {
  if (!_firebaseCoreReady || _foregroundListenersAttached) return;
  _foregroundListenersAttached = true;

  await _ensureLocalNotificationsInitialized();

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: true,
    sound: false,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
    if (!await shouldDeliverFcmData(m.data)) {
      _logPush('FCM foreground ignored — wrong/missing recipient');
      return;
    }
    // Silent session-control message (active sessions changed / revoked):
    // refresh the sessions list + re-validate this session. No tray.
    if (isSessionsChangedRealtimePayload(m.data)) {
      _logPush('FCM foreground sessions.changed — triggering session re-check');
      notifySessionsChanged();
      return;
    }
    if (isAccountDeletionStateChangedPayload(m.data)) {
      _logPush(
        'FCM foreground account deletion state changed — refreshing banner',
      );
      notifyAccountDeletionStateChanged(Map<String, dynamic>.from(m.data));
      return;
    }
    if (isMaintenanceRecoveryRealtimePayload(m.data)) {
      _logPush('FCM foreground maintenance recovery — triggering health probe');
      notifyMaintenanceRecoveryProbe();
      return;
    }
    if (isMaintenanceStartedRealtimePayload(m.data)) {
      _logPush('FCM foreground maintenance started');
      MaintenanceServiceHolder.instance.enterMaintenance();
      return;
    }
    final n = m.notification;
    final title =
        n?.title ?? m.data['title']?.toString() ?? 'Wayo Ads';
    final body = n?.body ?? m.data['body']?.toString() ?? '';
    _logPush(
      'FCM foreground id=${m.messageId} title=$title '
      'dataKeys=${m.data.keys.join(',')}',
    );
    final chat = WayoChatPushPayload.fromMessageData(m.data);
    if (chat != null) {
      if (await isViewingChatConversation(chat.conversationId)) {
        _logPush(
          'FCM foreground chat ignored — user viewing conversation ${chat.conversationId}',
        );
        return;
      }
    }
    if (chat != null && Platform.isAndroid) {
      await _presentIncomingChatTray(
        chat: chat,
        notificationTitle: title,
        messageBody: body,
        mergeWithExisting: true,
      );
      return;
    }
    if (chat != null) {
      if (await shouldSuppressChatTrayEcho(chat, body)) {
        _logPush(
          'Skipped local chat push — matches recent inline reply echo',
        );
        return;
      }
      if (shouldSkipDuplicateFcmLocalTray(
        hasDisplayNotificationPayload: m.notification != null,
        foreground: true,
      )) {
        _logPush(
          'FCM foreground chat skipped local tray — system notification already shown',
        );
        return;
      }
      await _showLocalPush(
        id: wayoChatNotificationId(chat.conversationId),
        title: title,
        body: body.isEmpty ? ' ' : body,
        payload: chat.toLocalNotificationPayload(),
        isIosChat: Platform.isIOS,
        iosThreadIdentifier: wayoChatThreadIdentifier(chat.conversationId),
      );
      return;
    }

    if (shouldSkipDuplicateFcmLocalTray(
      hasDisplayNotificationPayload: m.notification != null,
      foreground: true,
    )) {
      _logPush(
        'FCM foreground skipped local tray — system notification already shown',
      );
      return;
    }

    final routePayload = WayoRoutePushPayload.fromMessageData(m.data);
    final route =
        routePayload?.route ?? resolveWayoPushRoute(data: m.data);
    final bodyText = (routePayload?.body ?? body).trim();
    final titleText = routePayload?.title ?? title;
    if (route == null) {
      if (titleText.isEmpty && bodyText.isEmpty) return;
      await _showLocalPush(
        id: wayoFcmTrayNotificationId(m.data),
        title: titleText.isNotEmpty ? titleText : 'Wayo Ads',
        body: bodyText.isEmpty ? ' ' : bodyText,
        payload: '/notifications',
        isAndroidChat: false,
      );
      return;
    }

    await _showLocalPush(
      id: wayoFcmTrayNotificationId(m.data),
      title: titleText,
      body: bodyText.isEmpty ? ' ' : bodyText,
      payload: encodeWayoRoutePushLocalPayload(route: route, fcmData: m.data),
      isAndroidChat: false,
    );
    _notifySuperadminWithdrawalsRefreshFromFcm(m.data, route);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) async {
    if (!await shouldDeliverFcmData(m.data)) {
      _logPush('FCM open-from-tray ignored — wrong/missing recipient');
      return;
    }
    _logPush('FCM opened app from tray: ${m.messageId}');
    final chat = WayoChatPushPayload.fromMessageData(m.data);
    if (chat != null) {
      unawaited(dismissWayoChatNotification(chat.conversationId));
      await _navigateOrDeferPushRoute(
        chat.route(forReply: false),
        fromBackgroundIsolate: false,
      );
      return;
    }
    final route = resolveWayoPushRoute(data: m.data);
    if (route != null) {
      await _navigateOrDeferPushRoute(
        route,
        fromBackgroundIsolate: false,
        payloadData: flattenPushPayloadMap(m.data),
      );
      return;
    }
    await _persistOpenFromFcmData(m.data);
    _pingDeferredPushConsume();
  });

  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    if (await shouldDeliverFcmData(initial.data)) {
      _logPush('FCM app launched from quit state: ${initial.messageId}');
      final chat = WayoChatPushPayload.fromMessageData(initial.data);
      if (chat != null) {
        unawaited(dismissWayoChatNotification(chat.conversationId));
      }
      await _persistOpenFromFcmData(initial.data);
      _pingDeferredPushConsume();
    } else {
      _logPush('FCM cold-start open ignored — wrong/missing recipient');
    }
  }
}

bool _tokenRefreshAttached = false;

/// Requests OS notification permission. Returns whether tray alerts can be shown.
///
/// On Android, FCM [getToken] does not require POST_NOTIFICATIONS — callers may
/// still register the token when this returns false (Android 13+ tray blocked).
Future<bool> requestSystemPushPermission() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final before = await Permission.notification.status;
    logPushLifecycle(
      'permission: Android POST_NOTIFICATIONS before=$before platform=android',
    );
    var status = before;
    if (!status.isGranted && !status.isLimited) {
      status = await Permission.notification.request();
    }
    logPushLifecycle('permission: Android POST_NOTIFICATIONS after=$status');
    PushRegistrationDebug.recordPermission(
      'Android after=$status',
      granted: status.isGranted || status.isLimited,
    );
    if (status.isPermanentlyDenied) {
      logPushLifecycle('permission: permanently denied — open system settings');
      return false;
    }
    if (status.isDenied) {
      logPushLifecycle(
        'permission: denied — FCM getToken may still work; tray alerts blocked on API 33+',
      );
      return false;
    }
    if (!_firebaseCoreReady) {
      logPushLifecycle(
        'permission: Android granted but Firebase not ready — token will fail until init',
      );
      return true;
    }
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      logPushLifecycle(
        'permission: Android FCM settings authorizationStatus='
        '${settings.authorizationStatus}',
      );
    } catch (e) {
      logPushLifecycle('permission: Android getNotificationSettings: $e');
    }
    return true;
  }

  if (!_firebaseCoreReady) {
    logPushLifecycle('permission: skipped — Firebase not ready (non-Android)');
    PushRegistrationDebug.recordPermission('Firebase not ready', granted: false);
    return false;
  }

  final before = await FirebaseMessaging.instance.getNotificationSettings();
  logPushLifecycle(
    'permission: iOS before authorizationStatus=${before.authorizationStatus}',
  );

  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  logPushLifecycle(
    'permission: iOS after authorizationStatus=${settings.authorizationStatus}',
  );

  final ok = settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
  PushRegistrationDebug.recordPermission(
    'iOS after=${settings.authorizationStatus}',
    granted: ok,
  );
  return ok;
}

/// iOS/macOS: FCM [getToken] requires a valid APNs device token first.
Future<bool> _waitForApnsTokenIfNeeded() async {
  if (defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.macOS) {
    return true;
  }
  const maxAttempts = 12;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns != null && apns.isNotEmpty) {
        logPushLifecycle(
          'getToken: APNs token ready (attempt ${attempt + 1}/$maxAttempts, '
          '${apns.length} chars)',
        );
        return true;
      }
      logPushLifecycle(
        'getToken: APNs token null (attempt ${attempt + 1}/$maxAttempts)',
      );
    } catch (e) {
      logPushLifecycle(
        'getToken: getAPNSToken failed (attempt ${attempt + 1}/$maxAttempts): $e',
      );
    }
    if (attempt >= maxAttempts - 1) {
      break;
    }
    await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
  }
  _logPush(
    'FCM iOS: no APNs token — verify Runner.entitlements has aps-environment, '
    'Xcode Push Notifications capability, APNs key (.p8) uploaded in Firebase Console '
    '(Project Settings → Cloud Messaging → Apple app ma.wayo.wayoadsgo), and that the '
    'provisioning profile includes Push Notifications.',
  );
  return false;
}

Future<void> refreshAndCacheFcmToken(AppPrefs prefs) async {
  if (!_firebaseCoreReady) {
    logPushLifecycle('getToken: skipped — Firebase not ready');
    return;
  }
  try {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        await requestSystemPushPermission();
      }
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
    }
    await _waitForApnsTokenIfNeeded();
    String? token;
    const maxAttempts = 10;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        token = await FirebaseMessaging.instance.getToken();
        logPushLifecycle(
          'getToken: attempt ${attempt + 1}/$maxAttempts '
          'result=${token == null ? 'null' : '${token.length} chars'}',
        );
      } catch (e, st) {
        _logPush(
          'FCM getToken attempt ${attempt + 1} failed: $e',
          error: e,
          stackTrace: st,
        );
        token = null;
      }
      if (token != null && token.isNotEmpty) {
        break;
      }
      if (attempt >= maxAttempts - 1) {
        break;
      }
      final delayMs =
          defaultTargetPlatform == TargetPlatform.iOS ? 450 * (attempt + 1) : 350 * (attempt + 1);
      logPushLifecycle('getToken: retry in ${delayMs}ms');
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    if (token == null || token.isEmpty) {
      final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
      _logPush(
        isApple
            ? 'FCM getToken: no token after $maxAttempts retries — iOS: enable Push '
                'Notifications in Xcode (aps-environment), upload APNs auth key in Firebase '
                'Console (wayo-ads-27cbf), rebuild on a physical device (simulator has no APNs).'
            : 'FCM getToken: no token after $maxAttempts retries — Android: add debug AND '
                'release SHA-1 + SHA-256 in Firebase Console (wayo-ads-27cbf); ensure Google Play '
                'services; package ma.wayo.wayoadsgo. Run: cd android && ./gradlew signingReport',
      );
      wayoConfigDiagPrint(
        isApple
            ? 'Push: getToken() failed — check iOS Push capability + Firebase APNs key.'
            : 'Push: getToken() failed after retries. Add matching keystore SHA-1/SHA-256 in Firebase.',
        name: 'wayo.push',
      );
      return;
    }
    final prev = prefs.getString(_kFcmTokenPrefKey);
    await prefs.setString(_kFcmTokenPrefKey, token);
    if (prev != token) {
      _logPush('FCM token cached (${token.length} chars)');
      wayoConfigDiagPrint(
        'Push: FCM token stored (prefs key $_kFcmTokenPrefKey, ${token.length} chars)',
        name: 'wayo.push',
      );
    } else {
      logPushLifecycle('getToken: unchanged (${token.length} chars)');
    }
    if (!_tokenRefreshAttached) {
      _tokenRefreshAttached = true;
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        final old = prefs.getString(_kFcmTokenPrefKey);
        if (old != t) {
          _logPush('FCM token refreshed (${t.length} chars) — re-registering with backend');
        } else {
          logPushLifecycle('FCM onTokenRefresh (${t.length} chars)');
        }
        unawaited(prefs.setString(_kFcmTokenPrefKey, t));
        final hook = _fcmTokenBackendRegistrationCallback;
        if (hook != null) {
          unawaited(
            hook(t).catchError((Object e, StackTrace st) {
              _logPush('FCM token refresh backend sync failed: $e', error: e, stackTrace: st);
            }),
          );
        } else {
          logPushLifecycle('FCM onTokenRefresh: no backend hook installed yet');
        }
      });
      logPushLifecycle('getToken: onTokenRefresh listener attached');
    }
  } catch (e, st) {
    _logPush('FCM getToken failed: $e', error: e, stackTrace: st);
  }
}

/// Clears chat tray notifications for this conversation (Android tray + iOS local/APNs).
Future<void> dismissWayoChatNotification(String conversationId) async {
  if (conversationId.isEmpty) return;
  try {
    await _ensureLocalNotificationsInitialized();
    final id = wayoChatNotificationId(conversationId);
    if (Platform.isAndroid) {
      final android = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final tag = wayoAndroidChatNotificationTag(conversationId);
      await android?.cancel(id, tag: tag);
    } else if (Platform.isIOS) {
      await _localNotifications.cancel(id);
      try {
        await _wayoPushDismissChannel.invokeMethod<void>(
          'dismissChatNotification',
          conversationId,
        );
      } catch (e, st) {
        _logPush(
          'iOS delivered chat notification dismiss failed: $e',
          error: e,
          stackTrace: st,
        );
      }
    }
  } catch (e, st) {
    _logPush(
      'dismissWayoChatNotification failed conv=$conversationId: $e',
      error: e,
      stackTrace: st,
    );
  }
}

/// @deprecated Use [dismissWayoChatNotification].
Future<void> dismissWayoChatAndroidNotification(String conversationId) =>
    dismissWayoChatNotification(conversationId);

/// Sends a message typed in the Android notification inline reply, once the app is foregrounded + authed.
Future<void> consumeDeferredChatQuickReply({
  required Future<void> Function(int conversationId, String text) onSend,
}) async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(kWayoPushPendingQuickReplyKey);
  if (raw == null || raw.isEmpty) return;
  Map<String, dynamic>? map;
  try {
    final d = jsonDecode(raw);
    if (d is Map) {
      map = Map<String, dynamic>.from(d);
    }
  } catch (_) {}
  if (map == null) return;
  final rawConv = map['conversationId'];
  final convId = switch (rawConv) {
    final int v => v,
    final num v => v.toInt(),
    _ => int.tryParse(rawConv?.toString().trim() ?? ''),
  };
  final text = map['text']?.toString().trim() ?? '';
  if (convId == null || text.isEmpty) {
    _logPush(
      'Deferred chat quick reply dropped — invalid prefs '
      '(conv=$rawConv parsed=$convId textLen=${text.length})',
    );
    await p.remove(kWayoPushPendingQuickReplyKey);
    return;
  }

  // Cold resume: auth + FlutterSecureStorage can lag the first Wayo-ads request.
  await Future<void>.delayed(const Duration(milliseconds: 200));
  try {
    await onSend(convId, text);
    await p.remove(kWayoPushPendingQuickReplyKey);
  } catch (e, st) {
    _logPush(
      'Deferred chat quick reply failed (will retry on next open): $e',
      error: e,
      stackTrace: st,
    );
  }
}

/// Called from UI when auth is ready — opens deferred chat route / marks notification read.
Future<void> consumeDeferredWayoPushIntents({
  required BuildContext context,
  required bool isAuthenticated,
  required Future<void> Function({
    required String notificationId,
    String? conversationId,
  }) processDeferredMarkRead,
  WayoAdsAccountRole role = WayoAdsAccountRole.unknown,
}) async {
  if (!isAuthenticated || !context.mounted) return;
  final p = await SharedPreferences.getInstance();
  final routePending = p.getString(kWayoPushPendingRouteKey) ?? '';
  final markRaw = p.getString(kWayoPushPendingMarkReadKey) ?? '';
  if (routePending.isEmpty && markRaw.isEmpty) return;

  if (markRaw.isNotEmpty) {
    await p.remove(kWayoPushPendingMarkReadKey);
    String nid = markRaw;
    String? cid;
    try {
      final d = jsonDecode(markRaw);
      if (d is Map) {
        final parsed = d['notificationId']?.toString();
        if (parsed != null && parsed.isNotEmpty) {
          nid = parsed;
        }
        final c = d['conversationId']?.toString();
        cid = (c != null && c.isNotEmpty) ? c : null;
      }
    } catch (_) {
      /* legacy: raw string was notification id only */
    }
    try {
      await processDeferredMarkRead(notificationId: nid, conversationId: cid);
    } catch (_) {}
  }

  if (routePending.isNotEmpty) {
    await p.remove(kWayoPushPendingRouteKey);
    final payloadRaw = p.getString(kWayoPushPendingPayloadKey) ?? '';
    await p.remove(kWayoPushPendingPayloadKey);
    // Cold resume: auth + FlutterSecureStorage can lag the first Wayo-ads request.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (context.mounted) {
      Map<String, dynamic>? payloadData;
      if (payloadRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(payloadRaw);
          if (decoded is Map) {
            payloadData = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
      final effectiveRole =
          role != WayoAdsAccountRole.unknown
              ? role
              : _readCurrentPushRouteRole(context);
      final target = _resolvePushNavigationTarget(
        fallbackRoute: routePending,
        payloadData: payloadData,
        role: effectiveRole,
      );
      navigateWayoPushRoute(GoRouter.of(context), target);
    }
  }
}
