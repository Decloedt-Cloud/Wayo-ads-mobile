import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart' as c;
import 'app_config.dart';

/// Merges compile-time `--dart-define(-from-file)` with [dart_defines.json] bundled as an asset.
///
/// Non-empty values in `dart_defines.json` override compile-time defaults so local runs work
/// without passing `--dart-define-from-file` on the CLI.
final class AuthRuntimeConfig {
  AuthRuntimeConfig._();

  static final AuthRuntimeConfig instance = AuthRuntimeConfig._();

  String _authWayoBaseUrl = '';
  String _authBaseUrl = '';
  String _apiBaseUrl = '';
  String _googleServerClientId = '';
  String _wayoAdsAppKey = '';
  String _authAppName = '';
  String _overlaySentryDsn = '';
  String _overlaySentryEnv = '';
  String _overlayAppRelease = '';
  String _certPinPrimary = '';
  String _certPinBackup = '';
  String _wayoAdsApiBaseUrl = '';

  /// Optional override for chat-service HTTP base (Laravel). When set, replaces
  /// `apiBaseUrl` from Wayo-ads `/api/chat/token` — use `http://10.0.2.2:PORT` on Android emulator.
  String _chatServiceApiBaseUrl = '';
  String _reverbHost = '';
  String _reverbKey = '';
  String _reverbPort = '';
  String _reverbScheme = '';

  String get authWayoBaseUrl => _authWayoBaseUrl;
  String get googleServerClientId => _googleServerClientId;
  String get wayoAdsAppKey => _wayoAdsAppKey;
  String get authAppName => _authAppName;

  /// Non-empty → use as chat-service origin instead of bootstrap `apiBaseUrl`.
  String get chatServiceApiBaseUrl => _chatServiceApiBaseUrl;

  /// Merged certificate pins (Base64 SHA-256 of DER), deduplicated, non-empty only.
  List<String> get mergedPinnedSha256Base64 {
    final out = <String>[];
    void add(String? v) {
      final t = v?.trim() ?? '';
      if (t.isNotEmpty && !out.contains(t)) {
        out.add(t);
      }
    }

    add(AppConfig.certPinPrimary);
    add(AppConfig.certPinBackup);
    add(_certPinPrimary);
    add(_certPinBackup);
    return out;
  }

  String get effectiveSentryDsn =>
      _overlaySentryDsn.isNotEmpty ? _overlaySentryDsn : AppConfig.sentryDsn;

  bool get effectiveSentryEnabled => effectiveSentryDsn.isNotEmpty;

  String get effectiveSentryEnv {
    final o = _overlaySentryEnv.trim();
    if (o.isNotEmpty) {
      return o;
    }
    return AppConfig.sentryEnv;
  }

  String get effectiveAppRelease {
    final o = _overlayAppRelease.trim();
    if (o.isNotEmpty) {
      return o;
    }
    return AppConfig.appRelease;
  }

  /// Normalized Wayo-ads API base (trailing `/`).
  ///
  /// Order: overlay `WAYO_ADS_API_BASE_URL` → compile-time define → **same origin as
  /// [resolvedDioBaseUrl]** (dev monolith / reverse-proxy). Empty only if Auth URL is unset.
  String get resolvedWayoAdsBaseUrl {
    final o = _trimSlash(_wayoAdsApiBaseUrl);
    if (o.isNotEmpty) {
      return '$o/';
    }
    final c = _trimSlash(AppConfig.wayoAdsApiBaseUrl);
    if (c.isNotEmpty) {
      return '$c/';
    }
    final shared = _trimSlash(
      resolvedDioBaseUrl.replaceAll(RegExp(r'/+$'), ''),
    );
    if (shared.isNotEmpty) {
      return '$shared/';
    }
    return '';
  }

  /// Whether [resolvedWayoAdsBaseUrl] already includes an `/api` segment (avoid `api/api/...`).
  bool get wayoAdsBaseHostsApiPrefix {
    final u = _trimSlash(resolvedWayoAdsBaseUrl.replaceAll(RegExp(r'/+$'), ''));
    return u.endsWith('/api') || u == 'api';
  }

  /// Path for [Dio] calls whose [BaseOptions.baseUrl] is [resolvedWayoAdsBaseUrl].
  ///
  /// [path] uses the `api/...` style from [ApiEndpoints]. When the base URL already ends
  /// with `/api`, the leading `api/` is stripped so requests hit `/api/advertiser/...`
  /// instead of `/api/api/advertiser/...`.
  String wayoAdsRequestPath(String path) {
    var p = path.replaceAll(RegExp(r'^/+'), '');
    if (wayoAdsBaseHostsApiPrefix && p.startsWith('api/')) {
      return p.substring(4);
    }
    return p;
  }

