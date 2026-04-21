import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../scrubber.dart';

/// Debug-only Dio interceptor: logs method, URL, status, duration with scrubbed payloads.
final class WayoLoggingInterceptor extends Interceptor {
  WayoLoggingInterceptor();

  static const _kStart = 'wayo_dio_req_start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra[_kStart] = DateTime.now();
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _emit(response.requestOptions, response.statusCode);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _emit(err.requestOptions, err.response?.statusCode, error: err);
    }
    handler.next(err);
  }

  void _emit(
    RequestOptions options,
    int? statusCode, {
    DioException? error,
  }) {
    final started = options.extra[_kStart] as DateTime?;
    final elapsedMs = started == null
        ? null
        : DateTime.now().difference(started).inMilliseconds;
    final uri = options.uri;
    final headers = scrub(Map<String, dynamic>.from(options.headers));
    final data = scrub(_dataAsMap(options.data));
    final buffer = StringBuffer()
      ..write('[Dio] ${options.method} $uri')
      ..write(' → ${statusCode ?? '—'}')
      ..write(elapsedMs == null ? '' : ' (${elapsedMs}ms)')
      ..writeln()
      ..write('headers: $headers')
      ..writeln()
      ..write('body: $data');
    if (error != null) {
      buffer
        ..writeln()
        ..write('error: ${error.type} ${error.message}');
    }
    debugPrint(buffer.toString());
  }

  Map<String, dynamic> _dataAsMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    if (data is Map) {
      return data.map((k, v) => MapEntry('$k', v));
    }
    return {'raw': data.toString()};
  }
}
