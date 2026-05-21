import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/creator_application.dart';
import '../domain/creator_stats.dart';

/// Thin HTTP wrapper over `/api/creator/*` on Wayo-ads (Next.js).
///
/// All endpoints accept `Authorization: Bearer <jwt>` via [getCurrentUser]
/// (see `Wayo-ads/src/lib/server-auth.ts`).
class CreatorDashboardRemoteDatasource {
  CreatorDashboardRemoteDatasource(this._dio);

  final Dio _dio;

  /// `GET /api/creator/stats` — KPIs for the active creator.
  Future<CreatorStats> fetchStats() async {
    final res = await _dio.get<Object?>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.creatorStats),
    );
    final body = res.data;
    if (body is! Map) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Invalid /creator/stats payload',
        type: DioExceptionType.badResponse,
      );
    }
    return CreatorStats.fromJson(Map<String, dynamic>.from(body));
  }

  /// `GET /api/creator/applications` — list of all the creator's applications.
  Future<List<CreatorApplication>> fetchApplications() async {
    final res = await _dio.get<Object?>(
      AuthRuntimeConfig.instance
          .wayoAdsRequestPath(ApiEndpoints.creatorApplications),
    );
    final body = res.data;
    final raw = body is Map ? body['applications'] : null;
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => CreatorApplication.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}
