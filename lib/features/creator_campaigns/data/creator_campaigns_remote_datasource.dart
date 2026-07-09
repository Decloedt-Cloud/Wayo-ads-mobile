import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/campaigns/campaign_marketplace_facets.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/creator_browse_campaign.dart';
import '../domain/creator_browse_page_result.dart';
import '../domain/creator_campaign_detail.dart';
import '../domain/creator_social_post.dart';
import '../domain/creator_tracking_link.dart';

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
  /// campaigns the creator can apply to (paginated).
  Future<CreatorBrowsePageResult> fetchBrowseCampaignsPage({
    int limit = 10,
    int page = 1,
    String? search,
    String? type,
    String? niche,
    String? countryCode,
  }) async {
    try {
      final qp = <String, dynamic>{
        'status': 'ACTIVE',
        'creatorOnly': 'true',
        'page': page,
        'limit': limit.clamp(1, 100),
      };
      final trimmed = search?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        qp['search'] = trimmed;
      }
      if (type != null && type.isNotEmpty) {
        qp['type'] = type.toUpperCase();
      }
      if (niche != null && niche.isNotEmpty) {
        qp['niche'] = niche;
      }
      if (countryCode != null && countryCode.length == 2) {
        qp['country'] = countryCode.toUpperCase();
      }
      final res = await _dio.get<Object?>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.campaigns),
        queryParameters: qp,
      );
      final body = res.data;
      if (body is! Map) {
        return CreatorBrowsePageResult(
          campaigns: const [],
          total: 0,
          page: page,
          totalPages: 1,
        );
      }
      final map = Map<String, dynamic>.from(body);
      final raw = map['campaigns'];
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map(
                (e) =>
                    CreatorBrowseCampaign.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
          : const <CreatorBrowseCampaign>[];
      final total = _intFromJson(map['total'], list.length);
      final pageNum = _intFromJson(map['page'], page);
      var totalPages = _intFromJson(map['totalPages'], 0);
      if (totalPages < 1) {
        final lim = limit.clamp(1, 100);
        totalPages = total > 0 ? (total + lim - 1) ~/ lim : 1;
      }
      return CreatorBrowsePageResult(
        campaigns: list,
        total: total,
        page: pageNum,
        totalPages: totalPages,
        facets: CampaignMarketplaceFacets.fromJson(map),
      );
    } on DioException catch (e) {
      throw _mapDioException(e, 'Failed to load campaigns');
    }
  }

  static int _intFromJson(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  /// `GET /api/campaigns/:id` — full detail. The response shape depends on
  /// whether the caller is the advertiser, an approved creator, or a stranger:
  /// we flatten it inside [CreatorCampaignDetail].
  Future<CreatorCampaignDetail> fetchCampaignDetail(String id) async {
    try {
      final res = await _dio.get<Object?>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.campaignDetail(id)),
      );
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
        AuthRuntimeConfig.instance.wayoAdsRequestPath(
          ApiEndpoints.campaignApply(campaignId),
        ),
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
        AuthRuntimeConfig.instance.wayoAdsRequestPath(
          ApiEndpoints.creatorCampaignSubmitPost(campaignId),
        ),
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
        AuthRuntimeConfig.instance.wayoAdsRequestPath(
          ApiEndpoints.creatorCampaignSubmitPost(campaignId),
        ),
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

  /// `GET /api/campaigns/:id/links` — ensures and returns the creator's
  /// tracking short link for LINK campaigns (idempotent on the server).
  Future<List<CreatorTrackingLink>> fetchTrackingLinks(String campaignId) async {
    try {
      final res = await _dio.get<Object?>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(
          ApiEndpoints.campaignTrackingLinks(campaignId),
        ),
      );
      final body = res.data;
      if (body is! Map) return const [];
      final links = body['links'];
      if (links is! List) return const [];
      return links
          .whereType<Map>()
          .map(
            (e) => CreatorTrackingLink.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      throw _mapDioException(e, 'Failed to load your tracking link');
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
