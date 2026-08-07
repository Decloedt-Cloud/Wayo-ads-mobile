import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/admin_api_endpoints.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../../creator/presentation/providers/creator_session_gate.dart';
import '../domain/entities/admin_ops.dart';

final superadminOpsRemoteProvider = Provider<SuperadminOpsRemote>((ref) {
  return SuperadminOpsRemote(ref.watch(wayoAdsDioProvider));
});

final class SuperadminOpsRemote {
  SuperadminOpsRemote(this._dio);

  final Dio _dio;

  String _path(String endpoint) =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(endpoint);

  Future<PaymentAuditsPage> fetchPaymentAudits({
    int page = 1,
    int limit = 20,
    String? search,
    String? advertiserId,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.paymentAudits),
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (advertiserId != null && advertiserId.trim().isNotEmpty)
          'advertiserId': advertiserId.trim(),
      },
    );
    final data = _map(res.data);
    final raw = data['records'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => PaymentAuditRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PaymentAuditRecord>[];
    return PaymentAuditsPage(
      records: list,
      total: _asInt(data['total']),
      page: _asInt(data['page'] ?? page),
      limit: _asInt(data['limit'] ?? limit),
    );
  }

  /// [POST /api/admin/payment-audits/{id}/reconcile] — targeted Stripe fee
  /// reconciliation for one audit row.
  Future<PaymentAuditReconcileResult> reconcilePaymentAudit(String auditId) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.paymentAuditReconcile(auditId)),
    );
    final data = _map(res.data);
    return PaymentAuditReconcileResult.fromJson(data);
  }

  /// [GET /api/admin/advertiser-deposits] — per-advertiser deposit totals
  /// (drill-down source for the "By advertiser" tab).
  Future<AdvertiserDepositsPage> fetchAdvertiserDeposits({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.advertiserDeposits),
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = _map(res.data);
    return AdvertiserDepositsPage.fromJson(data);
  }

  Future<AuditLogPage> fetchAuditLog({
    int limit = 50,
    int offset = 0,
    String? search,
    String? action,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.auditLog),
      queryParameters: <String, dynamic>{
        'limit': limit.clamp(1, 100),
        'offset': offset.clamp(0, 100000),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (action != null && action.isNotEmpty && action != 'all')
          'action': action,
      },
    );
    final data = _map(res.data);
    final raw = data['entries'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => AuditLogEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AuditLogEntry>[];
    return AuditLogPage(
      entries: list,
      total: _asInt(data['total']),
      limit: _asInt(data['limit'] ?? limit),
      offset: _asInt(data['offset'] ?? offset),
    );
  }

  Future<PlatformHealthSnapshot> fetchHealth() async {
    final res = await _dio.get<Object?>(_path(AdminApiEndpoints.health));
    return PlatformHealthSnapshot.fromJson(_map(res.data));
  }

  Future<List<AdminServiceStatus>> fetchServicesHealth() async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.healthServices),
      queryParameters: const <String, dynamic>{'full': '1'},
    );
    final data = _map(res.data);
    final raw = data['services'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AdminServiceStatus.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<TokenPurchasesPage> fetchTokenPurchases({
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.tokenPurchases),
      queryParameters: <String, dynamic>{
        'limit': limit.clamp(1, 100),
        'offset': offset.clamp(0, 100000),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = _map(res.data);
    final raw = data['purchases'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => TokenPurchaseRecord.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : <TokenPurchaseRecord>[];
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : <String, dynamic>{};
    final statsRaw = data['packageStats'];
    final stats = statsRaw is List
        ? statsRaw
            .whereType<Map>()
            .map((e) => TokenPackageStat.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <TokenPackageStat>[];
    return TokenPurchasesPage(
      purchases: list,
      total: _asInt(data['total']),
      page: _asInt(data['page'] ?? 1),
      totalTokens: _asInt(summary['totalTokens']),
      totalRevenueCents: _asInt(summary['totalRevenueCents']),
      totalTaxCents: _asInt(summary['totalTaxCents']),
      packageStats: stats,
    );
  }

  Future<ClickPipelineSnapshot> fetchClickPipeline() async {
    final res = await _dio.get<Object?>(_path(AdminApiEndpoints.clickPipeline));
    return ClickPipelineSnapshot.fromJson(_map(res.data));
  }

  Future<CreatorVelocitySnapshot> fetchCreatorVelocity({
    String period = '7d',
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.creatorVelocity),
      queryParameters: <String, dynamic>{'period': period},
    );
    final data = _map(res.data);
    final raw = data['topCreators'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => CreatorVelocityRow.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : <CreatorVelocityRow>[];
    return CreatorVelocitySnapshot(period: period, topCreators: list);
  }

  Future<EmailLogsPage> fetchEmailLogs({
    int limit = 30,
    int offset = 0,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.emailLogs),
      queryParameters: <String, dynamic>{
        'limit': limit.clamp(1, 100),
        'offset': offset.clamp(0, 100000),
      },
    );
    final data = _map(res.data);
    final raw = data['logs'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => EmailLogRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <EmailLogRecord>[];
    return EmailLogsPage(
      logs: list,
      total: _asInt(data['total']),
      limit: _asInt(data['limit'] ?? limit),
      offset: _asInt(data['offset'] ?? offset),
    );
  }

  Future<RecentActivityPage> fetchRecentActivity({
    int limit = 30,
    int offset = 0,
    String? search,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.recentActivity),
      queryParameters: <String, dynamic>{
        'limit': limit.clamp(1, 100),
        'offset': offset.clamp(0, 100000),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = _map(res.data);
    final raw = data['activities'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => RecentActivityItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : <RecentActivityItem>[];
    return RecentActivityPage(
      activities: list,
      total: _asInt(data['total']),
    );
  }

  Future<AdminInvoicesPage> fetchAdminInvoices({
    int page = 1,
    int limit = 30,
    String? search,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.invoices),
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = _map(res.data);
    final raw = data['invoices'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => AdminInvoiceRecord.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : <AdminInvoiceRecord>[];
    return AdminInvoicesPage(
      invoices: list,
      total: _asInt(data['total']),
      page: _asInt(data['page'] ?? page),
      totalPages: _asInt(data['totalPages'] ?? 1),
    );
  }

  Future<AdminPaymentStatementsPage> fetchPaymentStatements({
    int page = 1,
    int limit = 30,
    String? search,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.paymentStatements),
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = _map(res.data);
    final raw = data['statements'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) =>
                  AdminPaymentStatement.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : <AdminPaymentStatement>[];
    return AdminPaymentStatementsPage(
      statements: list,
      total: _asInt(data['total']),
      page: _asInt(data['page'] ?? page),
      totalPages: _asInt(data['totalPages'] ?? 1),
    );
  }

  Future<YoutubeMonitoringStats> fetchYoutubeMonitoring() async {
    final res =
        await _dio.get<Object?>(_path(AdminApiEndpoints.youtubeCheckPostViews));
    return YoutubeMonitoringStats.fromJson(_map(res.data));
  }

  Future<AdminJobRunResult> runJob(
    String endpoint, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final res = await _dio.post<Object?>(
      _path(endpoint),
      queryParameters: query,
      data: body,
    );
    final data = _map(res.data);
    final ok = data['success'] == true ||
        data['error'] == null ||
        res.statusCode == 200;
    final summary = data['message']?.toString() ??
        data['error']?.toString() ??
        [
          if (data['processed'] != null) 'processed ${data['processed']}',
          if (data['released'] != null) 'released ${data['released']}',
          if (data['successCount'] != null) 'ok ${data['successCount']}',
          if (data['failedCount'] != null) 'fail ${data['failedCount']}',
          if (data['success'] is num) 'success ${data['success']}',
          if (data['failed'] is num) 'failed ${data['failed']}',
          if (data['updated'] != null) 'updated ${data['updated']}',
        ].where((e) => e.isNotEmpty).join(' · ');
    return AdminJobRunResult(
      ok: ok && data['error'] == null,
      summary: summary.isEmpty ? 'Done' : summary,
    );
  }

  Future<List<AdminTokenPackage>> fetchTokenPackages() async {
    final res = await _dio.get<Object?>(_path(AdminApiEndpoints.tokenPackages));
    final data = _map(res.data);
    final raw = data['packages'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AdminTokenPackage.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<AdminTokenPackage> createTokenPackage({
    required String slug,
    required String name,
    required int tokens,
    int bonusTokens = 0,
    required int priceCents,
    String currency = 'USD',
    bool isActive = true,
    bool isBestValue = false,
    String? appleProductId,
    String? googleProductId,
  }) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.tokenPackages),
      data: <String, dynamic>{
        'slug': slug,
        'name': name,
        'tokens': tokens,
        'bonusTokens': bonusTokens,
        'priceCents': priceCents,
        'currency': currency.toUpperCase(),
        'isActive': isActive,
        'isBestValue': isBestValue,
        if (appleProductId != null && appleProductId.isNotEmpty)
          'appleProductId': appleProductId,
        if (googleProductId != null && googleProductId.isNotEmpty)
          'googleProductId': googleProductId,
      },
    );
    return _parseTokenPackageResponse(res.data);
  }

  /// [appleProductId] / [googleProductId] pass `''` to clear the store product
  /// id (falls back to Stripe for that platform); omit (`null`) to leave as-is.
  Future<AdminTokenPackage> updateTokenPackage({
    required String slug,
    String? name,
    int? tokens,
    int? bonusTokens,
    int? priceCents,
    String? currency,
    bool? isActive,
    bool? isBestValue,
    int? sortOrder,
    String? appleProductId,
    String? googleProductId,
  }) async {
    final body = <String, dynamic>{'slug': slug};
    if (name != null) body['name'] = name;
    if (tokens != null) body['tokens'] = tokens;
    if (bonusTokens != null) body['bonusTokens'] = bonusTokens;
    if (priceCents != null) body['priceCents'] = priceCents;
    if (currency != null) body['currency'] = currency.toUpperCase();
    if (isActive != null) body['isActive'] = isActive;
    if (isBestValue != null) body['isBestValue'] = isBestValue;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    if (appleProductId != null) {
      body['appleProductId'] = appleProductId.isEmpty ? null : appleProductId;
    }
    if (googleProductId != null) {
      body['googleProductId'] = googleProductId.isEmpty ? null : googleProductId;
    }

    final res = await _dio.put<Object?>(
      _path(AdminApiEndpoints.tokenPackages),
      data: body,
    );
    return _parseTokenPackageResponse(res.data);
  }

  Future<void> setTokenPackageActive({
    required String slug,
    required bool isActive,
  }) async {
    await updateTokenPackage(slug: slug, isActive: isActive);
  }

  /// [POST /api/admin/token-packages/sync-stripe] — create/update Stripe Product+Price.
  Future<AdminTokenPackage> syncTokenPackageStripe(String slug) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.tokenPackagesSyncStripe),
      data: <String, dynamic>{'slug': slug},
    );
    final data = _map(res.data);
    if (data['error'] != null) {
      throw StateError('${data['error']}');
    }
    final pkg = data['package'];
    if (pkg is Map) {
      return AdminTokenPackage.fromJson(Map<String, dynamic>.from(pkg));
    }
    throw StateError('Invalid sync-stripe response');
  }

  AdminTokenPackage _parseTokenPackageResponse(Object? raw) {
    final data = _map(raw);
    if (data['error'] != null) {
      throw StateError('${data['error']}');
    }
    final pkg = data['package'];
    if (pkg is Map) {
      return AdminTokenPackage.fromJson(Map<String, dynamic>.from(pkg));
    }
    throw StateError('Invalid token package response');
  }

  Future<PlatformSettingsSnapshot> fetchPlatformSettings() async {
    final res =
        await _dio.get<Object?>(_path(AdminApiEndpoints.platformSettings));
    return PlatformSettingsSnapshot.fromJson(_map(res.data));
  }

  Future<PlatformSettingsSnapshot> updatePlatformSettings({
    required double platformFeeRate,
    required String defaultCurrency,
    required int minimumWithdrawalCents,
    required int pendingHoldDays,
    required int viewSettlementHoldHours,
    String? platformName,
    String? platformFeeDescription,
  }) async {
    final res = await _dio.put<Object?>(
      _path(AdminApiEndpoints.platformSettings),
      data: <String, dynamic>{
        'platformFeeRate': platformFeeRate,
        'defaultCurrency': defaultCurrency,
        'minimumWithdrawalCents': minimumWithdrawalCents,
        'pendingHoldDays': pendingHoldDays,
        'viewSettlementHoldHours': viewSettlementHoldHours,
        if (platformName != null) 'platformName': platformName,
        if (platformFeeDescription != null)
          'platformFeeDescription': platformFeeDescription,
      },
    );
    final data = _map(res.data);
    if (data['error'] != null) {
      throw StateError('${data['error']}');
    }
    if (data['settings'] is Map) {
      return PlatformSettingsSnapshot.fromJson(data);
    }
    return fetchPlatformSettings();
  }

  Future<StripeSettingsStatus> fetchStripeSettings() async {
    final res = await _dio.get<Object?>(_path(AdminApiEndpoints.stripeSettings));
    return StripeSettingsStatus.fromJson(_map(res.data));
  }

  Future<void> sendBroadcast({
    required String title,
    required String message,
    String scope = 'GLOBAL',
    String? toRole,
  }) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.notificationsBroadcast),
      data: <String, dynamic>{
        'scope': scope,
        if (toRole != null) 'toRole': toRole,
        'title': title,
        'message': message,
        'type': 'SYSTEM_ANNOUNCEMENT',
        'priority': 'P2_NORMAL',
      },
    );
    final data = _map(res.data);
    if (data['success'] != true && data['error'] != null) {
      throw StateError('${data['error']}');
    }
  }

  Future<List<AdminEmailTemplate>> fetchEmailTemplates() async {
    final res = await _dio.get<Object?>(_path(AdminApiEndpoints.emailTemplates));
    final data = _map(res.data);
    final raw = data['templates'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AdminEmailTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AdminEmailTemplatePreview> fetchEmailTemplatePreview(
    String name, {
    String locale = 'en',
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.emailTemplatePreview(name)),
      queryParameters: <String, dynamic>{'locale': locale},
    );
    return AdminEmailTemplatePreview.fromJson(_map(res.data));
  }

  Future<AdminUserDetail> fetchUserDetail(
    String userId, {
    int campaignsPage = 1,
    int applicationsPage = 1,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.userById(userId)),
      queryParameters: <String, dynamic>{
        'campaignsPage': campaignsPage,
        'applicationsPage': applicationsPage,
      },
    );
    return AdminUserDetail.fromJson(_map(res.data));
  }

  // ─── Sensitive ops (previously web-only) ──────────────────────────────────

  /// Permanently deletes [userId] and all associated data. Irreversible —
  /// callers must double-confirm in the UI before invoking this.
  Future<void> hardDeleteUser(String userId) async {
    final res = await _dio.delete<Object?>(_path(AdminApiEndpoints.userById(userId)));
    final data = _map(res.data);
    if (data['ok'] != true) {
      throw StateError('${data['error'] ?? 'Failed to hard-delete user'}');
    }
  }

  /// Upserts credentials for one Stripe [mode] (TEST/LIVE). Omitted secret
  /// fields keep their existing encrypted values on the server.
  Future<StripeSettingsStatus> updateStripeSettings({
    required String mode,
    String? publishableKey,
    String? secretKey,
    String? webhookSecret,
  }) async {
    final res = await _dio.put<Object?>(
      _path(AdminApiEndpoints.stripeSettings),
      data: <String, dynamic>{
        'mode': mode,
        if (publishableKey != null && publishableKey.isNotEmpty)
          'publishableKey': publishableKey,
        if (secretKey != null && secretKey.isNotEmpty) 'secretKey': secretKey,
        if (webhookSecret != null && webhookSecret.isNotEmpty)
          'webhookSecret': webhookSecret,
      },
    );
    final data = _map(res.data);
    if (data['success'] != true) {
      throw StateError('${data['error'] ?? 'Failed to update Stripe settings'}');
    }
    return _parseStripeBundleResponse(data);
  }

  /// Password-gated reveal of one encrypted Stripe credential. Returns the
  /// plaintext value once — never logged, never cached.
  Future<String> revealStripeSecret({
    required String mode,
    required String field,
    required String password,
  }) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.stripeSettingsReveal),
      data: <String, dynamic>{
        'mode': mode,
        'field': field,
        'password': password,
      },
    );
    final data = _map(res.data);
    final value = data['value'];
    if (value is! String) {
      throw StateError('${data['error'] ?? 'Failed to reveal Stripe credential'}');
    }
    return value;
  }

  /// Switches platform payments to TEST or LIVE credentials.
  Future<StripeSettingsStatus> setStripeActiveMode(String mode) async {
    final res = await _dio.patch<Object?>(
      _path(AdminApiEndpoints.stripeSettingsActiveMode),
      data: <String, dynamic>{'activeMode': mode},
    );
    final data = _map(res.data);
    if (data['success'] != true) {
      throw StateError('${data['error'] ?? 'Failed to update active Stripe mode'}');
    }
    return StripeSettingsStatus.fromJson(data);
  }

  /// Validates Stripe credentials for [mode] (defaults to the active mode).
  Future<StripeTestConnectionResult> testStripeConnection({String? mode}) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.stripeSettingsTestConnection),
      data: <String, dynamic>{if (mode != null) 'mode': mode},
    );
    return StripeTestConnectionResult.fromJson(_map(res.data));
  }

  StripeSettingsStatus _parseStripeBundleResponse(Map<String, dynamic> data) {
    final bundle = data['bundle'];
    return StripeSettingsStatus.fromJson(<String, dynamic>{
      'activeMode': data['activeMode'],
      'settings': bundle is Map ? bundle : <String, dynamic>{},
    });
  }

  /// Masked email/SMTP settings — `null` when never configured.
  Future<EmailSettingsSnapshot?> fetchEmailSettings() async {
    final res = await _dio.get<Object?>(_path(AdminApiEndpoints.emailSettings));
    final data = _map(res.data);
    final settings = data['settings'];
    if (settings is! Map) return null;
    return EmailSettingsSnapshot.fromJson(Map<String, dynamic>.from(settings));
  }

  /// Updates SMTP settings. The server always re-encrypts and replaces the
  /// settings row, so [password] is required on every save — omitting it
  /// would silently wipe the stored credential (web parity behavior).
  Future<EmailSettingsSnapshot> updateEmailSettings({
    required String host,
    required int port,
    required bool secure,
    required String fromEmail,
    required bool isEnabled,
    required String password,
    String? username,
    String? fromName,
    String? replyToEmail,
  }) async {
    final res = await _dio.put<Object?>(
      _path(AdminApiEndpoints.emailSettings),
      data: <String, dynamic>{
        'host': host,
        'port': port,
        'secure': secure,
        'fromEmail': fromEmail,
        'isEnabled': isEnabled,
        'password': password,
        if (username != null && username.isNotEmpty) 'username': username,
        if (fromName != null && fromName.isNotEmpty) 'fromName': fromName,
        if (replyToEmail != null && replyToEmail.isNotEmpty)
          'replyToEmail': replyToEmail,
      },
    );
    final data = _map(res.data);
    if (data['success'] != true || data['settings'] is! Map) {
      throw StateError('${data['error'] ?? 'Failed to update email settings'}');
    }
    return EmailSettingsSnapshot.fromJson(
      Map<String, dynamic>.from(data['settings'] as Map),
    );
  }

  /// Sends a raw SMTP test email using the currently saved credentials.
  Future<AdminActionResult> testSmtpEmail({required String email}) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.emailSettingsTest),
      data: <String, dynamic>{'email': email},
    );
    return AdminActionResult.fromJson(_map(res.data));
  }

  /// Sends a rendered template (transactional or notification) to [to] for
  /// QA — mirrors the web "Send test" action on a template preview.
  Future<AdminActionResult> sendTestEmailTemplate({
    required String to,
    required String templateName,
  }) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.emailsSendTest),
      data: <String, dynamic>{'to': to, 'templateName': templateName},
    );
    return AdminActionResult.fromJson(_map(res.data));
  }

  /// Downloads a ZIP of admin invoice PDFs for [ids] (server caps at 100).
  Future<Uint8List> downloadAdminInvoicesZip(
    List<String> ids, {
    String locale = 'en',
  }) async {
    final res = await _dio.post<List<int>>(
      _path(AdminApiEndpoints.invoicesZip),
      data: <String, dynamic>{'ids': ids, 'locale': locale},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  /// Downloads a ZIP of creator payout statement PDFs for [ids] (server caps
  /// at 150).
  Future<Uint8List> downloadAdminPaymentStatementsZip(
    List<String> ids, {
    String locale = 'en',
  }) async {
    final res = await _dio.post<List<int>>(
      _path(AdminApiEndpoints.paymentStatementsZip),
      data: <String, dynamic>{'ids': ids, 'locale': locale},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Map<String, dynamic> _map(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

/// Compound key for [paymentAuditsProvider] — search + pagination + optional
/// by-advertiser drill-down filter.
typedef PaymentAuditsQuery = ({String search, int page, String? advertiserId});

final paymentAuditsProvider = FutureProvider.autoDispose
    .family<PaymentAuditsPage, PaymentAuditsQuery>((ref, query) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(
    ref,
    () => remote.fetchPaymentAudits(
      search: query.search.isEmpty ? null : query.search,
      page: query.page,
      advertiserId: query.advertiserId,
    ),
  );
});

/// Compound key for [advertiserDepositsProvider] — search + pagination.
typedef AdvertiserDepositsQuery = ({String search, int page});

final advertiserDepositsProvider = FutureProvider.autoDispose
    .family<AdvertiserDepositsPage, AdvertiserDepositsQuery>((ref, query) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(
    ref,
    () => remote.fetchAdvertiserDeposits(
      search: query.search.isEmpty ? null : query.search,
      page: query.page,
    ),
  );
});

/// [POST /api/admin/payment-audits/{id}/reconcile] one-off action (not
/// cached — invalidate [paymentAuditsProvider] after a successful call).
Future<PaymentAuditReconcileResult> reconcilePaymentAudit(
  Ref ref,
  String auditId,
) {
  final remote = ref.read(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, () => remote.reconcilePaymentAudit(auditId));
}

final auditLogProvider =
    FutureProvider.autoDispose.family<AuditLogPage, String>((ref, search) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(
    ref,
    () => remote.fetchAuditLog(search: search.isEmpty ? null : search),
  );
});

final platformHealthProvider =
    FutureProvider.autoDispose<PlatformHealthSnapshot>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchHealth);
});

