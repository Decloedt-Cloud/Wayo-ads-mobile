import 'dart:io' show Platform;

import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';

/// Registers this phone as an active session on Wayo-ads (visible on web + mobile).
Future<void> registerMobileWayoSession({
  required Dio wayoAdsDio,
  required SecureStorageService storage,
}) async {
  final platform = Platform.isIOS
      ? 'ios'
      : Platform.isAndroid
      ? 'android'
      : 'android';

  final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
    ApiEndpoints.userSessionsRegister,
  );

  try {
    final res = await wayoAdsDio.post<Map<String, dynamic>>(
      path,
      data: <String, dynamic>{'platform': platform},
    );
    final sessionId = res.data?['sessionId']?.toString().trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      await storage.saveMobileSessionId(sessionId);
    }
  } on DioException {
    // Non-blocking — settings may still list other devices.
  } catch (_) {}
}
