import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/campaigns/campaign_explorer_layout.dart';
import '../../../../core/campaigns/campaigns_explorer_toolbar_expanded_provider.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/campaigns_explorer_toolbar.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../../creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../../domain/creator_browse_campaign.dart';
import '../../domain/creator_browse_page_result.dart';
import '../providers/creator_campaigns_providers.dart';
import '../widgets/creator_browse_campaign_card.dart';
import '../widgets/creator_browse_campaign_grid_tile.dart';
import '../widgets/creator_browse_explorer_filters.dart';
import '../theme/creator_campaigns_chrome.dart';

String _moneyLocale(AppLocale l) => switch (l) {
  AppLocale.en => 'en_US',
  AppLocale.fr => 'fr_FR',
  AppLocale.ar => 'ar_SA',
};

List<CreatorBrowseCampaign> _filterCreatorBrowsePage(
  List<CreatorBrowseCampaign> raw,
  CreatorCampaignType? type,
  String? niche,
  String? location,
) {
  return raw.where((c) {
    if (type != null && c.type != type) return false;
    if (niche != null &&
        niche.isNotEmpty &&
        normalizeCampaignNicheApiValue(c.niche) !=
            normalizeCampaignNicheApiValue(niche)) {
      return false;
    }
    if (location != null && location.isNotEmpty) {
      final loc = normalizeCampaignLocationValue(c.location);
      if (loc != normalizeCampaignLocationValue(location)) return false;
    }
    return true;
  }).toList();
}

bool _creatorPageHasExplorerFilters(List<CreatorBrowseCampaign> list) {
  return list.isNotEmpty;
}

void _sanitizeCreatorBrowseFilters(
  WidgetRef ref,
  List<CreatorBrowseCampaign> list,
) {
  var tSel = ref.read(creatorCampaignExplorerTypeFilterProvider);
  final nSel = ref.read(creatorCampaignExplorerNicheProvider);
  final lSel = ref.read(creatorCampaignExplorerLocationProvider);

  if (tSel != null && !list.any((c) => c.type == tSel)) {
    ref.read(creatorCampaignExplorerTypeFilterProvider.notifier).state = null;
    tSel = null;
  }

  bool matchesType(CreatorBrowseCampaign c) {
    if (tSel != null && c.type != tSel) return false;
    return true;
  }

  if (nSel != null && nSel.isNotEmpty) {
    final want = normalizeCampaignNicheApiValue(nSel);
    if (want != null &&
        !list.any(
          (c) =>
              matchesType(c) &&
              normalizeCampaignNicheApiValue(c.niche) == want,
        )) {
      ref.read(creatorCampaignExplorerNicheProvider.notifier).state = null;
    }
  }

  final nicheAfter = ref.read(creatorCampaignExplorerNicheProvider);
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
  Timer? _debounce;

  // OPTIMIZATION: Removed _searchCtrl.addListener(() => setState(() {}))
  // _BrowseSearchField now uses ValueListenableBuilder internally.

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _scheduleSearchQuery(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      ref.read(creatorBrowseCampaignPageProvider.notifier).state = 1;
      ref.read(creatorBrowseCampaignSearchQueryProvider.notifier).state = raw;
    });
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
    final browseKey = (page: browsePage, search: searchQ);
    final browseAsync = ref.watch(
      creatorBrowseCampaignsPagedProvider(browseKey),
    );
    final appsAsync = ref.watch(creatorApplicationsProvider);

    ref.listen(creatorBrowseCampaignsPagedProvider(browseKey), (prev, next) {
      next.whenData(
        (page) => _sanitizeCreatorBrowseFilters(ref, page.campaigns),
      );
    });

    final browsePageForExplorerFilters = browseAsync.maybeWhen(
      data: (CreatorBrowsePageResult p) =>
          !_creatorPageHasExplorerFilters(p.campaigns) ? null : p,
      orElse: () => null,
    );

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
          final k = (
            page: 1,
            search: ref.read(creatorBrowseCampaignSearchQueryProvider),
          );
          await ref.read(creatorBrowseCampaignsPagedProvider(k).future);
        },
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
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
              filterScrollContent: browsePageForExplorerFilters == null
                  ? null
                  : CreatorBrowseExplorerFilters(
                      campaigns: browsePageForExplorerFilters.campaigns,
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
                        _sanitizeCreatorBrowseFilters(
                          ref,
                          browsePageForExplorerFilters.campaigns,
                        );
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
                        _sanitizeCreatorBrowseFilters(
                          ref,
                          browsePageForExplorerFilters.campaigns,
                        );
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
                        _sanitizeCreatorBrowseFilters(
                          ref,
                          browsePageForExplorerFilters.campaigns,
                        );
                      },
                    ),
              onResetExplorerFilters: browsePageForExplorerFilters == null
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
                      _sanitizeCreatorBrowseFilters(
                        ref,
                        browsePageForExplorerFilters.campaigns,
                      );
                    },
              resultCountText: _browseCountLabel(
                browseAsync,
                typeFilter,
                nicheFilter,
                locationFilter,
                t,
              ),
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
              error: (err, _) => _ErrorBlock(
                message: t.creator.campaigns.load_error,
                onRetry: () => ref.invalidate(
                  creatorBrowseCampaignsPagedProvider(browseKey),
                ),
              ),
              data: (pageResult) {
                final list = pageResult.campaigns;
                final filtered = _filterCreatorBrowsePage(
                  list,
                  typeFilter,
                  nicheFilter,
                  locationFilter,
                );
                final hasSearch = searchQ.trim().isNotEmpty;
                if (list.isEmpty) {
                  return _EmptyBrowseBlock(
                    title: hasSearch
                        ? t.creator.campaigns.browse_empty_search_title
                        : t.creator.campaigns.empty_title,
                    subtitle: hasSearch
                        ? t.creator.campaigns.browse_empty_search_subtitle
                        : t.creator.campaigns.empty_subtitle,
                  );
                }
                if (filtered.isEmpty) {
                  return _EmptyBrowseBlock(
                    title: t.campaigns_explorer.empty_filters,
                    subtitle: t.campaigns_explorer.empty_filters_subtitle,
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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.50,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        return CreatorBrowseCampaignGridTile(
                          campaign: c,
                          moneyLocale: moneyLocale,
                          gridIndex: i,
                          applicationStatus: statusByCampaign[c.id],
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            context.push(
                              '/creator/campaigns/${c.id}',
                              extra: <String, Object?>{
                                'title': c.title,
                              },
                            );
                          },
                        );
                      },
                    )
                  else ...[
                    for (var i = 0; i < filtered.length; i++) ...[
                      CreatorBrowseCampaignCard(
                        campaign: filtered[i],
                        moneyLocale: moneyLocale,
                        listIndex: i,
                        applicationStatus:
                            statusByCampaign[filtered[i].id],
                        onTap: () {
                          final c = filtered[i];
                          FocusManager.instance.primaryFocus?.unfocus();
                          context.push(
                            '/creator/campaigns/${c.id}',
                            extra: <String, Object?>{
                              'title': c.title,
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
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
    CreatorCampaignType? typeFilter,
    String? nicheFilter,
    String? locationFilter,
    Translations t,
  ) {
    if (browseAsync.isLoading) return '…';
    return browseAsync.maybeWhen(
      data: (pageResult) {
        final n = _filterCreatorBrowsePage(
          pageResult.campaigns,
          typeFilter,
          nicheFilter,
          locationFilter,
        ).length;
        return n == 1
            ? t.campaigns_explorer.results_one
            : t.campaigns_explorer.results_many(n: n);
      },
      orElse: () => '…',
    );
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
