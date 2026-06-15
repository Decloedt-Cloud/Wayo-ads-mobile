import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/campaigns/campaign_explorer_layout.dart';
import '../../../../core/campaigns/campaigns_explorer_toolbar_expanded_provider.dart';
import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/layout/wayo_system_insets.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/campaigns_explorer_toolbar.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../creator_campaigns/presentation/providers/creator_campaigns_providers.dart';
import '../../../creator_campaigns/presentation/theme/creator_campaigns_chrome.dart';
import '../../../creator_campaigns/presentation/widgets/creator_browse_campaign_grid_tile.dart';
import '../../../creator_campaigns/presentation/widgets/creator_browse_explorer_filters.dart';
import '../providers/superadmin_providers.dart';

String _moneyLocale(AppLocale l) => switch (l) {
      AppLocale.en => 'en_US',
      AppLocale.fr => 'fr_FR',
      AppLocale.ar => 'ar_SA',
    };

List<CreatorBrowseCampaign> _filterBrowseList(
  List<CreatorBrowseCampaign> raw, {
  CreatorCampaignType? type,
  String? niche,
  String? location,
}) {
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

String? _countryApiFromLocation(String? location) {
  final loc = location?.trim().toUpperCase();
  if (loc == null || loc.length != 2) return null;
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(loc)) return null;
  return loc;
}

/// Superadmin marketplace — `GET /api/campaigns` (public ACTIVE list) + live refresh.
class SuperadminBrowseCampaignsScreen extends ConsumerStatefulWidget {
  const SuperadminBrowseCampaignsScreen({super.key});

  @override
  ConsumerState<SuperadminBrowseCampaignsScreen> createState() =>
      _SuperadminBrowseCampaignsScreenState();
}

