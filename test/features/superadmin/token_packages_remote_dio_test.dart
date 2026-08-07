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

const _samplePackage = {
  'slug': 'growth',
  'name': 'Growth',
  'tokens': 300,
  'bonusTokens': 50,
  'priceCents': 1999,
  'currency': 'USD',
  'isActive': true,
  'isBestValue': false,
  'sortOrder': 2,
};

void main() {
  group('SuperadminOpsRemote token packages', () {
    test('createTokenPackage POSTs metadata fields', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('token-packages'));
        final data = options.data as Map;
        expect(data['slug'], 'growth');
        expect(data['name'], 'Growth');
        expect(data['tokens'], 300);
        expect(data['bonusTokens'], 50);
        expect(data['priceCents'], 1999);
        expect(data['currency'], 'USD');
        expect(data['isActive'], isTrue);
        expect(data['isBestValue'], isFalse);
        return _json({'package': _samplePackage}, status: 201);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final pkg = await remote.createTokenPackage(
        slug: 'growth',
        name: 'Growth',
        tokens: 300,
        bonusTokens: 50,
        priceCents: 1999,
      );

      expect(pkg.slug, 'growth');
      expect(pkg.totalTokens, 350);
      expect(adapter.requests, hasLength(1));
    });

    test('updateTokenPackage PUTs slug and changed fields only', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'PUT');
        expect(options.path, contains('token-packages'));
        final data = options.data as Map;
        expect(data['slug'], 'growth');
        expect(data['name'], 'Growth Plus');
        expect(data['priceCents'], 2499);
        expect(data.containsKey('stripeProductId'), isFalse);
        return _json({
          'package': {
            ..._samplePackage,
            'name': 'Growth Plus',
            'priceCents': 2499,
          },
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final pkg = await remote.updateTokenPackage(
        slug: 'growth',
        name: 'Growth Plus',
        priceCents: 2499,
      );

      expect(pkg.name, 'Growth Plus');
      expect(pkg.priceCents, 2499);
    });

    test('setTokenPackageActive delegates to updateTokenPackage', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'PUT');
        final data = options.data as Map;
        expect(data['slug'], 'starter');
        expect(data['isActive'], isFalse);
        return _json({
          'package': {
            ..._samplePackage,
            'slug': 'starter',
            'isActive': false,
          },
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      await remote.setTokenPackageActive(slug: 'starter', isActive: false);

      expect(adapter.requests, hasLength(1));
    });

    test('throws StateError when API returns error', () async {
      final adapter = _RecordingAdapter((_, __) async {
        return _json({'error': 'Package not found'}, status: 200);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      expect(
        () => remote.updateTokenPackage(slug: 'missing', name: 'X'),
        throwsA(isA<StateError>()),
      );
    });

    test('createTokenPackage POSTs store product IDs when provided', () async {
      final adapter = _RecordingAdapter((options, _) async {
        final data = options.data as Map;
        expect(data['appleProductId'], 'com.wayo.studio.growth');
        expect(data['googleProductId'], 'studio_growth');
        return _json({
          'package': {
            ..._samplePackage,
            'appleProductId': 'com.wayo.studio.growth',
            'googleProductId': 'studio_growth',
          },
        }, status: 201);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final pkg = await remote.createTokenPackage(
        slug: 'growth',
        name: 'Growth',
        tokens: 300,
        priceCents: 1999,
        appleProductId: 'com.wayo.studio.growth',
        googleProductId: 'studio_growth',
      );

      expect(pkg.appleProductId, 'com.wayo.studio.growth');
      expect(pkg.googleProductId, 'studio_growth');
    });

    test('updateTokenPackage sends null to clear an empty store product ID',
        () async {
      final adapter = _RecordingAdapter((options, _) async {
        final data = options.data as Map;
        expect(data['appleProductId'], isNull);
        expect(data.containsKey('appleProductId'), isTrue);
        return _json({'package': _samplePackage});
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      await remote.updateTokenPackage(slug: 'growth', appleProductId: '');

      expect(adapter.requests, hasLength(1));
    });

    test('syncTokenPackageStripe POSTs slug to sync-stripe endpoint', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('token-packages/sync-stripe'));
        final data = options.data as Map;
        expect(data['slug'], 'growth');
        return _json({
          'package': {
            ..._samplePackage,
            'stripeProductId': 'prod_123',
            'stripePriceId': 'price_123',
          },
          'stripeProductId': 'prod_123',
          'stripePriceId': 'price_123',
          'priceRotated': false,
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final pkg = await remote.syncTokenPackageStripe('growth');

      expect(pkg.slug, 'growth');
      expect(adapter.requests, hasLength(1));
    });

    test('syncTokenPackageStripe throws StateError when API returns error',
        () async {
      final adapter = _RecordingAdapter((_, __) async {
        return _json({'error': 'Stripe is not configured'}, status: 200);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      expect(
        () => remote.syncTokenPackageStripe('growth'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
