import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../domain/advertiser_submitted_video.dart';
import 'advertiser_video_reviews_remote_datasource.dart';

final advertiserVideoReviewsRemoteProvider =
    Provider<AdvertiserVideoReviewsRemote>((ref) {
      return AdvertiserVideoReviewsRemoteDatasource(
        ref.watch(wayoAdsDioProvider),
      );
    });

final advertiserVideoReviewsRepositoryProvider =
    Provider<AdvertiserVideoReviewsRepository>((ref) {
      return AdvertiserVideoReviewsRepository(
        ref.watch(advertiserVideoReviewsRemoteProvider),
      );
    });

final class AdvertiserVideoReviewsRepository {
  AdvertiserVideoReviewsRepository(this._remote);

  final AdvertiserVideoReviewsRemote _remote;

  Future<AdvertiserVideosPageResult> loadVideos({
    AdvertiserVideoReviewFilter? status,
    int page = 1,
    int pageSize = 10,
    String? campaignId,
  }) => _remote.fetchVideos(
    status: status,
    page: page,
    pageSize: pageSize,
    campaignId: campaignId,
  );

  /// Lightweight call used for dashboard KPI counts.
  Future<AdvertiserVideoStatusCounts> loadStatusCounts() async {
    final page = await _remote.fetchVideos(page: 1, pageSize: 1);
    return page.countsByStatus;
  }

  Future<void> approveVideo(String videoId) => _remote.approveVideo(videoId);

  Future<void> rejectVideo(String videoId, {required String reason}) =>
      _remote.rejectVideo(videoId, reason: reason);

  static AuthException mapError(Object e) {
    if (e is AuthException) return e;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const NetworkException();
      }
      final data = e.response?.data;
      if (data is Map && data['error'] is String) {
        return ServerException(data['error'] as String);
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
