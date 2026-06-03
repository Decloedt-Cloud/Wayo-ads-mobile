import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../push/wayo_push_service.dart';
import 'app_version_utils.dart';
import 'force_update_config.dart';

/// Reads minimum build + store URLs from Firebase Remote Config.
///
/// Firebase Console keys (create in Remote Config):
/// - `force_update_enabled` (Boolean) — master switch
/// - `force_update_min_build_android` (Number) — minimum Android build (`versionCode`)
/// - `force_update_min_build_ios` (Number) — minimum iOS build (`CFBundleVersion`)
/// - `force_update_android_store_url` (String, optional)
/// - `force_update_ios_store_url` (String, optional — App Store link with numeric id)
abstract final class ForceUpdateService {
  static const _logName = 'wayo.force_update';

  static const _defaultAndroidStoreUrl =
      'https://play.google.com/store/apps/details?id=ma.wayo.wayoadsgo';

  static const _rcEnabled = 'force_update_enabled';
  static const _rcMinBuildAndroid = 'force_update_min_build_android';
  static const _rcMinBuildIos = 'force_update_min_build_ios';
  static const _rcAndroidStoreUrl = 'force_update_android_store_url';
  static const _rcIosStoreUrl = 'force_update_ios_store_url';

  static FirebaseRemoteConfig? _remoteConfig;
  static bool _defaultsApplied = false;

  static Future<ForceUpdateConfig> evaluate() async {
    if (!wayoFirebaseCoreReady) {
      return ForceUpdateConfig.disabled;
    }

    try {
      final remoteConfig = await _ensureRemoteConfig();
      await remoteConfig.fetchAndActivate().timeout(const Duration(seconds: 8));

      if (!remoteConfig.getBool(_rcEnabled)) {
        return ForceUpdateConfig.disabled;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild =
          AppVersionUtils.parseBuildNumber(packageInfo.buildNumber);

      final minimumBuild = Platform.isIOS
          ? remoteConfig.getInt(_rcMinBuildIos)
          : remoteConfig.getInt(_rcMinBuildAndroid);

      final required = AppVersionUtils.isBuildBelowMinimum(
        currentBuild: currentBuild,
        minimumBuild: minimumBuild,
      );

      if (!required) {
        return ForceUpdateConfig.disabled;
      }

      final storeUrl = _resolveStoreUrl(remoteConfig);
      if (storeUrl.isEmpty) {
        developer.log(
          'Force update required but store URL missing — allowing app '
          '(set force_update_${Platform.isIOS ? 'ios' : 'android'}_store_url)',
          name: _logName,
        );
        return ForceUpdateConfig.disabled;
      }

      developer.log(
        'Force update required: build=$currentBuild min=$minimumBuild',
        name: _logName,
      );

      return ForceUpdateConfig(
        required: true,
        minimumBuild: minimumBuild,
        storeUrl: storeUrl,
      );
    } catch (e, st) {
      developer.log(
        'Force update check failed (continuing): $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return ForceUpdateConfig.disabled;
    }
  }

  static String _resolveStoreUrl(FirebaseRemoteConfig remoteConfig) {
    if (Platform.isIOS) {
      final configured = remoteConfig.getString(_rcIosStoreUrl).trim();
      return configured;
    }

    final configured = remoteConfig.getString(_rcAndroidStoreUrl).trim();
    return configured.isNotEmpty ? configured : _defaultAndroidStoreUrl;
  }

  static Future<FirebaseRemoteConfig> _ensureRemoteConfig() async {
    if (_remoteConfig != null) return _remoteConfig!;

    final remoteConfig = FirebaseRemoteConfig.instance;
    if (!_defaultsApplied) {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults(<String, dynamic>{
        _rcEnabled: false,
        _rcMinBuildAndroid: 0,
        _rcMinBuildIos: 0,
        _rcAndroidStoreUrl: _defaultAndroidStoreUrl,
        _rcIosStoreUrl: '',
      });
      _defaultsApplied = true;
    }

    _remoteConfig = remoteConfig;
    return remoteConfig;
  }
}
