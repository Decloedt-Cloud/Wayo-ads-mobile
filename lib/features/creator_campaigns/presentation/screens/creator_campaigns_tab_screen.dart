import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/campaigns/campaign_explorer_layout.dart';
import '../../../../core/campaigns/campaign_marketplace_facets.dart';
import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/campaigns/campaigns_explorer_toolbar_expanded_provider.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/campaigns_explorer_toolbar.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';
import '../../../creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../../domain/creator_browse_campaign.dart';
import '../../domain/creator_browse_page_result.dart';
import '../providers/creator_campaigns_providers.dart';
import '../widgets/creator_browse_campaign_card.dart';
import '../widgets/creator_browse_campaign_grid_tile.dart';
import '../widgets/creator_browse_explorer_filters.dart';
import '../theme/creator_campaigns_chrome.dart';

String _moneyLocale(AppLocale l) => wayoPublicMoneyLocale(l);

void _sanitizeCreatorBrowseFilters(
  WidgetRef ref,
  CampaignMarketplaceFacets facets,
) {
  var tSel = ref.read(creatorCampaignExplorerTypeFilterProvider);
  final typeSet = marketplaceTypesFromFacets(facets);
  if (tSel != null && typeSet.isNotEmpty && !typeSet.contains(tSel)) {
    ref.read(creatorCampaignExplorerTypeFilterProvider.notifier).state = null;
    tSel = null;
  }

  final nSel = ref.read(creatorCampaignExplorerNicheProvider);
  if (nSel != null && nSel.isNotEmpty && facets.activeNiches.isNotEmpty) {
    final want = normalizeCampaignNicheApiValue(nSel);
    if (want != null &&
        !facets.activeNiches
            .map(normalizeCampaignNicheApiValue)
            .whereType<String>()
            .contains(want)) {
      ref.read(creatorCampaignExplorerNicheProvider.notifier).state = null;
    }
  }

  final lSel = ref.read(creatorCampaignExplorerLocationProvider);
  if (lSel != null && lSel.isNotEmpty && facets.activeCountries.isNotEmpty) {
    final wantLoc = normalizeCampaignLocationValue(lSel);
    if (wantLoc != null &&
        !facets.activeCountries
            .map(normalizeCampaignLocationValue)
            .whereType<String>()
            .contains(wantLoc)) {
      ref.read(creatorCampaignExplorerLocationProvider.notifier).state = null;
    }
  }
}

/// Creator **campaigns** tab — browse active campaigns and see the state
/// of applications you've already submitted.
///
/// Pull-to-refresh resets to page 1, invalidates both
/// [creatorBrowseCampaignsPagedProvider] and [creatorApplicationsProvider].
class CreatorCampaignsTabScreen extends ConsumerStatefulWidget {
  const CreatorCampaignsTabScreen({super.key});

  @override
  ConsumerState<CreatorCampaignsTabScreen> createState() =>
      _CreatorCampaignsTabScreenState();
}

