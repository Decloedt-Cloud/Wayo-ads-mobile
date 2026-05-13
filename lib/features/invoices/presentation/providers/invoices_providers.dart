import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../data/invoices_repository.dart';
import '../../domain/invoice.dart';
import '../../domain/invoices_page.dart';

/// Active filter for the invoices list.
enum InvoiceFilter {
  all,
  deposit,
  billing,
  payout,
  earnings;

  bool matches(Invoice inv) {
    switch (this) {
      case InvoiceFilter.all:
        return true;
      case InvoiceFilter.deposit:
        return inv.type == InvoiceType.deposit;
      case InvoiceFilter.billing:
        return inv.type == InvoiceType.billing;
      case InvoiceFilter.payout:
        return inv.type == InvoiceType.payout;
      case InvoiceFilter.earnings:
        return inv.type == InvoiceType.earnings;
    }
  }
}

/// Reactive filter (kept in memory). Reset when the user switches roles.
final invoicesFilterProvider = StateProvider<InvoiceFilter>(
  (_) => InvoiceFilter.all,
);

/// Accumulated list of invoices across pages + paging metadata.
@immutable
class InvoicesState {
  const InvoicesState({
    required this.invoices,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.isLoadingMore,
  });

  final List<Invoice> invoices;
  final int page;
  final int totalPages;
  final int totalCount;
  final bool isLoadingMore;

  bool get hasNextPage => page < totalPages;

  InvoicesState copyWith({
    List<Invoice>? invoices,
    int? page,
    int? totalPages,
    int? totalCount,
    bool? isLoadingMore,
  }) => InvoicesState(
    invoices: invoices ?? this.invoices,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    totalCount: totalCount ?? this.totalCount,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  static const InvoicesState empty = InvoicesState(
    invoices: [],
    page: 0,
    totalPages: 1,
    totalCount: 0,
    isLoadingMore: false,
  );
}

/// Async controller for the role-aware invoices feed.
///
/// - Auto-detects the **role** from [currentWayoAdsAccountRoleProvider] (creator → creator
///   endpoint, advertiser → advertiser endpoint).
/// - Holds **accumulated** pages so the UI can render `load more` without re-fetching.
/// - [refresh] resets to page 1 (used by pull-to-refresh and realtime invalidation).
/// - [loadNext] fetches the next page and merges.
class InvoicesController extends AsyncNotifier<InvoicesState> {
  late final InvoicesRepository _repo;

  @override
  Future<InvoicesState> build() async {
    _repo = ref.read(invoicesRepositoryProvider);
    // Re-run when role is resolved or changes (advertiser ↔ creator).
    ref.watch(currentWayoAdsAccountRoleProvider);
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    if (role == WayoAdsAccountRole.unknown) {
      return InvoicesState.empty;
    }
    if (role == WayoAdsAccountRole.creator) {
      return InvoicesState.empty;
    }
    try {
      return await _fetchPage(1, accumulated: const []);
    } catch (e, st) {
      Error.throwWithStackTrace(InvoicesRepository.mapError(e), st);
    }
  }

  /// Pull-to-refresh / realtime invalidation. Keeps the current loading state
  /// optimistic-soft (data stays visible while we re-fetch).
  Future<void> refresh() async {
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    if (role == WayoAdsAccountRole.creator) {
      return;
    }
    final previous = state.valueOrNull ?? InvoicesState.empty;
    state = AsyncValue<InvoicesState>.data(
      previous.copyWith(isLoadingMore: false),
    );
    try {
      final next = await _fetchPage(1, accumulated: const []);
      state = AsyncValue<InvoicesState>.data(next);
    } catch (e, st) {
      state = AsyncValue<InvoicesState>.error(InvoicesRepository.mapError(e), st);
    }
  }

