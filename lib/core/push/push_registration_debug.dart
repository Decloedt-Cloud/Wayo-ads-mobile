import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/auth_runtime_config.dart';
import '../storage/app_prefs.dart';
import 'system_push_permission.dart';
import 'user_push_notifications_preference.dart';
import 'wayo_push_service.dart';

/// Which step failed during [enableUserPushNotifications].
enum PushEnableStep {
  firebaseInit,
  permission,
  getToken,
  backendRegister,
  success,
}

/// In-memory snapshot for debug UI + adb logcat (no PII beyond masked token).
class PushRegistrationDebug {
  PushRegistrationDebug._();

  static PushEnableStep? lastFailedStep;
  static String? lastFailedMessage;
  static String? lastPermissionStatus;
  static bool? lastPermissionGranted;
  static String? lastTokenPreview;
  static int? lastHttpStatus;
  static String? lastHttpResponse;
  static String? lastHttpRequestBody;
  static String? lastRegisteredUserId;
  static DateTime? lastAttemptAt;

  static void reset() {
    lastFailedStep = null;
    lastFailedMessage = null;
    lastPermissionStatus = null;
    lastPermissionGranted = null;
    lastTokenPreview = null;
    lastHttpStatus = null;
    lastHttpResponse = null;
    lastHttpRequestBody = null;
    lastRegisteredUserId = null;
    lastAttemptAt = DateTime.now();
  }

  static void recordFailure(PushEnableStep step, String message) {
    lastFailedStep = step;
    lastFailedMessage = message;
    lastAttemptAt = DateTime.now();
    logPushLifecycle('debug: FAILED step=$step — $message');
  }

  static void recordSuccess({String? userId}) {
    lastFailedStep = null;
    lastFailedMessage = null;
    lastRegisteredUserId = userId;
    lastAttemptAt = DateTime.now();
    logPushLifecycle('debug: SUCCESS userId=${userId ?? "(unknown)"}');
  }

  static void recordPermission(String status, {required bool granted}) {
    lastPermissionStatus = status;
    lastPermissionGranted = granted;
    logPushLifecycle('debug: permission status=$status granted=$granted');
  }

  static void recordToken(String? token) {
    lastTokenPreview = maskFcmToken(token);
    logPushLifecycle(
      'debug: token ${token == null || token.isEmpty ? "MISSING" : "present (${token.length} chars) ${maskFcmToken(token)}"}',
    );
  }

  static void recordHttp({
    required int? status,
    required String requestBody,
    required String responseBody,
  }) {
    lastHttpStatus = status;
    lastHttpRequestBody = requestBody;
    lastHttpResponse = responseBody;
    logPushLifecycle(
      'debug: HTTP status=$status request=$requestBody response=$responseBody',
    );
  }

  static String maskFcmToken(String? token) {
    if (token == null || token.isEmpty) return '(empty)';
    if (token.length <= 12) return '${token.length} chars';
    return '${token.substring(0, 8)}…${token.substring(token.length - 4)} (${token.length})';
  }

  static String get failureSummary {
    if (lastFailedStep == null) return 'OK';
    final step = lastFailedStep!.name;
    final msg = lastFailedMessage ?? '';
    return '$step: $msg';
  }

  /// Read-only diagnostic snapshot for the debug panel.
  static Future<Map<String, String>> collectSnapshot(AppPrefs prefs) async {
    final platform = kIsWeb
        ? 'web'
        : Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : defaultTargetPlatform.name;

    final firebaseProject = wayoFirebaseCoreReady
        ? 'initialized (wayo-ads-27cbf)'
        : 'NOT READY — check google-services.json / firebase_options.dart';

    String permissionLine = '(unknown)';
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.notification.status;
      permissionLine = 'Android POST_NOTIFICATIONS: $status';
    } else if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      if (wayoFirebaseCoreReady) {
        try {
          final s = await FirebaseMessaging.instance.getNotificationSettings();
          permissionLine = 'iOS authorization: ${s.authorizationStatus}';
        } catch (e) {
          permissionLine = 'iOS settings error: $e';
        }
      } else {
        permissionLine = 'iOS (Firebase not ready)';
      }
    }

    final cachedToken = readCachedFcmToken(prefs);
    final userEnabled = await isUserPushNotificationsEnabled(prefs);
    final systemGranted = await areSystemPushNotificationsGranted();
    final registeredUser = await readRegisteredPushWayoUserId();
    final suppressed = await isPushExternalDeliverySuppressed();
    final apiBase = AuthRuntimeConfig.instance.resolvedWayoAdsBaseUrl;

    return {
      'Platform': platform,
      'Firebase': firebaseProject,
      'google-services': Platform.isAndroid
          ? 'android/app/google-services.json (wayo-ads-27cbf)'
          : Platform.isIOS
          ? 'ios/Runner/GoogleService-Info.plist'
          : 'n/a',
      'API base': apiBase.isEmpty ? '(empty!)' : apiBase,
      'User pref enabled': userEnabled ? 'yes' : 'no',
      'OS permission': permissionLine,
      'OS granted (check)': systemGranted ? 'yes' : 'no',
      'Cached FCM token': maskFcmToken(cachedToken),
      'Registered userId': registeredUser ?? '(none)',
      'Delivery suppressed': suppressed ? 'yes' : 'no',
      'Last failure': failureSummary,
      'Last HTTP': lastHttpStatus == null
          ? '(none)'
          : '$lastHttpStatus ${lastHttpResponse ?? ""}',
    };
  }
}
