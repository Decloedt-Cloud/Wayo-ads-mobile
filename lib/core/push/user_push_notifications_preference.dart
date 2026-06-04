import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/auth_runtime_config.dart';
import '../network/api_endpoints.dart';
import '../storage/app_prefs.dart';
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
  logPushLifecycle('enable: start');
  await setUserPushNotificationsEnabled(prefs, true);

  if (!wayoFirebaseCoreReady) {
    logPushLifecycle('enable: Firebase not ready — initializing');
    await initializeFirebaseForPush();
  }
  if (!wayoFirebaseCoreReady) {
    logPushLifecycle(
      'enable: FAILED — Firebase.initializeApp did not succeed. '
      'Check google-services.json (project wayo-ads-27cbf), '
      'lib/firebase_options.dart, and release SHA-1/SHA-256 in Firebase Console.',
    );
    return false;
  }

  await attachForegroundFcmHandlers();
  logPushLifecycle('enable: foreground FCM handlers attached');

  final granted = await requestSystemPushPermission();
  logPushLifecycle('enable: system permission granted=$granted');
  if (!granted) {
    logPushLifecycle(
      'enable: FAILED — POST_NOTIFICATIONS denied or FCM permission not authorized',
    );
    return false;
  }

  await refreshAndCacheFcmToken(prefs);
  final token = readCachedFcmToken(prefs);
  if (token == null || token.isEmpty) {
    logPushLifecycle(
      'enable: FAILED — no FCM token after refresh. '
      'Add debug/release SHA-1 and SHA-256 for ma.wayo.wayoadsgo in Firebase Console '
      '(Project settings → Your apps → Android). '
      'Run: cd android && ./gradlew signingReport',
    );
    return false;
  }
  logPushLifecycle('enable: FCM token cached (${token.length} chars)');

  final registered = await registerWayoPushDeviceIfTokenPresent(
    wayoAdsDio: wayoAdsDio,
    prefs: prefs,
  );
  if (!registered) {
    logPushLifecycle(
      'enable: FAILED — POST /api/user/push-device did not succeed. '
      'Check Wayo-ads auth session (Bearer token) and API base URL.',
    );
    return false;
  }

  logPushLifecycle('enable: SUCCESS — token registered with backend');
  return true;
}