final adminServicesHealthProvider =
    FutureProvider.autoDispose<List<AdminServiceStatus>>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchServicesHealth);
});

final tokenPurchasesProvider =
    FutureProvider.autoDispose.family<TokenPurchasesPage, String>((ref, search) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(
    ref,
    () => remote.fetchTokenPurchases(search: search.isEmpty ? null : search),
  );
});

final clickPipelineProvider =
    FutureProvider.autoDispose<ClickPipelineSnapshot>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchClickPipeline);
});

final creatorVelocityProvider =
    FutureProvider.autoDispose.family<CreatorVelocitySnapshot, String>((ref, period) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(
    ref,
    () => remote.fetchCreatorVelocity(period: period),
  );
});

final emailLogsProvider =
    FutureProvider.autoDispose<EmailLogsPage>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchEmailLogs);
});

final recentActivityProvider =
    FutureProvider.autoDispose.family<RecentActivityPage, String>((ref, search) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(
    ref,
    () => remote.fetchRecentActivity(search: search.isEmpty ? null : search),
  );
});

final adminInvoicesProvider =
    FutureProvider.autoDispose.family<AdminInvoicesPage, String>((ref, search) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(
    ref,
    () => remote.fetchAdminInvoices(search: search.isEmpty ? null : search),
  );
});

