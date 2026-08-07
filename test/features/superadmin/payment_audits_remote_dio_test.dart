import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/superadmin/data/superadmin_ops_remote.dart';

typedef _Handler = Future<ResponseBody> Function(
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

ResponseBody _json(Object data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

Dio _newDio() => Dio(BaseOptions(baseUrl: 'https://example.test/'));

void main() {
  group('SuperadminOpsRemote.fetchPaymentAudits', () {
    test('sends advertiserId filter when provided', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'GET');
        expect(options.path, contains('admin/payment-audits'));
        expect(options.queryParameters['advertiserId'], 'adv_1');
        expect(options.queryParameters['search'], 'pi_abc');
        return _json({
          'records': [
            {
              'id': 'pa_1',
              'stripePaymentIntentId': 'pi_abc',
              'advertiserId': 'adv_1',
              'amountCents': 5000,
              'currency': 'eur',
              'reconciliationStatus': 'MATCHED',
              'createdAt': '2026-08-01T12:00:00.000Z',
            },
          ],
          'total': 1,
          'page': 1,
          'limit': 20,
        });
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final page = await remote.fetchPaymentAudits(
        search: 'pi_abc',
        advertiserId: 'adv_1',
      );

      expect(page.records, hasLength(1));
      expect(page.records.first.advertiserId, 'adv_1');
      expect(page.total, 1);
      expect(adapter.requests, hasLength(1));
    });

    test('omits advertiserId/search when blank', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.queryParameters.containsKey('advertiserId'), isFalse);
        expect(options.queryParameters.containsKey('search'), isFalse);
        return _json({'records': [], 'total': 0, 'page': 1, 'limit': 20});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      await remote.fetchPaymentAudits(search: '  ', advertiserId: '  ');

      expect(adapter.requests, hasLength(1));
    });
  });

  group('SuperadminOpsRemote.reconcilePaymentAudit', () {
    test('POSTs to the {id}/reconcile endpoint and parses the result', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('admin/payment-audits/pa_1/reconcile'));
        return _json({
          'auditId': 'pa_1',
          'reconciliationStatus': 'MATCHED',
          'additionalStripeFeeCents': 12,
          'processingFeeSettled': true,
        });
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final result = await remote.reconcilePaymentAudit('pa_1');

      expect(result.auditId, 'pa_1');
      expect(result.reconciliationStatus, 'MATCHED');
      expect(result.additionalStripeFeeCents, 12);
      expect(result.processingFeeSettled, isTrue);
      expect(adapter.requests, hasLength(1));
    });

    test('URL-encodes the audit id', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.path, contains('pa%2F1/reconcile'));
        return _json({'auditId': 'pa/1', 'reconciliationStatus': 'MATCHED'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      await remote.reconcilePaymentAudit('pa/1');

      expect(adapter.requests, hasLength(1));
    });
  });

  group('SuperadminOpsRemote.fetchAdvertiserDeposits', () {
    test('GETs advertiser-deposits and parses rows/pagination', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'GET');
        expect(options.path, contains('admin/advertiser-deposits'));
        expect(options.queryParameters['page'], 2);
        expect(options.queryParameters['search'], 'acme');
        return _json({
          'rows': [
            {
              'advertiserId': 'adv_1',
              'advertiserEmail': 'a@wayo.ma',
              'advertiserName': 'Acme',
              'currency': 'eur',
              'depositCount': 3,
              'totalChargedCents': 30000,
              'totalStripeFeeCents': 900,
              'totalInternationalFeeCents': 0,
              'totalAdditionalStripeFeeCents': 0,
              'totalNetCents': 29100,
              'walletAvailableCents': 5000,
              'lastDepositAt': '2026-08-01T12:00:00.000Z',
            },
          ],
          'total': 1,
          'page': 2,
          'limit': 20,
        });
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final page = await remote.fetchAdvertiserDeposits(page: 2, search: 'acme');

      expect(page.rows, hasLength(1));
      expect(page.rows.first.advertiserName, 'Acme');
      expect(page.rows.first.totalNetCents, 29100);
      expect(page.rows.first.walletAvailableCents, 5000);
      expect(page.page, 2);
      expect(page.totalPages, 1);
      expect(adapter.requests, hasLength(1));
    });
  });
}