  /// Absolute URL for non-Dio callers (e.g. Reverb authorizer).
  String wayoAdsAbsoluteUrl(String path) {
    final b = _trimSlash(resolvedWayoAdsBaseUrl.replaceAll(RegExp(r'/+$'), ''));
    final p = wayoAdsRequestPath(path);
    return '$b/$p';
  }

  String get reverbHost =>
      _reverbHost.isNotEmpty ? _reverbHost : AppConfig.reverbHost;
  String get reverbKey =>
      _reverbKey.isNotEmpty ? _reverbKey : AppConfig.reverbKey;
  String get reverbPort =>
      _reverbPort.isNotEmpty ? _reverbPort : AppConfig.reverbPort;
  String get reverbScheme =>
      _reverbScheme.isNotEmpty ? _reverbScheme : AppConfig.reverbScheme;

  bool get reverbConfigured => reverbKey.isNotEmpty && reverbHost.isNotEmpty;

  /// Normalized base URL for Dio (trailing `/`).
  String get resolvedDioBaseUrl {
    final api = _trimSlash(_apiBaseUrl);
    if (api.isNotEmpty) {
      return '$api/';
    }
    final auth = _trimSlash(_authBaseUrl);
    if (auth.isNotEmpty) {
      return '$auth/';
    }
    final legacy = _trimSlash(_authWayoBaseUrl);
    if (legacy.isNotEmpty) {
      return '$legacy/';
    }
    return '';
  }

  /// `true` when [resolvedDioBaseUrl] already ends with `/api` (paths omit the `api/` prefix).
  bool get dioBaseHostsApiPrefix {
    final u = _trimSlash(resolvedDioBaseUrl.replaceAll(RegExp(r'/+$'), ''));
    return u.endsWith('/api') || u == 'api';
  }

  /// Relative path for Auth_Wayo JSON routes (`…/api/auth/...` or `…/auth/...`).
  String authHttpPath(String action) {
    final segment = action.replaceAll(RegExp(r'^/+'), '');
    if (dioBaseHostsApiPrefix) {
      return 'auth/$segment';
    }
    return 'api/auth/$segment';
  }

  static bool looksLikeGoogleWebClientId(String value) =>
      value.contains('.apps.googleusercontent.com');

  static String _trimSlash(String s) => s.trim().replaceAll(RegExp(r'/+$'), '');

  /// Call after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> ensureLoaded() async {
    final i = instance;
    i._authWayoBaseUrl = c.authWayoBaseUrl.trim();
    i._authBaseUrl = AppConfig.authBaseUrl.trim();
    i._apiBaseUrl = AppConfig.apiBaseUrl.trim();
    i._googleServerClientId = c.authGoogleServerClientId.trim();
    i._wayoAdsAppKey = c.wayoAdsAppKey.trim();
    i._authAppName = c.authAppName.trim();

    try {
      final raw = await rootBundle.loadString('dart_defines.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      void overlay(String key, void Function(String v) set) {
        final v = map[key];
        if (v is String && v.trim().isNotEmpty) {
          set(v.trim());
        }
      }

      overlay('AUTH_WAYO_BASE_URL', (v) => i._authWayoBaseUrl = v);
      overlay('AUTH_BASE_URL', (v) => i._authBaseUrl = v);
      overlay('API_BASE_URL', (v) => i._apiBaseUrl = v);
      overlay(
        'AUTH_GOOGLE_SERVER_CLIENT_ID',
        (v) => i._googleServerClientId = v,
      );
      overlay('WAYO_ADS_APP_KEY', (v) => i._wayoAdsAppKey = v);
      overlay('AUTH_APP_NAME', (v) => i._authAppName = v);
      overlay('SENTRY_DSN', (v) => i._overlaySentryDsn = v);
      overlay('SENTRY_ENV', (v) => i._overlaySentryEnv = v);
      overlay('APP_RELEASE', (v) => i._overlayAppRelease = v);
      overlay('CERT_PIN_PRIMARY', (v) => i._certPinPrimary = v);
      overlay('CERT_PIN_BACKUP', (v) => i._certPinBackup = v);
      overlay('WAYO_ADS_API_BASE_URL', (v) => i._wayoAdsApiBaseUrl = v);
      overlay('CHAT_SERVICE_API_BASE_URL', (v) => i._chatServiceApiBaseUrl = v);
      // Legacy key (same intent as WAYO_ADS_API_BASE_URL)
      if (i._wayoAdsApiBaseUrl.isEmpty) {
        overlay('WAYO_ADS_API_BASE', (v) => i._wayoAdsApiBaseUrl = v);
      }
      overlay('REVERB_HOST', (v) => i._reverbHost = v);
      overlay('REVERB_KEY', (v) => i._reverbKey = v);
      overlay('REVERB_PORT', (v) => i._reverbPort = v);
      overlay('REVERB_SCHEME', (v) => i._reverbScheme = v);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'AuthRuntimeConfig: dart_defines.json asset missing or invalid ($e)',
        );
        debugPrintStack(stackTrace: st);
      }
    }
  }
}
