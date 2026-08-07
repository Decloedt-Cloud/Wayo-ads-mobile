import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../config/auth_runtime_config.dart';
import '../network/api_endpoints.dart';
import '../storage/app_prefs.dart';
import 'push_registration_debug.dart';
import 'push_registration_lifecycle.dart';
import 'user_push_notifications_preference.dart';
import 'wayo_push_intent.dart';
import 'wayo_push_service.dart';

const _kLastRegTokenHash = 'push.reg.last_token_hash';
const _kLastRegUserId = 'push.reg.last_user_id';
const _kLastRegClientApp = 'push.reg.last_client_app';
const _kLastRegAtMs = 'push.reg.last_at_ms';

const _kClientApp = 'wayo-ads-go';

String _tokenHash(String token) =>
    sha256.convert(utf8.encode(token)).toString().substring(0, 16);

String _tokenPrefix(String? token) {
  if (token == null || token.isEmpty) return '(empty)';
  final n = token.length < 18 ? token.length : 18;
  return token.substring(0, n);
}

Future<bool>? _pushDeviceRegistrationInFlight;
Future<void>? _pushDeviceUnregisterInFlight;

/// Registers with any cached FCM token first, then refreshes from Firebase and
/// re-registers only if the token changed / was missing.
Future<bool> ensureWayoPushDeviceRegistered({
  required Dio wayoAdsDio,
  required AppPrefs prefs,
  PushRegisterReason reason = PushRegisterReason.ensureAfterCache,
}) async {
  if (PushRegistrationGate.isBlocked) {
    logPushLifecycle(
      '[FCM][REGISTER_ATTEMPT] reason=${reason.name} blocked=true',
    );
    return false;
  }

  final before = readCachedFcmToken(prefs);
  var ok = false;
  if (before != null && before.isNotEmpty) {
    PushRegistrationDebug.recordToken(before);
    ok = await registerWayoPushDeviceIfTokenPresent(
      wayoAdsDio: wayoAdsDio,
      prefs: prefs,
      reason: reason,
    );
    logPushLifecycle('ensureRegister: early (cached) result=$ok');
  }

  await refreshAndCacheFcmToken(
    prefs,
    preferCached: before != null && before.isNotEmpty,
  );
  final after = readCachedFcmToken(prefs);
  PushRegistrationDebug.recordToken(after);

  if (after == null || after.isEmpty) {
    logPushLifecycle('ensureRegister: no FCM token after refresh');
    return ok;
  }
  if (!ok || after != before) {
    ok = await registerWayoPushDeviceIfTokenPresent(
      wayoAdsDio: wayoAdsDio,
      prefs: prefs,
      reason: reason,
    );
    logPushLifecycle('ensureRegister: after refresh result=$ok');
  }
  return ok;
}

