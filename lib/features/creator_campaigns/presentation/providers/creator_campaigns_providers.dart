import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/rate_limiter.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../data/creator_campaigns_remote_datasource.dart';
import '../../data/creator_campaigns_repository.dart';
import '../../domain/creator_browse_campaign.dart';
import '../../domain/creator_campaign_detail.dart';
import '../../domain/creator_social_post.dart';

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

/// Browseable campaigns (`GET /api/campaigns?status=ACTIVE&creatorOnly=true`).
final creatorBrowseCampaignsProvider =
    FutureProvider<List<CreatorBrowseCampaign>>((ref) async {
      ref.keepAlive();
      return ref
          .watch(creatorCampaignsRepositoryProvider)
          .fetchBrowseCampaigns();
    });

/// Detail of a single campaign — keyed by campaign id.
final creatorCampaignDetailProvider =
    FutureProvider.family<CreatorCampaignDetail, String>((ref, id) async {
      ref.keepAlive();
      return ref
          .watch(creatorCampaignsRepositoryProvider)
          .fetchCampaignDetail(id);
    });

/// Social posts (videos) the creator has submitted for a given campaign —
/// keyed by campaign id. Complements [creatorCampaignDetailProvider] when the
/// user is APPROVED so we can show a live review status list without
/// refetching the whole campaign payload.
final creatorMySubmissionsProvider =
    FutureProvider.family<List<CreatorSocialPost>, String>((ref, id) async {
      ref.keepAlive();
      return ref
          .watch(creatorCampaignsRepositoryProvider)
          .fetchMySubmissions(id);
    });
