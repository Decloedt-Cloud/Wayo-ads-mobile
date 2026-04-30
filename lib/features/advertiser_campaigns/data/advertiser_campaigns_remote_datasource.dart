import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/wayo_ads_public_url.dart';
import '../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../dashboard/domain/entities/campaign_platform.dart';
import '../../dashboard/domain/entities/campaign_status.dart';
import '../domain/advertiser_campaign.dart';
import '../domain/advertiser_campaigns_page_result.dart';
import '../domain/campaign_application.dart';

/// Wayo-ads `GET /api/campaigns` (Bearer via [Dio] interceptors).
abstract interface class AdvertiserCampaignsRemote {
  Future<List<AdvertiserCampaign>> fetchAdvertiserCampaigns({int limit = 100});

  /// Paginated listing with optional [status] (`ACTIVE`, `DRAFT`, …) and [search].
  Future<AdvertiserCampaignsPageResult> fetchAdvertiserCampaignsPage({
    required int page,
    int limit = 10,
    String? status,
    String? search,
  });

  Future<Map<String, dynamic>> fetchCampaignDetailJson(String id);

  Future<List<CampaignApplication>> fetchCampaignApplications(
    String campaignId,
  );

  Future<void> approveApplication(String campaignId, String applicationId);

  Future<void> rejectApplication(String campaignId, String applicationId);
}

