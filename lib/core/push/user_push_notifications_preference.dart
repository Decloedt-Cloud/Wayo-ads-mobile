import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/auth_runtime_config.dart';
import '../network/api_endpoints.dart';
import '../storage/app_prefs.dart';
import 'push_registration_debug.dart';
import 'wayo_push_device_register.dart';
import 'wayo_push_service.dart';

/// In-app opt-in for push (creator + advertiser). Distinct from OS permission.
const kPushUserEnabledPrefKey = 'push.user_enabled';

Future<bool> isUserPushNotificationsEnabled(AppPrefs prefs) async {
  final raw = prefs.getString(kPushUserEnabledPrefKey);
  if (raw == null) {
    return true;
  }
  return raw == '1';
}

Future<void> setUserPushNotificationsEnabled(
  AppPrefs prefs,
  bool enabled,
) async {
  await prefs.setString(kPushUserEnabledPrefKey, enabled ? '1' : '0');
}

Future<bool> isUserPushNotificationsEnabledFromDisk() async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(kPushUserEnabledPrefKey);
  if (raw == null) {
    return true;
  }
  return raw == '1';
}

/// User turned off push in preferences: stop delivery and unlink token server-side.
Future<void> disableUserPushNotifications({
  required Dio wayoAdsDio,
  required AppPrefs prefs,
}) async {
  logPushLifecycle('disable: user opted out');
  await setUserPushNotificationsEnabled(prefs, false);
  await deactivatePushDelivery();
  await dismissAllWayoLocalPushNotifications();

  if (!wayoFirebaseCoreReady) {
    logPushLifecycle('disable: Firebase not ready — skipped server DELETE');
    return;
  }
  final token = readCachedFcmToken(prefs);
  if (token == null || token.isEmpty) {
    logPushLifecycle('disable: no cached FCM token — skipped server DELETE');
    return;
  }
  try {
    final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
      ApiEndpoints.userPushDevice,
    );
    logPushLifecycle('disable: DELETE $path fcmTokenLen=${token.length}');
    await wayoAdsDio.delete<void>(
      path,
      queryParameters: <String, dynamic>{'fcmToken': token},
    );
    logPushLifecycle('disable: server DELETE succeeded');
  } on DioException catch (e) {
    logPushLifecycle(
      'disable: server DELETE failed status=${e.response?.statusCode} '
      'message=${e.message}',
    );
  } catch (e) {
    logPushLifecycle('disable: server DELETE failed: $e');
  }
}

/// User turned on push: OS permission + FCM register with Wayo-ads.
Future<bool> enableUserPushNotifications({
  required Dio wayoAdsDio,
  required AppPrefs prefs,
}) async {
  PushRegistrationDebug.reset();
  logPushLifecycle('enable: start');
  await setUserPushNotificationsEnabled(prefs, true);

  if (!wayoFirebaseCoreReady) {
    logPushLifecycle('enable: Firebase not ready — initializing');
    await initializeFirebaseForPush();
  }
  if (!wayoFirebaseCoreReady) {
    const msg =
        'Firebase.initializeApp failed — verify google-services.json / '
        'GoogleService-Info.plist / firebase_options.dart (project wayo-ads-27cbf)';
    PushRegistrationDebug.recordFailure(PushEnableStep.firebaseInit, msg);
    logPushLifecycle('enable: FAILED — $msg');
    return false;
  }

  await attachForegroundFcmHandlers();
  logPushLifecycle('enable: foreground FCM handlers attached');

  final granted = await requestSystemPushPermission();
  logPushLifecycle('enable: system permission granted=$granted');

  final isApple = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (!granted && isApple) {
    const msg =
        'iOS notification permission denied — enable in Settings → Wayo Ads → Notifications';
    PushRegistrationDebug.recordFailure(PushEnableStep.permission, msg);
    logPushLifecycle('enable: FAILED — $msg');
    return false;
  }
  if (!granted && Platform.isAndroid) {
    logPushLifecycle(
      'enable: Android POST_NOTIFICATIONS not granted — continuing to getToken/register',
    );
  }

  await refreshAndCacheFcmToken(prefs);
  final token = readCachedFcmToken(prefs);
  PushRegistrationDebug.recordToken(token);
  if (token == null || token.isEmpty) {
    final isApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final msg = granted
        ? isApple
            ? 'FirebaseMessaging.getToken() returned empty — iOS: enable Push Notifications '
                'in Xcode (aps-environment), upload APNs key in Firebase Console '
                '(wayo-ads-27cbf), test on a physical device'
            : 'FirebaseMessaging.getToken() returned empty — add debug+release SHA-1/SHA-256 '
                'for ma.wayo.wayoadsgo in Firebase Console (wayo-ads-27cbf). '
                'Run: cd android && ./gradlew signingReport'
        : 'No FCM token — grant POST_NOTIFICATIONS (Android 13+) or fix Firebase SHA fingerprints';
    PushRegistrationDebug.recordFailure(PushEnableStep.getToken, msg);
    logPushLifecycle('enable: FAILED — $msg');
    return false;
  }
  logPushLifecycle(
    'enable: FCM token cached (${token.length} chars) '
    '${PushRegistrationDebug.maskFcmToken(token)}',
  );

  final registered = await registerWayoPushDeviceIfTokenPresent(
    wayoAdsDio: wayoAdsDio,
    prefs: prefs,
  );
  if (!registered) {
    const msg =
        'POST /api/user/push-device failed — check auth Bearer token, '
        'WAYO_ADS_API_BASE_URL, and server logs';
    PushRegistrationDebug.recordFailure(PushEnableStep.backendRegister, msg);
    logPushLifecycle('enable: FAILED — $msg');
    return false;
  }

  PushRegistrationDebug.recordSuccess(
    userId: PushRegistrationDebug.lastRegisteredUserId,
  );
  logPushLifecycle('enable: SUCCESS — token registered with backend');
  return true;
}
