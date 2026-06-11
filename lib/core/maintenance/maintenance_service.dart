import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/auth_runtime_config.dart';
import '../network/interceptors/certificate_pinning.dart';

/// HTTP codes that indicate the Wayo-ads / reverse-proxy stack is in maintenance.
bool isMaintenanceHttpStatus(int? statusCode) {
  return statusCode == 502 || statusCode == 503 || statusCode == 521;
}

/// Probe treats any 5xx from Wayo-ads as downtime (nginx maintenance, gateway, etc.).
bool isPlatformDownProbeStatus(int? statusCode) {
  if (statusCode == null) return false;
  return statusCode >= 500;
}

/// True when the origin responded (not a transport failure) and is not in maintenance.
bool isWayoServerReachableStatus(int? statusCode) {
  if (statusCode == null) return false;
  if (isMaintenanceHttpStatus(statusCode)) return false;
  return statusCode < 500;
}

/// Shared instance — Dio interceptors and [MaintenanceGate] must use the same object.
final class MaintenanceServiceHolder {
  MaintenanceServiceHolder._();

  static final MaintenanceService instance = MaintenanceService();
}

String _bodyAsString(dynamic data) {
  if (data == null) return '';
  if (data is String) return data;
  if (data is List<int>) {
    try {
      return String.fromCharCodes(data);
    } catch (_) {
      return '';
    }
  }
  return data.toString();
}

bool bodyLooksLikeMaintenancePage(String body) {
  if (body.isEmpty) return false;
  final lower = body.toLowerCase();
  const markers = [
    'maintenance',
    'maintenance en cours',
    'cours de maintenance',
    'under maintenance',
    'temporarily unavailable',
    'service unavailable',
    'en maintenance',
    'scheduled maintenance',
    'site is down',
    'be back soon',
    'revenez bientôt',
    'revenez plus tard',
    'bad gateway',
    'gateway time-out',
    'indisponible',
    'déploiement',
    'deployment in progress',
    'service temporarily unavailable',
    'temporarily unavailable',
    'nginx',
    'erreur',
    'patience',
    'wayo ads',
    'wayo-ads',
  ];
  return markers.any(lower.contains);
}

bool _responseLooksLikePlatformDown(Response<dynamic> response) {
  if (responseIndicatesMaintenance(response)) return true;
  return isPlatformDownProbeStatus(response.statusCode);
}

bool _jsonBodyIndicatesMaintenance(dynamic data) {
  if (data is! Map) return false;
  final status = data['status'];
  if (status is String && status.toLowerCase() == 'maintenance') {
    return true;
  }
  return false;
}

/// Detects maintenance from status, headers, or HTML/JSON body (Cloudflare, Vercel, nginx).
bool responseIndicatesMaintenance(Response<dynamic> response) {
  final code = response.statusCode;
  if (isMaintenanceHttpStatus(code)) return true;

  if (response.headers.value('x-wayo-maintenance') == '1') return true;

  final data = response.data;
  if (_jsonBodyIndicatesMaintenance(data)) return true;

  final body = _bodyAsString(data);
  final contentType =
      response.headers.value('content-type')?.toLowerCase() ?? '';
  final retryAfter = response.headers.value('retry-after');

  if (retryAfter != null && retryAfter.trim().isNotEmpty && code != null && code >= 500) {
    return true;
  }

  if (code != null && code >= 500 && bodyLooksLikeMaintenancePage(body)) {
    return true;
  }

  // Static maintenance page served as HTML with HTTP 200.
  if (code == 200 &&
      contentType.contains('text/html') &&
      bodyLooksLikeMaintenancePage(body)) {
    return true;
  }

  return false;
}

bool dioExceptionIndicatesMaintenance(DioException err) {
  final response = err.response;
  if (response != null && responseIndicatesMaintenance(response)) {
    return true;
  }
  final code = response?.statusCode;
  return isMaintenanceHttpStatus(code);
}

/// Tracks platform maintenance and probes Wayo-ads (+ Auth when distinct) on demand.
class MaintenanceService extends ChangeNotifier {
  bool _active = false;
  bool _probing = false;

  bool get isActive => _active;
  bool get isProbing => _probing;

  void enterMaintenance() {
    if (_active) return;
    _active = true;
    if (kDebugMode) {
      debugPrint('[MaintenanceService] enterMaintenance');
    }
    notifyListeners();
  }

