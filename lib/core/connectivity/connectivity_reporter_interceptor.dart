import 'dart:io';

import 'package:dio/dio.dart';

import 'connectivity_service.dart';

/// Reports network-shaped Dio failures to [ConnectivityService.reportRemoteFailure]
/// so the offline/weak popup can react within ~1 s instead of waiting for the
/// next periodic probe.
///
/// Only failures that *look like* connectivity loss are forwarded: connect /
/// send / receive timeouts, [DioExceptionType.connectionError], and wrapped
/// [SocketException]s. HTTP 4xx/5xx are **not** reported (server is reachable).
final class ConnectivityReporterInterceptor extends Interceptor {
  ConnectivityReporterInterceptor(this._service);

  final ConnectivityService _service;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_looksLikeConnectivityLoss(err)) {
      _service.reportRemoteFailure(err);
    }
    handler.next(err);
  }

  bool _looksLikeConnectivityLoss(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        return err.error is SocketException;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
        return false;
    }
  }
}
