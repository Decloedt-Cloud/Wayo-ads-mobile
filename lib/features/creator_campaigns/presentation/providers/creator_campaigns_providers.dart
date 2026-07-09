import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/campaigns/campaign_explorer_layout.dart';
import '../../../../core/network/rate_limiter.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../data/creator_campaigns_remote_datasource.dart';
import '../../data/creator_campaigns_repository.dart';
import '../../domain/creator_browse_campaign.dart';
import '../../domain/creator_browse_page_result.dart';
import '../../domain/creator_campaign_detail.dart';
import '../../domain/creator_social_post.dart';
import '../../domain/creator_tracking_link.dart';
import '../../data/creator_youtube_remote.dart';
import '../../domain/creator_youtube_status.dart';

/// Rate limiter for the creator campaigns feature. Slightly tighter than the
/// dashboard (5 s) because the browse list doesn't change very often, but it
/// still pulls from `/api/campaigns` which is a heavy endpoint.
final creatorCampaignsRateLimiterProvider = Provider<RateLimiter>((ref) {
  ref.keepAlive();
  return RateLimiter(minInterval: const Duration(seconds: 3));
});

final creatorCampaignsRemoteProvider =
    Provider<CreatorCampaignsRemoteDatasource>((ref) {
      return CreatorCampaignsRemoteDatasource(ref.watch(wayoAdsDioProvider));
    });

final creatorCampaignsRepositoryProvider = Provider<CreatorCampaignsRepository>(
  (ref) {
    ref.keepAlive();
    return CreatorCampaignsRepository(
      remote: ref.watch(creatorCampaignsRemoteProvider),
      deduplicator: ref.watch(requestDeduplicatorProvider),
      rateLimiter: ref.watch(creatorCampaignsRateLimiterProvider),
    );
  },
);

/// Current page index for **browse** list (1-based). Used with [creatorBrowseCampaignsPagedProvider].
final creatorBrowseCampaignPageProvider = StateProvider<int>((ref) => 1);

/// Applied search text for [creatorBrowseCampaignsPagedProvider] (debounced from the search field).
final creatorBrowseCampaignSearchQueryProvider = StateProvider<String>(
  (ref) => '',
);

/// Browse UI: compact list vs grid (persisted per session only).
final creatorCampaignExplorerLayoutProvider =
    StateProvider<CampaignExplorerLayout>((ref) => CampaignExplorerLayout.list);

/// Client-side type filter; `null` means all types.
final creatorCampaignExplorerTypeFilterProvider =
    StateProvider<CreatorCampaignType?>((ref) => null);

final creatorCampaignExplorerNicheProvider = StateProvider<String?>(
  (ref) => null,
);

final creatorCampaignExplorerLocationProvider = StateProvider<String?>(
  (ref) => null,
);

/// Paginated browse key: page, search, and server-side explorer filters (API).
typedef CreatorBrowsePagedKey = ({
  int page,
  String search,
  String? typeApi,
  String? nicheApi,
  String? countryApi,
});

/// Paginated browse (`GET /api/campaigns?creatorOnly=true&limit=10&search=…`).
final creatorBrowseCampaignsPagedProvider = FutureProvider.autoDispose
    .family<CreatorBrowsePageResult, CreatorBrowsePagedKey>((ref, key) async {
      final userId = await awaitCreatorSessionUserId(ref);
      final q = key.search.trim();
      return fetchCreatorWithAuthRetry(
        ref,
        () => ref
            .watch(creatorCampaignsRepositoryProvider)
            .fetchBrowseCampaignsPage(
              sessionUserId: userId,
              page: key.page,
              limit: 10,
              search: q.isEmpty ? null : q,
              type: key.typeApi,
              niche: key.nicheApi,
              countryCode: key.countryApi,
            ),
      );
    });

/// Detail of a single campaign — keyed by campaign id.
final creatorCampaignDetailProvider =
    FutureProvider.family<CreatorCampaignDetail, String>((ref, id) async {
      final userId = ref.watch(currentAppUserProvider)?.id;
      if (userId == null) {
        throw StateError('Creator campaign detail requires an authenticated user');
      }
      ref.keepAlive();
      return ref
          .watch(creatorCampaignsRepositoryProvider)
          .fetchCampaignDetail(id, sessionUserId: userId);
    });

/// Social posts (videos) the creator has submitted for a given campaign —
/// keyed by campaign id. Complements [creatorCampaignDetailProvider] when the
/// user is APPROVED so we can show a live review status list without
/// refetching the whole campaign payload.
final creatorMySubmissionsProvider =
    FutureProvider.family<List<CreatorSocialPost>, String>((ref, id) async {
      final userId = ref.watch(currentAppUserProvider)?.id;
      if (userId == null) {
        throw StateError('Creator submissions require an authenticated user');
      }
      ref.keepAlive();
      return ref
          .watch(creatorCampaignsRepositoryProvider)
          .fetchMySubmissions(id, sessionUserId: userId);
    });

/// Tracking short links for LINK campaigns — keyed by campaign id.
/// Falls back to [GET /api/campaigns/:id/links] when the detail payload
/// has not embedded links yet.
final creatorTrackingLinksProvider =
    FutureProvider.family<List<CreatorTrackingLink>, String>((ref, id) async {
      ref.keepAlive();
      final detail = ref.watch(creatorCampaignDetailProvider(id)).valueOrNull;
      if (detail != null && detail.trackingLinks.isNotEmpty) {
        return detail.trackingLinks;
      }
      if (detail != null &&
          detail.type == CreatorCampaignType.link &&
          detail.isApproved) {
        return ref
            .read(creatorCampaignsRepositoryProvider)
            .fetchTrackingLinks(id);
      }
      return detail?.trackingLinks ?? const [];
    });

final creatorYoutubeRemoteProvider = Provider<CreatorYoutubeRemote>((ref) {
  return CreatorYoutubeRemote(ref.watch(wayoAdsDioProvider));
});

/// Linked YouTube channel + OAuth status — gates video/short submission on mobile.
final creatorYoutubeChannelStatusProvider =
    FutureProvider.autoDispose<CreatorYoutubeChannelStatus>((ref) async {
      ref.watch(currentAppUserProvider);
      return ref.watch(creatorYoutubeRemoteProvider).fetchChannelStatus();
    });
