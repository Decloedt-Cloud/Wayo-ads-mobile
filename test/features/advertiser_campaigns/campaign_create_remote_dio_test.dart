import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/errors/auth_exceptions.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/data/advertiser_campaigns_remote_datasource.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/data/campaign_cost_remote.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_cost_estimate.dart';

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
  group('AdvertiserCampaignsRemoteDatasource createCampaign', () {
    test('sends Idempotency-Key and body without userId', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('campaigns'));
        expect(options.headers['Idempotency-Key'], 'idem-key-01-abcdef');
        final data = options.data;
        expect(data, isA<Map>());
        expect((data as Map).containsKey('userId'), isFalse);
        expect(data['advertiserId'], isNull);
        return _json({
          'campaign': {'id': 'camp_1', 'status': 'ACTIVE'},
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      dio.httpClientAdapter = adapter;
      final remote = AdvertiserCampaignsRemoteDatasource(dio);

      final map = await remote.createCampaign(
        <String, dynamic>{
          'title': 'T',
          'type': 'LINK',
          'status': 'ACTIVE',
          'totalBudgetCents': 5000,
        },
        idempotencyKey: 'idem-key-01-abcdef',
      );

      expect(map['campaign'], isA<Map>());
      expect(adapter.requests, hasLength(1));
    });

    test('retry keeps same Idempotency-Key across two POSTs', () async {
      var calls = 0;
      final adapter = _RecordingAdapter((options, _) async {
        calls++;
        if (calls == 1) {
          return _json({'error': 'timeout'}, status: 503);
        }
        return _json({
          'campaign': {'id': 'camp_2', 'status': 'DRAFT'},
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      dio.httpClientAdapter = adapter;
      final remote = AdvertiserCampaignsRemoteDatasource(dio);
      const key = 'same-key-retry-xxxxxx';

      await expectLater(
        remote.createCampaign({'title': 'A'}, idempotencyKey: key),
        throwsA(isA<ServerException>()),
      );
      final ok = await remote.createCampaign(
        {'title': 'A'},
        idempotencyKey: key,
      );
      expect(ok['campaign'], isA<Map>());
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].headers['Idempotency-Key'], key);
      expect(adapter.requests[1].headers['Idempotency-Key'], key);
    });

    test('maps INSUFFICIENT_FUNDS with draft id', () async {
      final adapter = _RecordingAdapter((options, _) async {
        return _json({
          'error': 'Insufficient funds',
          'errorCode': 'INSUFFICIENT_FUNDS',
          'details': {
            'required': 12000,
            'available': 100,
            'platformFee': 500,
            'tax': 500,
          },
          'campaign': {'id': 'draft_x', 'status': 'DRAFT'},
        }, status: 400);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      dio.httpClientAdapter = adapter;
      final remote = AdvertiserCampaignsRemoteDatasource(dio);

      await expectLater(
        remote.createCampaign({'status': 'ACTIVE'}, idempotencyKey: 'abcdefgh'),
        throwsA(
          isA<CampaignInsufficientFundsException>()
              .having((e) => e.draftCampaignId, 'draft', 'draft_x')
              .having((e) => e.requiredCents, 'required', 12000),
        ),
      );
    });
  });

  group('uploadCampaignLogoDataUrl', () {
    test('posts data URL only (no filesystem path)', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.path, contains('upload-logo'));
        final body = options.data as Map;
        expect(body.keys, ['data']);
        expect(body['data'], startsWith('data:image/png;base64,'));
        expect(body.containsKey('path'), isFalse);
        expect(body.containsKey('filePath'), isFalse);
        return _json({'url': '/uploads/campaign-logos/logo-1.png'});
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      dio.httpClientAdapter = adapter;
      final remote = AdvertiserCampaignsRemoteDatasource(dio);

      final url = await remote.uploadCampaignLogoDataUrl(
        'data:image/png;base64,aaa',
      );
      expect(url, '/uploads/campaign-logos/logo-1.png');
    });

    test('surfaces 413 as ServerException status', () async {
      final adapter = _RecordingAdapter((options, _) async {
        return _json({'error': 'Payload too large'}, status: 413);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      dio.httpClientAdapter = adapter;
      final remote = AdvertiserCampaignsRemoteDatasource(dio);

      await expectLater(
        remote.uploadCampaignLogoDataUrl('data:image/png;base64,x'),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'code', 413),
        ),
      );
    });
  });

  group('CampaignCostRemote', () {
    test('fees + tax-rate contract matches web hooks', () async {
      final adapter = _RecordingAdapter((options, _) async {
        if (options.path.contains('platform/fees')) {
          return _json({
            'platformFeePercentage': 5,
            'platformFeeDescription': 'Platform fee',
          });
        }
        expect(options.path, contains('tokens/tax-rate'));
        expect(options.queryParameters['country'], 'MA');
        expect(options.queryParameters['priceCents'], 10500);
        expect(options.queryParameters['profileType'], 'BUSINESS');
        return _json({
          'taxCents': 525,
          'effectiveRate': 5,
          'taxLabel': 'VAT',
          'countryCode': 'MA',
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      dio.httpClientAdapter = adapter;
      final remote = CampaignCostRemote(dio);

      final fees = await remote.fetchPlatformFees();
      expect(fees.platformFeePercentage, 5);
      final tax = await remote.fetchTaxRate(
        country: 'MA',
        priceCents: 10500,
        profileType: 'BUSINESS',
      );
      final estimate = CampaignCostEstimate.assemble(
        budgetCents: 10000,
        platformFeePercentage: fees.platformFeePercentage,
        taxCents: tax.taxCents,
        taxRate: tax.effectiveRate,
        taxLabel: tax.taxLabel,
        countryCode: tax.countryCode,
      );
      expect(estimate.platformFeeCents, 500);
      expect(estimate.taxCents, 525);
      expect(estimate.totalCents, 11025);
    });
  });
}
