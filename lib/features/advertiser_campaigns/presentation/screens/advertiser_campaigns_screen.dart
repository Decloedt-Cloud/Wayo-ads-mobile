import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/campaigns/campaign_explorer_layout.dart';
import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/campaigns/campaigns_explorer_toolbar_expanded_provider.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/campaigns_explorer_toolbar.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../domain/advertiser_campaign.dart';
import '../../domain/campaign_niche_catalog.dart';
import '../providers/advertiser_campaigns_providers.dart';
import '../theme/advertiser_campaigns_chrome.dart';
import '../widgets/advertiser_campaign_card.dart';
import '../widgets/advertiser_campaign_explorer_filters.dart';
import '../widgets/advertiser_campaign_grid_tile.dart';

String _moneyLocale(AppLocale l) => wayoPublicMoneyLocale(l);

List<AdvertiserCampaign> _filterAdvertiserCampaigns(
  List<AdvertiserCampaign> raw,
  CreatorCampaignType? type,
  String? niche,
  String? location,
) {
  return raw.where((c) {
    if (type != null && c.campaignType != type) return false;
    if (niche != null &&
        niche.isNotEmpty &&
        normalizeCampaignNicheApiValue(c.niche) !=
            normalizeCampaignNicheApiValue(niche)) {
      return false;
    }
    if (location != null && location.isNotEmpty) {
      final cl = normalizeCampaignLocationValue(c.location);
      if (cl != normalizeCampaignLocationValue(location)) return false;
    }
    return true;
  }).toList();
}

