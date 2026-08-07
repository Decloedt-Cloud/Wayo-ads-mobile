import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/config/youtube_oauth_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../domain/youtube_channel.dart';

final youtubeRemoteProvider = Provider<YouTubeRemote>((ref) {
  return YouTubeRemote(ref.watch(wayoAdsDioProvider));
});

class YouTubeRemote {
  YouTubeRemote(this._dio);

  final Dio _dio;

  String _path(String endpoint) =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(endpoint);

  Future<YouTubeChannelResponse> fetchChannelStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _path(ApiEndpoints.creatorYoutubeChannel),
        options: Options(headers: {'Cache-Control': 'no-store'}),
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response');
      }
      return YouTubeChannelResponse.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<YouTubeConnectInit> initiateConnect({bool reconnect = false}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _path(ApiEndpoints.creatorYoutubeConnect),
        queryParameters: {
          'mobile': '1',
          'returnApp': YouTubeOAuthConfig.returnApp,
          if (reconnect) 'reconnect': '1',
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response');
      }
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        throw ServerException(error);
      }
      final init = YouTubeConnectInit.fromJson(data);
      if (init.authUrl.isEmpty) {
        throw const ServerException('Invalid OAuth init response');
      }
      if (!_authUrlUsesHttpsRedirect(init.authUrl)) {
        throw const ServerException(
          'invalid_oauth_config: server must use HTTPS redirect_uri for YouTube OAuth',
        );
      }
      return init;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<YouTubeConnectResult> completeMobileOAuth({
    required String code,
    required String state,
    required String codeVerifier,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _path(ApiEndpoints.creatorYoutubeMobileComplete),
        data: {'code': code, 'state': state, 'codeVerifier': codeVerifier},
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response');
      }
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        throw ServerException(error);
      }
      return YouTubeConnectResult.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> disconnect() async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        _path(ApiEndpoints.creatorYoutubeDisconnect),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> refreshChannel() async {
    try {
      await _dio.post<Map<String, dynamic>>(
        _path(ApiEndpoints.creatorYoutubeRefresh),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  AuthException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return const SessionInvalidException();
    }
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return ServerException(data['error'] as String, status);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    return ServerException(e.message ?? 'Network error', status);
  }

  bool _authUrlUsesHttpsRedirect(String authUrl) {
    final uri = Uri.tryParse(authUrl);
    if (uri == null) return false;
    final redirect = uri.queryParameters['redirect_uri'];
    if (redirect == null || redirect.isEmpty) return false;
    final decoded = Uri.decodeComponent(redirect);
    return decoded.startsWith('https://') || decoded.startsWith('http://');
  }
}
