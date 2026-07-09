import '../../../core/network/rate_limiter.dart';
import '../../../core/network/request_deduplicator.dart';
import '../domain/creator_browse_campaign.dart';
import '../domain/creator_browse_page_result.dart';
import '../domain/creator_campaign_detail.dart';
import '../domain/creator_social_post.dart';
import '../domain/creator_tracking_link.dart';
import 'creator_campaigns_remote_datasource.dart';

/// Repository for the creator campaigns feature.
///
/// Reads (browse, detail, my-submissions) are deduplicated and rate-limited —
/// the dashboard already polls these providers every 10 s on foreground, so we
/// avoid hammering the backend when a realtime event arrives during the same
/// window.
///
/// Mutations ([applyToCampaign], [submitPost]) deliberately bypass the limiter:
/// they're user-initiated one-shots that must always reach the backend.
class CreatorCampaignsRepository {
  CreatorCampaignsRepository({
    required CreatorCampaignsRemoteDatasource remote,
    required RequestDeduplicator deduplicator,
    required RateLimiter rateLimiter,
  }) : _remote = remote,
       _dedup = deduplicator,
       _rate = rateLimiter;

  final CreatorCampaignsRemoteDatasource _remote;
  final RequestDeduplicator _dedup;
  final RateLimiter _rate;

  static String _browseKey(
    int userId,
    int page,
    int limit,
    String search,
    String type,
    String niche,
    String country,
  ) =>
      'creator_browse_${userId}_${page}_${limit}_${search}_${type}_${niche}_$country';
  static String _detailKey(int userId, String id) =>
      'creator_campaign_detail_${userId}_$id';
  static String _submissionsKey(int userId, String campaignId) =>
      'creator_campaign_submissions_${userId}_$campaignId';

  Future<CreatorBrowsePageResult> fetchBrowseCampaignsPage({
    required int sessionUserId,
    List<CreatorBrowseCampaign>? fallbackList,
    CreatorBrowsePageResult? fallbackPage,
    int limit = 10,
    int page = 1,
    String? search,
    String? type,
    String? niche,
    String? countryCode,
  }) async {
    final normalizedSearch = search?.trim() ?? '';
    final normalizedType = type?.trim().toUpperCase() ?? '';
    final normalizedNiche = niche?.trim() ?? '';
    final normalizedCountry = countryCode?.trim().toUpperCase() ?? '';
    final key = _browseKey(
      sessionUserId,
      page,
      limit,
      normalizedSearch,
      normalizedType,
      normalizedNiche,
      normalizedCountry,
    );
    final fallback =
        fallbackPage ??
        (fallbackList != null
            ? CreatorBrowsePageResult(
                campaigns: fallbackList,
                total: fallbackList.length,
                page: page,
                totalPages: 1,
              )
            : null);
    if (!_rate.canCall(key) && fallback != null) {
      return fallback;
    }
    _rate.mark(key);
    return _dedup.run<CreatorBrowsePageResult>(
      key,
      () => _remote.fetchBrowseCampaignsPage(
        limit: limit,
        page: page,
        search: normalizedSearch.isEmpty ? null : normalizedSearch,
        type: normalizedType.isEmpty ? null : normalizedType,
        niche: normalizedNiche.isEmpty ? null : normalizedNiche,
        countryCode: normalizedCountry.isEmpty ? null : normalizedCountry,
      ),
    );
  }

  Future<CreatorCampaignDetail> fetchCampaignDetail(
    String id, {
    required int sessionUserId,
    CreatorCampaignDetail? fallback,
  }) async {
    final key = _detailKey(sessionUserId, id);
    if (!_rate.canCall(key) && fallback != null) {
      return fallback;
    }
    _rate.mark(key);
    return _dedup.run<CreatorCampaignDetail>(
      key,
      () => _remote.fetchCampaignDetail(id),
    );
  }

  Future<List<CreatorSocialPost>> fetchMySubmissions(
    String campaignId, {
    required int sessionUserId,
  }) async {
    final key = _submissionsKey(sessionUserId, campaignId);
    _rate.mark(key);
    return _dedup.run<List<CreatorSocialPost>>(
      key,
      () => _remote.fetchMySubmissions(campaignId),
    );
  }

  Future<String> applyToCampaign(String campaignId, {String? message}) =>
      _remote.applyToCampaign(campaignId, message: message);

  Future<CreatorSocialPost> submitPost({
    required String campaignId,
    required String platform,
    required String postUrl,
  }) => _remote.submitPost(
    campaignId: campaignId,
    platform: platform,
    postUrl: postUrl,
  );

  Future<List<CreatorTrackingLink>> fetchTrackingLinks(String campaignId) =>
      _remote.fetchTrackingLinks(campaignId);
}
