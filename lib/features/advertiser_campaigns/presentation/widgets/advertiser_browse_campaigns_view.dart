import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/campaigns/campaign_explorer_layout.dart';
import '../../../../core/campaigns/campaign_marketplace_facets.dart';
import '../../../../core/campaigns/campaigns_explorer_toolbar_expanded_provider.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/campaigns_explorer_toolbar.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../creator_campaigns/presentation/widgets/creator_browse_campaign_card.dart';
import '../../../creator_campaigns/presentation/widgets/creator_browse_campaign_grid_tile.dart';
import '../../../creator_campaigns/presentation/widgets/creator_browse_explorer_filters.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../domain/campaign_niche_catalog.dart';
import '../providers/advertiser_campaigns_providers.dart';
import '../theme/advertiser_campaigns_chrome.dart';

String _moneyLocale(AppLocale l) => wayoPublicMoneyLocale(l);

/// Advertiser marketplace browse — active campaigns on the platform (read-only).
class AdvertiserBrowseCampaignsView extends ConsumerStatefulWidget {
  const AdvertiserBrowseCampaignsView({super.key});

  @override
  ConsumerState<AdvertiserBrowseCampaignsView> createState() =>
      _AdvertiserBrowseCampaignsViewState();
}

class _AdvertiserBrowseCampaignsViewState
    extends ConsumerState<AdvertiserBrowseCampaignsView> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _scheduleSearch(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      ref.read(advertiserBrowseCampaignPageProvider.notifier).state = 1;
      ref.read(advertiserBrowseCampaignSearchProvider.notifier).state = raw;
    });
  }

  AdvertiserBrowsePagedKey _browseKey() {
    final type = ref.read(advertiserBrowseTypeFilterProvider);
    final niche = ref.read(advertiserBrowseNicheProvider);
    final location = ref.read(advertiserBrowseLocationProvider);
    return (
      page: ref.read(advertiserBrowseCampaignPageProvider),
      search: ref.read(advertiserBrowseCampaignSearchProvider),
      typeApi: marketplaceTypeApiFromFilter(type),
      nicheApi: niche != null && niche.isNotEmpty
          ? normalizeCampaignNicheApiValue(niche)
          : null,
      countryApi: marketplaceCountryApiFromLocation(location),
    );
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    ref.read(advertiserBrowseCampaignPageProvider.notifier).state = 1;
    invalidateAdvertiserBrowseCampaigns(ref);
    await ref.read(advertiserBrowseCampaignsPagedProvider(_browseKey()).future);
  }

  void _openCampaign(CreatorBrowseCampaign c) {
    FocusManager.instance.primaryFocus?.unfocus();
    context.push(
      '/campaigns/${c.id}',
      extra: <String, Object?>{'title': c.title},
    );
  }

  String _errorMessage(BuildContext context, Object e) {
    final t = context.t;
    if (e is NetworkException) return t.errors.network;
    if (e is ServerException) {
      return e.message.isNotEmpty ? e.message : t.errors.server_generic;
    }
    return t.errors.server_generic;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final moneyLocale = _moneyLocale(ref.watch(localeProvider));
    final toolbarExpanded = ref.watch(campaignsExplorerToolbarExpandedProvider);
    final typeFilter = ref.watch(advertiserBrowseTypeFilterProvider);
    final nicheFilter = ref.watch(advertiserBrowseNicheProvider);
    final locationFilter = ref.watch(advertiserBrowseLocationProvider);
    final layout = ref.watch(advertiserBrowseExplorerLayoutProvider);
    final pageIdx = ref.watch(advertiserBrowseCampaignPageProvider);
    final browseKey = _browseKey();
    final browseAsync = ref.watch(
      advertiserBrowseCampaignsPagedProvider(browseKey),
    );

    final resultCountText = browseAsync.maybeWhen(
      data: (p) {
        if (p.total == 0) return '…';
        return p.total == 1
            ? t.campaigns_explorer.results_one
            : t.campaigns_explorer.results_many(n: p.total);
      },
      orElse: () => '…',
    );

    ref.listen(chatPostLoginGateProvider, (previous, gateAt) {
      if (gateAt == null) return;
      scheduleSessionRetryAfterBootstrap(ref, () {
        if (!mounted) return;
        if (ref
            .read(advertiserBrowseCampaignsPagedProvider(browseKey))
            .hasError) {
          ref.invalidate(advertiserBrowseCampaignsPagedProvider);
        }
      });
    });

    ref.listen(advertiserBrowseCampaignsPagedProvider(browseKey), (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (e, _) {
          if (!shouldSuppressSessionLoadError(ref, e)) return;
          scheduleSessionRetryAfterBootstrap(ref, () {
            if (!mounted) return;
            ref.invalidate(advertiserBrowseCampaignsPagedProvider);
          });
        },
      );
    });

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.advertiser_campaigns.browse.title,
                    style: AdvertiserCampaignsChrome.heroTitle(context),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.advertiser_campaigns.browse.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AdvertiserCampaignsChrome.heroSubtitle(context),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: CampaignsExplorerToolbar(
                searchField: Semantics(
                  label: t.campaigns_explorer.search_aria,
                  child: _BrowseSearchField(
                    controller: _searchCtrl,
                    hint: t.advertiser_campaigns.browse.search_placeholder,
                    onChanged: _scheduleSearch,
                    onClear: () {
                      _debounce?.cancel();
                      _searchCtrl.clear();
                      ref
                              .read(
                                advertiserBrowseCampaignPageProvider.notifier,
                              )
                              .state =
                          1;
                      ref
                              .read(
                                advertiserBrowseCampaignSearchProvider.notifier,
                              )
                              .state =
                          '';
                    },
                  ),
                ),
                filtersExpanded: toolbarExpanded,
                onFiltersExpandedChanged: (v) =>
                    ref
                            .read(
                              campaignsExplorerToolbarExpandedProvider.notifier,
                            )
                            .state =
                        v,
                filterScrollContent: browseAsync.maybeWhen(
                  data: (p) => p.campaigns.isEmpty && p.facets.isEmpty
                      ? null
                      : CreatorBrowseExplorerFilters(
                          campaigns: p.campaigns,
                          facets: p.facets,
                          t: t,
                          typeFilter: typeFilter,
                          nicheFilter: nicheFilter,
                          locationFilter: locationFilter,
                          onTypeChanged: (v) {
                            ref
                                    .read(
                                      advertiserBrowseCampaignPageProvider
                                          .notifier,
                                    )
                                    .state =
                                1;
                            ref
                                    .read(
                                      advertiserBrowseTypeFilterProvider
                                          .notifier,
                                    )
                                    .state =
                                v;
                          },
                          onNicheChanged: (v) {
                            ref
                                    .read(
                                      advertiserBrowseCampaignPageProvider
                                          .notifier,
                                    )
                                    .state =
                                1;
                            ref
                                .read(advertiserBrowseNicheProvider.notifier)
                                .state = v == null
                                ? null
                                : normalizeCampaignNicheApiValue(v);
                          },
                          onLocationChanged: (v) {
                            ref
                                    .read(
                                      advertiserBrowseCampaignPageProvider
                                          .notifier,
                                    )
                                    .state =
                                1;
                            ref
                                .read(advertiserBrowseLocationProvider.notifier)
                                .state = v == null
                                ? null
                                : normalizeCampaignLocationValue(v);
                          },
                        ),
                  orElse: () => null,
                ),
                onResetExplorerFilters: () {
                  ref
                          .read(advertiserBrowseCampaignPageProvider.notifier)
                          .state =
                      1;
                  ref.read(advertiserBrowseTypeFilterProvider.notifier).state =
                      null;
                  ref.read(advertiserBrowseNicheProvider.notifier).state = null;
                  ref.read(advertiserBrowseLocationProvider.notifier).state =
                      null;
                },
                resultCountText: resultCountText,
                layout: layout,
                onLayoutChanged: (v) =>
                    ref
                            .read(
                              advertiserBrowseExplorerLayoutProvider.notifier,
                            )
                            .state =
                        v,
              ),
            ),
          ),
          browseAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) {
              if (shouldSuppressSessionLoadError(ref, e)) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: ErrorBanner(
                    message: _errorMessage(context, e),
                    retryLabel: t.dashboard.errors.retry,
                    onRetry: () =>
                        ref.invalidate(advertiserBrowseCampaignsPagedProvider),
                  ),
                ),
              );
            },
            data: (pageResult) {
              final list = pageResult.campaigns;
              final hasSearch = browseKey.search.trim().isNotEmpty;
              final hasFilters =
                  typeFilter != null ||
                  (nicheFilter?.isNotEmpty ?? false) ||
                  (locationFilter?.isNotEmpty ?? false);

              if (list.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyBlock(
                    title: hasSearch || hasFilters
                        ? t.advertiser_campaigns.browse.empty_search_title
                        : t.advertiser_campaigns.browse.empty_title,
                    subtitle: hasSearch || hasFilters
                        ? t.advertiser_campaigns.browse.empty_search_subtitle
                        : t.advertiser_campaigns.browse.empty_subtitle,
                  ),
                );
              }

              final countLabel = pageResult.total == 1
                  ? t.campaigns_explorer.results_one
                  : t.campaigns_explorer.results_many(n: pageResult.total);

              if (layout == CampaignExplorerLayout.grid) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final c = list[i];
                      return CreatorBrowseCampaignGridTile(
                        campaign: c,
                        moneyLocale: moneyLocale,
                        gridIndex: i,
                        onTap: () => _openCampaign(c),
                      );
                    }, childCount: list.length),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        countLabel,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: AppColors.textMutedOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  final c = list[i - 1];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: CreatorBrowseCampaignCard(
                      campaign: c,
                      moneyLocale: moneyLocale,
                      listIndex: i - 1,
                      onTap: () => _openCampaign(c),
                    ),
                  );
                }, childCount: list.length + 1),
              );
            },
          ),
          browseAsync.maybeWhen(
            data: (pageResult) {
              if (pageResult.totalPages <= 1) {
                return const SliverToBoxAdapter(child: SizedBox(height: 120));
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  child: _PaginationBar(
                    page: pageIdx,
                    totalPages: pageResult.totalPages,
                    onPrevious: pageIdx > 1
                        ? () {
                            HapticFeedback.selectionClick();
                            ref
                                    .read(
                                      advertiserBrowseCampaignPageProvider
                                          .notifier,
                                    )
                                    .state =
                                pageIdx - 1;
                          }
                        : null,
                    onNext: pageIdx < pageResult.totalPages
                        ? () {
                            HapticFeedback.selectionClick();
                            ref
                                    .read(
                                      advertiserBrowseCampaignPageProvider
                                          .notifier,
                                    )
                                    .state =
                                pageIdx + 1;
                          }
                        : null,
                  ),
                ),
              );
            },
            orElse: () =>
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ),
        ],
      ),
    );
  }
}

class _BrowseSearchField extends StatefulWidget {
  const _BrowseSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final void Function(String) onChanged;
  final VoidCallback onClear;

  @override
  State<_BrowseSearchField> createState() => _BrowseSearchFieldState();
}

class _BrowseSearchFieldState extends State<_BrowseSearchField> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        return TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: widget.onClear,
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 56,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium(
                context,
              ).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onPrevious,
          child: Text(t.dashboard.campaigns.pagination_previous),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            t.dashboard.campaigns.pagination_page(
              current: page,
              total: totalPages,
            ),
            style: AppTextStyles.bodyLarge(context),
          ),
        ),
        TextButton(
          onPressed: onNext,
          child: Text(t.dashboard.campaigns.pagination_next),
        ),
      ],
    );
  }
}