final class AdvertiserCampaignsRemoteDatasource
    implements AdvertiserCampaignsRemote {
  AdvertiserCampaignsRemoteDatasource(this._dio);

  final Dio _dio;

  @override
  Future<List<AdvertiserCampaign>> fetchAdvertiserCampaigns({
    int limit = 100,
  }) async {
    final page = await fetchAdvertiserCampaignsPage(
      page: 1,
      limit: limit.clamp(1, 100),
    );
    return page.campaigns;
  }

  @override
  Future<AdvertiserCampaignsPageResult> fetchAdvertiserCampaignsPage({
    required int page,
    int limit = 10,
    String? status,
    String? search,
  }) async {
    final qp = <String, dynamic>{
      'advertiserOnly': 'true',
      'page': page,
      'limit': limit.clamp(1, 100),
    };
    if (status != null && status.isNotEmpty) {
      qp['status'] = status;
    }
    final trimmed = search?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      qp['search'] = trimmed;
    }
    final res = await _dio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.campaigns),
      queryParameters: qp,
    );
    final data = res.data;
    if (data == null) {
      throw const ServerException('Empty response');
    }
    if (data['error'] is String) {
      throw ServerException(data['error'] as String);
    }
    dynamic list = data['campaigns'];
    if (list is! List<dynamic>) {
      list = data['data'] is List<dynamic>
          ? data['data'] as List<dynamic>
          : const [];
    }
    final campaigns = list
        .map((e) => _parseListItem(e as Map<String, dynamic>))
        .toList();
    final total = _parseInt(data['total'], campaigns.length);
    final pageNum = _parseInt(data['page'], page);
    var totalPages = _parseInt(data['totalPages'], 0);
    final lim = limit.clamp(1, 100);
    if (totalPages < 1) {
      totalPages = total > 0 ? (total + lim - 1) ~/ lim : 1;
    }
    return AdvertiserCampaignsPageResult(
      campaigns: campaigns,
      total: total,
      page: pageNum,
      totalPages: totalPages,
    );
  }

  static int _parseInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  @override
  Future<Map<String, dynamic>> fetchCampaignDetailJson(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.campaignDetail(id),
      ),
    );
    final data = res.data;
    if (data == null) {
      throw const ServerException('Empty response');
    }
    if (data['error'] is String) {
      throw ServerException(data['error'] as String);
    }
    // Wayo-ads `GET /api/campaigns/:id` returns `{ campaign: { ... } }` (not a bare object).
    final raw = data['campaign'] ?? data['data'] ?? data;
    if (raw is! Map<String, dynamic>) {
      throw const ServerException('Invalid campaign payload');
    }
    return Map<String, dynamic>.from(raw);
  }

  @override
  Future<List<CampaignApplication>> fetchCampaignApplications(
    String campaignId,
  ) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(
          ApiEndpoints.campaignApplications(campaignId),
        ),
      );
      final data = res.data;
      if (data == null) {
        return const [];
      }
      if (data['error'] is String) {
        throw ServerException(data['error'] as String);
      }
      dynamic list = data['applications'];
      if (list is! List<dynamic>) {
        list = data['data'] is List<dynamic>
            ? data['data'] as List<dynamic>
            : const [];
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(CampaignApplication.fromJson)
          .toList();
    } on DioException catch (e) {
      // 404 means the endpoint doesn't exist yet — return empty list gracefully.
      if (e.response?.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('[CampaignApplications] 404 — returning empty list');
        }
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<void> approveApplication(
    String campaignId,
    String applicationId,
  ) async {
    await _postApplicationAction(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.campaignApplicationApprove(campaignId, applicationId),
      ),
    );
  }

  @override
  Future<void> rejectApplication(
    String campaignId,
    String applicationId,
  ) async {
    await _postApplicationAction(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.campaignApplicationReject(campaignId, applicationId),
      ),
    );
  }

  /// Next.js returns 200 + JSON, or 4xx with `{ "error": "…" }`. Dio throws on 4xx
  /// before we see [Response.data] unless we read it in [DioException.response].
  Future<void> _postApplicationAction(String path) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: const <String, dynamic>{},
      );
      _throwIfErrorBody(_asStringKeyedMap(res.data));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AdvertiserCampaigns] POST application action '
          '${e.response?.statusCode}: ${e.response?.data}',
        );
      }
      final data = e.response?.data;
      if (e.response?.statusCode == 400 && _isAlreadyProcessedPayload(data)) {
        return;
      }
      final msg = _errorMessageFromDio(e);
      final code = e.response?.statusCode;
      if (code == 400 && msg != null) {
        // Already approved/rejected (e.g. from web) — same outcome for refresh.
        if (_idempotentApproveReject(msg.toLowerCase())) {
          return;
        }
        throw ServerException(msg);
      }
      if (msg != null && msg.isNotEmpty) {
        throw ServerException(msg);
      }
      rethrow;
    }
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic data) {
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

  static String? _errorMessageFromDio(DioException e) {
    return _messageFromErrorPayload(e.response?.data);
  }

  /// Wayo-ads returns 400 with `{ error: "Application already processed", application: {…} }`
  /// when the listing is stale — treat as success.
  static bool _isAlreadyProcessedPayload(dynamic data) {
    final m = _asStringKeyedMap(data);
    if (m == null) {
      return false;
    }
    final errAny = m['error'];
    final s = switch (errAny) {
      final String e => e,
      _ when errAny != null => errAny.toString(),
      _ => '',
    };
    if (s.toLowerCase().contains('already processed')) {
      return true;
    }
    return false;
  }

  /// String, nested map `{ "message": "…" }`, or skips non-text types.
  static String? _scalarOrMessageString(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    if (v is Map) {
      for (final key in const <String>[
        'message',
        'msg',
        'detail',
        'description',
        'error',
      ]) {
        final inner = v[key];
        if (inner is String && inner.trim().isNotEmpty) {
          return inner.trim();
        }
      }
      return null;
    }
    return null;
  }

  /// Wayo-ads sometimes returns `{ "error": "…" }`, sometimes `{ "message": "…" }`
  /// or NestJS-style `{ "message": ["…"] }`; Zod routes may expose `issues`.
  static String? _messageFromErrorPayload(dynamic data) {
    if (data is String) {
      final t = data.trim();
      return t.isNotEmpty ? t : null;
    }
    final m = _asStringKeyedMap(data);
    if (m == null) {
      return null;
    }
    for (final key in <String>[
      'error',
      'message',
      'detail',
      'reason',
      'description',
    ]) {
      final s = _scalarOrMessageString(m[key]);
      if (s != null) {
        return s;
      }
    }
    final msg = m['message'];
    if (msg is List) {
      final parts = msg
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        return parts.join('; ');
      }
    }
    final issues = m['issues'];
    if (issues is List && issues.isNotEmpty) {
      final parts = <String>[];
      for (final i in issues) {
        if (i is Map) {
          final path = i['path'];
          final mes = i['message'];
          if (mes is String && mes.trim().isNotEmpty) {
            parts.add(path is List ? '$path: ${mes.trim()}' : mes.trim());
          }
        }
      }
      if (parts.isNotEmpty) {
        return parts.join('; ');
      }
    }
    return null;
  }

  /// Treat as successful no-op so lists refresh cleanly after redundant taps.
  static bool _idempotentApproveReject(String lower) {
    if (lower.contains('already processed')) {
      return true;
    }
    if (lower.contains('already approved') ||
        lower.contains('already rejected')) {
      return true;
    }
    if (lower.contains('not pending') && lower.contains('application')) {
      return true;
    }
    return false;
  }

  static void _throwIfErrorBody(Map<String, dynamic>? data) {
    if (data == null) {
      return;
    }
    if (data['error'] is String) {
      throw ServerException(data['error'] as String);
    }
    if (data['success'] == false && data['message'] is String) {
      final m = data['message'] as String;
      if (m.isNotEmpty) {
        throw ServerException(m);
      }
    }
  }

  static AdvertiserCampaign _parseListItem(Map<String, dynamic> m) {
    final id = '${m['id'] ?? ''}';
    final title = m['title'] as String? ?? m['name'] as String? ?? '';
    final platformStr = _primaryPlatformKey(m);
    final total = _parseCents(m['totalBudgetCents'] ?? m['totalBudget']);
    final spent = _parseCents(m['spentBudget'] ?? m['spentBudgetCents']);
    final remaining = _parseCents(
      m['remainingBudget'] ?? m['remainingBudgetCents'],
    );
    final locked = _parseCents(m['lockedBudget'] ?? m['lockedBudgetCents']);
    final cpc = _parseCents(m['cpcCents']);
    final views = (m['validViews'] as num?)?.toInt() ?? 0;
    final creators =
        (m['approvedCreators'] as num?)?.toInt() ??
        (m['approved_creators'] as num?)?.toInt() ??
        0;
    return AdvertiserCampaign(
      id: id,
      name: title,
      status: CampaignStatus.fromString(m['status'] as String?),
      platform: CampaignPlatform.fromString(platformStr),
      campaignType: CreatorCampaignType.fromApi(m['type']),
      totalBudgetCents: total,
      remainingBudgetCents: remaining,
      spentBudgetCents: spent,
      lockedBudgetCents: locked,
      cpcCents: cpc,
      validViews: views,
      approvedCreators: creators,
      coverUrl:
          m['cover_url'] as String? ??
          m['coverUrl'] as String? ??
          m['coverImageUrl'] as String?,
      brandLogoUrl: parseCampaignBrandLogoFromJson(m),
      currency: (m['currency'] as String?)?.toUpperCase() ?? 'EUR',
    );
  }

  static int _parseCents(dynamic v) {
    if (v == null) {
      return 0;
    }
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    return int.tryParse('$v') ?? 0;
  }

  static String _primaryPlatformKey(Map<String, dynamic> m) {
    final shorts = m['shortsPlatform'] as String?;
    if (shorts != null && shorts.trim().isNotEmpty) {
      return shorts.trim();
    }
    final platforms = m['platforms'] as String?;
    if (platforms != null && platforms.trim().isNotEmpty) {
      return platforms.split(',').first.trim();
    }
    final type = m['type'] as String?;
    if (type == 'VIDEO' || type == 'SHORTS') {
      return 'youtube';
    }
    return '';
  }
}
