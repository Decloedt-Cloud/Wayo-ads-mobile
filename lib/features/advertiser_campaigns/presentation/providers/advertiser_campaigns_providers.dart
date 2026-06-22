import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/campaigns/campaign_explorer_layout.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../creator_campaigns/domain/creator_browse_page_result.dart';
import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/advertiser_campaigns_page_result.dart';
import '../../domain/campaign_application.dart';

/// Primary status filter (explorer dropdown + API). Drafts are separate from "Active".
enum AdvertiserCampaignsTab { active, draft, paused, completed }

/// Top-level campaigns tab: own campaigns vs marketplace browse.
enum AdvertiserCampaignsViewMode { mine, browse }

final advertiserCampaignsViewModeProvider =
    StateProvider<AdvertiserCampaignsViewMode>(
  (ref) => AdvertiserCampaignsViewMode.mine,
);

String apiStatusForAdvertiserTab(AdvertiserCampaignsTab tab) => switch (tab) {
  AdvertiserCampaignsTab.active => 'ACTIVE',
  AdvertiserCampaignsTab.draft => 'DRAFT',
  AdvertiserCampaignsTab.paused => 'PAUSED',
  AdvertiserCampaignsTab.completed => 'COMPLETED',
};

final advertiserCampaignsTabProvider = StateProvider<AdvertiserCampaignsTab>(
  (ref) => AdvertiserCampaignsTab.active,
);

/// 1-based page for the current tab + search ([advertiserCampaignsPagedKeyProvider]).
final advertiserCampaignsPageIndexProvider = StateProvider<int>((ref) => 1);

/// Debounced search is written here from the screen (lowercase match on name).
final advertiserCampaignsSearchQueryProvider = StateProvider<String>(
  (ref) => '',
);

/// List vs grid for the campaign catalog (same mental model as Wayo-ads web).
final advertiserCampaignExplorerLayoutProvider =
    StateProvider<CampaignExplorerLayout>((ref) => CampaignExplorerLayout.list);

/// Client-side refinements on top of the status tab + server search.
final advertiserCampaignExplorerTypeFilterProvider =
    StateProvider<CreatorCampaignType?>((ref) => null);

final advertiserCampaignExplorerNicheProvider = StateProvider<String?>(
  (ref) => null,
);

final advertiserCampaignExplorerLocationProvider = StateProvider<String?>(
  (ref) => null,
);

/// Immutable key for [advertiserCampaignsPagedProvider].
typedef AdvertiserCampaignsPagedKey = ({
  AdvertiserCampaignsTab tab,
  int page,
  String search,
});

/// Current page of campaigns (server-side, 10 per page, filtered by tab + search).
final advertiserCampaignsPagedProvider = FutureProvider.autoDispose
    .family<AdvertiserCampaignsPageResult, AdvertiserCampaignsPagedKey>((
      ref,
      key,
    ) async {
      final repo = ref.watch(advertiserCampaignsRepositoryProvider);
      try {
        final status = apiStatusForAdvertiserTab(key.tab);
        final q = key.search.trim();
        return await repo.loadCampaignsPage(
          status: status,
          page: key.page,
          limit: 10,
          search: q.isEmpty ? null : q,
        );
      } catch (e) {
        throw AdvertiserCampaignsRepository.mapError(e);
      }
    });

/// Tab totals for chips (four `limit=1` requests).
final advertiserCampaignsCountsProvider =
    FutureProvider<({int active, int draft, int paused, int completed})>((
      ref,
    ) async {
      ref.keepAlive();
      final repo = ref.watch(advertiserCampaignsRepositoryProvider);
      try {
        return await repo.loadCampaignStatusCounts();
      } catch (e) {
        throw AdvertiserCampaignsRepository.mapError(e);
      }
    });

final advertiserCampaignDetailProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, String>((ref, id) async {
      final repo = ref.watch(advertiserCampaignsRepositoryProvider);
      try {
        return await repo.loadCampaignDetail(id);
      } catch (e) {
        throw AdvertiserCampaignsRepository.mapError(e);
      }
    });

/// Applications for a specific campaign (pending, approved, rejected).
///
/// Reuses `applications` from [advertiserCampaignDetailProvider] when present
/// (Wayo-ads `GET /api/campaigns/:id` already embeds them for owners).
final campaignApplicationsProvider = FutureProvider.family
    .autoDispose<List<CampaignApplication>, String>((ref, campaignId) async {
      final detail = await ref.watch(
        advertiserCampaignDetailProvider(campaignId).future,
      );
      final embedded = campaignApplicationsFromCampaignDetail(detail);
      if (embedded != null) {
        return embedded;
      }

      final repo = ref.watch(advertiserCampaignsRepositoryProvider);
      try {
        return await repo.loadCampaignApplications(campaignId);
      } catch (e) {
        throw AdvertiserCampaignsRepository.mapError(e);
      }
    });

/// Only pending applications — derived from [campaignApplicationsProvider].
final pendingCampaignApplicationsProvider = Provider.family
    .autoDispose<List<CampaignApplication>, String>((ref, campaignId) {
      final list =
          ref.watch(campaignApplicationsProvider(campaignId)).valueOrNull ??
          const [];
      return list
          .where((a) => a.status == CampaignApplicationStatus.pending)
          .toList();
    });

// —— Marketplace browse (active campaigns on the platform) ——

final advertiserBrowseCampaignPageProvider = StateProvider<int>((ref) => 1);

final advertiserBrowseCampaignSearchProvider = StateProvider<String>(
  (ref) => '',
);

final advertiserBrowseExplorerLayoutProvider =
    StateProvider<CampaignExplorerLayout>((ref) => CampaignExplorerLayout.list);

final advertiserBrowseTypeFilterProvider =
    StateProvider<CreatorCampaignType?>((ref) => null);

final advertiserBrowseNicheProvider = StateProvider<String?>((ref) => null);

final advertiserBrowseLocationProvider = StateProvider<String?>((ref) => null);

typedef AdvertiserBrowsePagedKey = ({
  int page,
  String search,
  String? typeApi,
  String? nicheApi,
  String? countryApi,
});

/// Public marketplace — `GET /api/campaigns?status=ACTIVE`.
final advertiserBrowseCampaignsPagedProvider = FutureProvider.autoDispose
    .family<CreatorBrowsePageResult, AdvertiserBrowsePagedKey>((ref, key) async {
      await awaitPostLoginBootstrap(ref);
      final repo = ref.watch(advertiserCampaignsRepositoryProvider);
      return fetchWithSessionRetry(
        ref,
        () async {
          try {
            return await repo.loadMarketplaceBrowsePage(
              page: key.page,
              limit: 10,
              search: key.search.trim().isEmpty ? null : key.search.trim(),
              type: key.typeApi,
              niche: key.nicheApi,
              countryCode: key.countryApi,
            );
          } catch (e) {
            throw AdvertiserCampaignsRepository.mapError(e);
          }
        },
      );
    });

void invalidateAdvertiserBrowseCampaigns(dynamic ref) {
  ref.read(advertiserBrowseCampaignPageProvider.notifier).state = 1;
  ref.invalidate(advertiserBrowseCampaignsPagedProvider);
}

void resetAdvertiserBrowseExplorerFilters(dynamic ref) {
  ref.read(advertiserBrowseTypeFilterProvider.notifier).state = null;
  ref.read(advertiserBrowseNicheProvider.notifier).state = null;
  ref.read(advertiserBrowseLocationProvider.notifier).state = null;
}
