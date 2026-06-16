import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/wayo_ads_dio.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../data/superadmin_remote_datasource.dart';
import '../../data/superadmin_repository.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/ai_usage.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/banned_user.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../creator_campaigns/domain/creator_browse_page_result.dart';
import '../../domain/entities/country_tax_rate.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/withdrawal.dart';

part 'superadmin_providers.g.dart';

@Riverpod(keepAlive: true)
SuperadminRemote superadminRemote(SuperadminRemoteRef ref) {
  return SuperadminRemoteDatasource(ref.watch(wayoAdsDioProvider));
}

@Riverpod(keepAlive: true)
ISuperadminRepository superadminRepository(SuperadminRepositoryRef ref) {
  return SuperadminRepository(ref.watch(superadminRemoteProvider));
}

// Dashboard Providers
@riverpod
Future<DashboardStats> dashboardStats(DashboardStatsRef ref) async {
  final repo = ref.watch(superadminRepositoryProvider);
  final result = await repo.getDashboardStats();
  return result.when(
    success: (stats) => stats,
    failure: (e) => throw e,
  );
}

@riverpod
Future<PayoutStats> payoutStats(PayoutStatsRef ref) async {
  final repo = ref.watch(superadminRepositoryProvider);
  final result = await repo.getPayoutStats();
  return result.when(
    success: (stats) => stats,
    failure: (e) => throw e,
  );
}

// Banned Users Providers
@riverpod
class BannedUsersNotifier extends _$BannedUsersNotifier {
  @override
  Future<BannedUsersPage> build({String? search}) async {
    final repo = ref.watch(superadminRepositoryProvider);
    final result = await repo.getBannedUsers(search: search);
    return result.when(
      success: (page) => page,
      failure: (e) => throw e,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.offset + current.limit >= current.total) return;

    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.getBannedUsers(
      search: search,
      offset: current.offset + current.limit,
    );
    result.when(
      success: (page) {
        state = AsyncData(BannedUsersPage(
          bans: [...current.bans, ...page.bans],
          total: page.total,
          limit: page.limit,
          offset: page.offset,
        ));
      },
      failure: (e) {
        // Keep current state on failure
      },
    );
  }

  Future<bool> banUser(String wayoUserId, {String? reason}) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.banUser(wayoUserId: wayoUserId, reason: reason);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> unbanUser(int authUserId) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.unbanUser(authUserId);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }
}

@riverpod
Future<List<SearchUser>> userSearch(
  UserSearchRef ref, {
  required String query,
}) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(superadminRepositoryProvider);
  final result = await repo.searchUsers(search: query);
  return result.when(
    success: (users) => users,
    failure: (e) => throw e,
  );
}

// Admin Users Management Providers
@riverpod
class AdminUsersNotifier extends _$AdminUsersNotifier {
  @override
  Future<AdminUsersPage> build({
    String? search,
    RoleFilter? role,
    JoinedFilter? joined,
    bool? bannedOnly,
  }) async {
    return _fetchPage(1);
  }

  Future<AdminUsersPage> _fetchPage(int page) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.getUsers(
      search: search,
      role: role,
      joined: joined,
      bannedOnly: bannedOnly,
      page: page,
      limit: kAdminUsersPageSize,
    );
    return result.when(
      success: (p) => p,
      failure: (e) => throw e,
    );
  }

  /// Loads a specific page from Wayo-ads (replaces the current list).
  Future<void> goToPage(int page) async {
    final current = state.valueOrNull;
    if (current != null) {
      if (page < 1 || page > current.totalPages) return;
      if (page == current.page) return;
    } else if (page < 1) {
      return;
    }

    state = const AsyncLoading();
    try {
      state = AsyncData(await _fetchPage(page));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.page >= current.totalPages) return;
    await goToPage(current.page + 1);
  }

  Future<void> previousPage() async {
    final current = state.valueOrNull;
    if (current == null || current.page <= 1) return;
    await goToPage(current.page - 1);
  }

  Future<bool> banUser(String wayoUserId, {String? reason}) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.banUser(wayoUserId: wayoUserId, reason: reason);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> unbanUser(int authUserId) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.unbanUser(authUserId);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }
}

// Withdrawals Providers
@riverpod
class WithdrawalsNotifier extends _$WithdrawalsNotifier {
  @override
  Future<WithdrawalsPage> build({WithdrawalStatus? status}) async {
    ref.watch(superadminWithdrawalsLivePulseProvider);
    final repo = ref.watch(superadminRepositoryProvider);
    final result = await repo.getWithdrawals(status: status);
    return result.when(
      success: (page) => page,
      failure: (e) => throw e,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.page >= current.totalPages) return;

    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.getWithdrawals(
      status: status,
      offset: current.withdrawals.length,
    );
    result.when(
      success: (page) {
        state = AsyncData(WithdrawalsPage(
          withdrawals: [...current.withdrawals, ...page.withdrawals],
          total: page.total,
          totalPages: page.totalPages,
          page: page.page,
          summary: page.summary,
        ));
      },
      failure: (e) {
        // Keep current state on failure
      },
    );
  }

