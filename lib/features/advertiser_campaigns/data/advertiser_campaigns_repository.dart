import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/wayo_ads_dio.dart';
import 'advertiser_campaigns_remote_datasource.dart';
import '../domain/advertiser_campaign.dart';
import '../domain/advertiser_campaign_status_counts.dart';
import '../domain/advertiser_campaigns_page_result.dart';
import '../domain/campaign_application.dart';
import '../domain/campaign_mutation_result.dart';
import '../../creator_campaigns/domain/creator_browse_page_result.dart';

final advertiserCampaignsRemoteProvider = Provider<AdvertiserCampaignsRemote>((
  ref,
) {
  return AdvertiserCampaignsRemoteDatasource(ref.watch(wayoAdsDioProvider));
});

final advertiserCampaignsRepositoryProvider =
    Provider<AdvertiserCampaignsRepository>((ref) {
      return AdvertiserCampaignsRepository(
        ref.watch(advertiserCampaignsRemoteProvider),
      );
    });

final class AdvertiserCampaignsRepository {
  AdvertiserCampaignsRepository(this._remote);

  final AdvertiserCampaignsRemote _remote;

  Future<List<AdvertiserCampaign>> loadCampaigns() =>
      _remote.fetchAdvertiserCampaigns();

  Future<AdvertiserCampaignsPageResult> loadCampaignsPage({
    required String status,
    required int page,
    int limit = 10,
    String? search,
    String? type,
    String? niche,
    String? countryCode,
  }) => _remote.fetchAdvertiserCampaignsPage(
    page: page,
    limit: limit,
    status: status,
    search: search,
    type: type,
    niche: niche,
    countryCode: countryCode,
  );

  /// Tab totals from `statusCounts` on a single advertiser-only list call.
  Future<AdvertiserCampaignStatusCounts> loadCampaignStatusCounts() async {
    final page = await _remote.fetchAdvertiserCampaignsPage(
      page: 1,
      limit: 1,
      status: 'ACTIVE',
    );
    if (page.statusCounts != null) {
      return page.statusCounts!;
    }
    // Fallback when API omits rollup (older backend).
    final r = await Future.wait([
      _remote.fetchAdvertiserCampaignsPage(page: 1, limit: 1, status: 'ACTIVE'),
      _remote.fetchAdvertiserCampaignsPage(page: 1, limit: 1, status: 'DRAFT'),
      _remote.fetchAdvertiserCampaignsPage(page: 1, limit: 1, status: 'PAUSED'),
      _remote.fetchAdvertiserCampaignsPage(
        page: 1,
        limit: 1,
        status: 'UNDER_REVIEW',
      ),
      _remote.fetchAdvertiserCampaignsPage(
        page: 1,
        limit: 1,
        status: 'COMPLETED',
      ),
      _remote.fetchAdvertiserCampaignsPage(
        page: 1,
        limit: 1,
        status: 'CANCELLED',
      ),
    ]);
    return AdvertiserCampaignStatusCounts(
      active: r[0].total,
      draft: r[1].total,
      paused: r[2].total,
      underReview: r[3].total,
      completed: r[4].total,
      cancelled: r[5].total,
    );
  }

  Future<Map<String, dynamic>> loadCampaignDetail(String id) =>
      _remote.fetchCampaignDetailJson(id);

  Future<List<CampaignApplication>> loadCampaignApplications(
    String campaignId,
  ) => _remote.fetchCampaignApplications(campaignId);

  Future<void> approveApplication(String campaignId, String applicationId) =>
      _remote.approveApplication(campaignId, applicationId);

  Future<void> rejectApplication(String campaignId, String applicationId) =>
      _remote.rejectApplication(campaignId, applicationId);

  Future<CreatorBrowsePageResult> loadMarketplaceBrowsePage({
    required int page,
    int limit = 10,
    String? search,
    String? type,
    String? niche,
    String? countryCode,
  }) => _remote.fetchMarketplaceBrowsePage(
    page: page,
    limit: limit,
    search: search,
    type: type,
    niche: niche,
    countryCode: countryCode,
  );

  /// Returns created campaign id + status.
  Future<CampaignMutationResult> createCampaign(
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    final map = await _remote.createCampaign(
      body,
      idempotencyKey: idempotencyKey,
    );
    return _mutationFromMap(map);
  }

  Future<CampaignMutationResult> updateCampaign(
    String id,
    Map<String, dynamic> body,
  ) async {
    final map = await _remote.updateCampaign(id, body);
    try {
      return _mutationFromMap(map, fallbackId: id);
    } catch (_) {
      return CampaignMutationResult(
        id: id,
        status: '${body['status'] ?? 'DRAFT'}',
      );
    }
  }

  CampaignMutationResult _mutationFromMap(
    Map<String, dynamic> map, {
    String? fallbackId,
  }) {
    final campaign = map['campaign'];
    if (campaign is Map) {
      final id = campaign['id']?.toString();
      final status = campaign['status']?.toString() ?? 'DRAFT';
      if (id != null && id.isNotEmpty) {
        return CampaignMutationResult(id: id, status: status);
      }
    }
    final id = map['id']?.toString() ?? fallbackId;
    if (id != null && id.isNotEmpty) {
      return CampaignMutationResult(
        id: id,
        status: '${map['status'] ?? 'DRAFT'}',
      );
    }
    throw const ServerException('Campaign id missing in response');
  }

  Future<String> uploadCampaignLogoDataUrl(String dataUrl) =>
      _remote.uploadCampaignLogoDataUrl(dataUrl);

  Future<void> setCampaignStatus(String id, String status) async {
    await _remote.setCampaignStatus(id, status);
  }

  Future<Map<String, dynamic>> loadCampaignAnalytics(String id) =>
      _remote.fetchCampaignAnalytics(id);

  Future<Map<String, dynamic>> loadCampaignFinancialSummary(String id) =>
      _remote.fetchCampaignFinancialSummary(id);

  static AuthException mapError(Object e) {
    if (e is AuthException) {
      return e;
    }
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const NetworkException();
      }
      final code = e.response?.statusCode;
      final data = e.response?.data;
      if (data is Map && data['errorCode']?.toString() == 'INSUFFICIENT_FUNDS') {
        final campaign = data['campaign'];
        String? draftId;
        if (campaign is Map) draftId = campaign['id']?.toString();
        final details = data['details'];
        final d = details is Map ? Map<String, dynamic>.from(details) : null;
        int asInt(Object? v) {
          if (v is int) return v;
          if (v is num) return v.toInt();
          return int.tryParse('$v') ?? 0;
        }
        return CampaignInsufficientFundsException(
          draftCampaignId: draftId,
          requiredCents: d == null ? null : asInt(d['required']),
          availableCents: d == null ? null : asInt(d['available']),
          platformFeeCents: d == null ? null : asInt(d['platformFee']),
          taxCents: d == null ? null : asInt(d['tax']),
          message: data['error']?.toString() ?? 'Insufficient funds',
        );
      }
      String message = e.message ?? 'Request failed';
      if (data is Map) {
        final err = data['error'] ?? data['message'];
        if (err != null && '$err'.isNotEmpty) message = '$err';
      }
      if (code == 401) {
        return const SessionInvalidException();
      }
      if (code == 429) {
        final retry = data is Map
            ? int.tryParse('${data['retry_after'] ?? data['retryAfter'] ?? ''}')
            : null;
        return RateLimitedException(retryAfterSeconds: retry ?? 60);
      }
      return ServerException(message, code);
    }
    return ServerException('$e');
  }
}
