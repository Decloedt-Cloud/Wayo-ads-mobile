import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/invoice.dart';
import '../domain/invoices_page.dart';

/// Wayo-ads invoice HTTP surface — Bearer via [Dio] interceptors.
abstract interface class InvoicesRemote {
  Future<InvoicesPage> fetchAdvertiserPage({
    required int page,
    int limit = 15,
    String? invoiceType,
    String search = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  });

  Future<InvoicesPage> fetchCreatorPayoutsPage({
    required int page,
    int limit = 10,
    String? payoutType,
    String search = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    String sortBy = 'statementDate',
    String sortDir = 'desc',
  });

  Future<InvoicesPage> fetchCreatorPage({
    required int page,
    int limit = 10,
    String? invoiceType,
    String search = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  });

  Future<Uint8List> fetchInvoicePdf(
    String invoiceId, {
    required String locale,
    void Function(int received, int total)? onProgress,
  });

  Future<Uint8List> fetchPayoutPdf(
    String statementId, {
    required String locale,
    void Function(int received, int total)? onProgress,
  });
}

final class InvoicesRemoteDatasource implements InvoicesRemote {
  InvoicesRemoteDatasource(this._dio);

  final Dio _dio;

  static const int _legacyPageSize = 15;

  static String? _yyyyMmDd(DateTime? d) {
    if (d == null) return null;
    final local = DateTime(d.year, d.month, d.day);
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Future<InvoicesPage> fetchAdvertiserPage({
    required int page,
    int limit = 15,
    String? invoiceType,
    String search = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        'sortBy': sortBy,
        'sortDir': sortDir,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (_yyyyMmDd(dateFrom) != null) 'dateFrom': _yyyyMmDd(dateFrom),
        if (_yyyyMmDd(dateTo) != null) 'dateTo': _yyyyMmDd(dateTo),
        if (invoiceType != null && invoiceType.isNotEmpty) 'invoiceType': invoiceType,
      };

      final res = await _dio.get<Object?>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.advertiserInvoices),
        queryParameters: query,
      );
      return _parsePaginatedResponse(res.data, fallbackPage: page);
    } on DioException catch (e) {
      if (_shouldFallbackToLegacyList(e)) {
        return _legacyListPage(
          page: page,
          limit: limit.clamp(1, 100),
          filterRole: InvoiceRoleType.advertiser,
          invoiceType: invoiceType,
          search: search,
          dateFrom: dateFrom,
          dateTo: dateTo,
          sortBy: sortBy,
          sortDir: sortDir,
        );
      }
      rethrow;
    }
  }

  @override
  Future<InvoicesPage> fetchCreatorPayoutsPage({
    required int page,
    int limit = 10,
    String? payoutType,
    String search = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    String sortBy = 'statementDate',
    String sortDir = 'desc',
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        'sortBy': sortBy,
        'sortDir': sortDir,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (_yyyyMmDd(dateFrom) != null) 'dateFrom': _yyyyMmDd(dateFrom),
        if (_yyyyMmDd(dateTo) != null) 'dateTo': _yyyyMmDd(dateTo),
        if (payoutType != null && payoutType.isNotEmpty) 'payoutType': payoutType,
      };

      final res = await _dio.get<Object?>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.creatorPayouts),
        queryParameters: query,
      );
      if (_responseIndicatesFailure(res.data)) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      return _parseCreatorPayoutsResponse(res.data, fallbackPage: page);
    } on DioException catch (e) {
      return _fallbackCreatorPayoutsPage(
        e,
        page: page,
        limit: limit,
        payoutType: payoutType,
        search: search,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    }
  }

  bool _responseIndicatesFailure(Object? body) {
    if (body is! Map) return false;
    final row = Map<String, dynamic>.from(body);
    final nested = row['data'];
    if (nested is Map) {
      return nested['success'] == false;
    }
    return row['success'] == false;
  }

  /// When `/api/creator/payouts` is unavailable (older deploy, missing migration),
  /// fall back to `/api/creator/invoices` so the tab still loads.
  Future<InvoicesPage> _fallbackCreatorPayoutsPage(
    DioException error, {
    required int page,
    required int limit,
    String? payoutType,
    String search = '',
    DateTime? dateTo,
    DateTime? dateFrom,
  }) async {
    if (!_shouldFallbackToLegacyList(error)) {
      throw error;
    }

    final invoiceType = switch (payoutType) {
      'WITHDRAWAL' => 'PAYOUT',
      'TOKEN_PURCHASE' => null,
      _ => null,
    };

    final legacy = await fetchCreatorPage(
      page: page,
      limit: limit,
      invoiceType: invoiceType,
      search: search,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );

    if (payoutType == 'TOKEN_PURCHASE') {
      return InvoicesPage(
        invoices: const [],
        page: legacy.page,
        pageSize: legacy.pageSize,
        totalCount: 0,
        totalPages: 1,
        currency: legacy.currency ?? 'USD',
        creatorStats: legacy.creatorStats,
      );
    }

    return legacy;
  }

  InvoicesPage _parseCreatorPayoutsResponse(Object? body, {required int fallbackPage}) {
    Map<String, dynamic>? row;
    if (body is Map) {
      row = Map<String, dynamic>.from(body);
      final nested = row['data'];
      if (nested is Map) {
        row = Map<String, dynamic>.from(nested);
      }
    }
    if (row == null) {
      return InvoicesPage.empty();
    }

    final rawList = row['payouts'];
    final list = rawList is List
        ? rawList
            .whereType<Map>()
            .map((e) => _invoiceFromCreatorPayout(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : <Invoice>[];

    final page = _int(row['page'], fallbackPage);
    final pageSize = _int(row['pageSize'] ?? row['limit'], 10).clamp(1, 100);
    final totalCount = _int(row['totalCount'] ?? row['total'] ?? row['count'], list.length);
    var totalPages = _int(row['totalPages'], 0);
    if (totalPages < 1) {
      totalPages = totalCount > 0 ? (totalCount + pageSize - 1) ~/ pageSize : 1;
    }

    final statsRaw = row['stats'];
    final statsMap =
        statsRaw is Map ? Map<String, dynamic>.from(statsRaw) : null;
    final creatorStats = statsMap != null
        ? CreatorInvoicesStats.fromJson(statsMap)
        : null;
    final currency = row['currency'] is String && (row['currency'] as String).isNotEmpty
        ? (row['currency'] as String).trim().toUpperCase()
        : 'USD';

    return InvoicesPage(
      invoices: list,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: totalPages,
      currency: currency,
      creatorStats: creatorStats,
    );
  }

  Invoice _invoiceFromCreatorPayout(Map<String, dynamic> json) {
    final typeRaw = '${json['type'] ?? ''}'.trim().toUpperCase();
    final invoiceType = typeRaw == 'TOKEN_PURCHASE'
        ? InvoiceType.tokenPurchase
        : InvoiceType.payout;
    final statusRaw = '${json['status'] ?? ''}'.trim().toUpperCase();
    final status = switch (statusRaw) {
      'PAID' => InvoiceStatus.paid,
      'VALIDATED' => InvoiceStatus.validated,
      'PENDING' || 'PROCESSING' => InvoiceStatus.pending,
      'CANCELLED' || 'FAILED' => InvoiceStatus.cancelled,
      _ => InvoiceStatus.unknown,
    };
    final currency = json['currency'] is String && (json['currency'] as String).isNotEmpty
        ? (json['currency'] as String).trim().toUpperCase()
        : 'USD';

    return Invoice(
      id: '${json['id'] ?? ''}',
      invoiceNumber: '${json['statementId'] ?? ''}',
      type: invoiceType,
      roleType: InvoiceRoleType.creator,
      status: status,
      totalAmountCents: _parseInt(json['netPayoutCents'], 0),
      taxAmountCents: _parseInt(json['taxCents'], 0),
      currency: currency,
      referenceId: json['payoutId'] is String ? json['payoutId'] as String : null,
      createdAt: _parseDate(json['statementDate']) ?? DateTime.now().toUtc(),
      paidAt: _parseDate(json['payoutDate']),
    );
  }

  static int _parseInt(Object? v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse('$v')?.toUtc();
  }

  @override
  Future<InvoicesPage> fetchCreatorPage({
    required int page,
    int limit = 10,
    String? invoiceType,
    String search = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        'sortBy': sortBy,
        'sortDir': sortDir,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (_yyyyMmDd(dateFrom) != null) 'dateFrom': _yyyyMmDd(dateFrom),
        if (_yyyyMmDd(dateTo) != null) 'dateTo': _yyyyMmDd(dateTo),
        if (invoiceType != null && invoiceType.isNotEmpty) 'invoiceType': invoiceType,
      };

      final res = await _dio.get<Object?>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.creatorInvoices),
        queryParameters: query,
      );
      return _parsePaginatedResponse(res.data, fallbackPage: page);
    } on DioException catch (e) {
      if (_shouldFallbackToLegacyList(e)) {
        return _legacyListPage(
          page: page,
          limit: limit.clamp(1, 100),
          filterRole: InvoiceRoleType.creator,
          invoiceType: invoiceType,
          search: search,
          dateFrom: dateFrom,
          dateTo: dateTo,
          sortBy: sortBy,
          sortDir: sortDir,
        );
      }
      rethrow;
    }
  }

  /// When role-specific routes are missing, blocked, or misconfigured, ask the
  /// unified list and paginate in memory (same behaviour as pre-paginated API).
  Future<InvoicesPage> _legacyListPage({
    required int page,
    required int limit,
    required InvoiceRoleType filterRole,
    String? invoiceType,
    String search = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  }) async {
    final res = await _dio.get<Object?>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.invoicesAll),
    );
    final all = _parseInvoiceList(res.data);
    var rows = all.where((i) => i.roleType == filterRole).toList(growable: true);
    if (rows.isEmpty &&
        all.isNotEmpty &&
        all.every((i) => i.roleType == InvoiceRoleType.unknown)) {
      rows = List<Invoice>.from(all);
    }

    if (invoiceType != null && invoiceType.isNotEmpty) {
      final t = InvoiceType.fromApi(invoiceType);
      rows = rows.where((i) => i.type == t).toList();
    }

    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      rows = rows
          .where(
            (i) =>
                i.invoiceNumber.toLowerCase().contains(q) ||
                (i.referenceId?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    if (dateFrom != null) {
      final from = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
      rows = rows.where((i) => !i.createdAt.toLocal().isBefore(from)).toList();
    }
    if (dateTo != null) {
      final to = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59, 999);
      rows = rows.where((i) => !i.createdAt.toLocal().isAfter(to)).toList();
    }

    int cmp(Invoice a, Invoice b) {
      final asc = sortDir == 'asc';
      if (sortBy == 'amount') {
        final c = a.totalAmountCents.compareTo(b.totalAmountCents);
        return asc ? c : -c;
      }
      if (sortBy == 'status') {
        final c = a.status.api.compareTo(b.status.api);
        return asc ? c : -c;
      }
      final c = a.createdAt.compareTo(b.createdAt);
      return asc ? c : -c;
    }

    rows.sort(cmp);

    final totalCount = rows.length;
    final totalPages = totalCount > 0 ? (totalCount + limit - 1) ~/ limit : 1;
    final start = (page.clamp(1, totalPages) - 1) * limit;
    final slice = rows.skip(start).take(limit).toList(growable: false);

    return InvoicesPage(
      invoices: slice,
      page: page.clamp(1, totalPages),
      pageSize: limit,
      totalCount: totalCount,
      totalPages: totalPages,
    );
  }

  InvoicesPage _parsePaginatedResponse(Object? body, {required int fallbackPage}) {
    Map<String, dynamic>? row;
    if (body is Map) {
      row = Map<String, dynamic>.from(body);
      final nested = row['data'];
      if (nested is Map) {
        row = Map<String, dynamic>.from(nested);
      }
    }
    if (row == null) {
      return InvoicesPage.empty();
    }

    final rawList = row['invoices'] ?? row['data'];
    final list = rawList is List
        ? rawList
            .whereType<Map>()
            .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : <Invoice>[];

    final page = _int(row['page'], fallbackPage);
    final pageSize = _int(row['pageSize'] ?? row['limit'], _legacyPageSize).clamp(1, 100);
    final totalCount = _int(
      row['totalCount'] ?? row['total'] ?? row['count'],
      list.length,
    );
    var totalPages = _int(row['totalPages'], 0);
    if (totalPages < 1) {
      totalPages = totalCount > 0 ? (totalCount + pageSize - 1) ~/ pageSize : 1;
    }

    final statsRaw = row['stats'];
    final statsMap =
        statsRaw is Map ? Map<String, dynamic>.from(statsRaw) : null;
    final advertiserStats = statsMap != null
        ? AdvertiserInvoicesStats.fromJson(statsMap)
        : null;
    final creatorStats = statsMap != null &&
            (statsMap.containsKey('totalValidated') ||
                statsMap.containsKey('totalValidatedCents') ||
                statsMap.containsKey('totalEarned'))
        ? CreatorInvoicesStats.fromJson(statsMap)
        : null;
    final currency = row['currency'] is String ? (row['currency'] as String).trim() : null;

    return InvoicesPage(
      invoices: list,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: totalPages,
      currency: currency,
      advertiserStats: advertiserStats,
      creatorStats: creatorStats,
    );
  }

  List<Invoice> _parseInvoiceList(Object? body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }
    if (body is Map) {
      final m = Map<String, dynamic>.from(body);
      final raw = m['invoices'] ?? m['data'];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false);
      }
    }
    return const <Invoice>[];
  }

  static int _int(Object? v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static bool _shouldFallbackToLegacyList(DioException e) {
    final code = e.response?.statusCode;
    if (code == null) return false;
    return code == 401 ||
        code == 403 ||
        code == 404 ||
        code == 405 ||
        code >= 500;
  }

  @override
  Future<Uint8List> fetchInvoicePdf(
    String invoiceId, {
    required String locale,
    void Function(int received, int total)? onProgress,
  }) async {
    final res = await _dio.get<Object?>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.invoicePdf(invoiceId)),
      queryParameters: {'locale': locale},
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress,
    );
    final data = res.data;
    if (data is Uint8List) {
      return data;
    }
    if (data is List<int>) {
      return Uint8List.fromList(data);
    }
    throw const FormatException('Invoice PDF: expected binary body');
  }

  @override
  Future<Uint8List> fetchPayoutPdf(
    String statementId, {
    required String locale,
    void Function(int received, int total)? onProgress,
  }) async {
    final res = await _dio.get<Object?>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.payoutPdf(statementId),
      ),
      queryParameters: {'locale': locale},
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress,
    );
    final data = res.data;
    if (data is Uint8List) {
      return data;
    }
    if (data is List<int>) {
      return Uint8List.fromList(data);
    }
    throw const FormatException('Payout PDF: expected binary body');
  }
}
