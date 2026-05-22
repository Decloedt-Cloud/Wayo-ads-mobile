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
  await setUserPushNotificationsEnabled(prefs, false);
  await deactivatePushDelivery();
  await dismissAllWayoLocalPushNotifications();

  if (!wayoFirebaseCoreReady) {
    return;
  }
  final token = readCachedFcmToken(prefs);
  if (token == null || token.isEmpty) {
    return;
  }
  try {
    final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
      ApiEndpoints.userPushDevice,
    );
    await wayoAdsDio.delete<void>(
      path,
      queryParameters: <String, dynamic>{'fcmToken': token},
    );
  } on DioException {
    /* best effort */
  } catch (_) {}
}

/// User turned on push: OS permission + FCM register with Wayo-ads.
Future<bool> enableUserPushNotifications({
  required Dio wayoAdsDio,
  required AppPrefs prefs,
}) async {
  await setUserPushNotificationsEnabled(prefs, true);
  if (!wayoFirebaseCoreReady) {
    await initializeFirebaseForPush();
  }
  if (!wayoFirebaseCoreReady) {
    return false;
  }
  await attachForegroundFcmHandlers();
  final granted = await requestSystemPushPermission();
  if (!granted) {
    return false;
  }
  await refreshAndCacheFcmToken(prefs);
  return registerWayoPushDeviceIfTokenPresent(
    wayoAdsDio: wayoAdsDio,
    prefs: prefs,
  );
}
