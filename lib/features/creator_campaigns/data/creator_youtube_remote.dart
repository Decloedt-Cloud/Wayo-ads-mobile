import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/creator_youtube_status.dart';

final class CreatorYoutubeRemote {
  CreatorYoutubeRemote(this._dio);

  final Dio _dio;

  Future<CreatorYoutubeChannelStatus> fetchChannelStatus() async {
    final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
      ApiEndpoints.creatorYoutubeChannel,
    );
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      options: Options(headers: {'Cache-Control': 'no-store'}),
    );
    final data = res.data;
    if (data == null) {
      return CreatorYoutubeChannelStatus.disconnected;
    }
    return CreatorYoutubeChannelStatus.fromJson(data);
  }
}
