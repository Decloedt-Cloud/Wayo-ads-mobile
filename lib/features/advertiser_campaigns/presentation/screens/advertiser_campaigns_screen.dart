import 'dart:async';

import 'package:flutter/material.dart';
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

/// Advertiser campaigns — read-only list, filters, search (no create/edit).
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
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
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
      ref.read(advertiserCampaignsSearchQueryProvider.notifier).state = raw;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final async = ref.watch(advertiserCampaignsListProvider);
    final filtered = ref.watch(advertiserCampaignsFilteredProvider);
    final counts = ref.watch(advertiserCampaignsCountsProvider);
    final tab = ref.watch(advertiserCampaignsTabProvider);
    final searchQ = ref.watch(advertiserCampaignsSearchQueryProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? Colors.transparent
          : Theme.of(context).scaffoldBackgroundColor,
      body: DecoratedBox(
        decoration: _campaignsPageBackground(context),
        child: SafeArea(
          child: async.when(
            data: (_) => _Body(
              filtered: filtered,
              counts: counts,
              tab: tab,
              searchCtrl: _searchCtrl,
              searchQ: searchQ,
              moneyLocale: moneyLocale,
              reduceMotion: reduceMotion,
              onTab: (v) =>
                  ref.read(advertiserCampaignsTabProvider.notifier).state = v,
              onSearchChanged: _scheduleSearchDebounce,
              onClearSearch: () {
                _debounce?.cancel();
                _searchCtrl.clear();
                ref
                        .read(advertiserCampaignsSearchQueryProvider.notifier)
                        .state =
                    '';
                setState(() {});
              },
              onRefresh: () async {
                ref.invalidate(advertiserCampaignsListProvider);
                await ref.read(advertiserCampaignsListProvider.future);
              },
            ),
            loading: () => _LoadingShell(t: t),
            error: (e, _) => _ErrorShell(
              t: t,
              message: _errorMessage(context, e),
              onRetry: () => ref.invalidate(advertiserCampaignsListProvider),
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
    required this.filtered,
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
  });

  final List<AdvertiserCampaign> filtered;
  final ({int active, int paused, int completed}) counts;
  final AdvertiserCampaignsTab tab;
  final TextEditingController searchCtrl;
  final String searchQ;
  final String moneyLocale;
  final bool reduceMotion;
  final void Function(AdvertiserCampaignsTab) onTab;
  final void Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onRefresh;

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
                hasText: searchCtrl.text.isNotEmpty || searchQ.isNotEmpty,
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(hasSearch: searchQ.trim().isNotEmpty),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final c = filtered[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AdvertiserCampaignCard(
                      campaign: c,
                      moneyLocale: moneyLocale,
                      onTap: () => context.push(
                        '/campaigns/${c.id}',
                        extra: <String, String?>{
                          'coverUrl': c.coverUrl,
                          'title': c.name,
                        },
                      ),
                    ),
                  );
                }, childCount: filtered.length),
              ),
            ),
        ],
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
            style: AppTextStyles.displayLarge(context).copyWith(fontSize: 36),
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
      child: Row(
        children: [
          _TabPill(
            label: t.advertiser_campaigns.tabs.active,
            selected: selected == AdvertiserCampaignsTab.active,
            duration: duration,
            onTap: () => onChanged(AdvertiserCampaignsTab.active),
          ),
          _TabPill(
            label: t.advertiser_campaigns.tabs.paused,
            selected: selected == AdvertiserCampaignsTab.paused,
            duration: duration,
            onTap: () => onChanged(AdvertiserCampaignsTab.paused),
          ),
          _TabPill(
            label: t.advertiser_campaigns.tabs.completed,
            selected: selected == AdvertiserCampaignsTab.completed,
            duration: duration,
            onTap: () => onChanged(AdvertiserCampaignsTab.completed),
          ),
        ],
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
    return Expanded(
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
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

  final ({int active, int paused, int completed}) counts;
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.textPrimaryOf(context)),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: t.advertiser_campaigns.search_placeholder,
        hintStyle: TextStyle(color: AppColors.textMutedOf(context)),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.textMutedOf(context),
        ),
        suffixIcon: hasText
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.textMutedOf(context),
                ),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceElevatedOf(context).withValues(alpha: 0.35)
            : AppColors.surfaceElevatedOf(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderOf(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      ),
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
