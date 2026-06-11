import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_dio/sentry_dio.dart';

import '../config/auth_runtime_config.dart';
import '../constants/app_constants.dart' as ac;
import '../connectivity/connectivity_providers.dart';
import '../maintenance/maintenance_interceptor.dart';
import '../maintenance/maintenance_service.dart';
import '../observability/app_log.dart';
import '../connectivity/connectivity_reporter_interceptor.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'interceptors/certificate_pinning.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final storage = ref.watch(secureStorageProvider);
  final runtime = AuthRuntimeConfig.instance;
  final base = runtime.resolvedDioBaseUrl;
  if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
    final host = base.toLowerCase();
    if (host.contains('localhost') || host.contains('127.0.0.1')) {
      debugPrint(
        '[Wayo] API base uses localhost/127.0.0.1 — on Android emulator that is '
        'the device itself, not your PC. Use http://10.0.2.2:8000 in dart_defines.json '
        'and run Laravel with php artisan serve --host=0.0.0.0 --port=8000.',
      );
    }
  }
  final oauthRedirect = ac.authOAuthRedirectUri.trim();
  final oauthClientId = ac.authOAuthClientId.trim();
  final client = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: <String, dynamic>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Client': 'wayo-ads-go',
        'X-Client-Version': runtime.effectiveAppRelease,
        if (oauthRedirect.isNotEmpty) 'X-OAuth-Redirect-Uri': oauthRedirect,
        if (oauthClientId.isNotEmpty) 'X-OAuth-Client-Id': oauthClientId,
      },
    ),
  );

  client.interceptors.add(AuthInterceptor(storage: storage, dio: client));
  client.interceptors.add(
    buildWayoRetryInterceptor(
      client,
      logPrint: kWayoDiagnosticsLogging ? (m) => wayoDiagPrint(m, name: 'wayo.retry') : null,
    ),
  );
  client.interceptors.add(
    ConnectivityReporterInterceptor(ref.read(connectivityServiceProvider)),
  );
  if (kWayoDiagnosticsLogging) {
    client.interceptors.add(WayoLoggingInterceptor());
  }
  client.interceptors.add(
    MaintenanceInterceptor(MaintenanceServiceHolder.instance),
  );

  CertificatePinning.attach(
    client,
    pinnedSha256Base64: runtime.mergedPinnedSha256Base64,
  );

  if (runtime.effectiveSentryEnabled) {
    client.addSentry(captureFailedRequests: true);
  }

  return client;
}
