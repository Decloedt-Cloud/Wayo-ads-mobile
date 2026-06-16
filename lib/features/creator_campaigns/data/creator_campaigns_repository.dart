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

  static String _browseKey(int page, int limit, String search) =>
      'creator_browse_campaigns_${page}_${limit}_$search';
  static String _detailKey(String id) => 'creator_campaign_detail_$id';
  static String _submissionsKey(String id) =>
      'creator_campaign_submissions_$id';

  Future<CreatorBrowsePageResult> fetchBrowseCampaignsPage({
    List<CreatorBrowseCampaign>? fallbackList,
    CreatorBrowsePageResult? fallbackPage,
    int limit = 10,
    int page = 1,
    String? search,
  }) async {
    final normalizedSearch = search?.trim() ?? '';
    final key = _browseKey(page, limit, normalizedSearch);
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
      ),
    );
  }

  Future<CreatorCampaignDetail> fetchCampaignDetail(
    String id, {
    CreatorCampaignDetail? fallback,
  }) async {
    final key = _detailKey(id);
    if (!_rate.canCall(key) && fallback != null) {
      return fallback;
    }
    _rate.mark(key);
    return _dedup.run<CreatorCampaignDetail>(
      key,
      () => _remote.fetchCampaignDetail(id),
    );
  }

  Future<List<CreatorSocialPost>> fetchMySubmissions(String campaignId) async {
    final key = _submissionsKey(campaignId);
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