class _CreatorCampaignsTabScreenState
    extends ConsumerState<CreatorCampaignsTabScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  // OPTIMIZATION: Removed _searchCtrl.addListener(() => setState(() {}))
  // _BrowseSearchField now uses ValueListenableBuilder internally.

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBrowseListToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleSearchQuery(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      ref.read(creatorBrowseCampaignPageProvider.notifier).state = 1;
      ref.read(creatorBrowseCampaignSearchQueryProvider.notifier).state = raw;
    });
  }

  CreatorBrowsePagedKey _browseKey() {
    final type = ref.read(creatorCampaignExplorerTypeFilterProvider);
    final niche = ref.read(creatorCampaignExplorerNicheProvider);
    final location = ref.read(creatorCampaignExplorerLocationProvider);
    return (
      page: ref.read(creatorBrowseCampaignPageProvider),
      search: ref.read(creatorBrowseCampaignSearchQueryProvider),
      typeApi: marketplaceTypeApiFromFilter(type),
      nicheApi: niche != null && niche.isNotEmpty
          ? normalizeCampaignNicheApiValue(niche)
          : null,
      countryApi: marketplaceCountryApiFromLocation(location),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final browsePage = ref.watch(creatorBrowseCampaignPageProvider);
    final searchQ = ref.watch(creatorBrowseCampaignSearchQueryProvider);
    final explorerLayout = ref.watch(creatorCampaignExplorerLayoutProvider);
    final toolbarExpanded = ref.watch(campaignsExplorerToolbarExpandedProvider);
    final typeFilter = ref.watch(creatorCampaignExplorerTypeFilterProvider);
    final nicheFilter = ref.watch(creatorCampaignExplorerNicheProvider);
    final locationFilter = ref.watch(creatorCampaignExplorerLocationProvider);
    final browseKey = _browseKey();
    final browseAsync = ref.watch(
      creatorBrowseCampaignsPagedProvider(browseKey),
    );
    final appsAsync = ref.watch(creatorApplicationsProvider);

    ref.listen(creatorBrowseCampaignsPagedProvider(browseKey), (prev, next) {
      next.whenData(
        (page) => _sanitizeCreatorBrowseFilters(ref, page.facets),
      );
      next.whenOrNull(
        error: (e, _) {
          if (!isTransientSessionError(e) &&
              !shouldSuppressCreatorLoadError(ref, e)) {
            return;
          }
          scheduleCreatorRetryAfterBootstrap(ref, () {
            if (!context.mounted) return;
            ref.invalidate(creatorBrowseCampaignsPagedProvider(browseKey));
          });
        },
      );
    });

    ref.listen(chatPostLoginGateProvider, (previous, gateAt) {
      if (gateAt == null) return;
      scheduleCreatorRetryAfterBootstrap(ref, () {
        if (!context.mounted) return;
        if (ref.read(creatorBrowseCampaignsPagedProvider(browseKey)).hasError) {
          ref.invalidate(creatorBrowseCampaignsPagedProvider(browseKey));
        }
        if (ref.read(creatorApplicationsProvider).hasError) {
          ref.invalidate(creatorApplicationsProvider);
        }
      });
    });

    ref.listen<int>(creatorBrowseCampaignPageProvider, (previous, next) {
      if (previous == null || previous == next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollBrowseListToTop();
      });
    });

    final cachedBrowsePage = browseAsync.valueOrNull;
    final browseFacets = cachedBrowsePage?.facets;
    final showExplorerFilters =
        browseFacets != null && !browseFacets.isEmpty ||
        (cachedBrowsePage?.campaigns.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: CreatorCampaignsChrome.bg(context),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
        color: CreatorCampaignsChrome.amber(context),
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.read(creatorBrowseCampaignPageProvider.notifier).state = 1;
          ref.invalidate(creatorBrowseCampaignsPagedProvider);
          ref.invalidate(creatorApplicationsProvider);
          await ref.read(creatorBrowseCampaignsPagedProvider(_browseKey()).future);
        },
        child: ListView(
          controller: _scrollController,
          cacheExtent: 640,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.creator.campaigns.browse_title,
                    style: CreatorCampaignsChrome.heroTitle(context),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.creator.campaigns.browse_subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CreatorCampaignsChrome.heroSubtitle(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CampaignsExplorerToolbar(
              searchField: Semantics(
                label: t.campaigns_explorer.search_aria,
                child: _BrowseSearchField(
                  controller: _searchCtrl,
                  onChanged: _scheduleSearchQuery,
                  onClear: () {
                    _debounce?.cancel();
                    _searchCtrl.clear();
                    ref.read(creatorBrowseCampaignPageProvider.notifier).state =
                        1;
                    ref
                            .read(
                              creatorBrowseCampaignSearchQueryProvider.notifier,
                            )
                            .state =
                        '';
                  },
                ),
              ),
              filtersExpanded: toolbarExpanded,
              onFiltersExpandedChanged: (v) => ref
                  .read(campaignsExplorerToolbarExpandedProvider.notifier)
                  .state = v,
              filterScrollContent: !showExplorerFilters
                  ? null
                  : CreatorBrowseExplorerFilters(
                      campaigns: cachedBrowsePage?.campaigns ?? const [],
                      facets: browseFacets,
                      t: t,
                      typeFilter: typeFilter,
                      nicheFilter: nicheFilter,
                      locationFilter: locationFilter,
                      onTypeChanged: (v) {
                        ref
                                .read(
                                  creatorBrowseCampaignPageProvider.notifier,
                                )
                                .state =
                            1;
                        ref
                                .read(
                                  creatorCampaignExplorerTypeFilterProvider
                                      .notifier,
                                )
                                .state =
                            v;
                        if (browseFacets != null) {
                          _sanitizeCreatorBrowseFilters(ref, browseFacets);
                        }
                      },
                      onNicheChanged: (v) {
                        ref
                                .read(
                                  creatorBrowseCampaignPageProvider.notifier,
                                )
                                .state =
                            1;
                        ref
                                .read(
                                  creatorCampaignExplorerNicheProvider.notifier,
                                )
                                .state = v == null
                                ? null
                                : normalizeCampaignNicheApiValue(v);
                        if (browseFacets != null) {
                          _sanitizeCreatorBrowseFilters(ref, browseFacets);
                        }
                      },
                      onLocationChanged: (v) {
                        ref
                                .read(
                                  creatorBrowseCampaignPageProvider.notifier,
                                )
                                .state =
                            1;
                        ref
                                .read(
                                  creatorCampaignExplorerLocationProvider
                                      .notifier,
                                )
                                .state = v == null
                                ? null
                                : normalizeCampaignLocationValue(v);
                        if (browseFacets != null) {
                          _sanitizeCreatorBrowseFilters(ref, browseFacets);
                        }
                      },
                    ),
              onResetExplorerFilters: !showExplorerFilters
                  ? null
                  : () {
                      ref
                          .read(creatorBrowseCampaignPageProvider.notifier)
                          .state = 1;
                      ref
                          .read(creatorCampaignExplorerTypeFilterProvider.notifier)
                          .state = null;
                      ref
                          .read(creatorCampaignExplorerNicheProvider.notifier)
                          .state = null;
                      ref
                          .read(
                            creatorCampaignExplorerLocationProvider.notifier,
                          )
                          .state = null;
                      if (browseFacets != null) {
                        _sanitizeCreatorBrowseFilters(ref, browseFacets);
                      }
                    },
              resultCountText: _browseCountLabel(browseAsync, t),
              layout: explorerLayout,
              onLayoutChanged: (v) =>
                  ref
                          .read(creatorCampaignExplorerLayoutProvider.notifier)
                          .state =
                      v,
            ),
            const SizedBox(height: 14),
            browseAsync.when(
              loading: () => const _LoadingBlock(),
              error: (err, _) {
                if (shouldSuppressCreatorLoadError(ref, err)) {
                  return const _LoadingBlock();
                }
                return _ErrorBlock(
                  message: t.creator.campaigns.load_error,
                  onRetry: () => ref.invalidate(
                    creatorBrowseCampaignsPagedProvider(browseKey),
                  ),
                );
              },
              data: (pageResult) {
                final list = pageResult.campaigns;
                final hasSearch = searchQ.trim().isNotEmpty;
                final hasFilters =
                    typeFilter != null ||
                    (nicheFilter?.isNotEmpty ?? false) ||
                    (locationFilter?.isNotEmpty ?? false);
                if (list.isEmpty) {
                  return _EmptyBrowseBlock(
                    title: hasSearch || hasFilters
                        ? t.creator.campaigns.browse_empty_search_title
                        : t.creator.campaigns.empty_title,
                    subtitle: hasSearch || hasFilters
                        ? t.creator.campaigns.browse_empty_search_subtitle
                        : t.creator.campaigns.empty_subtitle,
                  );
                }
                final statusByCampaign = <String, CreatorApplicationStatus>{};
                for (final a
                    in appsAsync.valueOrNull ?? const <CreatorApplication>[]) {
                  final existing = statusByCampaign[a.campaignId];
                  if (existing == null ||
                      _statusPriority(a.status) > _statusPriority(existing)) {
                    statusByCampaign[a.campaignId] = a.status;
                  }
                }
                final browseItems = <Widget>[
                  if (explorerLayout == CampaignExplorerLayout.grid)
                    _CreatorBrowseLazyGrid(
                      campaigns: list,
                      moneyLocale: moneyLocale,
                      statusByCampaign: statusByCampaign,
                      onOpen: (c) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        context.push(
                          '/creator/campaigns/${c.id}',
                          extra: <String, Object?>{'title': c.title},
                        );
                      },
                    )
                  else
                    _CreatorBrowseLazyList(
                      campaigns: list,
                      moneyLocale: moneyLocale,
                      statusByCampaign: statusByCampaign,
                      onOpen: (c) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        context.push(
                          '/creator/campaigns/${c.id}',
                          extra: <String, Object?>{'title': c.title},
                        );
                      },
                    ),
                  if (pageResult.totalPages > 1) ...[
                    const SizedBox(height: 6),
                    _BrowsePaginationBar(
                      page: browsePage,
                      totalPages: pageResult.totalPages,
                      previousLabel: t.creator.campaigns.pagination_previous,
                      nextLabel: t.creator.campaigns.pagination_next,
                      pageLabel: (cur, tot) => t.creator.campaigns
                          .pagination_page(current: cur, total: tot),
                      onPrevious: browsePage > 1
                          ? () {
                              HapticFeedback.selectionClick();
                              FocusManager.instance.primaryFocus?.unfocus();
                              ref
                                      .read(
                                        creatorBrowseCampaignPageProvider
                                            .notifier,
                                      )
                                      .state =
                                  browsePage - 1;
                            }
                          : null,
                      onNext: browsePage < pageResult.totalPages
                          ? () {
                              HapticFeedback.selectionClick();
                              FocusManager.instance.primaryFocus?.unfocus();
                              ref
                                      .read(
                                        creatorBrowseCampaignPageProvider
                                            .notifier,
                                      )
                                      .state =
                                  browsePage + 1;
                            }
                          : null,
                    ),
                  ],
                ];
                return Column(children: browseItems);
              },
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: t.creator.campaigns.applications_title,
              subtitle: t.creator.campaigns.applications_subtitle,
            ),
            const SizedBox(height: 12),
            appsAsync.when(
              loading: () => const _LoadingBlock(),
              error: (_, _) => _ErrorBlock(
                message: t.creator.applications.load_error,
                onRetry: () => ref.invalidate(creatorApplicationsProvider),
              ),
              data: (apps) {
                final active = apps
                    .where(
                      (a) =>
                          a.status == CreatorApplicationStatus.pending ||
                          a.status == CreatorApplicationStatus.approved,
                    )
                    .toList();
                if (active.isEmpty) {
                  return _EmptyBrowseBlock(
                    title: t.creator.applications.empty_title,
                    subtitle: t.creator.applications.empty_subtitle,
                  );
                }
                return Column(
                  children: [
                    for (final a in active) ...[
                      _ApplicationTile(
                        application: a,
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          context.push(
                            '/creator/campaigns/${a.campaignId}',
                            extra: <String, Object?>{
                              'title': a.campaignTitle,
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _browseCountLabel(
    AsyncValue<CreatorBrowsePageResult> browseAsync,
    Translations t,
  ) {
    final pageResult = browseAsync.valueOrNull;
    if (pageResult == null) return '…';
    final n = pageResult.total;
    return n == 1
        ? t.campaigns_explorer.results_one
        : t.campaigns_explorer.results_many(n: n);
  }
}

/// Focus-aware browse search (creator).
class _BrowseSearchField extends StatefulWidget {
  const _BrowseSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;

  @override
  State<_BrowseSearchField> createState() => _BrowseSearchFieldState();
}

class _BrowseSearchFieldState extends State<_BrowseSearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'creatorCampaignBrowseSearch')
      ..addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final amber = CreatorCampaignsChrome.amber(context);
    final fill = CreatorCampaignsChrome.card(context);
    final hintColor = AppColors.textMutedOf(context);
    final hasFocus = _focusNode.hasFocus;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        final prefixClr = hasFocus ? amber : hintColor;
        final borderClr = hasFocus ? amber : Colors.transparent;

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
            boxShadow: hasFocus && isDark
                ? [
                    BoxShadow(
                      color: amber.withValues(alpha: 0.2),
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
            textInputAction: TextInputAction.search,
            onSubmitted: widget.onChanged,
            style: TextStyle(color: AppColors.textPrimaryOf(context)),
            cursorColor: amber,
            decoration: InputDecoration(
              hintText: t.creator.campaigns.browse_search_placeholder,
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: prefixClr.withValues(alpha: hasFocus ? 1 : 0.92),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CreatorCampaignsChrome.sectionTitle(context),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: CreatorCampaignsChrome.bodyDm(context, size: 13),
        ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(
          color: CreatorCampaignsChrome.amber(context),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppTextStyles.bodyLarge(context)),
          ),
          TextButton(onPressed: onRetry, child: Text(t.dashboard.errors.retry)),
        ],
      ),
    );
  }
}

class _EmptyBrowseBlock extends StatelessWidget {
  const _EmptyBrowseBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: CreatorCampaignsChrome.card(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.explore_outlined,
            color: CreatorCampaignsChrome.amber(context),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style:
                CreatorCampaignsChrome.cardTitle(context).copyWith(fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: CreatorCampaignsChrome.bodyDm(
              context,
              size: 14,
              color: CreatorCampaignsChrome.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// When a creator has multiple applications for the same campaign (re-apply
/// flow), prefer showing the most meaningful status on the browse card.
int _statusPriority(CreatorApplicationStatus s) {
  return switch (s) {
    CreatorApplicationStatus.approved => 5,
    CreatorApplicationStatus.pending => 4,
    CreatorApplicationStatus.rejected => 3,
    CreatorApplicationStatus.withdrawn => 2,
    CreatorApplicationStatus.unknown => 1,
  };
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.application, required this.onTap});

  final CreatorApplication application;
  final VoidCallback onTap;

  Color _statusColor(BuildContext context, CreatorApplicationStatus s) {
    return switch (s) {
      CreatorApplicationStatus.approved => const Color(0xFF10B981),
      CreatorApplicationStatus.pending => const Color(0xFFF59E0B),
      CreatorApplicationStatus.rejected => Colors.red,
      CreatorApplicationStatus.withdrawn => AppColors.textSecondaryOf(context),
      CreatorApplicationStatus.unknown => AppColors.textSecondaryOf(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = application;
    final statusLabel = switch (a.status) {
      CreatorApplicationStatus.approved =>
        t.creator.applications.status_approved,
      CreatorApplicationStatus.pending => t.creator.applications.status_pending,
      CreatorApplicationStatus.rejected =>
        t.creator.applications.status_rejected,
      CreatorApplicationStatus.withdrawn =>
        t.creator.applications.status_withdrawn,
      CreatorApplicationStatus.unknown => t.creator.applications.status_unknown,
    };
    final color = _statusColor(context, a.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: CreatorCampaignsChrome.card(context),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  a.status == CreatorApplicationStatus.approved
                      ? Icons.verified_rounded
                      : Icons.timelapse_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.campaignTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CreatorCampaignsChrome.cardTitle(context).copyWith(
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(height: 3),
                    if (a.advertiserName != null &&
                        a.advertiserName!.isNotEmpty)
                      Text(
                        a.advertiserName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CreatorCampaignsChrome.bodyDm(context, size: 12),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowsePaginationBar extends StatelessWidget {
  const _BrowsePaginationBar({
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
    return Material(
      color: CreatorCampaignsChrome.card(context),
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
                style: AppTextStyles.labelLarge(
                  context,
                ).copyWith(color: AppColors.textSecondaryOf(context)),
              ),
            ),
            TextButton(onPressed: onNext, child: Text(nextLabel)),
          ],
        ),
      ),
    );
  }
}

/// Lazy 2-column grid rows — avoids building every tile when nested in [ListView].
class _CreatorBrowseLazyGrid extends StatelessWidget {
  const _CreatorBrowseLazyGrid({
    required this.campaigns,
    required this.moneyLocale,
    required this.statusByCampaign,
    required this.onOpen,
  });

  final List<CreatorBrowseCampaign> campaigns;
  final String moneyLocale;
  final Map<String, CreatorApplicationStatus> statusByCampaign;
  final void Function(CreatorBrowseCampaign campaign) onOpen;

  @override
  Widget build(BuildContext context) {
    final rowCount = (campaigns.length + 1) ~/ 2;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: rowCount,
      itemBuilder: (context, row) {
        final leftIndex = row * 2;
        final rightIndex = leftIndex + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CreatorBrowseCampaignGridTile(
                  campaign: campaigns[leftIndex],
                  moneyLocale: moneyLocale,
                  gridIndex: leftIndex,
                  applicationStatus:
                      statusByCampaign[campaigns[leftIndex].id],
                  onTap: () => onOpen(campaigns[leftIndex]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: rightIndex < campaigns.length
                    ? CreatorBrowseCampaignGridTile(
                        campaign: campaigns[rightIndex],
                        moneyLocale: moneyLocale,
                        gridIndex: rightIndex,
                        applicationStatus:
                            statusByCampaign[campaigns[rightIndex].id],
                        onTap: () => onOpen(campaigns[rightIndex]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lazy list cards — replaces eager `for` loops inside parent [ListView].
class _CreatorBrowseLazyList extends StatelessWidget {
  const _CreatorBrowseLazyList({
    required this.campaigns,
    required this.moneyLocale,
    required this.statusByCampaign,
    required this.onOpen,
  });

  final List<CreatorBrowseCampaign> campaigns;
  final String moneyLocale;
  final Map<String, CreatorApplicationStatus> statusByCampaign;
  final void Function(CreatorBrowseCampaign campaign) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: campaigns.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final c = campaigns[i];
        return CreatorBrowseCampaignCard(
          campaign: c,
          moneyLocale: moneyLocale,
          listIndex: i,
          applicationStatus: statusByCampaign[c.id],
          onTap: () => onOpen(c),
        );
      },
    );
  }
}
