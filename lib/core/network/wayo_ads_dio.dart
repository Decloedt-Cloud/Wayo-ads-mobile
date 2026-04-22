import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_dio/sentry_dio.dart';

import '../config/auth_runtime_config.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'interceptors/certificate_pinning.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

part 'wayo_ads_dio.g.dart';

/// Dio client for Wayo-ads (Next.js) API — same auth stack as main [dio].
@Riverpod(keepAlive: true)
Dio wayoAdsDio(WayoAdsDioRef ref) {
  final storage = ref.watch(secureStorageProvider);
  final runtime = AuthRuntimeConfig.instance;
  final base = runtime.resolvedWayoAdsBaseUrl;
  if (kDebugMode &&
      runtime.resolvedWayoAdsBaseUrl == runtime.resolvedDioBaseUrl) {
    debugPrint(
      '[Wayo] Wayo-ads API uses the same base as Auth. Set WAYO_ADS_API_BASE_URL in '
      'dart_defines.json if your Next.js API is on another host (e.g. http://10.0.2.2:3000).',
    );
  }
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
      },
    ),
  );

  client.interceptors.add(AuthInterceptor(storage: storage, dio: client));
  client.interceptors.add(
    buildWayoRetryInterceptor(
      client,
      logPrint: kDebugMode ? (m) => debugPrint(m) : null,
    ),
  );
  if (kDebugMode) {
    client.interceptors.add(WayoLoggingInterceptor());
  }

  final authHost = Uri.tryParse(runtime.resolvedDioBaseUrl)?.host;
  final adsHost = Uri.tryParse(base)?.host;
  if (authHost != null && adsHost != null && authHost == adsHost) {
    CertificatePinning.attach(
      client,
      pinnedSha256Base64: runtime.mergedPinnedSha256Base64,
    );
  }

  if (runtime.effectiveSentryEnabled) {
    client.addSentry(captureFailedRequests: true);
  }

  return client;
}