  Future<bool> approve(String withdrawalId) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.approveWithdrawal(withdrawalId);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> cancel(String withdrawalId) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.cancelWithdrawal(withdrawalId);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }
}

// Announcements Providers
@riverpod
class AnnouncementsNotifier extends _$AnnouncementsNotifier {
  @override
  Future<List<Announcement>> build() async {
    final repo = ref.watch(superadminRepositoryProvider);
    final result = await repo.getAnnouncements();
    return result.when(
      success: (list) => list,
      failure: (e) => throw e,
    );
  }

  Future<bool> create(Announcement announcement) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.createAnnouncement(announcement);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> updateAnnouncement(String id, Announcement announcement) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.updateAnnouncement(id, announcement);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> deleteAnnouncement(String id) async {
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.deleteAnnouncement(id);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }
}

// AI Usage Providers
@riverpod
Future<AiUsageStats> aiUsage(AiUsageRef ref, {String period = '30d'}) async {
  final repo = ref.watch(superadminRepositoryProvider);
  final result = await repo.getAiUsage(period: period);
  return result.when(
    success: (stats) => stats,
    failure: (e) => throw e,
  );
}

// Ledger Providers
@riverpod
class LedgerNotifier extends _$LedgerNotifier {
  @override
  Future<LedgerPage> build({
    LedgerEntryType? type,
    String? creatorId,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final repo = ref.watch(superadminRepositoryProvider);
    final result = await repo.getLedger(
      type: type,
      creatorId: creatorId,
      campaignId: campaignId,
      startDate: startDate,
      endDate: endDate,
    );
    return result.when(
      success: (page) => page,
      failure: (e) => throw e,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.page >= current.totalPages) return;

    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.getLedger(
      page: current.page + 1,
      type: type,
      creatorId: creatorId,
      campaignId: campaignId,
      startDate: startDate,
      endDate: endDate,
    );
    result.when(
      success: (page) {
        state = AsyncData(LedgerPage(
          entries: [...current.entries, ...page.entries],
          page: page.page,
          limit: page.limit,
          total: page.total,
          totalPages: page.totalPages,
          summary: page.summary,
        ));
      },
      failure: (e) {
        // Keep current state on failure
      },
    );
  }
}

// Tax rates
@riverpod
Future<TaxRatesPage> taxRates(TaxRatesRef ref) async {
  final repo = ref.watch(superadminRepositoryProvider);
  final result = await repo.getTaxRates();
  return result.when(
    success: (page) => page,
    failure: (e) => throw e,
  );
}

/// Browse campaigns list page (1-based).
final superadminBrowseCampaignPageProvider = StateProvider<int>((ref) => 1);

final superadminBrowseCampaignSearchProvider = StateProvider<String>(
  (ref) => '',
);

final superadminBrowseTypeFilterProvider =
    StateProvider<CreatorCampaignType?>((ref) => null);

final superadminBrowseNicheProvider = StateProvider<String?>((ref) => null);

final superadminBrowseLocationProvider = StateProvider<String?>((ref) => null);

typedef SuperadminBrowsePagedKey = ({
  int page,
  String search,
  String? typeApi,
  String? nicheApi,
  String? countryApi,
});

/// Public marketplace — `GET /api/campaigns?status=ACTIVE`.
final superadminBrowseCampaignsPagedProvider = FutureProvider.autoDispose
    .family<CreatorBrowsePageResult, SuperadminBrowsePagedKey>((ref, key) async {
      ref.watch(superadminBrowseLivePulseProvider);
      final repo = ref.watch(superadminRepositoryProvider);
      final result = await repo.getMarketplaceCampaignsPage(
        page: key.page,
        limit: 10,
        search: key.search.trim().isEmpty ? null : key.search.trim(),
        type: key.typeApi,
        niche: key.nicheApi,
        countryCode: key.countryApi,
      );
      return result.when(
        success: (page) => page,
        failure: (e) => throw e,
      );
    });

/// Bumps when Reverb invalidates superadmin payout data (live refresh pulse).
final superadminWithdrawalsLivePulseProvider = StateProvider<int>((ref) => 0);

/// Bumps when campaign marketplace stats change (live browse refresh).
final superadminBrowseLivePulseProvider = StateProvider<int>((ref) => 0);

void invalidateSuperadminBrowseCampaigns(dynamic ref) {
  ref.read(superadminBrowseLivePulseProvider.notifier).update((n) => n + 1);
  ref.invalidate(superadminBrowseCampaignsPagedProvider);
}

/// Refreshes withdrawals list, payout stats, and dashboard KPIs after a realtime signal.
void invalidateSuperadminWithdrawalData(dynamic ref) {
  ref.read(superadminWithdrawalsLivePulseProvider.notifier).update((n) => n + 1);
  ref.invalidate(withdrawalsNotifierProvider);
  ref.invalidate(payoutStatsProvider);
  ref.invalidate(dashboardStatsProvider);
}

void invalidateSuperadminRealtimePanels(dynamic ref) {
  invalidateSuperadminWithdrawalData(ref);
  invalidateSuperadminBrowseCampaigns(ref);
  ref.invalidate(notificationsListProvider);
  ref.invalidate(notificationsUnreadCountsProvider);
}