/// Registers the cached FCM token with Wayo-ads (idempotent + coalesced).
Future<bool> registerWayoPushDeviceIfTokenPresent({
  required Dio wayoAdsDio,
  required AppPrefs prefs,
  PushRegisterReason reason = PushRegisterReason.login,
}) async {
  if (PushRegistrationGate.isBlocked) {
    logPushLifecycle(
      '[FCM][REGISTER_ATTEMPT] reason=${reason.name} skipped — gate blocked',
    );
    return false;
  }
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
  PushRegistrationDebug.recordToken(token);

  final suppressed = await isPushExternalDeliverySuppressed();

  // Idempotent short-circuit: same user + token + app already registered.
  // Never dedupe while delivery is suppressed — that leaves FCM dead until
  // the user toggles push off/on.
  final hash = _tokenHash(token);
  final lastHash = prefs.getString(_kLastRegTokenHash);
  final lastUser = prefs.getString(_kLastRegUserId);
  final lastApp = prefs.getString(_kLastRegClientApp);
  final registeredUser = await readRegisteredPushWayoUserId();
  final forcePost = suppressed ||
      reason == PushRegisterReason.tokenRefresh ||
      reason == PushRegisterReason.resumeRefresh ||
      reason == PushRegisterReason.forceHeal ||
      reason == PushRegisterReason.userEnabled ||
      reason == PushRegisterReason.appStart;
  if (!forcePost &&
      lastHash == hash &&
      lastApp == _kClientApp &&
      registeredUser != null &&
      registeredUser.isNotEmpty &&
      (lastUser == null || lastUser == registeredUser)) {
    final lastAt = prefs.getInt(_kLastRegAtMs);
    final ageMs = DateTime.now().millisecondsSinceEpoch - lastAt;
    if (ageMs >= 0 && ageMs < 45000) {
      logPushLifecycle(
        '[FCM][REGISTER_ATTEMPT] reason=${reason.name} deduped '
        'tokenPrefix=${_tokenPrefix(token)} ageMs=$ageMs',
      );
      PushRegistrationDebug.recordRegisterReason(reason.name);
      PushRegistrationDebug.lastRegisteredUserId = registeredUser;
      // Heal sticky suppress after logout/disable races without a full POST.
      await activatePushDeliveryForWayoUser(registeredUser);
      return true;
    }
  }
  if (suppressed) {
    logPushLifecycle(
      '[FCM][REGISTER_ATTEMPT] reason=${reason.name} forcePost=suppress '
      'tokenPrefix=${_tokenPrefix(token)}',
    );
  }

  final existing = _pushDeviceRegistrationInFlight;
  if (existing != null) {
    logPushLifecycle('register: coalesced with in-flight POST');
    return existing;
  }

  final gen = PushRegistrationGate.beginAttempt();
  final runner = _postPushDevice(
    wayoAdsDio: wayoAdsDio,
    prefs: prefs,
    token: token,
    reason: reason,
    generation: gen,
  );
  _pushDeviceRegistrationInFlight = runner;
  try {
    return await runner;
  } finally {
    if (identical(_pushDeviceRegistrationInFlight, runner)) {
      _pushDeviceRegistrationInFlight = null;
    }
  }
}

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
  required AppPrefs prefs,
  required String token,
  required PushRegisterReason reason,
  required int generation,
}) async {
  final platform = Platform.isIOS
      ? 'ios'
      : Platform.isAndroid
      ? 'android'
      : 'other';
  final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
    ApiEndpoints.userPushDevice,
  );
  final prefix = _tokenPrefix(token);

  logPushLifecycle(
    '[FCM][REGISTER_ATTEMPT] reason=${reason.name} '
    'tokenPrefix=$prefix platform=$platform clientApp=$_kClientApp '
    'lifecycle=register timestamp=${DateTime.now().toUtc().toIso8601String()}',
  );
  PushRegistrationDebug.recordRegisterReason(reason.name);

  if (PushRegistrationGate.isBlocked ||
      generation != PushRegistrationGate.generation) {
    logPushLifecycle(
      '[FCM][REGISTER_RESULT] success=false aborted=gate '
      'tokenPrefix=$prefix',
    );
    return false;
  }

  final requestBody =
      '{fcmToken: ${PushRegistrationDebug.maskFcmToken(token)}, '
      'platform: $platform, clientApp: $_kClientApp}';
  try {
    final res = await wayoAdsDio.post<Map<String, dynamic>>(
      path,
      data: <String, dynamic>{
        'fcmToken': token,
        'platform': platform,
        'clientApp': _kClientApp,
      },
    );

    final responseBody = res.data?.toString() ?? '(empty)';
    PushRegistrationDebug.recordHttp(
      status: res.statusCode,
      requestBody: requestBody,
      responseBody: responseBody,
      kind: 'register',
    );
    logPushLifecycle(
      '[FCM][REGISTER_RESULT] success=true status=${res.statusCode} '
      'tokenPrefix=$prefix body=$responseBody',
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

    // POST already upserted the token. If unregister raced mid-flight, skip
    // local activation — next allow/heal reconciles.
    if (PushRegistrationGate.isBlocked ||
        generation != PushRegistrationGate.generation) {
      logPushLifecycle(
        '[FCM][REGISTER_RESULT] success=false aborted=post_gate '
        'status=${res.statusCode} tokenPrefix=$prefix '
        '(token may exist server-side — next heal will reconcile)',
      );
      return false;
    }

    PushRegistrationDebug.lastRegisteredUserId = wayoUserId;
    await activatePushDeliveryForWayoUser(wayoUserId);
    await prefs.setString(_kLastRegTokenHash, _tokenHash(token));
    await prefs.setString(_kLastRegUserId, wayoUserId);
    await prefs.setString(_kLastRegClientApp, _kClientApp);
    await prefs.setInt(
      _kLastRegAtMs,
      DateTime.now().millisecondsSinceEpoch,
    );
    logPushLifecycle('register: delivery activated for userId=$wayoUserId');
    return true;
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    final data = e.response?.data?.toString() ?? e.message ?? '(no body)';
    PushRegistrationDebug.recordHttp(
      status: status,
      requestBody: requestBody,
      responseBody: data,
      kind: 'register',
    );
    logPushLifecycle(
      '[FCM][REGISTER_RESULT] success=false status=$status '
      'tokenPrefix=$prefix type=${e.type} response=$data',
    );
    return false;
  } catch (e, st) {
    logPushLifecycle(
      '[FCM][REGISTER_RESULT] success=false unexpected: $e',
      error: e,
      stackTrace: st,
    );
    return false;
  }
}

