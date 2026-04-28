import 'package:dio/dio.dart';

import '../domain/creator_business_profile.dart';
import '../domain/creator_wallet_models.dart';

/// Raised when a creator tries to withdraw but doesn't have enough available
/// funds. The server returns `errorCode: INSUFFICIENT_FUNDS` with a `details`
/// block; we surface both to the UI.
class WithdrawalInsufficientFundsException implements Exception {
  WithdrawalInsufficientFundsException({
    required this.requestedCents,
    required this.availableCents,
  });

  final int requestedCents;
  final int availableCents;

  @override
  String toString() =>
      'WithdrawalInsufficientFundsException(requested=$requestedCents, '
      'available=$availableCents)';
}

/// Server returned a structured error (`{ error: string, errorCode? }`).
class CreatorWalletApiException implements Exception {
  CreatorWalletApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => 'CreatorWalletApiException($statusCode $code: $message)';
}

/// Thin HTTP wrapper over `/api/creator/{withdrawal,stripe-connect/*}` on
/// Wayo-ads (Next.js). Authentication uses the Bearer JWT attached by
/// `wayoAdsDioProvider` (see `core/network/wayo_ads_dio.dart`).
class CreatorWalletRemoteDatasource {
  CreatorWalletRemoteDatasource(this._dio);

  final Dio _dio;

  /// `GET /api/creator/withdrawal` — balance + platform settings + history.
  Future<CreatorWalletPage> fetchWalletPage({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get<Object?>(
      'api/creator/withdrawal',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final body = res.data;
    if (body is! Map) {
      throw CreatorWalletApiException(
        'Invalid /creator/withdrawal payload',
        statusCode: res.statusCode,
      );
    }
    final map = Map<String, dynamic>.from(body);
    final balanceRaw = map['balance'];
    final platformRaw = map['platform'];
    final withdrawalsRaw = map['withdrawals'];
    final balance = balanceRaw is Map
        ? CreatorBalance.fromJson(Map<String, dynamic>.from(balanceRaw))
        : CreatorBalance.empty();
    final limits = platformRaw is Map
        ? CreatorPlatformLimits.fromJson(Map<String, dynamic>.from(platformRaw))
        : CreatorPlatformLimits.fallback;
    final list = withdrawalsRaw is List
        ? withdrawalsRaw
              .whereType<Map>()
              .map(
                (e) => CreatorWithdrawal.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const <CreatorWithdrawal>[];
    return CreatorWalletPage(
      balance: balance,
      limits: limits,
      withdrawals: list,
      canSimulate: map['canSimulate'] == true,
    );
  }

  /// `POST /api/creator/withdrawal` — request a new payout.
  Future<CreatorWithdrawal> requestWithdrawal({
    required int amountCents,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        'api/creator/withdrawal',
        data: {'amountCents': amountCents},
      );
      final body = res.data;
      if (body is! Map) {
        throw CreatorWalletApiException(
          'Invalid withdrawal response',
          statusCode: res.statusCode,
        );
      }
      final map = Map<String, dynamic>.from(body);
      final wdRaw = map['withdrawal'];
      if (wdRaw is! Map) {
        throw CreatorWalletApiException(
          'Missing withdrawal object',
          statusCode: res.statusCode,
        );
      }
      return CreatorWithdrawal.fromJson(Map<String, dynamic>.from(wdRaw));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// `DELETE /api/creator/withdrawal?id=...` — cancel a pending payout.
  Future<void> cancelWithdrawal(String id) async {
    try {
      await _dio.delete<Object?>(
        'api/creator/withdrawal',
        queryParameters: {'id': id},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// `GET /api/creator/stripe-connect/status` — onboarding flags.
  Future<CreatorStripeStatus> fetchStripeStatus() async {
    try {
      final res = await _dio.get<Object?>('api/creator/stripe-connect/status');
      final body = res.data;
      if (body is! Map) return CreatorStripeStatus.disconnected;
      return CreatorStripeStatus.fromJson(Map<String, dynamic>.from(body));
    } on DioException catch (e) {
      // 403 / 404 → unonboarded → expose a safe "disconnected" state rather
      // than crashing the screen. Other statuses propagate.
      final status = e.response?.statusCode ?? 0;
      if (status == 403 || status == 404) {
        return CreatorStripeStatus.disconnected;
      }
      throw _mapDioError(e);
    }
  }

  /// `POST /api/creator/stripe-connect/onboard` — returns a signed URL.
  Future<String> createOnboardingUrl() async {
    try {
      final res = await _dio.post<Object?>(
        'api/creator/stripe-connect/onboard',
      );
      final url = _extractUrl(res);
      if (url == null || url.isEmpty) {
        throw CreatorWalletApiException(
          'Missing onboarding url',
          statusCode: res.statusCode,
        );
      }
      return url;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// `GET /api/creator/business-profile` — current profile + completeness flag.
  Future<CreatorBusinessProfile> fetchBusinessProfile() async {
    try {
      final res = await _dio.get<Object?>('api/creator/business-profile');
      final body = res.data;
      if (body is! Map) return CreatorBusinessProfile.empty();
      return CreatorBusinessProfile.fromEnvelope(
        Map<String, dynamic>.from(body),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 404) return CreatorBusinessProfile.empty();
      throw _mapDioError(e);
    }
  }

  /// `PUT /api/creator/business-profile` — create or update the profile.
  ///
  /// Server returns `{ success, profile }`; we re-fetch the envelope shape to
  /// get a consistent [CreatorBusinessProfile] with the updated completeness
  /// flag.
  Future<CreatorBusinessProfile> updateBusinessProfile(
    CreatorBusinessProfileInput input,
  ) async {
    try {
      await _dio.put<Object?>(
        'api/creator/business-profile',
        data: input.toJson(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
    return fetchBusinessProfile();
  }

  /// `POST /api/creator/stripe-connect/login` — returns the Express dashboard URL.
  Future<String> createLoginUrl() async {
    try {
      final res = await _dio.post<Object?>('api/creator/stripe-connect/login');
      final url = _extractUrl(res);
      if (url == null || url.isEmpty) {
        throw CreatorWalletApiException(
          'Missing login url',
          statusCode: res.statusCode,
        );
      }
      return url;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  static String? _extractUrl(Response<Object?> res) {
    final body = res.data;
    if (body is Map) return body['url'] as String?;
    return null;
  }

  /// Converts a [DioException] into a typed creator-wallet exception.
  ///
  /// Server shape: `{ error: string, errorCode?: string, details?: {...} }`.
  Exception _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final map = data is Map ? Map<String, dynamic>.from(data) : null;
    final code = map?['errorCode'] as String?;
    final message =
        (map?['error'] as String?) ?? e.message ?? 'Wallet request failed';

    if (code == 'INSUFFICIENT_FUNDS') {
      final details = map?['details'];
      int? req;
      int? avail;
      if (details is Map) {
        req = (details['requested'] as num?)?.toInt();
        avail = (details['available'] as num?)?.toInt();
      }
      return WithdrawalInsufficientFundsException(
        requestedCents: req ?? 0,
        availableCents: avail ?? 0,
      );
    }
    return CreatorWalletApiException(message, code: code, statusCode: status);
  }
}
