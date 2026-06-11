import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/advertiser_submitted_video.dart';

abstract interface class AdvertiserVideoReviewsRemote {
  Future<AdvertiserVideosPageResult> fetchVideos({
    AdvertiserVideoReviewFilter? status,
    int page = 1,
    int pageSize = 10,
    String? campaignId,
  });

  Future<void> approveVideo(String videoId);

  Future<void> rejectVideo(String videoId, {required String reason});
}

final class AdvertiserVideoReviewsRemoteDatasource
    implements AdvertiserVideoReviewsRemote {
  AdvertiserVideoReviewsRemoteDatasource(this._dio);

  final Dio _dio;

  String _path(String endpoint) =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(endpoint);

  @override
  Future<AdvertiserVideosPageResult> fetchVideos({
    AdvertiserVideoReviewFilter? status,
    int page = 1,
    int pageSize = 10,
    String? campaignId,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize.clamp(1, 100),
    };
    if (status != null) {
      qp['status'] = status.apiValue;
    }
    if (campaignId != null && campaignId.isNotEmpty) {
      qp['campaignId'] = campaignId;
    }

    final res = await _dio.get<Map<String, dynamic>>(
      _path(ApiEndpoints.advertiserVideos),
      queryParameters: qp,
    );
    final data = res.data;
    if (data == null) {
      throw const ServerException('Empty response');
    }
    return AdvertiserVideosPageResult.fromJson(data);
  }

  @override
  Future<void> approveVideo(String videoId) async {
    await _dio.patch<Map<String, dynamic>>(
      _path(ApiEndpoints.advertiserVideoReview(videoId)),
      data: {'videoId': videoId, 'action': 'approve'},
    );
  }

  @override
  Future<void> rejectVideo(String videoId, {required String reason}) async {
    await _dio.patch<Map<String, dynamic>>(
      _path(ApiEndpoints.advertiserVideoReview(videoId)),
      data: {
        'videoId': videoId,
        'action': 'reject',
        'rejectionReason': reason,
      },
    );
  }
}
