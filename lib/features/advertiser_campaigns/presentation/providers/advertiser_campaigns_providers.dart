import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/advertiser_campaigns_page_result.dart';
import '../../domain/campaign_application.dart';

/// Primary status filter (tabs + chips). Drafts are separate from "Active".
enum AdvertiserCampaignsTab { active, draft, paused, completed }

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
final campaignApplicationsProvider = FutureProvider.family
    .autoDispose<List<CampaignApplication>, String>((ref, campaignId) async {
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
