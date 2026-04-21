import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/advertiser_campaign.dart';

/// Primary status filter (tabs + chips).
enum AdvertiserCampaignsTab { active, paused, completed }

final advertiserCampaignsTabProvider =
    StateProvider<AdvertiserCampaignsTab>(
  (ref) => AdvertiserCampaignsTab.active,
);

/// Debounced search is written here from the screen (lowercase match on name).
final advertiserCampaignsSearchQueryProvider =
    StateProvider<String>((ref) => '');

/// Cached list from `GET /api/campaigns?advertiserOnly=true`.
final advertiserCampaignsListProvider =
    FutureProvider<List<AdvertiserCampaign>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(advertiserCampaignsRepositoryProvider);
  try {
    return await repo.loadCampaigns();
  } catch (e) {
    throw AdvertiserCampaignsRepository.mapError(e);
  }
});

final advertiserCampaignsCountsProvider =
    Provider<({int active, int paused, int completed})>((ref) {
  final list =
      ref.watch(advertiserCampaignsListProvider).valueOrNull ??
          const <AdvertiserCampaign>[];
  return (
    active: list.where((c) => c.matchesActiveTab).length,
    paused: list.where((c) => c.matchesPausedTab).length,
    completed: list.where((c) => c.matchesCompletedTab).length,
  );
});

final advertiserCampaignsFilteredProvider =
    Provider<List<AdvertiserCampaign>>((ref) {
  final async = ref.watch(advertiserCampaignsListProvider);
  final list = async.valueOrNull ?? const <AdvertiserCampaign>[];
  final tab = ref.watch(advertiserCampaignsTabProvider);
  final q = ref.watch(advertiserCampaignsSearchQueryProvider).trim().toLowerCase();

  Iterable<AdvertiserCampaign> it = list;
  it = switch (tab) {
    AdvertiserCampaignsTab.active => it.where((c) => c.matchesActiveTab),
    AdvertiserCampaignsTab.paused => it.where((c) => c.matchesPausedTab),
    AdvertiserCampaignsTab.completed => it.where((c) => c.matchesCompletedTab),
  };
  if (q.isNotEmpty) {
    it = it.where((c) => c.name.toLowerCase().contains(q));
  }
  return it.toList();
});

final advertiserCampaignDetailProvider =
    FutureProvider.family.autoDispose<Map<String, dynamic>, String>(
  (ref, id) async {
    final repo = ref.watch(advertiserCampaignsRepositoryProvider);
    try {
      return await repo.loadCampaignDetail(id);
    } catch (e) {
      throw AdvertiserCampaignsRepository.mapError(e);
    }
  },
);
