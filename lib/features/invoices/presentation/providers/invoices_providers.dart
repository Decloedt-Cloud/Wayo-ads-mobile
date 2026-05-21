import 'dart:async';
import 'dart:math' as math;

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

String? _invoiceTypeForServer(WayoAdsAccountRole role, InvoiceFilter f) {
  switch (role) {
    case WayoAdsAccountRole.creator:
      switch (f) {
        case InvoiceFilter.payout:
          return 'PAYOUT';
        case InvoiceFilter.earnings:
          return 'EARNINGS';
        case InvoiceFilter.all:
        case InvoiceFilter.deposit:
        case InvoiceFilter.billing:
          return null;
      }
    case WayoAdsAccountRole.advertiser:
    case WayoAdsAccountRole.superAdmin:
      switch (f) {
        case InvoiceFilter.deposit:
          return 'DEPOSIT';
        case InvoiceFilter.billing:
          return 'BILLING';
        case InvoiceFilter.all:
        case InvoiceFilter.payout:
        case InvoiceFilter.earnings:
          return null;
      }
    case WayoAdsAccountRole.user:
    case WayoAdsAccountRole.unknown:
      return null;
  }
}

/// Reactive filter (kept in memory). Reset when the user switches roles.
final invoicesFilterProvider = StateProvider<InvoiceFilter>(
  (_) => InvoiceFilter.all,
);

final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');

final invoiceDateFromProvider = StateProvider<DateTime?>((ref) => null);

final invoiceDateToProvider = StateProvider<DateTime?>((ref) => null);

/// Accumulated list of invoices across pages + paging metadata.
@immutable
class InvoicesState {
  const InvoicesState({
    required this.invoices,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.isLoadingMore,
    this.advertiserStats,
    this.statsCurrency,
    this.creatorUsesClientPaging = false,
    this.creatorUiVisibleCount = 0,
  });

  final List<Invoice> invoices;
  final int page;
  final int totalPages;
  final int totalCount;
  final bool isLoadingMore;
  final AdvertiserInvoicesStats? advertiserStats;
  final String? statsCurrency;

  /// Creator: full list is loaded up front; [creatorUiVisibleCount] steps by 10 in the UI.
  final bool creatorUsesClientPaging;
  final int creatorUiVisibleCount;

  bool get hasNextPage {
    if (creatorUsesClientPaging) {
      return creatorUiVisibleCount < invoices.length;
    }
    return page < totalPages;
  }

  /// Footer / scroll UX: server pages (advertiser) or 10-row windows (creator).
  int get displayCurrentPage => creatorUsesClientPaging
      ? math.max(
          1,
          (math.min(creatorUiVisibleCount, invoices.length) + 9) ~/ 10,
        )
      : page;

  int get displayTotalPages => creatorUsesClientPaging
      ? math.max(1, (invoices.length + 9) ~/ 10)
      : totalPages;

  InvoicesState copyWith({
    List<Invoice>? invoices,
    int? page,
    int? totalPages,
    int? totalCount,
    bool? isLoadingMore,
    AdvertiserInvoicesStats? advertiserStats,
    String? statsCurrency,
    bool? creatorUsesClientPaging,
    int? creatorUiVisibleCount,
  }) => InvoicesState(
    invoices: invoices ?? this.invoices,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    totalCount: totalCount ?? this.totalCount,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    advertiserStats: advertiserStats ?? this.advertiserStats,
    statsCurrency: statsCurrency ?? this.statsCurrency,
    creatorUsesClientPaging: creatorUsesClientPaging ?? this.creatorUsesClientPaging,
    creatorUiVisibleCount: creatorUiVisibleCount ?? this.creatorUiVisibleCount,
  );

  static const InvoicesState empty = InvoicesState(
    invoices: [],
    page: 0,
    totalPages: 1,
    totalCount: 0,
    isLoadingMore: false,
    advertiserStats: null,
    statsCurrency: null,
    creatorUsesClientPaging: false,
    creatorUiVisibleCount: 0,
  );
}

