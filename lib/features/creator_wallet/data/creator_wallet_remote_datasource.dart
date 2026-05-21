import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
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

/// One Zod issue from Wayo-ads (`{ path: string[], message: string }`).
class CreatorWalletValidationIssue {
  const CreatorWalletValidationIssue({required this.path, required this.message});

  final List<String> path;
  final String message;

  String? get fieldKey => path.isEmpty ? null : path.last;
}

/// Server returned a structured error (`{ error: string, errorCode?: string, details?: ... }`).
class CreatorWalletApiException implements Exception {
  CreatorWalletApiException(
    this.message, {
    this.code,
    this.statusCode,
    this.validationIssues,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final List<CreatorWalletValidationIssue>? validationIssues;

  @override
  String toString() => 'CreatorWalletApiException($statusCode $code: $message)';

  static List<CreatorWalletValidationIssue>? _parseValidationDetails(
    dynamic raw,
    String fallbackMessage,
  ) {
    if (raw is! List) return null;
    final out = <CreatorWalletValidationIssue>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final pathRaw = m['path'];
      final path = pathRaw is List
          ? pathRaw.map((e) => e.toString()).toList(growable: false)
          : const <String>[];
      final msg = (m['message'] as String?)?.trim() ?? '';
      if (path.isEmpty && msg.isEmpty) continue;
      out.add(
        CreatorWalletValidationIssue(
          path: path,
          message: msg.isEmpty ? fallbackMessage : msg,
        ),
      );
    }
    return out.isEmpty ? null : out;
  }
}

extension CreatorWalletApiExceptionX on CreatorWalletApiException {
  /// True when the message likely refers to billing/address data the creator
  /// can fix in [PUT /api/creator/business-profile] (e.g. Stripe "Invalid FR postal code").
  bool get mayBeFixedViaBusinessProfileEdit {
    if (validationIssues != null && validationIssues!.isNotEmpty) return true;
    final m = message.toLowerCase();
    return m.contains('postal') ||
        m.contains('zip') ||
        m.contains('address') ||
        (m.contains('invalid') && m.contains('code')) ||
        m.contains('vat') ||
        m.contains('country');
  }
}

/// Thin HTTP wrapper over `/api/creator/{withdrawal,stripe-connect/*}` on
/// Wayo-ads (Next.js). Authentication uses the Bearer JWT attached by
/// `wayoAdsDioProvider` (see `core/network/wayo_ads_dio.dart`).
class CreatorWalletRemoteDatasource {
  CreatorWalletRemoteDatasource(this._dio);

  final Dio _dio;

  /// `GET /api/creator/withdrawal` — balance + platform settings + **full**
  /// withdrawal history (loops with max `limit` until the API returns no more rows).
  ///
  /// UI pagination (e.g. 10 rows) is client-only — this call loads everything once.
  Future<CreatorWalletPage> fetchWalletPage() async {
    const batch = 100;
    late final CreatorWalletPage first;
    final byId = <String, CreatorWithdrawal>{};

    var o = 0;
    var isFirst = true;
    while (true) {
      final page = await _fetchWalletPageSlice(limit: batch, offset: o);
      if (isFirst) {
        first = page;
        isFirst = false;
      }
      for (final w in page.withdrawals) {
        if (w.id.isNotEmpty) {
          byId[w.id] = w;
        }
      }
      if (page.withdrawals.length < batch) break;
      o += page.withdrawals.length;
    }

    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return CreatorWalletPage(
      balance: first.balance,
      limits: first.limits,
      withdrawals: merged,
      canSimulate: first.canSimulate,
    );
  }

  Future<CreatorWalletPage> _fetchWalletPageSlice({
    required int limit,
    required int offset,
  }) async {
    final res = await _dio.get<Object?>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.creatorWithdrawal),
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
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.creatorWithdrawal),
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
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.creatorWithdrawal),
        queryParameters: {'id': id},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// `GET /api/creator/stripe-connect/status` — onboarding flags.
  Future<CreatorStripeStatus> fetchStripeStatus() async {
    try {
      final res = await _dio.get<Object?>(
        AuthRuntimeConfig.instance
            .wayoAdsRequestPath(ApiEndpoints.creatorStripeConnectStatus),
      );
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
        AuthRuntimeConfig.instance
            .wayoAdsRequestPath(ApiEndpoints.creatorStripeConnectOnboard),
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
      final res = await _dio.get<Object?>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.creatorBusinessProfile),
      );
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
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.creatorBusinessProfile),
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
      final res = await _dio.post<Object?>(
        AuthRuntimeConfig.instance
            .wayoAdsRequestPath(ApiEndpoints.creatorStripeConnectLogin),
      );
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
    final validationIssues = CreatorWalletApiException._parseValidationDetails(
      map?['details'],
      message,
    );

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
    return CreatorWalletApiException(
      message,
      code: code,
      statusCode: status,
      validationIssues: validationIssues,
    );
  }
}
