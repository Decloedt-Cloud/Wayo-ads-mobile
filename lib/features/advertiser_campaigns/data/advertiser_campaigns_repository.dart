import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/wayo_ads_dio.dart';
import 'advertiser_campaigns_remote_datasource.dart';
import '../domain/advertiser_campaign.dart';
import '../domain/advertiser_campaigns_page_result.dart';
import '../domain/campaign_application.dart';

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
  }) =>
      _remote.fetchAdvertiserCampaignsPage(
        page: page,
        limit: limit,
        status: status,
        search: search,
      );

  /// Tab totals (4 light requests with `limit=1`).
  Future<({int active, int draft, int paused, int completed})>
  loadCampaignStatusCounts() async {
    final r = await Future.wait([
      _remote.fetchAdvertiserCampaignsPage(
        page: 1,
        limit: 1,
        status: 'ACTIVE',
      ),
      _remote.fetchAdvertiserCampaignsPage(
        page: 1,
        limit: 1,
        status: 'DRAFT',
      ),
      _remote.fetchAdvertiserCampaignsPage(
        page: 1,
        limit: 1,
        status: 'PAUSED',
      ),
      _remote.fetchAdvertiserCampaignsPage(
        page: 1,
        limit: 1,
        status: 'COMPLETED',
      ),
    ]);
    return (
      active: r[0].total,
      draft: r[1].total,
      paused: r[2].total,
      completed: r[3].total,
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
      if (code == 401 || code == 403) {
        return ServerException(e.message ?? 'Unauthorized');
      }
      return ServerException(e.message ?? 'Request failed');
    }
    return ServerException('$e');
  }
}
