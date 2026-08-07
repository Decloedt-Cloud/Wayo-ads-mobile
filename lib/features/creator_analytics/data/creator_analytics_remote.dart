import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../domain/creator_analytics_snapshot.dart';

final creatorAnalyticsRemoteProvider = Provider<CreatorAnalyticsRemote>((ref) {
  return CreatorAnalyticsRemote(ref.watch(wayoAdsDioProvider));
});

class CreatorAnalyticsRemote {
  CreatorAnalyticsRemote(this._dio);

  final Dio _dio;

  Future<CreatorAnalyticsSnapshot> fetch({
    String period = '30d',
    String? campaignId,
  }) async {
    try {
      final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.creatorAnalytics,
      );
      final qp = <String, dynamic>{'period': period};
      if (campaignId != null && campaignId.isNotEmpty) {
        qp['campaignId'] = campaignId;
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
      return CreatorAnalyticsSnapshot.fromJson(data);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['error'] is String) {
        throw ServerException(body['error'] as String, e.response?.statusCode);
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(
        e.message ?? 'Request failed',
        e.response?.statusCode,
      );
    }
  }
}

final creatorAnalyticsProvider = FutureProvider.autoDispose
    .family<CreatorAnalyticsSnapshot, String>((ref, period) async {
      return ref.watch(creatorAnalyticsRemoteProvider).fetch(period: period);
    });
