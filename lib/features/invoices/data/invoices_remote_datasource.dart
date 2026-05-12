import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/invoice.dart';
import '../domain/invoices_page.dart';

/// Wayo-ads invoice HTTP surface — Bearer via [Dio] interceptors.
abstract interface class InvoicesRemote {
  Future<InvoicesPage> fetchAdvertiserPage({required int page});

  Future<InvoicesPage> fetchCreatorPage({required int page});

  Future<Uint8List> fetchInvoicePdf(
    String invoiceId, {
    void Function(int received, int total)? onProgress,
  });
}

final class InvoicesRemoteDatasource implements InvoicesRemote {
  InvoicesRemoteDatasource(this._dio);

  final Dio _dio;

  static const int _defaultPageSize = 10;

  @override
  Future<InvoicesPage> fetchAdvertiserPage({required int page}) =>
      _fetchRolePaginated(
        path: ApiEndpoints.advertiserInvoices,
        page: page,
        filterRole: InvoiceRoleType.advertiser,
      );

  @override
  Future<InvoicesPage> fetchCreatorPage({required int page}) =>
      _fetchRolePaginated(
        path: ApiEndpoints.creatorInvoices,
        page: page,
        filterRole: InvoiceRoleType.creator,
      );

  Future<InvoicesPage> _fetchRolePaginated({
    required String path,
    required int page,
    required InvoiceRoleType filterRole,
  }) async {
    try {
      final res = await _dio.get<Object?>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(path),
        queryParameters: <String, dynamic>{
          'page': page,
        },
      );
      return _parsePaginatedResponse(res.data, fallbackPage: page);
    } on DioException catch (e) {
      if (_shouldFallbackToLegacyList(e)) {
        return _legacyListPage(
          page: page,
          filterRole: filterRole,
        );
      }
      rethrow;
    }
  }

  /// When role-specific routes are missing, blocked, or misconfigured, ask the
  /// unified list and paginate in memory (same behaviour as pre-paginated API).
  Future<InvoicesPage> _legacyListPage({
    required int page,
    required InvoiceRoleType filterRole,
  }) async {
    final res = await _dio.get<Object?>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.invoicesAll),
    );
    final all = _parseInvoiceList(res.data);
    // Prefer server `roleType` when present; legacy payloads may omit it (`unknown`).
    var rows = all.where((i) => i.roleType == filterRole).toList(growable: false);
    if (rows.isEmpty && all.isNotEmpty &&
        all.every((i) => i.roleType == InvoiceRoleType.unknown)) {
      rows = List<Invoice>.from(all);
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    const lim = _defaultPageSize;
    final totalCount = rows.length;
    final totalPages = totalCount > 0 ? (totalCount + lim - 1) ~/ lim : 1;
    final start = (page.clamp(1, totalPages) - 1) * lim;
    final slice = rows.skip(start).take(lim).toList(growable: false);

    return InvoicesPage(
      invoices: slice,
      page: page.clamp(1, totalPages),
      pageSize: lim,
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
    final pageSize = _int(row['pageSize'] ?? row['limit'], _defaultPageSize).clamp(1, 100);
    final totalCount = _int(
      row['totalCount'] ?? row['total'] ?? row['count'],
      list.length,
    );
    var totalPages = _int(row['totalPages'], 0);
    if (totalPages < 1) {
      totalPages = totalCount > 0 ? (totalCount + pageSize - 1) ~/ pageSize : 1;
    }

    return InvoicesPage(
      invoices: list,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: totalPages,
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
    void Function(int received, int total)? onProgress,
  }) async {
    final res = await _dio.get<Object?>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.invoicePdf(invoiceId)),
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
}
