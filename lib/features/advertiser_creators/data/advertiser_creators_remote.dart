import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../domain/advertiser_creator.dart';

final advertiserCreatorsRemoteProvider = Provider<AdvertiserCreatorsRemote>((
  ref,
) {
  return AdvertiserCreatorsRemote(ref.watch(wayoAdsDioProvider));
});

class AdvertiserCreatorsRemote {
  AdvertiserCreatorsRemote(this._dio);

  final Dio _dio;

  Future<AdvertiserCreatorsPage> fetch({int page = 1, String? q}) async {
    try {
      final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.advertiserCreators,
      );
      final qp = <String, dynamic>{'page': page};
      final trimmed = q?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        qp['q'] = trimmed;
      }
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: qp,
      );
      final data = res.data;
      if (data == null) throw const ServerException('Empty response');
      if (data['error'] is String) {
        throw ServerException(data['error'] as String);
      }
      return AdvertiserCreatorsPage.fromJson(data);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['error'] is String) {
        throw ServerException(body['error'] as String, e.response?.statusCode);
      }
      throw ServerException(
        e.message ?? 'Request failed',
        e.response?.statusCode,
      );
    }
  }
}

typedef AdvertiserCreatorsKey = ({int page, String q});

final advertiserCreatorsProvider = FutureProvider.autoDispose
    .family<AdvertiserCreatorsPage, AdvertiserCreatorsKey>((ref, key) async {
      return ref
          .watch(advertiserCreatorsRemoteProvider)
          .fetch(page: key.page, q: key.q);
    });