/// Async controller for the role-aware invoices feed.
class InvoicesController extends AsyncNotifier<InvoicesState> {
  InvoicesRepository get _repo => ref.read(invoicesRepositoryProvider);

  @override
  Future<InvoicesState> build() async {
    ref.watch(currentWayoAdsAccountRoleProvider);
    ref.watch(invoicesFilterProvider);
    ref.watch(invoiceSearchQueryProvider);
    // Date range is updated from the invoices toolbar; call
    // `ref.invalidate(invoicesControllerProvider)` there so the list refetches
    // with `dateFrom` / `dateTo` query params (watching [DateTime?] here did not
    // reliably rebuild this [AsyncNotifier] across all navigation/modal flows).

    final role = ref.read(currentWayoAdsAccountRoleProvider);
    if (role == WayoAdsAccountRole.unknown) {
      return InvoicesState.empty;
    }
    try {
      return await _fetchPage(1, accumulated: const []);
    } catch (e, st) {
      Error.throwWithStackTrace(InvoicesRepository.mapError(e), st);
    }
  }

  Future<void> refresh() async {
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    if (role == WayoAdsAccountRole.unknown) {
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

  Future<void> loadNext() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNextPage || current.isLoadingMore) {
      return;
    }
    if (current.creatorUsesClientPaging) {
      final nextVisible = math.min(
        current.creatorUiVisibleCount + 10,
        current.invoices.length,
      );
      state = AsyncValue<InvoicesState>.data(
        current.copyWith(creatorUiVisibleCount: nextVisible, isLoadingMore: false),
      );
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
      state = AsyncValue<InvoicesState>.data(
        current.copyWith(isLoadingMore: false),
      );
      state = AsyncValue<InvoicesState>.error(
        InvoicesRepository.mapError(e),
        st,
      );
    }
  }

  static const int _creatorFetchBatch = 100;

  Future<InvoicesPage> _loadAllCreatorPages({
    required String? invoiceType,
    required String search,
    required DateTime? dateFrom,
    required DateTime? dateTo,
  }) async {
    final byId = <String, Invoice>{};
    late InvoicesPage last;
    var page = 1;
    while (true) {
      final chunk = await _repo.loadCreatorPage(
        page: page,
        limit: _creatorFetchBatch,
        invoiceType: invoiceType,
        search: search,
        dateFrom: dateFrom,
        dateTo: dateTo,
        sortBy: 'createdAt',
        sortDir: 'desc',
      );
      last = chunk;
      for (final inv in chunk.invoices) {
        byId[inv.id] = inv;
      }
      if (chunk.invoices.isEmpty) break;
      if (chunk.invoices.length < _creatorFetchBatch) break;
      if (page >= chunk.totalPages) break;
      page++;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return InvoicesPage(
      invoices: merged,
      page: 1,
      pageSize: last.pageSize,
      totalCount: merged.length,
      totalPages: math.max(1, (merged.length + 9) ~/ 10),
      currency: last.currency,
      advertiserStats: last.advertiserStats,
    );
  }

  Future<InvoicesState> _fetchPage(
    int page, {
    required List<Invoice> accumulated,
  }) async {
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    final filter = ref.read(invoicesFilterProvider);
    final InvoicesPage result;

    switch (role) {
      case WayoAdsAccountRole.creator:
        result = await _loadAllCreatorPages(
          invoiceType: _invoiceTypeForServer(role, filter),
          search: ref.read(invoiceSearchQueryProvider),
          dateFrom: ref.read(invoiceDateFromProvider),
          dateTo: ref.read(invoiceDateToProvider),
        );
        break;
      case WayoAdsAccountRole.advertiser:
      case WayoAdsAccountRole.superAdmin:
        result = await _repo.loadAdvertiserPage(
          page: page,
          limit: 15,
          invoiceType: _invoiceTypeForServer(role, filter),
          search: ref.read(invoiceSearchQueryProvider),
          dateFrom: ref.read(invoiceDateFromProvider),
          dateTo: ref.read(invoiceDateToProvider),
          sortBy: 'createdAt',
          sortDir: 'desc',
        );
        break;
      case WayoAdsAccountRole.user:
      case WayoAdsAccountRole.unknown:
        return InvoicesState.empty;
    }

    final byId = <String, Invoice>{
      for (final inv in accumulated) inv.id: inv,
    };
    for (final inv in result.invoices) {
      byId[inv.id] = inv;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final prev = accumulated.isEmpty ? null : state.valueOrNull;

    final creatorPaging = role == WayoAdsAccountRole.creator;
    final initialVisible = creatorPaging
        ? math.min(10, merged.length)
        : merged.length;

    return InvoicesState(
      invoices: merged,
      page: result.page,
      totalPages: result.totalPages,
      totalCount: result.totalCount,
      isLoadingMore: false,
      advertiserStats: result.advertiserStats ?? prev?.advertiserStats,
      statsCurrency: result.currency ?? prev?.statsCurrency,
      creatorUsesClientPaging: creatorPaging,
      creatorUiVisibleCount: initialVisible,
    );
  }
}

final invoicesControllerProvider =
    AsyncNotifierProvider<InvoicesController, InvoicesState>(
      InvoicesController.new,
    );

/// Server-side filters for both roles; list order preserved from API.
final filteredInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  return ref.watch(invoicesControllerProvider).whenData((s) {
    if (s.creatorUsesClientPaging) {
      final n = math.min(s.creatorUiVisibleCount, s.invoices.length);
      if (n <= 0) return const <Invoice>[];
      return s.invoices.take(n).toList(growable: false);
    }
    return s.invoices;
  });
});

