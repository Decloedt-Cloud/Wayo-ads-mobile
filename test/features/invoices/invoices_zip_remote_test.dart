import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/invoices/data/invoices_remote_datasource.dart';
import 'package:wayoadsgo/features/invoices/data/invoices_repository.dart';

typedef _Handler =
    Future<ResponseBody> Function(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
    );

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._handler);

  final _Handler _handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _bytes(List<int> data, {int status = 200}) {
  return ResponseBody.fromBytes(
    data,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/zip'],
    },
  );
}

ResponseBody _json(Object data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  group('InvoicesRepository ZIP download', () {
    test('downloadAdvertiserZip POSTs ids+locale and returns bytes', () async {
      final zipBytes = Uint8List.fromList([0x50, 0x4b, 0x03, 0x04, 0x00]);
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('advertiser/invoices/zip'));
        expect(options.responseType, ResponseType.bytes);
        final data = options.data;
        expect(data, isA<Map>());
        expect((data as Map)['ids'], ['inv_1', 'inv_2']);
        expect(data['locale'], 'fr');
        return _bytes(zipBytes);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final repo = InvoicesRepository(InvoicesRemoteDatasource(dio));

      final out = await repo.downloadAdvertiserZip(
        const ['inv_1', 'inv_2'],
        locale: 'fr',
      );

      expect(out, zipBytes);
      expect(adapter.requests, hasLength(1));
    });

    test('downloadCreatorPayoutsZip POSTs withdrawal ids', () async {
      final zipBytes = Uint8List.fromList([0x50, 0x4b, 0x05, 0x06]);
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('creator/payouts/zip'));
        final data = options.data as Map;
        expect(data['ids'], ['wr_a', 'wr_b']);
        expect(data['locale'], 'en');
        return _bytes(zipBytes);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final repo = InvoicesRepository(InvoicesRemoteDatasource(dio));

      final out = await repo.downloadCreatorPayoutsZip(
        const ['wr_a', 'wr_b'],
        locale: 'en',
      );

      expect(out, zipBytes);
    });

    test('downloadCreatorInvoicesZip POSTs invoice ids', () async {
      final zipBytes = Uint8List.fromList([0x50, 0x4b, 0x01, 0x02]);
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.path, contains('creator/invoices/zip'));
        final data = options.data as Map;
        expect(data['ids'], ['ci_1']);
        return _bytes(zipBytes);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final repo = InvoicesRepository(InvoicesRemoteDatasource(dio));

      final out = await repo.downloadCreatorInvoicesZip(
        const ['ci_1'],
        locale: 'en',
      );

      expect(out, zipBytes);
    });

    test('empty ids map to AuthException via mapError', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = _RecordingAdapter(
        (_, _) async => _json({'error': 'should not call'}, status: 500),
      );
      final repo = InvoicesRepository(InvoicesRemoteDatasource(dio));

      expect(
        () => repo.downloadAdvertiserZip(const [], locale: 'en'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('no IDs'),
          ),
        ),
      );
    });
  });
}
