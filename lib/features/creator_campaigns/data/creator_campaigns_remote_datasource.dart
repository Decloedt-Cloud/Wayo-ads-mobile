import 'package:dio/dio.dart';

import '../domain/creator_browse_campaign.dart';
import '../domain/creator_campaign_detail.dart';
import '../domain/creator_social_post.dart';

/// Raised when the backend returns a structured `{ error, errorCode? }`
/// payload — we keep both so the UI can show the message directly or branch on
/// the code (e.g. `ALREADY_APPLIED`).
class CreatorCampaignsApiException implements Exception {
  CreatorCampaignsApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() =>
      'CreatorCampaignsApiException($statusCode $code: $message)';
}

/// Thin HTTP wrapper over `/api/campaigns/*` and
/// `/api/creator/campaigns/:id/submit-post` on Wayo-ads (Next.js).
///
/// Bearer JWT is attached by `wayoAdsDioProvider` — we only shape the
/// payloads and normalise errors here.
class CreatorCampaignsRemoteDatasource {
  CreatorCampaignsRemoteDatasource(this._dio);

  final Dio _dio;

  /// `GET /api/campaigns?status=ACTIVE&creatorOnly=true` — browseable
  /// campaigns the creator can apply to.
  Future<List<CreatorBrowseCampaign>> fetchBrowseCampaigns({
    int limit = 30,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get<Object?>(
        'api/campaigns',
        queryParameters: <String, dynamic>{
          'status': 'ACTIVE',
          'creatorOnly': 'true',
          'page': page,
          'limit': limit.clamp(1, 100),
        },
      );
      final body = res.data;
      if (body is! Map) return const [];
      final raw = body['campaigns'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => CreatorBrowseCampaign.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      throw _mapDioException(e, 'Failed to load campaigns');
    }
  }

  /// `GET /api/campaigns/:id` — full detail. The response shape depends on
  /// whether the caller is the advertiser, an approved creator, or a stranger:
  /// we flatten it inside [CreatorCampaignDetail].
  Future<CreatorCampaignDetail> fetchCampaignDetail(String id) async {
    try {
      final res = await _dio.get<Object?>('api/campaigns/$id');
      final body = res.data;
      if (body is! Map) {
        throw CreatorCampaignsApiException(
          'Invalid campaign payload',
          statusCode: res.statusCode,
        );
      }
      final raw = body['campaign'] ?? body['data'] ?? body;
      if (raw is! Map) {
        throw CreatorCampaignsApiException(
          'Invalid campaign payload',
          statusCode: res.statusCode,
        );
      }
      return CreatorCampaignDetail.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (e) {
      throw _mapDioException(e, 'Failed to load campaign');
    }
  }

  /// `POST /api/campaigns/:id/apply` — creator applies to the campaign.
  /// Returns the created application id so the UI can navigate or refresh.
  Future<String> applyToCampaign(String campaignId, {String? message}) async {
    try {
      final res = await _dio.post<Object?>(
        'api/campaigns/$campaignId/apply',
        data: <String, dynamic>{
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
      );
      final body = res.data;
      if (body is Map) {
        final app = body['application'];
        if (app is Map && app['id'] is String) {
          return app['id'] as String;
        }
      }
      return '';
    } on DioException catch (e) {
      throw _mapDioException(e, 'Failed to apply to campaign');
    }
  }

  /// `GET /api/creator/campaigns/:id/submit-post` — the creator's application
  /// + every `SocialPost` they've submitted for this campaign (even rejected).
  Future<List<CreatorSocialPost>> fetchMySubmissions(String campaignId) async {
    try {
      final res = await _dio.get<Object?>(
        'api/creator/campaigns/$campaignId/submit-post',
      );
      final body = res.data;
      if (body is! Map) return const [];
      final app = body['application'];
      if (app is! Map) return const [];
      final posts = app['socialPosts'];
      if (posts is! List) return const [];
      return posts
          .whereType<Map>()
          .map((e) => CreatorSocialPost.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const [];
      }
      throw _mapDioException(e, 'Failed to load your submissions');
    }
  }

  /// `POST /api/creator/campaigns/:id/submit-post` — creator submits a public
  /// YouTube URL. Validation (platform, min duration, Shorts vertical ratio,
  /// privacy status, duplicate) is enforced server-side.
  Future<CreatorSocialPost> submitPost({
    required String campaignId,
    required String platform,
    required String postUrl,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        'api/creator/campaigns/$campaignId/submit-post',
        data: <String, dynamic>{'platform': platform, 'postUrl': postUrl},
      );
      final body = res.data;
      if (body is Map && body['post'] is Map) {
        return CreatorSocialPost.fromJson(
          Map<String, dynamic>.from(body['post'] as Map),
        );
      }
      throw CreatorCampaignsApiException(
        'Invalid submission response',
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioException(e, 'Failed to submit your video');
    }
  }

  CreatorCampaignsApiException _mapDioException(
    DioException e,
    String fallback,
  ) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? message;
    String? code;
    if (data is Map) {
      final err = data['error'];
      if (err is String) message = err;
      if (data['errorCode'] is String) {
        code = data['errorCode'] as String;
      }
    }
    return CreatorCampaignsApiException(
      (message?.isNotEmpty ?? false) ? message! : fallback,
      code: code,
      statusCode: status,
    );
  }
}