/// Derived: KPIs for the hero card.
@immutable
class InvoicesKpis {
  const InvoicesKpis({
    required this.totalPaidCents,
    required this.thisMonthCents,
    required this.pendingCount,
    required this.count,
    required this.currency,
  });

  final int totalPaidCents;
  final int thisMonthCents;
  final int pendingCount;
  final int count;
  final String currency;
}

final invoicesKpisProvider = Provider<AsyncValue<InvoicesKpis>>((ref) {
  return ref.watch(invoicesControllerProvider).whenData((s) {
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    final filter = ref.watch(invoicesFilterProvider);
    final server = s.advertiserStats;
    final currency = s.statsCurrency ?? 'EUR';

    // Advertiser "Dépôts" / "Budget campagne": totals must match the filtered list,
    // not the account-wide KPI block returned by the API.
    final useAdvertiserFilteredKpis =
        (role == WayoAdsAccountRole.advertiser ||
            role == WayoAdsAccountRole.superAdmin) &&
        filter != InvoiceFilter.all;

    if (server != null && !useAdvertiserFilteredKpis) {
      var pending = 0;
      for (final inv in s.invoices) {
        if (inv.status == InvoiceStatus.pending) pending++;
      }
      return InvoicesKpis(
        totalPaidCents: server.totalPaidCents,
        thisMonthCents: server.totalThisMonthCents,
        pendingCount: pending,
        count: s.totalCount,
        currency: currency,
      );
    }

    var totalPaid = 0;
    var thisMonth = 0;
    var pending = 0;
    String c = currency;
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month);
    for (final inv in s.invoices) {
      c = inv.currency;
      if (inv.status == InvoiceStatus.paid ||
          inv.status == InvoiceStatus.validated) {
        totalPaid += inv.totalAmountCents;
        if (!inv.createdAt.toLocal().isBefore(startMonth)) {
          thisMonth += inv.totalAmountCents;
        }
      } else if (inv.status == InvoiceStatus.pending) {
        pending += 1;
      }
    }
    return InvoicesKpis(
      totalPaidCents: totalPaid,
      thisMonthCents: thisMonth,
      pendingCount: pending,
      count: useAdvertiserFilteredKpis ? s.totalCount : s.invoices.length,
      currency: c,
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
    if (state) {
      ref.read(invoicesControllerProvider.notifier).refresh();
    }
  }
}

final invoicesPollingProvider =
    NotifierProvider<InvoicesPollingController, bool>(
      InvoicesPollingController.new,
    );