class _SuperadminBrowseCampaignsScreenState
    extends ConsumerState<SuperadminBrowseCampaignsScreen> {
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
      ref.read(superadminBrowseCampaignPageProvider.notifier).state = 1;
      ref.read(superadminBrowseCampaignSearchProvider.notifier).state = raw;
    });
  }

  SuperadminBrowsePagedKey _browseKey() {
    final type = ref.read(superadminBrowseTypeFilterProvider);
    final niche = ref.read(superadminBrowseNicheProvider);
    final location = ref.read(superadminBrowseLocationProvider);
    return (
      page: ref.read(superadminBrowseCampaignPageProvider),
      search: ref.read(superadminBrowseCampaignSearchProvider),
      typeApi: switch (type) {
        CreatorCampaignType.link => 'LINK',
        CreatorCampaignType.video => 'VIDEO',
        CreatorCampaignType.shorts => 'SHORTS',
        _ => null,
      },
      nicheApi: niche != null && niche.isNotEmpty
          ? normalizeCampaignNicheApiValue(niche)
          : null,
      countryApi: _countryApiFromLocation(location),
    );
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    ref.read(superadminBrowseCampaignPageProvider.notifier).state = 1;
    invalidateSuperadminBrowseCampaigns(ref);
    await ref.read(superadminBrowseCampaignsPagedProvider(_browseKey()).future);
  }

  void _openCampaign(CreatorBrowseCampaign c) {
    FocusManager.instance.primaryFocus?.unfocus();
    context.push(
      '/superadmin/campaigns/${c.id}',
      extra: <String, Object?>{'title': c.title},
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final moneyLocale = _moneyLocale(ref.watch(localeProvider));
    final toolbarExpanded = ref.watch(campaignsExplorerToolbarExpandedProvider);
    final typeFilter = ref.watch(superadminBrowseTypeFilterProvider);
    final nicheFilter = ref.watch(superadminBrowseNicheProvider);
    final locationFilter = ref.watch(superadminBrowseLocationProvider);
    final layout = ref.watch(creatorCampaignExplorerLayoutProvider);
    final browseKey = _browseKey();
    final browseAsync = ref.watch(superadminBrowseCampaignsPagedProvider(browseKey));
    ref.watch(superadminBrowseLivePulseProvider);

    return Scaffold(
      backgroundColor: CreatorCampaignsChrome.bg(context),
      appBar: AppBar(
        title: const Text('Browse campaigns'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: const WayoBlackBottomBar(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          color: CreatorCampaignsChrome.amber(context),
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              wayoScrollBottomReserve(context),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advertising opportunities',
                          style: CreatorCampaignsChrome.heroTitle(context),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Active campaigns on the marketplace — updates in real time.',
                          style: CreatorCampaignsChrome.heroSubtitle(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _LiveBadge(),
                ],
              ),
              const SizedBox(height: 14),
              CampaignsExplorerToolbar(
                resultCountText: browseAsync.maybeWhen(
                  data: (p) {
                    final n = p.total > 0 ? p.total : p.campaigns.length;
                    return n == 1
                        ? t.campaigns_explorer.results_one
                        : t.campaigns_explorer.results_many(n: n);
                  },
                  orElse: () => '',
                ),
                layout: layout,
                onLayoutChanged: (next) => ref
                    .read(creatorCampaignExplorerLayoutProvider.notifier)
                    .state = next,
                searchField: TextField(
                  controller: _searchCtrl,
                  onChanged: _scheduleSearch,
                  decoration: InputDecoration(
                    hintText: t.campaigns_explorer.search_aria,
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _debounce?.cancel();
                              _searchCtrl.clear();
                              ref
                                  .read(superadminBrowseCampaignPageProvider.notifier)
                                  .state = 1;
                              ref
                                  .read(superadminBrowseCampaignSearchProvider.notifier)
                                  .state = '';
                              setState(() {});
                            },
                          ),
                    filled: true,
                    fillColor: AppColors.surfaceElevatedOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
                filtersExpanded: toolbarExpanded,
                onFiltersExpandedChanged: (v) => ref
                    .read(campaignsExplorerToolbarExpandedProvider.notifier)
                    .state = v,
                filterScrollContent: browseAsync.maybeWhen(
                  data: (p) => p.campaigns.isEmpty
                      ? null
                      : CreatorBrowseExplorerFilters(
                          campaigns: p.campaigns,
                          t: t,
                          typeFilter: typeFilter,
                          nicheFilter: nicheFilter,
                          locationFilter: locationFilter,
                          onTypeChanged: (v) {
                            ref
                                .read(superadminBrowseCampaignPageProvider.notifier)
                                .state = 1;
                            ref
                                .read(superadminBrowseTypeFilterProvider.notifier)
                                .state = v;
                          },
                          onNicheChanged: (v) {
                            ref
                                .read(superadminBrowseCampaignPageProvider.notifier)
                                .state = 1;
                            ref.read(superadminBrowseNicheProvider.notifier).state =
                                v == null ? null : normalizeCampaignNicheApiValue(v);
                          },
                          onLocationChanged: (v) {
                            ref
                                .read(superadminBrowseCampaignPageProvider.notifier)
                                .state = 1;
                            ref
                                .read(superadminBrowseLocationProvider.notifier)
                                .state = v == null
                                    ? null
                                    : normalizeCampaignLocationValue(v);
                          },
                        ),
                  orElse: () => null,
                ),
                onResetExplorerFilters: () {
                  ref.read(superadminBrowseCampaignPageProvider.notifier).state = 1;
                  ref.read(superadminBrowseTypeFilterProvider.notifier).state = null;
                  ref.read(superadminBrowseNicheProvider.notifier).state = null;
                  ref.read(superadminBrowseLocationProvider.notifier).state = null;
                },
              ),
              const SizedBox(height: 16),
              browseAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _ErrorBlock(
                  message: e.toString(),
                  onRetry: _refresh,
                ),
                data: (pageResult) {
                  final filtered = _filterBrowseList(
                    pageResult.campaigns,
                    type: typeFilter,
                    niche: nicheFilter,
                    location: locationFilter,
                  );
                  if (filtered.isEmpty) {
                    return _EmptyBlock(
                      title: t.campaigns_explorer.empty_filters,
                      subtitle: 'Try another search or reset filters.',
                    );
                  }
                  final countLabel = pageResult.total > 0
                      ? '${pageResult.total} campaigns'
                      : '${filtered.length} campaigns';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        countLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (layout == CampaignExplorerLayout.grid)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            return CreatorBrowseCampaignGridTile(
                              campaign: c,
                              moneyLocale: moneyLocale,
                              gridIndex: i,
                              onTap: () => _openCampaign(c),
                            );
                          },
                        )
                      else
                        ...[
                          for (var i = 0; i < filtered.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CreatorBrowseCampaignGridTile(
                                campaign: filtered[i],
                                moneyLocale: moneyLocale,
                                gridIndex: i,
                                onTap: () => _openCampaign(filtered[i]),
                              ),
                            ),
                        ],
                      if (pageResult.totalPages > 1) ...[
                        const SizedBox(height: 8),
                        _PaginationBar(
                          page: browseKey.page,
                          totalPages: pageResult.totalPages,
                          onPrevious: browseKey.page > 1
                              ? () {
                                  ref
                                      .read(
                                        superadminBrowseCampaignPageProvider
                                            .notifier,
                                      )
                                      .state = browseKey.page - 1;
                                }
                              : null,
                          onNext: browseKey.page < pageResult.totalPages
                              ? () {
                                  ref
                                      .read(
                                        superadminBrowseCampaignPageProvider
                                            .notifier,
                                      )
                                      .state = browseKey.page + 1;
                                }
                              : null,
                        ),
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
}

class _LiveBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(superadminBrowseLivePulseProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Color(0xFF22C55E)),
          SizedBox(width: 6),
          Text(
            'Live',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          '$page / $totalPages',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.campaign_outlined, size: 48, color: AppColors.textMutedOf(context)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
