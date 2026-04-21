import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dashboard/domain/entities/campaign_platform.dart';
import '../../dashboard/domain/entities/campaign_status.dart';
import '../domain/advertiser_campaign.dart';

/// Wayo-ads `GET /api/campaigns` (Bearer via [Dio] interceptors).
abstract interface class AdvertiserCampaignsRemote {
  Future<List<AdvertiserCampaign>> fetchAdvertiserCampaigns({int limit = 100});

  Future<Map<String, dynamic>> fetchCampaignDetailJson(String id);
}

final class AdvertiserCampaignsRemoteDatasource implements AdvertiserCampaignsRemote {
  AdvertiserCampaignsRemoteDatasource(this._dio);

  final Dio _dio;

  @override
  Future<List<AdvertiserCampaign>> fetchAdvertiserCampaigns({int limit = 100}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.campaigns),
      queryParameters: <String, dynamic>{
        'advertiserOnly': 'true',
        'page': 1,
        'limit': limit.clamp(1, 100),
      },
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
      list = data['data'] is List<dynamic> ? data['data'] as List<dynamic> : const [];
    }
    return list.map((e) => _parseListItem(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Map<String, dynamic>> fetchCampaignDetailJson(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.campaignDetail(id)),
    );
    final data = res.data;
    if (data == null) {
      throw const ServerException('Empty response');
    }
    if (data['error'] is String) {
      throw ServerException(data['error'] as String);
    }
    return data;
  }

  static AdvertiserCampaign _parseListItem(Map<String, dynamic> m) {
    final id = '${m['id'] ?? ''}';
    final title = m['title'] as String? ?? m['name'] as String? ?? '';
    final platformStr = _primaryPlatformKey(m);
    final total = _parseCents(m['totalBudgetCents'] ?? m['totalBudget']);
    final spent = _parseCents(m['spentBudget'] ?? m['spentBudgetCents']);
    final remaining = _parseCents(m['remainingBudget'] ?? m['remainingBudgetCents']);
    final locked = _parseCents(m['lockedBudget'] ?? m['lockedBudgetCents']);
    final cpc = _parseCents(m['cpcCents']);
    final views = (m['validViews'] as num?)?.toInt() ?? 0;
    final creators = (m['approvedCreators'] as num?)?.toInt() ??
        (m['approved_creators'] as num?)?.toInt() ??
        0;
    return AdvertiserCampaign(
      id: id,
      name: title,
      status: CampaignStatus.fromString(m['status'] as String?),
      platform: CampaignPlatform.fromString(platformStr),
      totalBudgetCents: total,
      remainingBudgetCents: remaining,
      spentBudgetCents: spent,
      lockedBudgetCents: locked,
      cpcCents: cpc,
      validViews: views,
      approvedCreators: creators,
      coverUrl: m['cover_url'] as String? ?? m['coverUrl'] as String?,
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
