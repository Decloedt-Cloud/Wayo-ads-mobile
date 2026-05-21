import 'dart:io' show Platform;



import 'package:dio/dio.dart';



import '../config/auth_runtime_config.dart';

import '../network/api_endpoints.dart';

import '../storage/app_prefs.dart';

import 'wayo_push_intent.dart';

import 'wayo_push_service.dart';



/// Registers the cached FCM token with Wayo-ads so [scheduleMobilePushForNotification]

/// can reach this device (all roles: creator, advertiser, superadmin).

///

/// Coalesces concurrent calls (cold start login + permission host): one POST avoids

/// amplifying bursts when Wayo Ads returns 5xx during recovery.

///

/// Returns `true` when the token is linked to the Wayo-ads user and push delivery is active.

Future<bool> registerWayoPushDeviceIfTokenPresent({

  required Dio wayoAdsDio,

  required AppPrefs prefs,

}) async {

  if (!wayoFirebaseCoreReady) {

    return false;

  }

  var token = readCachedFcmToken(prefs);

  if (token == null || token.isEmpty) {

    await refreshAndCacheFcmToken(prefs);

    token = readCachedFcmToken(prefs);

  }

  if (token == null || token.isEmpty) {

    return false;

  }



  final existing = _pushDeviceRegistrationInFlight;

  if (existing != null) {

    return existing;

  }



  final runner = _postPushDevice(wayoAdsDio: wayoAdsDio, token: token);

  _pushDeviceRegistrationInFlight = runner;

  try {

    return await runner;

  } finally {

    if (identical(_pushDeviceRegistrationInFlight, runner)) {

      _pushDeviceRegistrationInFlight = null;

    }

  }

}



Future<bool>? _pushDeviceRegistrationInFlight;



Future<String?> _fetchWayoAdsUserId(Dio wayoAdsDio) async {
  try {
    final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
      ApiEndpoints.userProfile,
    );
    final res = await wayoAdsDio.get<Map<String, dynamic>>(path);
    final user = res.data?['user'];
    if (user is Map<String, dynamic>) {
      final id = user['id']?.toString().trim();
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }
  } on DioException {
    /* ignore */
  } catch (_) {}
  return null;
}

Future<bool> _postPushDevice({
  required Dio wayoAdsDio,
  required String token,
}) async {
  final platform = Platform.isIOS
      ? 'ios'
      : Platform.isAndroid
      ? 'android'
      : 'other';
  try {
    final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
      ApiEndpoints.userPushDevice,
    );
    final res = await wayoAdsDio.post<Map<String, dynamic>>(
      path,
      data: <String, dynamic>{'fcmToken': token, 'platform': platform},
    );
    final body = res.data;
    var wayoUserId = body?['userId']?.toString().trim() ?? '';
    if (wayoUserId.isEmpty) {
      wayoUserId = (await _fetchWayoAdsUserId(wayoAdsDio)) ?? '';
    }
    if (wayoUserId.isEmpty) {
      return false;
    }
    await activatePushDeliveryForWayoUser(wayoUserId);
    return true;
  } on DioException {
    return false;
  } catch (_) {
    return false;
  }
}



/// Removes this device's FCM token server-side and blocks local FCM until re-register.

Future<void> unregisterWayoPushDeviceOnLogout({

  required Dio wayoAdsDio,

  required AppPrefs prefs,

}) async {

  await deactivatePushDelivery();

  await clearWayoPushPendingIntents();

  await dismissAllWayoLocalPushNotifications();



  if (!wayoFirebaseCoreReady) {

    return;

  }

  final token = readCachedFcmToken(prefs);

  if (token != null && token.isNotEmpty) {

    try {

      final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(

        ApiEndpoints.userPushDevice,

      );

      await wayoAdsDio.delete<void>(

        path,

        queryParameters: <String, dynamic>{'fcmToken': token},

      );

    } on DioException {

      // Session may already be invalid; server also accepts token-only DELETE.

    } catch (_) {}

  }



  await revokeLocalFcmToken(prefs);

}


