import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../wallet/presentation/providers/advertiser_deposit_sync.dart';
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

enum InvoiceDatePreset { all, last30, last90, custom }

final invoiceDatePresetProvider = StateProvider<InvoiceDatePreset>(
  (_) => InvoiceDatePreset.all,
);

const int kCreatorInvoicesPageSize = 10;
const int kAdvertiserInvoicesPageSize = 10;

/// Creator and advertiser lists use server pages + prev/next (no infinite scroll).
bool invoicesUsePagedList(WayoAdsAccountRole role) {
  switch (role) {
    case WayoAdsAccountRole.creator:
    case WayoAdsAccountRole.advertiser:
    case WayoAdsAccountRole.superAdmin:
      return true;
    case WayoAdsAccountRole.user:
    case WayoAdsAccountRole.unknown:
      return false;
  }
}

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
    this.creatorStats,
    this.statsCurrency,
  });

  final List<Invoice> invoices;
  final int page;
  final int totalPages;
  final int totalCount;
  final bool isLoadingMore;
  final AdvertiserInvoicesStats? advertiserStats;
  final CreatorInvoicesStats? creatorStats;
  final String? statsCurrency;

  bool get hasNextPage => page < totalPages;

  int get displayCurrentPage => page;

  int get displayTotalPages => totalPages;

  InvoicesState copyWith({
    List<Invoice>? invoices,
    int? page,
    int? totalPages,
    int? totalCount,
    bool? isLoadingMore,
    AdvertiserInvoicesStats? advertiserStats,
    CreatorInvoicesStats? creatorStats,
    String? statsCurrency,
  }) => InvoicesState(
    invoices: invoices ?? this.invoices,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    totalCount: totalCount ?? this.totalCount,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    advertiserStats: advertiserStats ?? this.advertiserStats,
    creatorStats: creatorStats ?? this.creatorStats,
    statsCurrency: statsCurrency ?? this.statsCurrency,
  );

  static const InvoicesState empty = InvoicesState(
    invoices: [],
    page: 0,
    totalPages: 1,
    totalCount: 0,
    isLoadingMore: false,
    advertiserStats: null,
    creatorStats: null,
    statsCurrency: null,
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
    ref.watch(invoiceDateFromProvider);
    ref.watch(invoiceDateToProvider);

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
    syncAdvertiserPendingDepositFromInvoices(ref);
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
    state = AsyncValue<InvoicesState>.data(
      current.copyWith(isLoadingMore: true),
    );
    try {
      final role = ref.read(currentWayoAdsAccountRoleProvider);
      final replaceOnly = invoicesUsePagedList(role);
      final merged = await _fetchPage(
        current.page + 1,
        accumulated: replaceOnly ? const [] : current.invoices,
        replaceOnly: replaceOnly,
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

  /// Replace the list with the previous server page (creator / advertiser).
  Future<void> loadPrevious() async {
    final current = state.valueOrNull;
    if (current == null || current.page <= 1 || current.isLoadingMore) {
      return;
    }
    state = AsyncValue<InvoicesState>.data(
      current.copyWith(isLoadingMore: true),
    );
    try {
      final prev = await _fetchPage(
        current.page - 1,
        accumulated: const [],
        replaceOnly: true,
      );
      state = AsyncValue<InvoicesState>.data(prev);
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

  Future<InvoicesState> _fetchPage(
    int page, {
    required List<Invoice> accumulated,
    bool replaceOnly = false,
  }) async {
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    final filter = ref.read(invoicesFilterProvider);
    final InvoicesPage result;

    switch (role) {
      case WayoAdsAccountRole.creator:
        result = await _repo.loadCreatorPage(
          page: page,
          limit: kCreatorInvoicesPageSize,
          invoiceType: _invoiceTypeForServer(role, filter),
          search: ref.read(invoiceSearchQueryProvider),
          dateFrom: ref.read(invoiceDateFromProvider),
          dateTo: ref.read(invoiceDateToProvider),
          sortBy: 'createdAt',
          sortDir: 'desc',
        );
        break;
      case WayoAdsAccountRole.advertiser:
      case WayoAdsAccountRole.superAdmin:
        result = await _repo.loadAdvertiserPage(
          page: page,
          limit: kAdvertiserInvoicesPageSize,
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

    final List<Invoice> merged;
    if (replaceOnly || accumulated.isEmpty) {
      merged = List<Invoice>.from(result.invoices);
    } else {
      final byId = <String, Invoice>{
        for (final inv in accumulated) inv.id: inv,
      };
      for (final inv in result.invoices) {
        byId[inv.id] = inv;
      }
      merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final prev = accumulated.isEmpty ? null : state.valueOrNull;

    return InvoicesState(
      invoices: merged,
      page: result.page,
      totalPages: result.totalPages,
      totalCount: result.totalCount,
      isLoadingMore: false,
      advertiserStats: result.advertiserStats ?? prev?.advertiserStats,
      creatorStats: result.creatorStats ?? prev?.creatorStats,
      statsCurrency: result.currency ?? prev?.statsCurrency,
    );
  }
}

final invoicesControllerProvider =
    AsyncNotifierProvider<InvoicesController, InvoicesState>(
      InvoicesController.new,
    );

/// Server-side filters for both roles; list order preserved from API.
final filteredInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  return ref.watch(invoicesControllerProvider).whenData((s) => s.invoices);
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

    if (role == WayoAdsAccountRole.creator && s.creatorStats != null) {
      final cs = s.creatorStats!;
      return InvoicesKpis(
        totalPaidCents: cs.totalValidatedCents,
        thisMonthCents: cs.totalThisMonthCents,
        pendingCount: cs.pendingCount,
        count: s.totalCount,
        currency: currency,
      );
    }

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
