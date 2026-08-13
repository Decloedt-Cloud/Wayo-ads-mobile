import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../push/wayo_push_service.dart';
import '../review/app_store_links.dart';
import 'app_update_info.dart';
import 'app_update_status.dart';
import 'app_version_utils.dart';

/// Centralized store-version check (Android / iOS) via Firebase Remote Config.
///
/// Preferred Remote Config keys (platform-specific):
/// - `android_minimum_build` / `ios_minimum_build` (Number)
/// - `android_latest_build` / `ios_latest_build` (Number)
/// - `android_store_url` / `ios_store_url` (String)
/// - `android_update_message` / `ios_update_message` (String, optional)
///
/// Legacy Ads keys (still honored as fallbacks):
/// - `force_update_enabled`
/// - `force_update_min_build_android` / `force_update_min_build_ios`
/// - `force_update_android_store_url` / `force_update_ios_store_url`
abstract final class AppUpdateService {
  static const _logName = 'AppUpdate';

  static const _rcAndroidMin = 'android_minimum_build';
  static const _rcAndroidLatest = 'android_latest_build';
  static const _rcAndroidStore = 'android_store_url';
  static const _rcAndroidMessage = 'android_update_message';

  static const _rcIosMin = 'ios_minimum_build';
  static const _rcIosLatest = 'ios_latest_build';
  static const _rcIosStore = 'ios_store_url';
  static const _rcIosMessage = 'ios_update_message';

  // Legacy keys (Wayo Ads force-update).
  static const _rcLegacyEnabled = 'force_update_enabled';
  static const _rcLegacyMinAndroid = 'force_update_min_build_android';
  static const _rcLegacyMinIos = 'force_update_min_build_ios';
  static const _rcLegacyStoreAndroid = 'force_update_android_store_url';
  static const _rcLegacyStoreIos = 'force_update_ios_store_url';

  static FirebaseRemoteConfig? _remoteConfig;
  static bool _defaultsApplied = false;

  /// Evaluates Remote Config + [PackageInfo] for the current mobile platform.
  ///
  /// Fail-open: network / Firebase errors return [AppUpdateInfo.none] unless a
  /// previously activated Remote Config cache already exposes thresholds.
  static Future<AppUpdateInfo> checkForUpdate() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return AppUpdateInfo.none;
    }
    if (!wayoFirebaseCoreReady) {
      _log('Firebase not ready — skip');
      return AppUpdateInfo.none;
    }

    try {
      final remoteConfig = await _ensureRemoteConfig();
      try {
        await remoteConfig.fetchAndActivate().timeout(const Duration(seconds: 8));
      } catch (e) {
        // Use last activated / default values — do not block the app.
        _log('fetchAndActivate failed (using cache/defaults): $e');
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild =
          AppVersionUtils.parseBuildNumber(packageInfo.buildNumber);

      final isIos = Platform.isIOS;
      var minimumBuild = remoteConfig.getInt(isIos ? _rcIosMin : _rcAndroidMin);
      var latestBuild =
          remoteConfig.getInt(isIos ? _rcIosLatest : _rcAndroidLatest);

      // Legacy min-build fallback when new keys are unset.
      if (minimumBuild <= 0) {
        minimumBuild = remoteConfig.getInt(
          isIos ? _rcLegacyMinIos : _rcLegacyMinAndroid,
        );
      }

      // Legacy master switch: when new latest is unset, only force-update path.
      final legacyEnabled = remoteConfig.getBool(_rcLegacyEnabled);
      if (latestBuild <= 0 && legacyEnabled && minimumBuild > 0) {
        // Preserve old behavior: below min → required; otherwise none.
        latestBuild = 0;
      }

      final storeUrl = _resolveStoreUrl(remoteConfig, isIos: isIos);
      final message = remoteConfig
          .getString(isIos ? _rcIosMessage : _rcAndroidMessage)
          .trim();

      var status = AppVersionUtils.resolveStatus(
        currentBuild: currentBuild,
        minimumBuild: minimumBuild,
        latestBuild: latestBuild,
      );

      // Legacy: if only force_update_enabled + min (no latest), honor enabled flag.
      if (latestBuild <= 0 &&
          remoteConfig.getInt(isIos ? _rcIosMin : _rcAndroidMin) <= 0) {
        if (!legacyEnabled) {
          status = AppUpdateStatus.none;
        } else if (status != AppUpdateStatus.required) {
          status = AppUpdateStatus.none;
        }
      }

      if (status != AppUpdateStatus.none && storeUrl.isEmpty) {
        _log(
          'Update $status but store URL missing — allowing app '
          '(set ${isIos ? _rcIosStore : _rcAndroidStore})',
        );
        return AppUpdateInfo(
          status: AppUpdateStatus.none,
          currentBuild: currentBuild,
          minimumBuild: minimumBuild,
          latestBuild: latestBuild,
          storeUrl: '',
          message: message.isEmpty ? null : message,
        );
      }

      _log(
        'Platform: ${isIos ? 'ios' : 'android'}\n'
        'Current build: $currentBuild\n'
        'Minimum build: $minimumBuild\n'
        'Latest build: $latestBuild\n'
        'Status: ${status.name.toUpperCase()}',
      );

      return AppUpdateInfo(
        status: status,
        currentBuild: currentBuild,
        minimumBuild: minimumBuild,
        latestBuild: latestBuild,
        storeUrl: storeUrl,
        message: message.isEmpty ? null : message,
      );
    } catch (e, st) {
      developer.log(
        'checkForUpdate failed (continuing): $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return AppUpdateInfo.none;
    }
  }

  static String _resolveStoreUrl(
    FirebaseRemoteConfig remoteConfig, {
    required bool isIos,
  }) {
    if (isIos) {
      final configured = remoteConfig.getString(_rcIosStore).trim();
      if (configured.isNotEmpty) return configured;
      final legacy = remoteConfig.getString(_rcLegacyStoreIos).trim();
      if (legacy.isNotEmpty) return legacy;
      return AppStoreLinks.iosListingUrl;
    }

    final configured = remoteConfig.getString(_rcAndroidStore).trim();
    if (configured.isNotEmpty) return configured;
    final legacy = remoteConfig.getString(_rcLegacyStoreAndroid).trim();
    if (legacy.isNotEmpty) return legacy;
    return AppStoreLinks.androidListingUrl;
  }

  static Future<FirebaseRemoteConfig> _ensureRemoteConfig() async {
    if (_remoteConfig != null) return _remoteConfig!;

    final remoteConfig = FirebaseRemoteConfig.instance;
    if (!_defaultsApplied) {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults(<String, dynamic>{
        _rcAndroidMin: 0,
        _rcAndroidLatest: 0,
        _rcAndroidStore: AppStoreLinks.androidListingUrl,
        _rcAndroidMessage: '',
        _rcIosMin: 0,
        _rcIosLatest: 0,
        _rcIosStore: AppStoreLinks.iosListingUrl,
        _rcIosMessage: '',
        _rcLegacyEnabled: false,
        _rcLegacyMinAndroid: 0,
        _rcLegacyMinIos: 0,
        _rcLegacyStoreAndroid: AppStoreLinks.androidListingUrl,
        _rcLegacyStoreIos: AppStoreLinks.iosListingUrl,
      });
      _defaultsApplied = true;
    }

    _remoteConfig = remoteConfig;
    return remoteConfig;
  }

  static void _log(String message) {
    if (kDebugMode) {
      developer.log(message, name: _logName);
    }
  }
}