final adminPaymentStatementsProvider =
    FutureProvider.autoDispose.family<AdminPaymentStatementsPage, String>((ref, search) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(
    ref,
    () => remote.fetchPaymentStatements(search: search.isEmpty ? null : search),
  );
});

final youtubeMonitoringProvider =
    FutureProvider.autoDispose<YoutubeMonitoringStats>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchYoutubeMonitoring);
});

final adminTokenPackagesProvider =
    FutureProvider.autoDispose<List<AdminTokenPackage>>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchTokenPackages);
});

final platformSettingsProvider =
    FutureProvider.autoDispose<PlatformSettingsSnapshot>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchPlatformSettings);
});

final stripeSettingsStatusProvider =
    FutureProvider.autoDispose<StripeSettingsStatus>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchStripeSettings);
});

final emailTemplatesProvider =
    FutureProvider.autoDispose<List<AdminEmailTemplate>>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchEmailTemplates);
});

final emailTemplatePreviewProvider = FutureProvider.autoDispose
    .family<AdminEmailTemplatePreview, String>((ref, name) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(
    ref,
    () => remote.fetchEmailTemplatePreview(name),
  );
});

final adminUserDetailProvider =
    FutureProvider.autoDispose.family<AdminUserDetail, String>((ref, userId) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, () => remote.fetchUserDetail(userId));
});

final emailSettingsProvider =
    FutureProvider.autoDispose<EmailSettingsSnapshot?>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(superadminOpsRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchEmailSettings);
});
