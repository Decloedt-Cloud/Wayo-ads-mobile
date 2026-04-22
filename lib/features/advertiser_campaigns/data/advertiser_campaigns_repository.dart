import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/wayo_ads_dio.dart';
import 'advertiser_campaigns_remote_datasource.dart';
import '../domain/advertiser_campaign.dart';

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

  Future<Map<String, dynamic>> loadCampaignDetail(String id) =>
      _remote.fetchCampaignDetailJson(id);

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