void _sanitizeAdvertiserExplorerFilters(
  WidgetRef ref,
  List<AdvertiserCampaign> list,
) {
  var tSel = ref.read(advertiserCampaignExplorerTypeFilterProvider);

  if (tSel != null && !list.any((c) => c.campaignType == tSel)) {
    ref.read(advertiserCampaignExplorerTypeFilterProvider.notifier).state =
        null;
    tSel = null;
  }

  bool matchesType(AdvertiserCampaign c) {
    if (tSel != null && c.campaignType != tSel) return false;
    return true;
  }

  final nSel = ref.read(advertiserCampaignExplorerNicheProvider);
  if (nSel != null && nSel.isNotEmpty) {
    final want = normalizeCampaignNicheApiValue(nSel);
    if (want != null &&
        !list.any(
          (c) =>
              matchesType(c) &&
              normalizeCampaignNicheApiValue(c.niche) == want,
        )) {
      ref.read(advertiserCampaignExplorerNicheProvider.notifier).state = null;
    }
  }

  final lSel = ref.read(advertiserCampaignExplorerLocationProvider);
  final nicheAfter = ref.read(advertiserCampaignExplorerNicheProvider);
  if (lSel != null && lSel.isNotEmpty) {
    final wantLoc = normalizeCampaignLocationValue(lSel);
    final wantNiche = normalizeCampaignNicheApiValue(nicheAfter);
    if (wantLoc != null &&
        !list.any((c) {
          if (!matchesType(c)) return false;
          if (wantNiche != null &&
              normalizeCampaignNicheApiValue(c.niche) != wantNiche) {
            return false;
          }
          return normalizeCampaignLocationValue(c.location) == wantLoc;
        })) {
      ref.read(advertiserCampaignExplorerLocationProvider.notifier).state =
          null;
    }
  }
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
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final tab = ref.watch(advertiserCampaignsTabProvider);
    final pageIdx = ref.watch(advertiserCampaignsPageIndexProvider);
    final searchQ = ref.watch(advertiserCampaignsSearchQueryProvider);
    final key = (tab: tab, page: pageIdx, search: searchQ);
    final pageAsync = ref.watch(advertiserCampaignsPagedProvider(key));
    final countsAsync = ref.watch(advertiserCampaignsCountsProvider);
    Future<void> refresh() async {
      ref.invalidate(advertiserCampaignsPagedProvider);
      await ref.read(advertiserCampaignsPagedProvider(key).future);
    }

    final cachedPage = pageAsync.valueOrNull;
    final cachedCounts =
        countsAsync.valueOrNull ??
        (active: 0, draft: 0, paused: 0, completed: 0);

    Widget buildBody({
      required List<AdvertiserCampaign> campaigns,
      required int totalPages,
    }) {
      return _Body(
        campaigns: campaigns,
        totalPages: totalPages,
        currentPage: pageIdx,
        counts: cachedCounts,
        tab: tab,
        searchCtrl: _searchCtrl,
        searchQ: searchQ,
        moneyLocale: moneyLocale,
        onTab: (v) {
          ref.read(advertiserCampaignsTabProvider.notifier).state = v;
          ref.read(advertiserCampaignsPageIndexProvider.notifier).state = 1;
        },
        onSearchChanged: _scheduleSearchDebounce,
        onClearSearch: () {
          _debounce?.cancel();
          _searchCtrl.clear();
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

    return Scaffold(
      // Same as creator tab: default scaffold background (#0A0A0A) + no bottom SafeArea doubling
      // the shell’s nav reserve (avoids a tone seam above the floating pill / system gesture area).
      body: DecoratedBox(
        decoration: _campaignsPageBackground(context),
        child: SafeArea(
          bottom: false,
          child: cachedPage != null
              ? buildBody(
                  campaigns: cachedPage.campaigns,
                  totalPages: cachedPage.totalPages,
                )
              : pageAsync.when(
                  data: (pageResult) => buildBody(
                    campaigns: pageResult.campaigns,
                    totalPages: pageResult.totalPages,
                  ),
                  loading: () => _LoadingShell(t: t),
                  error: (e, _) => _ErrorShell(
                    t: t,
                    message: _errorMessage(context, e),
                    onRetry: () {
                      ref.invalidate(advertiserCampaignsPagedProvider);
                    },
                  ),
                ),
        ),
      ),
    );
  }

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
  final int currentPage;
  final ({int active, int draft, int paused, int completed}) counts;
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
    final filtered = _filterAdvertiserCampaigns(
      campaigns,
      typeF,
      nicheF,
      locF,
    );

    final pagedKey = (tab: tab, page: currentPage, search: searchQ);
    ref.listen(advertiserCampaignsPagedProvider(pagedKey), (prev, next) {
      next.whenData(
        (r) => _sanitizeAdvertiserExplorerFilters(ref, r.campaigns),
      );
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
      _sanitizeAdvertiserExplorerFilters(ref, campaigns);
    }

    final countText = filtered.isEmpty && campaigns.isEmpty
        ? '…'
        : (filtered.length == 1
              ? t.campaigns_explorer.results_one
              : t.campaigns_explorer.results_many(n: filtered.length));

    void pushDetail(AdvertiserCampaign c) {
      FocusManager.instance.primaryFocus?.unfocus();
      context.push(
        '/campaigns/${c.id}',
        extra: <String, String?>{
          'title': c.name,
        },
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
          children: [
            ...previous,
            ?current,
          ],
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
                onFiltersExpandedChanged: (v) => ref
                    .read(campaignsExplorerToolbarExpandedProvider.notifier)
                    .state = v,
                filterScrollContent: AdvertiserCampaignExplorerFilters(
                        campaigns: campaigns,
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
                          _sanitizeAdvertiserExplorerFilters(ref, campaigns);
                        },
                        onNicheChanged: (v) {
                          resetPageToFirst();
                          ref
                              .read(
                                advertiserCampaignExplorerNicheProvider
                                    .notifier,
                              )
                              .state = v == null
                              ? null
                              : normalizeCampaignNicheApiValue(v);
                          _sanitizeAdvertiserExplorerFilters(ref, campaigns);
                        },
                        onLocationChanged: (v) {
                          resetPageToFirst();
                          ref
                              .read(
                                advertiserCampaignExplorerLocationProvider
                                    .notifier,
                              )
                              .state = v == null
                              ? null
                              : normalizeCampaignLocationValue(v);
                          _sanitizeAdvertiserExplorerFilters(ref, campaigns);
                        },
                      ),
                onResetExplorerFilters:
                    campaigns.isNotEmpty ? resetAllExplorerFilters : null,
                resultCountText: countText,
                layout: layout,
                onLayoutChanged: (v) =>
                    ref
                            .read(
                              advertiserCampaignExplorerLayoutProvider.notifier,
                            )
                            .state =
                        v,
              ),
            ),
          ),
          if (campaigns.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(hasSearch: searchQ.trim().isNotEmpty),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_alt_off_rounded,
                        size: 56,
                        color: AppColors.textMutedOf(context),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t.campaigns_explorer.empty_filters,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineMedium(
                          context,
                        ).copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.advertiser_campaigns.empty.search_hint,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge(context),
                      ),
                    ],
                  ),
                ),
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
                  final c = filtered[i];
                  return AdvertiserCampaignGridTile(
                    campaign: c,
                    moneyLocale: moneyLocale,
                    gridIndex: i,
                    onTap: () => pushDetail(c),
                  );
                }, childCount: filtered.length),
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
                  if (i < filtered.length) {
                    final c = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AdvertiserCampaignCard(
                        campaign: c,
                        moneyLocale: moneyLocale,
                        listIndex: i,
                        onTap: () => pushDetail(c),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
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
                  );
                }, childCount: filtered.length + (totalPages > 1 ? 1 : 0)),
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
            : AppColors.borderOf(context).withValues(alpha: isDark ? 0.35 : 0.9);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderClr,
              width: hasFocus ? 1.5 : 1,
            ),
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
                      tooltip:
                          MaterialLocalizations.of(context).deleteButtonTooltip,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
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