  /// Fetch the next page and append.
  Future<void> loadNext() async {
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    if (role == WayoAdsAccountRole.creator) {
      return;
    }
    final current = state.valueOrNull;
    if (current == null || !current.hasNextPage || current.isLoadingMore) {
      return;
    }
    state = AsyncValue<InvoicesState>.data(
      current.copyWith(isLoadingMore: true),
    );
    try {
      final merged = await _fetchPage(
        current.page + 1,
        accumulated: current.invoices,
      );
      state = AsyncValue<InvoicesState>.data(merged);
    } catch (e, st) {
      // Roll back the loading flag; keep the data visible.
      state = AsyncValue<InvoicesState>.data(
        current.copyWith(isLoadingMore: false),
      );
      state = AsyncValue<InvoicesState>.error(
        InvoicesRepository.mapError(e),
        st,
      );
    }
  }

  Future<InvoicesState> _fetchPage(
    int page, {
    required List<Invoice> accumulated,
  }) async {
    // Always read the role at fetch time — do not cache from an earlier [build]
    // (the first build may have seen [WayoAdsAccountRole.unknown] before JWT
    // / profile resolved; [refresh] must then still use the real role).
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    final InvoicesPage result;
    switch (role) {
      case WayoAdsAccountRole.advertiser:
      case WayoAdsAccountRole.superAdmin:
        result = await _repo.loadAdvertiserPage(page: page);
        break;
      case WayoAdsAccountRole.creator:
        return InvoicesState(
          invoices: accumulated,
          page: 1,
          totalPages: 1,
          totalCount: accumulated.length,
          isLoadingMore: false,
        );
      case WayoAdsAccountRole.user:
      case WayoAdsAccountRole.unknown:
        return InvoicesState.empty;
    }
    // De-dupe by id to keep paging idempotent under realtime invalidation.
    final byId = <String, Invoice>{
      for (final inv in accumulated) inv.id: inv,
    };
    for (final inv in result.invoices) {
      byId[inv.id] = inv;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return InvoicesState(
      invoices: merged,
      page: result.page,
      totalPages: result.totalPages,
      totalCount: result.totalCount,
      isLoadingMore: false,
    );
  }
}

final invoicesControllerProvider =
    AsyncNotifierProvider<InvoicesController, InvoicesState>(
      InvoicesController.new,
    );

/// Derived: filtered invoices according to [invoicesFilterProvider].
final filteredInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  final filter = ref.watch(invoicesFilterProvider);
  return ref
      .watch(invoicesControllerProvider)
      .whenData((s) => s.invoices.where(filter.matches).toList());
});

/// Derived: KPIs for the hero card.
@immutable
class InvoicesKpis {
  const InvoicesKpis({
    required this.totalPaidCents,
    required this.pendingCount,
    required this.count,
    required this.currency,
  });

  final int totalPaidCents;
  final int pendingCount;
  final int count;
  final String currency;
}

final invoicesKpisProvider = Provider<AsyncValue<InvoicesKpis>>((ref) {
  return ref.watch(invoicesControllerProvider).whenData((s) {
    var totalPaid = 0;
    var pending = 0;
    String currency = 'EUR';
    for (final inv in s.invoices) {
      currency = inv.currency;
      if (inv.status == InvoiceStatus.paid) {
        totalPaid += inv.totalAmountCents;
      } else if (inv.status == InvoiceStatus.pending) {
        pending += 1;
      }
    }
    return InvoicesKpis(
      totalPaidCents: totalPaid,
      pendingCount: pending,
      count: s.invoices.length,
      currency: currency,
    );
  });
});

/// Periodic foreground polling helper (every 60s while screen is mounted & app foreground).
class InvoicesPollingController extends Notifier<bool> {
  Timer? _timer;
  bool _appPaused = false;

  @override
  bool build() {
    ref.onDispose(stop);
    return false;
  }

  void start() {
    _timer?.cancel();
    state = true;
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_appPaused) return;
      // Soft refresh — never overwrites a partial pagination.
      ref.read(invoicesControllerProvider.notifier).refresh();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = false;
  }

  void onAppLifecyclePaused() {
    _appPaused = true;
  }

  void onAppLifecycleResumed() {
    _appPaused = false;
    // Immediate refresh on resume so the user sees fresh data without waiting 60s.
    if (state) {
      ref.read(invoicesControllerProvider.notifier).refresh();
    }
  }
}

final invoicesPollingProvider =
    NotifierProvider<InvoicesPollingController, bool>(
      InvoicesPollingController.new,
    );
