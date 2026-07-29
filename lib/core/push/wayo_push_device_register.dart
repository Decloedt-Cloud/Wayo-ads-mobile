import 'dart:io' show Platform;

import 'package:dio/dio.dart';

import '../config/auth_runtime_config.dart';
import '../network/api_endpoints.dart';
import '../storage/app_prefs.dart';
import 'push_registration_debug.dart';
import 'user_push_notifications_preference.dart';
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
    logPushLifecycle('register: skipped — Firebase not ready');
    return false;
  }
  if (!await isUserPushNotificationsEnabled(prefs)) {
    logPushLifecycle('register: skipped — user disabled push in app settings');
    return false;
  }

  var token = readCachedFcmToken(prefs);
  if (token == null || token.isEmpty) {
    logPushLifecycle('register: no cached token — refreshing');
    await refreshAndCacheFcmToken(prefs);
    token = readCachedFcmToken(prefs);
  }
  if (token == null || token.isEmpty) {
    logPushLifecycle('register: skipped — still no FCM token');
    return false;
  }

  final existing = _pushDeviceRegistrationInFlight;
  if (existing != null) {
    logPushLifecycle('register: coalesced with in-flight POST');
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
    logPushLifecycle('register: GET $path (resolve userId fallback)');
    final res = await wayoAdsDio.get<Map<String, dynamic>>(path);
    final user = res.data?['user'];
    if (user is Map<String, dynamic>) {
      final id = user['id']?.toString().trim();
      if (id != null && id.isNotEmpty) {
        logPushLifecycle('register: resolved userId=$id from profile');
        return id;
      }
    }
    logPushLifecycle('register: profile response missing user.id');
  } on DioException catch (e) {
    logPushLifecycle(
      'register: profile fallback failed status=${e.response?.statusCode}',
    );
  } catch (e) {
    logPushLifecycle('register: profile fallback failed: $e');
  }
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
  final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
    ApiEndpoints.userPushDevice,
  );
  final baseUrl = wayoAdsDio.options.baseUrl;
  final requestBody =
      '{fcmToken: ${PushRegistrationDebug.maskFcmToken(token)}, platform: $platform}';
  logPushLifecycle(
    'register: POST $baseUrl$path platform=$platform fcmTokenLen=${token.length}',
  );
  logPushLifecycle('register: request body=$requestBody');
  try {
    final res = await wayoAdsDio.post<Map<String, dynamic>>(
      path,
      data: <String, dynamic>{
        'fcmToken': token,
        'platform': platform,
        'clientApp': 'wayo-ads-go',
      },
    );
    final responseBody = res.data?.toString() ?? '(empty)';
    PushRegistrationDebug.recordHttp(
      status: res.statusCode,
      requestBody: requestBody,
      responseBody: responseBody,
    );
    logPushLifecycle(
      'register: POST succeeded status=${res.statusCode} body=$responseBody',
    );
    final body = res.data;
    var wayoUserId = body?['userId']?.toString().trim() ?? '';
    if (wayoUserId.isEmpty) {
      wayoUserId = (await _fetchWayoAdsUserId(wayoAdsDio)) ?? '';
    }
    if (wayoUserId.isEmpty) {
      logPushLifecycle('register: FAILED — no userId in response or profile');
      return false;
    }
    PushRegistrationDebug.lastRegisteredUserId = wayoUserId;
    await activatePushDeliveryForWayoUser(wayoUserId);
    logPushLifecycle('register: delivery activated for userId=$wayoUserId');
    return true;
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    final data = e.response?.data?.toString() ?? e.message ?? '(no body)';
    PushRegistrationDebug.recordHttp(
      status: status,
      requestBody: requestBody,
      responseBody: data,
    );
    logPushLifecycle(
      'register: POST FAILED status=$status type=${e.type} '
      'message=${e.message} response=$data',
    );
    if (status == 401 || status == 403) {
      logPushLifecycle(
        'register: auth rejected — ensure user is logged in and '
        'AuthInterceptor attaches Bearer token to Wayo-ads requests',
      );
    }
    return false;
  } catch (e, st) {
    logPushLifecycle('register: POST FAILED unexpected: $e', error: e, stackTrace: st);
    return false;
  }
}

/// Removes this device's FCM token server-side and blocks local FCM until re-register.
Future<void> unregisterWayoPushDeviceOnLogout({
  required Dio wayoAdsDio,
  required AppPrefs prefs,
}) async {
  logPushLifecycle('logout: unregister push device');
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
      logPushLifecycle('logout: server DELETE succeeded');
    } on DioException catch (e) {
      logPushLifecycle(
        'logout: server DELETE failed status=${e.response?.statusCode}',
      );
    } catch (_) {}
  }

  await revokeLocalFcmToken(prefs);
}