  void leaveMaintenance() {
    if (!_active) return;
    _active = false;
    if (kDebugMode) {
      debugPrint('[MaintenanceService] leaveMaintenance');
    }
    notifyListeners();
  }

  /// Called from Dio interceptors and repositories when an API response looks like maintenance.
  void reportFromDio(DioException err) {
    if (dioExceptionIndicatesMaintenance(err)) {
      enterMaintenance();
    }
  }

  void reportFromResponse(Response<dynamic> response) {
    if (responseIndicatesMaintenance(response)) {
      enterMaintenance();
    }
  }

  /// Startup / resume probe — does not block the first frame.
  ///
  /// [allowRecovery] — when true (app resumed while maintenance is shown, or
  /// explicit retry flow), a healthy probe clears maintenance. On cold start we
  /// only *enter* maintenance on failure so a late probe cannot undo a 503
  /// already reported by [MaintenanceInterceptor].
  Future<void> probeOnLaunch({bool allowRecovery = false}) async {
    final ok = await _probeOrigins();
    if (!ok) {
      enterMaintenance();
      return;
    }
    if (allowRecovery) {
      leaveMaintenance();
    }
  }

  /// Manual recovery probe (optional — [MaintenanceGate] polls automatically).
  Future<bool> retry() async {
    _probing = true;
    notifyListeners();
    try {
      final ok = await _probeOrigins();
      if (ok) {
        leaveMaintenance();
        return true;
      }
      enterMaintenance();
      return false;
    } finally {
      _probing = false;
      notifyListeners();
    }
  }

  Future<bool> _probeOrigins() async {
    final runtime = AuthRuntimeConfig.instance;
    final ads = runtime.resolvedWayoAdsBaseUrl;
    if (ads.isEmpty) return true;

    final adsOk = await _probeOrigin(ads, isWayoAds: true);
    if (!adsOk) return false;

    final auth = runtime.resolvedDioBaseUrl;
    if (auth != ads && auth.isNotEmpty) {
      return _probeOrigin(auth, isWayoAds: false);
    }
    return true;
  }

  Future<bool> _probeOrigin(String baseUrl, {required bool isWayoAds}) async {
    final runtime = AuthRuntimeConfig.instance;
    // Preprod nginx Basic Auth makes `/` return 401 — probe mobile API routes only.
    final paths = isWayoAds
        ? <String>[
            runtime.wayoAdsRequestPath('api/health'),
            runtime.wayoAdsRequestPath('api/campaigns'),
            runtime.wayoAdsRequestPath('api/wallet/config'),
          ]
        : <String>['/'];

    for (final path in paths) {
      final ok = await _probePath(baseUrl, path);
      if (!ok) return false;
    }
    return true;
  }

  Future<bool> _probePath(String baseUrl, String path) async {
    final runtime = AuthRuntimeConfig.instance;
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 10),
        followRedirects: true,
        maxRedirects: 3,
        validateStatus: (_) => true,
        headers: <String, dynamic>{
          'Accept': 'application/json, text/plain, */*',
          'X-Client': 'wayo-ads-go',
          'X-Client-Version': runtime.effectiveAppRelease,
        },
      ),
    );

    CertificatePinning.attach(
      dio,
      pinnedSha256Base64: runtime.mergedPinnedSha256Base64,
    );

    try {
      final response = await dio.get<dynamic>(
        path,
        queryParameters: path.contains('campaigns')
            ? const {'limit': 1, 'status': 'ACTIVE'}
            : null,
        options: path.contains('health')
            ? Options(responseType: ResponseType.json)
            : null,
      );
      if (_responseLooksLikePlatformDown(response)) return false;
      return isWayoServerReachableStatus(response.statusCode);
    } on DioException catch (e) {
      if (dioExceptionIndicatesMaintenance(e)) return false;
      final errCode = e.response?.statusCode;
      if (isPlatformDownProbeStatus(errCode)) return false;
      if (e.response != null && _responseLooksLikePlatformDown(e.response!)) {
        return false;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.badCertificate) {
        // Network / TLS — connectivity overlay, not maintenance.
        return true;
      }
      if (e.type == DioExceptionType.badResponse) {
        if (isPlatformDownProbeStatus(errCode)) return false;
        return isWayoServerReachableStatus(errCode);
      }
      return true;
    } catch (_) {
      return true;
    } finally {
      dio.close(force: true);
    }
  }
}
