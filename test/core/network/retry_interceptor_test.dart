import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/network/interceptors/retry_interceptor.dart';
import 'package:wayoadsgo/core/network/interceptors/wayo_retry_evaluator.dart';

class _SequentialStatusAdapter implements HttpClientAdapter {
  _SequentialStatusAdapter(this.statuses);

  final List<int> statuses;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    final idx = callCount - 1;
    final code = idx < statuses.length ? statuses[idx] : statuses.last;
    return ResponseBody.fromString(
      '{}',
      code,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioException _badResponse({
  required RequestOptions requestOptions,
  required int status,
}) {
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: status,
      data: const <String, dynamic>{},
    ),
  );
}

void main() {
  group('wayoRetryEvaluator', () {
    test('500 is retryable', () async {
      final ro = RequestOptions(path: '/api/auth/user', method: 'GET');
      final err = _badResponse(requestOptions: ro, status: 500);
      expect(await wayoRetryEvaluator(err, 1), isTrue);
    });

    test('400 is not retryable', () async {
      final ro = RequestOptions(path: '/x', method: 'GET');
      final err = _badResponse(requestOptions: ro, status: 400);
      expect(await wayoRetryEvaluator(err, 1), isFalse);
    });

    test('429 is not retryable (rate limit must not auto-spam)', () async {
      final ro = RequestOptions(path: '/x', method: 'GET');
      final err = _badResponse(requestOptions: ro, status: 429);
      expect(await wayoRetryEvaluator(err, 1), isFalse);
    });

    test(
      'POST api/auth/login with 500 is not retryable (suffix rule)',
      () async {
        final ro = RequestOptions(
          baseUrl: 'https://example.com/',
          path: 'api/auth/login',
          method: 'POST',
        );
        final err = _badResponse(requestOptions: ro, status: 500);
        expect(await wayoRetryEvaluator(err, 1), isFalse);
      },
    );
  });

  group('RetryInterceptor + MockAdapter', () {
    test('500 triggers 4 total attempts then throws', () async {
      final adapter = _SequentialStatusAdapter([500, 500, 500, 500]);
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.com/',
          validateStatus: (_) => false,
        ),
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(buildWayoRetryInterceptor(dio));
      await expectLater(dio.get<Object>('/ping'), throwsA(isA<DioException>()));
      expect(adapter.callCount, 4);
    });

    test('400 does not retry', () async {
      final adapter = _SequentialStatusAdapter([400, 200]);
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.com/',
          validateStatus: (_) => false,
        ),
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(buildWayoRetryInterceptor(dio));
      await expectLater(dio.get<Object>('/ping'), throwsA(isA<DioException>()));
      expect(adapter.callCount, 1);
    });

    test('503 then 200 succeeds after one retry', () async {
      final adapter = _SequentialStatusAdapter([503, 200]);
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/'));
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(buildWayoRetryInterceptor(dio));
      final res = await dio.get<Object>('/ping');
      expect(res.statusCode, 200);
      expect(adapter.callCount, 2);
    });

    test('POST api/auth/login 500 is not retried', () async {
      final adapter = _SequentialStatusAdapter([500, 200]);
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.com/',
          validateStatus: (_) => false,
        ),
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(buildWayoRetryInterceptor(dio));
      await expectLater(
        dio.post<Object>('/api/auth/login'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, 1);
    });
  });
}
