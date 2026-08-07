import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/app_prefs.dart';
import 'push_registration_debug.dart';
import 'push_registration_lifecycle.dart';
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
  await unregisterWayoPushDeviceOnLogout(
    wayoAdsDio: wayoAdsDio,
    prefs: prefs,
    reason: PushUnregisterReason.userDisabled,
  );
}

/// User turned on push: OS permission + FCM register with Wayo-ads.
Future<bool> enableUserPushNotifications({
  required Dio wayoAdsDio,
  required AppPrefs prefs,
  PushRegisterReason reason = PushRegisterReason.userEnabled,
}) async {
  PushRegistrationDebug.reset();
  logPushLifecycle('enable: start');
  await setUserPushNotificationsEnabled(prefs, true);
  allowPushRegistrationAfterAuth();

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
    await setUserPushNotificationsEnabled(prefs, false);
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
    await setUserPushNotificationsEnabled(prefs, false);
    return false;
  }
  if (!granted && Platform.isAndroid) {
    logPushLifecycle(
      'enable: Android POST_NOTIFICATIONS not granted — continuing to getToken/register',
    );
  }

  final registered = await ensureWayoPushDeviceRegistered(
    wayoAdsDio: wayoAdsDio,
    prefs: prefs,
    reason: reason,
  );
  final token = readCachedFcmToken(prefs);
  PushRegistrationDebug.recordToken(token);
  if (token == null || token.isEmpty) {
    final isApplePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final msg = granted
        ? isApplePlatform
            ? 'FirebaseMessaging.getToken() returned empty — iOS: enable Push Notifications '
                'in Xcode (aps-environment), upload APNs key in Firebase Console '
                '(wayo-ads-27cbf), test on a physical device'
            : 'FirebaseMessaging.getToken() returned empty — add debug+release SHA-1/SHA-256 '
                'for ma.wayo.wayoadsgo in Firebase Console (wayo-ads-27cbf). '
                'Run: cd android && ./gradlew signingReport'
        : 'No FCM token — grant POST_NOTIFICATIONS (Android 13+) or fix Firebase SHA fingerprints';
    PushRegistrationDebug.recordFailure(PushEnableStep.getToken, msg);
    logPushLifecycle('enable: FAILED — $msg');
    await setUserPushNotificationsEnabled(prefs, false);
    return false;
  }
  logPushLifecycle(
    'enable: FCM token cached (${token.length} chars) '
    '${PushRegistrationDebug.maskFcmToken(token)}',
  );

  if (!registered) {
    const msg =
        'POST /api/user/push-device failed — check auth Bearer token, '
        'WAYO_ADS_API_BASE_URL, and server logs';
    PushRegistrationDebug.recordFailure(PushEnableStep.backendRegister, msg);
    logPushLifecycle('enable: FAILED — $msg');
    await setUserPushNotificationsEnabled(prefs, false);
    return false;
  }

  PushRegistrationDebug.recordSuccess(
    userId: PushRegistrationDebug.lastRegisteredUserId,
  );
  logPushLifecycle('enable: SUCCESS — token registered with backend');
  return true;
}
