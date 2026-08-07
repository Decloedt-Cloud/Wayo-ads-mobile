import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/errors/auth_exceptions.dart';
import 'package:wayoadsgo/features/wallet/data/advertiser_wallet_repository.dart';
import 'package:wayoadsgo/features/wallet/domain/wallet_models.dart';

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
  group('AdvertiserWalletRepository.fetchPendingDeposit', () {
    test('parses pending + achProcessing + wireAwaiting snapshot', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'GET');
        expect(options.path, contains('wallet/deposit-intent'));
        return _json({
          'pending': {
            'intent': {
              'intentId': 'pi_1',
              'clientSecret': 'secret_1',
              'amountCents': 5000,
              'currency': 'usd',
            },
            'walletAmountCents': 5000,
            'bankFeeCents': 150,
            'totalAmountCents': 5150,
            'depositMethod': 'card',
          },
          'achProcessing': [
            {'intentId': 'pi_ach', 'amountCents': 2000, 'currency': 'usd'},
          ],
          'wireAwaiting': [
            {
              'intentId': 'pi_wire',
              'amountCents': 300000,
              'currency': 'usd',
              'reference': 'WAYO-REF-1',
              'bankTransferInstructions': {
                'amountRemainingCents': 300000,
                'currency': 'usd',
                'addresses': [],
              },
            },
          ],
        });
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      final snapshot = await repo.fetchPendingDeposit();

      expect(snapshot.pending, isNotNull);
      expect(snapshot.pending!.intentId, 'pi_1');
      expect(snapshot.pending!.totalAmountCents, 5150);
      expect(snapshot.achProcessing, hasLength(1));
      expect(snapshot.achProcessing.first.intentId, 'pi_ach');
      expect(snapshot.wireAwaiting, hasLength(1));
      expect(snapshot.wireAwaiting.first.bankTransferInstructions, isNotNull);
      expect(snapshot.isEmpty, isFalse);
    });

    test('returns empty snapshot on 404', () async {
      final adapter = _RecordingAdapter((options, _) async {
        throw DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 404),
          type: DioExceptionType.badResponse,
        );
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      final snapshot = await repo.fetchPendingDeposit();

      expect(snapshot.isEmpty, isTrue);
    });

    test('throws ServerException with server error message on 500', () async {
      final adapter = _RecordingAdapter((options, _) async {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            data: {'error': 'Database unavailable'},
          ),
          type: DioExceptionType.badResponse,
        );
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      expect(
        () => repo.fetchPendingDeposit(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('AdvertiserWalletRepository.createDepositIntent', () {
    test('sends depositMethod and parses wire bankTransferInstructions', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('wallet/deposit-intent'));
        final data = options.data as Map;
        expect(data['amountCents'], 200000);
        expect(data['depositMethod'], 'wire');
        return _json({
          'intent': {
            'intentId': 'pi_wire',
            'clientSecret': 'secret_wire',
            'amountCents': 200000,
            'currency': 'usd',
          },
          'totalAmountCents': 200000,
          'canSimulate': false,
          'depositMethod': 'wire',
          'bankTransferInstructions': {
            'amountRemainingCents': 200000,
            'currency': 'usd',
            'reference': 'WAYO-REF-2',
            'addresses': [
              {'network': 'ach', 'bankName': 'Example Bank'},
            ],
          },
        });
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      final result = await repo.createDepositIntent(
        amountCents: 200000,
        depositMethod: AdvertiserDepositMethod.wire,
      );

      expect(result.intentId, 'pi_wire');
      expect(result.depositMethod, 'wire');
      expect(result.bankTransferInstructions, isNotNull);
      expect(result.bankTransferInstructions!.reference, 'WAYO-REF-2');
      expect(result.bankTransferInstructions!.addresses, hasLength(1));
    });

    test('throws ServerException with server error message on failure', () async {
      final adapter = _RecordingAdapter((options, _) async {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'error': 'Amount below minimum deposit'},
          ),
          type: DioExceptionType.badResponse,
        );
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      expect(
        () => repo.createDepositIntent(amountCents: 10),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Amount below minimum deposit',
          ),
        ),
      );
    });
  });

  group('AdvertiserWalletRepository.reconcileDeposit', () {
    test('POSTs to the reconcile endpoint and returns status', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('wallet/deposits/pi_1/reconcile'));
        return _json({'status': 'SUCCEEDED'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      final status = await repo.reconcileDeposit('pi_1');

      expect(status, 'SUCCEEDED');
    });

    test('throws ServerException when server returns an error payload', () async {
      final adapter = _RecordingAdapter((options, _) async {
        return _json({'error': 'Deposit still pending settlement'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      expect(
        () => repo.reconcileDeposit('pi_2'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('AdvertiserWalletRepository saved cards', () {
    test('fetchSavedCards GETs saved-cards and parses result', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'GET');
        expect(options.path, contains('wallet/saved-cards'));
        return _json({
          'cards': [
            {
              'id': 'pm_1',
              'brand': 'visa',
              'last4': '4242',
              'expMonth': 4,
              'expYear': 2030,
              'isDefault': true,
            },
          ],
          'projectionInitialized': true,
          'syncStatus': 'SYNCED',
        });
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      final result = await repo.fetchSavedCards();

      expect(result.cards, hasLength(1));
      expect(result.cards.first.id, 'pm_1');
      expect(result.projectionInitialized, isTrue);
    });

    test('refreshSavedCards POSTs to the refresh endpoint', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('wallet/saved-cards/refresh'));
        return _json({
          'cards': <Map<String, dynamic>>[],
          'projectionInitialized': true,
          'syncStatus': 'SYNCED',
        });
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      final result = await repo.refreshSavedCards();

      expect(result.cards, isEmpty);
      expect(result.syncStatus, 'SYNCED');
    });

    test('deleteSavedCard DELETEs with paymentMethodId body', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'DELETE');
        expect(options.path, contains('wallet/saved-cards'));
        final data = options.data as Map;
        expect(data['paymentMethodId'], 'pm_1');
        return _json({'success': true});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      await repo.deleteSavedCard('pm_1');

      expect(adapter.requests, hasLength(1));
    });

    test('deleteSavedCard throws ServerException on server error', () async {
      final adapter = _RecordingAdapter((options, _) async {
        return _json({'error': 'Card not found'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final repo = AdvertiserWalletRepository(dio);

      expect(
        () => repo.deleteSavedCard('pm_missing'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
