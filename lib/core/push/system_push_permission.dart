import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'wayo_push_service.dart';

/// Whether OS-level notification permission is already granted (no prompt).
Future<bool> areSystemPushNotificationsGranted() async {
  if (kIsWeb) {
    return false;
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    final status = await Permission.notification.status;
    logPushLifecycle('permission: Android POST_NOTIFICATIONS status=$status');
    return status.isGranted;
  }
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    if (!wayoFirebaseCoreReady) {
      logPushLifecycle('permission: iOS check skipped — Firebase not ready');
      return false;
    }
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      logPushLifecycle(
        'permission: iOS authorizationStatus=${settings.authorizationStatus}',
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      logPushLifecycle('permission: iOS getNotificationSettings failed: $e');
      return false;
    }
  }
  return false;
}
