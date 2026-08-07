import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/campaigns/campaign_explorer_layout.dart';
import '../../../../core/campaigns/campaign_marketplace_facets.dart';
import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/campaigns/campaigns_explorer_toolbar_expanded_provider.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/riverpod/defer_after_build.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../core/widgets/campaigns_explorer_toolbar.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/domain/entities/campaign_status.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';
import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/advertiser_campaign.dart';
import '../../domain/advertiser_campaign_status_counts.dart';
import '../../domain/campaign_niche_catalog.dart';
import '../../domain/campaign_status_actions.dart';
import '../providers/advertiser_campaigns_providers.dart';
import '../theme/advertiser_campaigns_chrome.dart';
import '../widgets/advertiser_browse_campaigns_view.dart';
import '../widgets/advertiser_campaign_card.dart';
import '../widgets/advertiser_campaign_explorer_filters.dart';
import '../widgets/advertiser_campaign_grid_tile.dart';

Future<void> _runCampaignStatus(
  BuildContext context,
  WidgetRef ref, {
  required String campaignId,
  required String apiStatus,
  bool destructive = false,
}) async {
  final a = context.t.advertiser_campaigns.actions;
  if (destructive) {
    final ok = await showWayoDialog<bool>(
      context: context,
      builder: (ctx) => WayoAlertDialog(
        title: Text(a.cancel_confirm_title),
        content: Text(a.cancel_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(a.dismiss),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(a.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }
  try {
    await ref
        .read(advertiserCampaignsRepositoryProvider)
        .setCampaignStatus(campaignId, apiStatus);
    ref.invalidate(advertiserCampaignsPagedProvider);
    ref.invalidate(advertiserCampaignsCountsProvider);
    ref.invalidate(advertiserCampaignDetailProvider(campaignId));
    if (context.mounted) {
      WayoToast.success(context, a.status_updated);
    }
  } catch (e) {
    if (!context.mounted) return;
    final msg = e is AuthException ? e.toString() : a.status_error;
    WayoToast.error(context, msg.isEmpty ? a.status_error : msg);
  }
}

String _moneyLocale(AppLocale l) => wayoPublicMoneyLocale(l);

void _sanitizeAdvertiserExplorerFilters(
  WidgetRef ref,
  CampaignMarketplaceFacets facets,
) {
  deferAfterBuild(() {
    var tSel = ref.read(advertiserCampaignExplorerTypeFilterProvider);
    final typeSet = marketplaceTypesFromFacets(facets);
    if (tSel != null && typeSet.isNotEmpty && !typeSet.contains(tSel)) {
      ref.read(advertiserCampaignExplorerTypeFilterProvider.notifier).state =
          null;
    }

    final nSel = ref.read(advertiserCampaignExplorerNicheProvider);
    if (nSel != null && nSel.isNotEmpty && facets.activeNiches.isNotEmpty) {
      final want = normalizeCampaignNicheApiValue(nSel);
      if (want != null &&
          !facets.activeNiches
              .map(normalizeCampaignNicheApiValue)
              .whereType<String>()
              .contains(want)) {
        ref.read(advertiserCampaignExplorerNicheProvider.notifier).state = null;
      }
    }

    final lSel = ref.read(advertiserCampaignExplorerLocationProvider);
    if (lSel != null && lSel.isNotEmpty && facets.activeCountries.isNotEmpty) {
      final wantLoc = normalizeCampaignLocationValue(lSel);
      if (wantLoc != null &&
          !facets.activeCountries
              .map(normalizeCampaignLocationValue)
              .whereType<String>()
              .contains(wantLoc)) {
        ref.read(advertiserCampaignExplorerLocationProvider.notifier).state =
            null;
      }
    }
  });
}

AdvertiserCampaignsPagedKey _mineCampaignsPagedKey(WidgetRef ref) {
  final type = ref.read(advertiserCampaignExplorerTypeFilterProvider);
  final niche = ref.read(advertiserCampaignExplorerNicheProvider);
  final location = ref.read(advertiserCampaignExplorerLocationProvider);
  return (
    tab: ref.read(advertiserCampaignsTabProvider),
    page: ref.read(advertiserCampaignsPageIndexProvider),
    search: ref.read(advertiserCampaignsSearchQueryProvider),
    typeApi: marketplaceTypeApiFromFilter(type),
    nicheApi: niche != null && niche.isNotEmpty
        ? normalizeCampaignNicheApiValue(niche)
        : null,
    countryApi: marketplaceCountryApiFromLocation(location),
  );
}

/// Page background — aligned with campaign detail premium palette.
BoxDecoration _campaignsPageBackground(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return BoxDecoration(color: AdvertiserCampaignsChrome.bg(context));
  }
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [scheme.surface, scheme.surfaceContainerLow],
    ),
  );
}

/// Advertiser campaigns — list, filters, and search (Wayo-ads API).
class AdvertiserCampaignsScreen extends ConsumerStatefulWidget {
  const AdvertiserCampaignsScreen({super.key});

  @override
  ConsumerState<AdvertiserCampaignsScreen> createState() =>
      _AdvertiserCampaignsScreenState();
}

class _AdvertiserCampaignsScreenState
    extends ConsumerState<AdvertiserCampaignsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String? _lastRouteViewParam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyViewFromRoute());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route query can change during rebuild — never write Riverpod mid-build.
    deferAfterBuild(() {
      if (mounted) _applyViewFromRoute();
    });
  }

  /// Deep links: `/campaigns?view=browse` opens the marketplace segment.
  void _applyViewFromRoute() {
    final view = GoRouterState.of(context).uri.queryParameters['view'];
    if (view == _lastRouteViewParam) return;
    _lastRouteViewParam = view;
    if (view == 'browse') {
      ref.read(advertiserCampaignsViewModeProvider.notifier).state =
          AdvertiserCampaignsViewMode.browse;
    } else if (view == 'mine') {
      ref.read(advertiserCampaignsViewModeProvider.notifier).state =
          AdvertiserCampaignsViewMode.mine;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _scheduleSearchDebounce(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      ref.read(advertiserCampaignsPageIndexProvider.notifier).state = 1;
      ref.read(advertiserCampaignsSearchQueryProvider.notifier).state = raw;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final viewMode = ref.watch(advertiserCampaignsViewModeProvider);

    return Scaffold(
      floatingActionButton: viewMode == AdvertiserCampaignsViewMode.mine
          ? FloatingActionButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                HapticFeedback.mediumImpact();
                context.push('/advertiser/campaigns/new');
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: DecoratedBox(
        decoration: _campaignsPageBackground(context),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SegmentedButton<AdvertiserCampaignsViewMode>(
                  segments: [
                    ButtonSegment(
                      value: AdvertiserCampaignsViewMode.mine,
                      label: Text(t.advertiser_campaigns.view_mine),
                      icon: const Icon(Icons.folder_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AdvertiserCampaignsViewMode.browse,
                      label: Text(t.advertiser_campaigns.view_browse),
                      icon: const Icon(Icons.explore_outlined, size: 18),
                    ),
                  ],
                  selected: {viewMode},
                  onSelectionChanged: (next) {
                    HapticFeedback.selectionClick();
                    ref
                            .read(advertiserCampaignsViewModeProvider.notifier)
                            .state =
                        next.first;
                  },
                ),
              ),
              Expanded(
                child: viewMode == AdvertiserCampaignsViewMode.browse
                    ? const AdvertiserBrowseCampaignsView()
                    : _MineCampaignsBody(
                        searchCtrl: _searchCtrl,
                        debounceCancel: () => _debounce?.cancel(),
                        onScheduleSearch: _scheduleSearchDebounce,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MineCampaignsBody extends ConsumerWidget {
  const _MineCampaignsBody({
    required this.searchCtrl,
    required this.debounceCancel,
    required this.onScheduleSearch,
  });

  final TextEditingController searchCtrl;
  final VoidCallback debounceCancel;
  final void Function(String) onScheduleSearch;

  String _errorMessage(BuildContext context, Object e) {
    final t = context.t;
    if (e is NetworkException) {
      return t.errors.network;
    }
    if (e is ServerException) {
      return e.message.isNotEmpty ? e.message : t.errors.server_generic;
    }
    return t.errors.server_generic;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final tab = ref.watch(advertiserCampaignsTabProvider);
    final pageIdx = ref.watch(advertiserCampaignsPageIndexProvider);
    final searchQ = ref.watch(advertiserCampaignsSearchQueryProvider);
    ref.watch(advertiserCampaignExplorerTypeFilterProvider);
    ref.watch(advertiserCampaignExplorerNicheProvider);
    ref.watch(advertiserCampaignExplorerLocationProvider);
    final key = _mineCampaignsPagedKey(ref);
    final pageAsync = ref.watch(advertiserCampaignsPagedProvider(key));
    final countsAsync = ref.watch(advertiserCampaignsCountsProvider);

    ref.listen(chatPostLoginGateProvider, (previous, gateAt) {
      if (gateAt == null) return;
      scheduleSessionRetryAfterBootstrap(ref, () {
        if (ref.read(advertiserCampaignsPagedProvider(key)).hasError) {
          ref.invalidate(advertiserCampaignsPagedProvider);
        }
        if (ref.read(advertiserCampaignsCountsProvider).hasError) {
          ref.invalidate(advertiserCampaignsCountsProvider);
        }
      });
    });

    ref.listen(advertiserCampaignsPagedProvider(key), (previous, next) {
      next.whenData((r) => _sanitizeAdvertiserExplorerFilters(ref, r.facets));
      next.whenOrNull(
        error: (e, _) {
          if (!shouldSuppressSessionLoadError(ref, e)) return;
          scheduleSessionRetryAfterBootstrap(ref, () {
            ref.invalidate(advertiserCampaignsPagedProvider(key));
          });
        },
      );
    });

    Future<void> refresh() async {
      ref.invalidate(advertiserCampaignsPagedProvider);
      await ref.read(
        advertiserCampaignsPagedProvider(_mineCampaignsPagedKey(ref)).future,
      );
    }

    final cachedPage = pageAsync.valueOrNull;
    final cachedCounts =
        countsAsync.valueOrNull ?? const AdvertiserCampaignStatusCounts();

    Widget buildBody({
      required List<AdvertiserCampaign> campaigns,
      required int totalPages,
      required int total,
      required CampaignMarketplaceFacets facets,
    }) {
      return _Body(
        campaigns: campaigns,
        totalPages: totalPages,
        total: total,
        facets: facets,
        currentPage: pageIdx,
        counts: cachedCounts,
        tab: tab,
        searchCtrl: searchCtrl,
        searchQ: searchQ,
        moneyLocale: moneyLocale,
        onTab: (v) {
          ref.read(advertiserCampaignsTabProvider.notifier).state = v;
          ref.read(advertiserCampaignsPageIndexProvider.notifier).state = 1;
        },
        onSearchChanged: onScheduleSearch,
        onClearSearch: () {
          debounceCancel();
          searchCtrl.clear();
          ref.read(advertiserCampaignsPageIndexProvider.notifier).state = 1;
          ref.read(advertiserCampaignsSearchQueryProvider.notifier).state = '';
        },
        onRefresh: refresh,
        onPagePrevious: pageIdx > 1
            ? () {
                HapticFeedback.selectionClick();
                ref.read(advertiserCampaignsPageIndexProvider.notifier).state =
                    pageIdx - 1;
              }
            : null,
        onPageNext: pageIdx < totalPages
            ? () {
                HapticFeedback.selectionClick();
                ref.read(advertiserCampaignsPageIndexProvider.notifier).state =
                    pageIdx + 1;
              }
            : null,
      );
    }

    if (cachedPage != null) {
      return buildBody(
        campaigns: cachedPage.campaigns,
        totalPages: cachedPage.totalPages,
        total: cachedPage.total,
        facets: cachedPage.facets,
      );
    }

    return pageAsync.when(
      data: (pageResult) => buildBody(
        campaigns: pageResult.campaigns,
        totalPages: pageResult.totalPages,
        total: pageResult.total,
        facets: pageResult.facets,
      ),
      loading: () => _LoadingShell(t: t),
      error: (e, _) {
        if (shouldSuppressSessionLoadError(ref, e)) {
          return _LoadingShell(t: t);
        }
        return _ErrorShell(
          t: t,
          message: _errorMessage(context, e),
          onRetry: () {
            ref.invalidate(advertiserCampaignsPagedProvider);
          },
        );
      },
    );
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _HeaderBlock(t: t)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Skeletonizer(
              enabled: true,
              child: Column(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 212,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedOf(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorShell extends StatelessWidget {
  const _ErrorShell({
    required this.t,
    required this.message,
    required this.onRetry,
  });

  final Translations t;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _HeaderBlock(t: t),
        const SizedBox(height: 16),
        ErrorBanner(
          message: message,
          retryLabel: t.dashboard.errors.retry,
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.campaigns,
    required this.totalPages,
    required this.total,
    required this.facets,
    required this.currentPage,
    required this.counts,
    required this.tab,
    required this.searchCtrl,
    required this.searchQ,
    required this.moneyLocale,
    required this.onTab,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onPagePrevious,
    required this.onPageNext,
  });

  final List<AdvertiserCampaign> campaigns;
  final int totalPages;
  final int total;
  final CampaignMarketplaceFacets facets;
  final int currentPage;
  final AdvertiserCampaignStatusCounts counts;
  final AdvertiserCampaignsTab tab;
  final TextEditingController searchCtrl;
  final String searchQ;
  final String moneyLocale;
  final void Function(AdvertiserCampaignsTab) onTab;
  final void Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onRefresh;
  final VoidCallback? onPagePrevious;
  final VoidCallback? onPageNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final layout = ref.watch(advertiserCampaignExplorerLayoutProvider);
    final toolbarExpanded = ref.watch(campaignsExplorerToolbarExpandedProvider);
    final typeF = ref.watch(advertiserCampaignExplorerTypeFilterProvider);
    final nicheF = ref.watch(advertiserCampaignExplorerNicheProvider);
    final locF = ref.watch(advertiserCampaignExplorerLocationProvider);

    final pagedKey = _mineCampaignsPagedKey(ref);
    ref.listen(advertiserCampaignsPagedProvider(pagedKey), (prev, next) {
      next.whenData((r) => _sanitizeAdvertiserExplorerFilters(ref, r.facets));
    });

    void resetPageToFirst() {
      ref.read(advertiserCampaignsPageIndexProvider.notifier).state = 1;
    }

    void resetAllExplorerFilters() {
      resetPageToFirst();
      ref.read(advertiserCampaignExplorerTypeFilterProvider.notifier).state =
          null;
      ref.read(advertiserCampaignExplorerNicheProvider.notifier).state = null;
      ref.read(advertiserCampaignExplorerLocationProvider.notifier).state =
          null;
      _sanitizeAdvertiserExplorerFilters(ref, facets);
    }

    final countText = total == 0 && campaigns.isEmpty
        ? '…'
        : (total == 1
              ? t.campaigns_explorer.results_one
              : t.campaigns_explorer.results_many(n: total));

    void pushDetail(AdvertiserCampaign c) {
      FocusManager.instance.primaryFocus?.unfocus();
      context.push(
        '/campaigns/${c.id}',
        extra: <String, String?>{'title': c.name},
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: CustomScrollView(
          key: ValueKey<CampaignExplorerLayout>(layout),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _HeaderBlock(t: t)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: CampaignsExplorerToolbar(
                  searchField: Semantics(
                    label: t.campaigns_explorer.search_aria,
                    child: _SearchField(
                      controller: searchCtrl,
                      onChanged: onSearchChanged,
                      onClear: onClearSearch,
                    ),
                  ),
                  filtersExpanded: toolbarExpanded,
                  onFiltersExpandedChanged: (v) =>
                      ref
                              .read(
                                campaignsExplorerToolbarExpandedProvider
                                    .notifier,
                              )
                              .state =
                          v,
                  filterScrollContent: AdvertiserCampaignExplorerFilters(
                    campaigns: campaigns,
                    facets: facets,
                    t: t,
                    statusTab: tab,
                    statusCounts: counts,
                    onStatusChanged: (v) {
                      resetPageToFirst();
                      onTab(v);
                    },
                    typeFilter: typeF,
                    nicheFilter: nicheF,
                    locationFilter: locF,
                    onTypeChanged: (v) {
                      resetPageToFirst();
                      ref
                              .read(
                                advertiserCampaignExplorerTypeFilterProvider
                                    .notifier,
                              )
                              .state =
                          v;
                      _sanitizeAdvertiserExplorerFilters(ref, facets);
                    },
                    onNicheChanged: (v) {
                      resetPageToFirst();
                      ref
                          .read(
                            advertiserCampaignExplorerNicheProvider.notifier,
                          )
                          .state = v == null
                          ? null
                          : normalizeCampaignNicheApiValue(v);
                      _sanitizeAdvertiserExplorerFilters(ref, facets);
                    },
                    onLocationChanged: (v) {
                      resetPageToFirst();
                      ref
                          .read(
                            advertiserCampaignExplorerLocationProvider.notifier,
                          )
                          .state = v == null
                          ? null
                          : normalizeCampaignLocationValue(v);
                      _sanitizeAdvertiserExplorerFilters(ref, facets);
                    },
                  ),
                  onResetExplorerFilters:
                      campaigns.isNotEmpty || !facets.isEmpty
                      ? resetAllExplorerFilters
                      : null,
                  resultCountText: countText,
                  layout: layout,
                  onLayoutChanged: (v) =>
                      ref
                              .read(
                                advertiserCampaignExplorerLayoutProvider
                                    .notifier,
                              )
                              .state =
                          v,
                ),
              ),
            ),
            if (campaigns.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  hasSearch:
                      searchQ.trim().isNotEmpty ||
                      typeF != null ||
                      (nicheF?.isNotEmpty ?? false) ||
                      (locF?.isNotEmpty ?? false),
                ),
              )
            else if (layout == CampaignExplorerLayout.grid) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // Taller cells: 2-line titles + budget row without clipping.
                    childAspectRatio: 0.56,
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final c = campaigns[i];
                    return AdvertiserCampaignGridTile(
                      campaign: c,
                      moneyLocale: moneyLocale,
                      gridIndex: i,
                      onTap: () => pushDetail(c),
                    );
                  }, childCount: campaigns.length),
                ),
              ),
              if (totalPages > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: _AdvertiserCampaignPaginationBar(
                      page: currentPage,
                      totalPages: totalPages,
                      previousLabel: t.dashboard.campaigns.pagination_previous,
                      nextLabel: t.dashboard.campaigns.pagination_next,
                      pageLabel: (cur, tot) => t.dashboard.campaigns
                          .pagination_page(current: cur, total: tot),
                      onPrevious: onPagePrevious,
                      onNext: onPageNext,
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ] else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    if (i < campaigns.length) {
                      final c = campaigns[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AdvertiserCampaignCard(
                          campaign: c,
                          moneyLocale: moneyLocale,
                          listIndex: i,
                          onTap: () => pushDetail(c),
                          onEdit: campaignAllowsOwnerEdit(c.status)
                              ? () => context.push(
                                    '/advertiser/campaigns/${c.id}/edit',
                                  )
                              : null,
                          onPause: c.status == CampaignStatus.active
                              ? () => _runCampaignStatus(
                                    context,
                                    ref,
                                    campaignId: c.id,
                                    apiStatus: 'PAUSED',
                                  )
                              : null,
                          onResume: c.status == CampaignStatus.paused
                              ? () => _runCampaignStatus(
                                    context,
                                    ref,
                                    campaignId: c.id,
                                    apiStatus: 'ACTIVE',
                                  )
                              : null,
                          onCancel: c.status == CampaignStatus.active ||
                                  c.status == CampaignStatus.paused ||
                                  c.status == CampaignStatus.draft
                              ? () => _runCampaignStatus(
                                    context,
                                    ref,
                                    campaignId: c.id,
                                    apiStatus: 'CANCELLED',
                                    destructive: true,
                                  )
                              : null,
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: _AdvertiserCampaignPaginationBar(
                        page: currentPage,
                        totalPages: totalPages,
                        previousLabel:
                            t.dashboard.campaigns.pagination_previous,
                        nextLabel: t.dashboard.campaigns.pagination_next,
                        pageLabel: (cur, tot) => t.dashboard.campaigns
                            .pagination_page(current: cur, total: tot),
                        onPrevious: onPagePrevious,
                        onNext: onPageNext,
                      ),
                    );
                  }, childCount: campaigns.length + (totalPages > 1 ? 1 : 0)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdvertiserCampaignPaginationBar extends StatelessWidget {
  const _AdvertiserCampaignPaginationBar({
    required this.page,
    required this.totalPages,
    required this.previousLabel,
    required this.nextLabel,
    required this.pageLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final String previousLabel;
  final String nextLabel;
  final String Function(int current, int total) pageLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Material(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              TextButton(onPressed: onPrevious, child: Text(previousLabel)),
              Expanded(
                child: Text(
                  pageLabel(page, totalPages),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
              TextButton(onPressed: onNext, child: Text(nextLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.advertiser_campaigns.title,
                  style: AdvertiserCampaignsChrome.heroTitle(context),
                ),
                const SizedBox(height: 6),
                Text(
                  t.advertiser_campaigns.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AdvertiserCampaignsChrome.heroSubtitle(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Create uses the floating + button — keep header clean.
        ],
      ),
    );
  }
}

/// Focus-aware search chrome (amber border glow, tinted icon, inline clear).
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'advertiserCampaignsExplorerSearch')
      ..addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = AdvertiserCampaignsChrome.card(context);
    final amber = AdvertiserCampaignsChrome.amber(context);
    final hintColor = AppColors.textMutedOf(context);
    final hasFocus = _focusNode.hasFocus;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        final prefixColor = hasFocus ? amber : hintColor;
        final borderClr = hasFocus
            ? amber
            : AppColors.borderOf(
                context,
              ).withValues(alpha: isDark ? 0.35 : 0.9);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderClr, width: hasFocus ? 1.5 : 1),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: amber.withValues(alpha: isDark ? 0.22 : 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            onChanged: widget.onChanged,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: TextStyle(color: AppColors.textPrimaryOf(context)),
            cursorColor: amber,
            decoration: InputDecoration(
              hintText: t.advertiser_campaigns.search_placeholder,
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: prefixColor.withValues(alpha: hasFocus ? 1 : 0.9),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      onPressed: widget.onClear,
                      icon: Icon(
                        Icons.close_rounded,
                        color: hasFocus
                            ? amber.withValues(alpha: 0.9)
                            : hintColor,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.folder_open_rounded,
              size: 72,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch
                  ? t.advertiser_campaigns.empty.search
                  : t.advertiser_campaigns.empty.none,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium(
                context,
              ).copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? t.advertiser_campaigns.empty.search_hint
                  : t.advertiser_campaigns.empty.hint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge(context),
            ),
          ],
        ),
      ),
    );
  }
}
