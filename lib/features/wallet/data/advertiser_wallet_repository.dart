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
      currency: (w['currency'] as String?)?.toUpperCase() ?? 'EUR',
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
          currency: (e['currency'] as String?)?.toUpperCase() ?? 'EUR',
          description: e['description'] as String? ?? '',
          createdAt: _parseDate(e['createdAt'] ?? e['created_at']),
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

  Future<DepositIntentResult> createDepositIntent({
    required int amountCents,
    String? currency,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _path(ApiEndpoints.walletDepositIntent),
      data: <String, dynamic>{
        'amountCents': amountCents,
        'currency': currency,
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
    return DepositIntentResult(
      intentId: '${intent['intentId'] ?? ''}',
      clientSecret: intent['clientSecret'] as String? ?? '',
      amountCents: (intent['amountCents'] as num?)?.toInt() ?? amountCents,
      currency: (intent['currency'] as String?)?.toUpperCase() ?? 'EUR',
      canSimulate: data['canSimulate'] == true,
    );
  }

  Future<void> confirmDeposit(String intentId) async {
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
  }

  /// Dev / mock PSP only.
  Future<void> simulatePspSuccess(String intentId) async {
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
  }
}
