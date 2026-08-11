import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/auth_runtime_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../../dashboard/domain/entities/advertiser_balance.dart';
import '../domain/wallet_models.dart';

final advertiserWalletRepositoryProvider = Provider<AdvertiserWalletRepository>(
  (ref) {
    return AdvertiserWalletRepository(ref.watch(wayoAdsDioProvider));
  },
);

final class AdvertiserWalletRepository {
  AdvertiserWalletRepository(this._dio);

  final Dio _dio;

  String _path(String p) => AuthRuntimeConfig.instance.wayoAdsRequestPath(p);

  static Map<String, dynamic>? _asMap(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static String? _err(dynamic data) {
    final m = _asMap(data);
    final e = m?['error'];
    return e is String ? e : null;
  }

  Future<WalletPspConfig> fetchPspConfig() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _path(ApiEndpoints.walletConfig),
    );
    final data = res.data;
    if (data == null) {
      throw const ServerException('Empty wallet config');
    }
    return WalletPspConfig(
      pspMode: data['pspMode'] as String? ?? 'mock',
      isStripe: data['isStripe'] == true,
      publishableKey: data['publishableKey'] as String?,
      isTestMode: data['isTestMode'] == true,
      keysMismatch: data['keysMismatch'] == true,
    );
  }

  Future<AdvertiserWalletPageData> fetchWalletPage() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _path(ApiEndpoints.wallet),
    );
    final data = res.data;
    if (data == null) {
      throw const ServerException('Empty wallet');
    }
    final w = _asMap(data['wallet']);
    if (w == null) {
      throw const ServerException('Empty wallet');
    }
    double fromCents(dynamic v) =>
        (v is num ? v.toDouble() : double.tryParse('$v') ?? 0) / 100.0;
    final balance = AdvertiserBalance(
      available: fromCents(w['availableCents']),
      locked: fromCents(w['pendingCents']),
      spent: 0,
      currency: (w['currency'] as String?)?.toUpperCase() ?? 'USD',
    );
    final rawTx = data['transactions'];
    final list = rawTx is List<dynamic> ? rawTx : const [];
    final transactions = <WalletTransactionRow>[];
    for (final e in list) {
      if (e is! Map<String, dynamic>) {
        continue;
      }
      transactions.add(
        WalletTransactionRow(
          id: '${e['id'] ?? ''}',
          type: e['type'] as String? ?? '',
          amountCents: (e['amountCents'] as num?)?.toInt() ?? 0,
          currency: (e['currency'] as String?)?.toUpperCase() ?? 'USD',
          description: e['description'] as String? ?? '',
          createdAt: _parseDate(e['createdAt'] ?? e['created_at']),
          status: e['status'] as String?,
          stripeFeeCents: (e['stripeFeeCents'] as num?)?.toInt(),
          chargedCents: (e['chargedCents'] as num?)?.toInt(),
        ),
      );
    }
    return AdvertiserWalletPageData(
      balance: balance,
      transactions: transactions,
      canSimulate: data['canSimulate'] == true,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  /// [GET /api/wallet/deposit-intent] — resume an abandoned Stripe checkout,
  /// plus any ACH-processing / wire-awaiting deposits.
  Future<AdvertiserPendingDepositsSnapshot> fetchPendingDeposit() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        _path(ApiEndpoints.walletDepositIntent),
      );
      final data = res.data;
      if (data == null) {
        return AdvertiserPendingDepositsSnapshot.empty;
      }
      return _parsePendingSnapshot(data);
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 403 || code == 404) {
        return AdvertiserPendingDepositsSnapshot.empty;
      }
      throw ServerException(_depositErrorMessage(e), code);
    }
  }

  /// [DELETE /api/wallet/deposit-intent] — discard an abandoned deposit.
  Future<void> cancelDepositIntent(String intentId) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        _path(ApiEndpoints.walletDepositIntent),
        data: <String, dynamic>{'intentId': intentId},
      );
      final data = res.data;
      if (data == null) {
        return;
      }
      final err = _err(data);
      if (err != null) {
        throw ServerException(err);
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 404) {
        return;
      }
      throw ServerException(_depositErrorMessage(e), code);
    }
  }

  static AdvertiserPendingDepositsSnapshot _parsePendingSnapshot(
    Map<String, dynamic> data,
  ) {
    final achRaw = data['achProcessing'];
    final ach = achRaw is List
        ? achRaw
            .whereType<Map>()
            .map((e) => AchProcessingDeposit.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AchProcessingDeposit>[];
    final wireRaw = data['wireAwaiting'];
    final wire = wireRaw is List
        ? wireRaw
            .whereType<Map>()
            .map((e) => WireAwaitingDeposit.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <WireAwaitingDeposit>[];
    return AdvertiserPendingDepositsSnapshot(
      pending: _parsePendingDeposit(data),
      achProcessing: ach,
      wireAwaiting: wire,
    );
  }

  static AdvertiserPendingDeposit? _parsePendingDeposit(
    Map<String, dynamic> data,
  ) {
    final pending = _asMap(data['pending']);
    if (pending == null) {
      return null;
    }
    final intent = _asMap(pending['intent']);
    if (intent == null) {
      return null;
    }
    final intentId = '${intent['intentId'] ?? ''}'.trim();
    final clientSecret = intent['clientSecret'] as String? ?? '';
    if (intentId.isEmpty || clientSecret.isEmpty) {
      return null;
    }
    final walletAmountCents =
        (pending['walletAmountCents'] as num?)?.toInt() ??
        (intent['amountCents'] as num?)?.toInt() ??
        0;
    final bankFeeCents = (pending['bankFeeCents'] as num?)?.toInt() ?? 0;
    final totalAmountCents =
        (pending['totalAmountCents'] as num?)?.toInt() ??
        (intent['amountCents'] as num?)?.toInt() ??
        walletAmountCents + bankFeeCents;
    return AdvertiserPendingDeposit(
      intentId: intentId,
      clientSecret: clientSecret,
      walletAmountCents: walletAmountCents,
      bankFeeCents: bankFeeCents,
      totalAmountCents: totalAmountCents,
      currency: (intent['currency'] as String?)?.toUpperCase() ?? 'USD',
      depositMethod: AdvertiserDepositMethod.normalize(
        pending['depositMethod'] as String?,
      ),
      bankTransferInstructions:
          BankTransferFundingInstructions.tryParse(pending['bankTransferInstructions']),
    );
  }

  Future<DepositIntentResult> createDepositIntent({
    required int amountCents,
    String? currency,
    String depositMethod = AdvertiserDepositMethod.card,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _path(ApiEndpoints.walletDepositIntent),
        data: <String, dynamic>{
          'amountCents': amountCents,
          'currency': currency,
          'depositMethod': depositMethod,
        }..removeWhere((_, v) => v == null),
      );
      final data = res.data;
      if (data == null) {
        throw const ServerException('Empty deposit response');
      }
      final err = _err(data);
      if (err != null) {
        throw ServerException(err);
      }
      final intent = _asMap(data['intent']);
      if (intent == null) {
        throw const ServerException('Invalid deposit intent');
      }
      final totalCents =
          (data['totalAmountCents'] as num?)?.toInt() ??
          (intent['amountCents'] as num?)?.toInt() ??
          amountCents;
      return DepositIntentResult(
        intentId: '${intent['intentId'] ?? ''}',
        clientSecret: intent['clientSecret'] as String? ?? '',
        amountCents: totalCents,
        currency: (intent['currency'] as String?)?.toUpperCase() ?? 'USD',
        canSimulate: data['canSimulate'] == true,
        walletAmountCents: (data['walletAmountCents'] as num?)?.toInt(),
        bankFeeCents: (data['bankFeeCents'] as num?)?.toInt(),
        depositMethod: AdvertiserDepositMethod.normalize(
          data['depositMethod'] as String? ?? depositMethod,
        ),
        bankTransferInstructions:
            BankTransferFundingInstructions.tryParse(data['bankTransferInstructions']),
      );
    } on DioException catch (e) {
      throw ServerException(_depositErrorMessage(e), e.response?.statusCode);
    }
  }

  /// [POST /api/wallet/deposits/:intentId/reconcile] — manual settle retry
  /// for a deposit stuck in PENDING (e.g. webhook delay).
  Future<String> reconcileDeposit(String intentId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _path(ApiEndpoints.walletDepositReconcile(intentId)),
      );
      final data = res.data;
      if (data == null) {
        throw const ServerException('Empty reconcile response');
      }
      final err = _err(data);
      if (err != null) {
        throw ServerException(err);
      }
      return '${data['status'] ?? 'PENDING'}';
    } on DioException catch (e) {
      throw ServerException(_depositErrorMessage(e), e.response?.statusCode);
    }
  }

  /// [GET /api/wallet/saved-cards] — DB projection (no live Stripe call).
  Future<SavedCardsResult> fetchSavedCards() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        _path(ApiEndpoints.walletSavedCards),
      );
      final data = res.data;
      if (data == null) return SavedCardsResult.empty;
      return SavedCardsResult.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_depositErrorMessage(e), e.response?.statusCode);
    }
  }

  /// [POST /api/wallet/saved-cards/refresh] — live Stripe → DB sync.
  Future<SavedCardsResult> refreshSavedCards() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _path(ApiEndpoints.walletSavedCardsRefresh),
      );
      final data = res.data;
      if (data == null) return SavedCardsResult.empty;
      return SavedCardsResult.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_depositErrorMessage(e), e.response?.statusCode);
    }
  }

  /// [DELETE /api/wallet/saved-cards] — detach a saved card.
  Future<void> deleteSavedCard(String paymentMethodId) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        _path(ApiEndpoints.walletSavedCards),
        data: <String, dynamic>{'paymentMethodId': paymentMethodId},
      );
      final data = res.data;
      final err = data == null ? null : _err(data);
      if (err != null) {
        throw ServerException(err);
      }
    } on DioException catch (e) {
      throw ServerException(_depositErrorMessage(e), e.response?.statusCode);
    }
  }

  Future<void> confirmDeposit(String intentId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _path(ApiEndpoints.walletConfirmDeposit),
        data: <String, dynamic>{'intentId': intentId},
      );
      final data = res.data;
      if (data == null) {
        return;
      }
      final err = _err(data);
      if (err != null) {
        throw ServerException(err);
      }
      if (data['success'] != true) {
        final d = _err(data) ?? 'Confirm failed';
        throw ServerException(d);
      }
    } on DioException catch (e) {
      throw ServerException(_depositErrorMessage(e), e.response?.statusCode);
    }
  }

  /// Dev / mock PSP only.
  Future<void> simulatePspSuccess(String intentId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _path(ApiEndpoints.webhooksPspSimulate),
        data: <String, dynamic>{'intentId': intentId},
      );
      final data = res.data;
      if (data == null) {
        throw const ServerException('Empty simulate response');
      }
      if (data['success'] != true) {
        final err = _err(data) ?? 'Simulate failed';
        throw ServerException(err);
      }
    } on DioException catch (e) {
      throw ServerException(_depositErrorMessage(e), e.response?.statusCode);
    }
  }

  static String _depositErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final code = map['code'] as String?;
      if (code == 'BUSINESS_PROFILE_INCOMPLETE') {
        final msg = map['error'] as String?;
        if (msg != null && msg.trim().isNotEmpty) {
          return msg.trim();
        }
        return 'Complete your business information before adding funds to your wallet.';
      }
      final err = map['error'];
      if (err is String && err.trim().isNotEmpty) {
        return err.trim();
      }
    }
    return e.message?.trim().isNotEmpty == true
        ? e.message!.trim()
        : 'Could not process wallet payment.';
  }
}