/// Removes this device's FCM token server-side. Does **not** call
/// [FirebaseMessaging.deleteToken] (avoids onTokenRefresh → re-POST race).
Future<void> unregisterWayoPushDeviceOnLogout({
  required Dio wayoAdsDio,
  required AppPrefs prefs,
  PushUnregisterReason reason = PushUnregisterReason.logout,
}) async {
  final existing = _pushDeviceUnregisterInFlight;
  if (existing != null) {
    logPushLifecycle('unregister: coalesced with in-flight DELETE');
    return existing;
  }

  final runner = _unregisterOnce(
    wayoAdsDio: wayoAdsDio,
    prefs: prefs,
    reason: reason,
  );
  _pushDeviceUnregisterInFlight = runner;
  try {
    await runner;
  } finally {
    if (identical(_pushDeviceUnregisterInFlight, runner)) {
      _pushDeviceUnregisterInFlight = null;
    }
  }
}

Future<void> _unregisterOnce({
  required Dio wayoAdsDio,
  required AppPrefs prefs,
  required PushUnregisterReason reason,
}) async {
  // Block token-refresh / sync from re-POSTing while we DELETE.
  PushRegistrationGate.block(reason: reason.name);
  _pushDeviceRegistrationInFlight = null;

  final token = readCachedFcmToken(prefs);
  final prefix = _tokenPrefix(token);
  final userId = await readRegisteredPushWayoUserId();

  logPushLifecycle(
    '[FCM][UNREGISTER_ATTEMPT] reason=${reason.name} '
    'userId=${userId ?? "(none)"} tokenPrefix=$prefix '
    'lifecycle=unregister '
    'timestamp=${DateTime.now().toUtc().toIso8601String()}',
  );
  PushRegistrationDebug.recordUnregisterReason(reason.name);

  await deactivatePushDelivery();
  await clearWayoPushPendingIntents();
  await dismissAllWayoLocalPushNotifications();

  var deleted = false;
  var statusCode = 0;
  if (token != null && token.isNotEmpty) {
    try {
      final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.userPushDevice,
      );
      final res = await wayoAdsDio.delete<void>(
        path,
        queryParameters: <String, dynamic>{'fcmToken': token},
      );
      statusCode = res.statusCode ?? 0;
      deleted = statusCode >= 200 && statusCode < 300;
      logPushLifecycle(
        '[FCM][UNREGISTER_RESULT] success=$deleted status=$statusCode '
        'deletedTokenPrefix=$prefix reason=${reason.name}',
      );
      PushRegistrationDebug.recordHttp(
        status: statusCode,
        requestBody: 'DELETE fcmToken=${PushRegistrationDebug.maskFcmToken(token)}',
        responseBody: 'ok=$deleted',
        kind: 'unregister',
      );
    } on DioException catch (e) {
      statusCode = e.response?.statusCode ?? 0;
      logPushLifecycle(
        '[FCM][UNREGISTER_RESULT] success=false status=$statusCode '
        'deletedTokenPrefix=$prefix reason=${reason.name}',
      );
      PushRegistrationDebug.recordHttp(
        status: statusCode,
        requestBody: 'DELETE fcmToken=${PushRegistrationDebug.maskFcmToken(token)}',
        responseBody: e.message ?? '(error)',
        kind: 'unregister',
      );
    } catch (e) {
      logPushLifecycle(
        '[FCM][UNREGISTER_RESULT] success=false unexpected=$e '
        'reason=${reason.name}',
      );
    }
  } else {
    logPushLifecycle(
      '[FCM][UNREGISTER_RESULT] success=true skipped=no_token '
      'reason=${reason.name}',
    );
  }

  // Clear local registration metadata + cached token string.
  // Do NOT call FirebaseMessaging.deleteToken() — that triggers onTokenRefresh
  // and caused DELETE→immediate POST while auth was still authenticated.
  await clearCachedFcmToken(prefs);
  await prefs.setString(_kLastRegTokenHash, '');
  await prefs.setString(_kLastRegUserId, '');
  await prefs.setString(_kLastRegClientApp, '');
  await prefs.setInt(_kLastRegAtMs, 0);
  PushRegistrationDebug.lastRegisteredUserId = null;
}

/// Re-enable registration after login / user opt-in.
void allowPushRegistrationAfterAuth() {
  PushRegistrationGate.allow(reason: 'auth_ready');
}
