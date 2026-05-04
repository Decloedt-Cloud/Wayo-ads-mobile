import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../domain/advertiser_campaign.dart';
import '../providers/advertiser_campaigns_providers.dart';
import '../widgets/advertiser_campaign_card.dart';

String _moneyLocale(AppLocale l) => switch (l) {
  AppLocale.en => 'en_US',
  AppLocale.fr => 'fr_FR',
  AppLocale.ar => 'ar_SA',
};

/// Page background: premium dark gradient or light surfaces (not hard-coded black).
BoxDecoration _campaignsPageBackground(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  if (theme.brightness == Brightness.dark) {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.black, AppColors.surface],
      ),
    );
  }
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [scheme.surface, scheme.surfaceContainerLow],
    ),
  );
}

/// Advertiser campaigns — list, filters, search, and draft creation (Wayo-ads API).
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

  // OPTIMIZATION: Removed _searchCtrl.addListener(() => setState(() {}))
  // _SearchField now uses ValueListenableBuilder internally for clear button.

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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Future<void> refresh() async {
      ref.invalidate(advertiserCampaignsPagedProvider);
      ref.invalidate(advertiserCampaignsCountsProvider);
      await ref.read(advertiserCampaignsPagedProvider(key).future);
    }

    return Scaffold(
      backgroundColor: isDark
          ? Colors.transparent
          : Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/campaigns/new');
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t.advertiser_campaigns.create.title),
      ),
      body: DecoratedBox(
        decoration: _campaignsPageBackground(context),
        child: SafeArea(
          child: pageAsync.when(
            data: (pageResult) {
              final counts = countsAsync.valueOrNull ??
                  (
                    active: 0,
                    draft: 0,
                    paused: 0,
                    completed: 0,
                  );
              return _Body(
                campaigns: pageResult.campaigns,
                totalPages: pageResult.totalPages,
                currentPage: pageIdx,
                counts: counts,
                tab: tab,
                searchCtrl: _searchCtrl,
                searchQ: searchQ,
                moneyLocale: moneyLocale,
                reduceMotion: reduceMotion,
                onTab: (v) {
                  ref.read(advertiserCampaignsTabProvider.notifier).state = v;
                  ref.read(advertiserCampaignsPageIndexProvider.notifier).state =
                      1;
                },
                onSearchChanged: _scheduleSearchDebounce,
                onClearSearch: () {
                  _debounce?.cancel();
                  _searchCtrl.clear();
                  ref.read(advertiserCampaignsPageIndexProvider.notifier).state =
                      1;
                  ref.read(advertiserCampaignsSearchQueryProvider.notifier).state =
                      '';
                },
                onRefresh: refresh,
                onPagePrevious: pageIdx > 1
                    ? () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(
                              advertiserCampaignsPageIndexProvider.notifier,
                            )
                            .state = pageIdx - 1;
                      }
                    : null,
                onPageNext: pageIdx < pageResult.totalPages
                    ? () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(
                              advertiserCampaignsPageIndexProvider.notifier,
                            )
                            .state = pageIdx + 1;
                      }
                    : null,
              );
            },
            loading: () => _LoadingShell(t: t),
            error: (e, _) => _ErrorShell(
              t: t,
              message: _errorMessage(context, e),
              onRetry: () {
                ref.invalidate(advertiserCampaignsPagedProvider);
                ref.invalidate(advertiserCampaignsCountsProvider);
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
                      height: 168,
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

class _Body extends StatelessWidget {
  const _Body({
    required this.campaigns,
    required this.totalPages,
    required this.currentPage,
    required this.counts,
    required this.tab,
    required this.searchCtrl,
    required this.searchQ,
    required this.moneyLocale,
    required this.reduceMotion,
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
  final bool reduceMotion;
  final void Function(AdvertiserCampaignsTab) onTab;
  final void Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onRefresh;
  final VoidCallback? onPagePrevious;
  final VoidCallback? onPageNext;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _HeaderBlock(t: t)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _StatusTabs(
                selected: tab,
                onChanged: onTab,
                duration: duration,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _CountChips(
                counts: counts,
                selected: tab,
                onSelect: onTab,
                duration: duration,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _SearchField(
                controller: searchCtrl,
                onChanged: onSearchChanged,
                onClear: onClearSearch,
              ),
            ),
          ),
          if (campaigns.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(hasSearch: searchQ.trim().isNotEmpty),
            )
          else
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
                        onTap: () => context.push(
                          '/campaigns/${c.id}',
                          extra: <String, String?>{
                            'coverUrl': c.coverUrl,
                            'brandLogoUrl': c.brandLogoUrl,
                            'title': c.name,
                          },
                        ),
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
                      pageLabel: (cur, tot) =>
                          t.dashboard.campaigns.pagination_page(
                            current: cur,
                            total: tot,
                          ),
                      onPrevious: onPagePrevious,
                      onNext: onPageNext,
                    ),
                  );
                }, childCount: campaigns.length + (totalPages > 1 ? 1 : 0)),
              ),
            ),
        ],
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
              TextButton(
                onPressed: onPrevious,
                child: Text(previousLabel),
              ),
              Expanded(
                child: Text(
                  pageLabel(page, totalPages),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
              TextButton(
                onPressed: onNext,
                child: Text(nextLabel),
              ),
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
            style: AppTextStyles.pageTitle(context),
          ),
          const SizedBox(height: 6),
          Text(
            t.advertiser_campaigns.subtitle,
            style: AppTextStyles.bodyLarge(context),
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.selected,
    required this.onChanged,
    required this.duration,
  });

  final AdvertiserCampaignsTab selected;
  final void Function(AdvertiserCampaignsTab) onChanged;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevatedOf(context).withValues(alpha: 0.45)
            : AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TabPill(
              label: t.advertiser_campaigns.tabs.active,
              selected: selected == AdvertiserCampaignsTab.active,
              duration: duration,
              onTap: () => onChanged(AdvertiserCampaignsTab.active),
            ),
            const SizedBox(width: 4),
            _TabPill(
              label: t.advertiser_campaigns.tabs.draft,
              selected: selected == AdvertiserCampaignsTab.draft,
              duration: duration,
              onTap: () => onChanged(AdvertiserCampaignsTab.draft),
            ),
            const SizedBox(width: 4),
            _TabPill(
              label: t.advertiser_campaigns.tabs.paused,
              selected: selected == AdvertiserCampaignsTab.paused,
              duration: duration,
              onTap: () => onChanged(AdvertiserCampaignsTab.paused),
            ),
            const SizedBox(width: 4),
            _TabPill(
              label: t.advertiser_campaigns.tabs.completed,
              selected: selected == AdvertiserCampaignsTab.completed,
              duration: duration,
              onTap: () => onChanged(AdvertiserCampaignsTab.completed),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 86),
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.22)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.55)
                : Colors.transparent,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.1,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountChips extends StatelessWidget {
  const _CountChips({
    required this.counts,
    required this.selected,
    required this.onSelect,
    required this.duration,
  });

  final ({int active, int draft, int paused, int completed}) counts;
  final AdvertiserCampaignsTab selected;
  final void Function(AdvertiserCampaignsTab) onSelect;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: '${t.advertiser_campaigns.tabs.active} (${counts.active})',
            selected: selected == AdvertiserCampaignsTab.active,
            duration: duration,
            onTap: () => onSelect(AdvertiserCampaignsTab.active),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: '${t.advertiser_campaigns.tabs.draft} (${counts.draft})',
            selected: selected == AdvertiserCampaignsTab.draft,
            duration: duration,
            onTap: () => onSelect(AdvertiserCampaignsTab.draft),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: '${t.advertiser_campaigns.tabs.paused} (${counts.paused})',
            selected: selected == AdvertiserCampaignsTab.paused,
            duration: duration,
            onTap: () => onSelect(AdvertiserCampaignsTab.paused),
          ),
          const SizedBox(width: 8),
          _Chip(
            label:
                '${t.advertiser_campaigns.tabs.completed} (${counts.completed})',
            selected: selected == AdvertiserCampaignsTab.completed,
            duration: duration,
            onTap: () => onSelect(AdvertiserCampaignsTab.completed),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surfaceElevatedOf(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search field that uses [ValueListenableBuilder] internally to update the
/// clear button visibility without requiring parent rebuilds.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? AppColors.surfaceElevatedOf(context).withValues(alpha: 0.35)
        : AppColors.surfaceElevatedOf(context);
    final borderColor = AppColors.borderOf(context);
    final hintColor = AppColors.textMutedOf(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: AppColors.textPrimaryOf(context)),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: t.advertiser_campaigns.search_placeholder,
            hintStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(Icons.search_rounded, color: hintColor),
            suffixIcon: hasText
                ? IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: onClear,
                    icon: Icon(Icons.close_rounded, color: hintColor),
                  )
                : null,
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
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
