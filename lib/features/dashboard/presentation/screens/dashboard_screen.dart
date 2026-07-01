import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../auth/presentation/widgets/wayo_logo.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../providers/dashboard_state_providers.dart';
import '../../domain/entities/campaign_platform.dart';
import '../../domain/entities/campaign_status.dart';
import '../../domain/entities/campaign_summary.dart';
import '../../../../shared/widgets/animated_logout_icon.dart';
import '../../../../core/push/push_disabled_settings_badge.dart';
import '../../../app_settings/presentation/widgets/app_settings_side_panel.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../shell/presentation/widgets/shell_tutorial_replay_scope.dart';
import '../../../advertiser_video_reviews/presentation/providers/advertiser_video_reviews_providers.dart';
import '../../../advertiser_video_reviews/presentation/widgets/advertiser_video_reviews_summary_card.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';
import '../widgets/error_banner.dart';
import '../widgets/notification_center_popup.dart';

String _moneyLocale(AppLocale l) => switch (l) {
  AppLocale.en => 'en_US',
  AppLocale.fr => 'fr_FR',
  AppLocale.ar => 'ar_SA',
};

String _localizedAdvertiserCampaignStatus(
  CampaignStatus status,
  Translations t,
) {
  return switch (status) {
    CampaignStatus.active => t.advertiser_campaigns.status.active,
    CampaignStatus.paused => t.advertiser_campaigns.status.paused,
    CampaignStatus.completed => t.advertiser_campaigns.status.completed,
    CampaignStatus.draft => t.advertiser_campaigns.status.draft,
    CampaignStatus.unknown => t.advertiser_campaigns.status.other,
  };
}

/// Advertiser home — balance, campaigns, premium visuals.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final async = ref.watch(dashboardStreamProvider);

    ref.listen(chatPostLoginGateProvider, (previous, gateAt) {
      if (gateAt == null) return;
      scheduleSessionRetryAfterBootstrap(ref, () {
        if (!mounted) return;
        ref.invalidate(dashboardStreamProvider);
      });
    });

    ref.listen(dashboardStreamProvider, (previous, next) {
      next.whenOrNull(
        data: (snap) {
          if (snap.campaignsError == null) return;
          if (!shouldSuppressAdvertiserSectionError(ref, snap.campaignsError)) {
            return;
          }
          scheduleSessionRetryAfterBootstrap(ref, () {
            if (!mounted) return;
            ref.invalidate(dashboardStreamProvider);
          });
        },
      );
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: async.when(
                  data: (snap) => _WelcomeBlock(snapshot: snap, t: t),
                  loading: () => Skeletonizer(
                    enabled: true,
                    child: Text(
                      t.dashboard.title,
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                  error: (e, _) => Text('$e'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: async.maybeWhen(
                data: (snap) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (snap.balanceError != null &&
                          !shouldSuppressAdvertiserSectionError(
                            ref,
                            snap.balanceError,
                          ))
                        ErrorBanner(
                          message: t.dashboard.errors.load_balance,
                          retryLabel: t.dashboard.errors.retry,
                          onRetry: () =>
                              ref.invalidate(dashboardStreamProvider),
                        ),
                      if (snap.campaignsError != null &&
                          !shouldSuppressAdvertiserSectionError(
                            ref,
                            snap.campaignsError,
                          ))
                        ErrorBanner(
                          message: t.dashboard.errors.load_campaigns,
                          retryLabel: t.dashboard.errors.retry,
                          onRetry: () =>
                              ref.invalidate(dashboardStreamProvider),
                        ),
                      _BalanceSection(
                        snapshot: snap,
                        moneyLocale: _moneyLocale(locale),
                        appLocale: locale,
                      ),
                      const AdvertiserVideoReviewsSummaryCard(),
                      _CampaignsSection(
                        snapshot: snap,
                        isLoading: async.isLoading,
                      ),
                    ],
                  );
                },
                orElse: () => const SizedBox(height: 120),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
          ],
        ),
      ),
    );
  }

  static Future<void> _refresh(WidgetRef ref) async {
    await ref
        .read(authNotifierProvider.notifier)
        .refreshProfileFromAuthServer(force: true);
    ref.read(advertiserDashboardCampaignPageProvider.notifier).state = 1;
    ref.invalidate(advertiserDashboardCampaignsPageFetchProvider);
    ref.invalidate(dashboardStreamProvider);
    invalidateAdvertiserVideoReviews(ref);
    await ref.read(dashboardStreamProvider.future);
    HapticFeedback.lightImpact();
  }
}

class _Header extends ConsumerStatefulWidget {
  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dashboardStreamProvider);
    final snap = async.valueOrNull;
    final unread = snap?.unreadCount ?? 0;
    final t = context.t;
    final replayOnboardingTour =
        ShellTutorialReplayScope.maybeOf(context)?.replay;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        8,
      ),
      child: Row(
        children: [
          const WayoLogo(size: 36, enableMotion: false),
          const Spacer(),
          Tooltip(
            message: t.app_settings.title,
            child: PushDisabledSettingsBadge(
              child: Material(
                color: AppColors.surfaceElevatedOf(
                  context,
                ).withValues(alpha: 0.65),
                shape: const CircleBorder(),
                elevation: 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showAppSettingsSidePanel(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.tune_rounded, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
          if (replayOnboardingTour != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: t.dashboard.shell_tour_restart_hint,
              child: Semantics(
                button: true,
                label: t.dashboard.shell_tour_restart,
                child: Material(
                  color: AppColors.surfaceElevatedOf(
                    context,
                  ).withValues(alpha: 0.65),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      replayOnboardingTour();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Material(
            color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.65),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                showNotificationCenterPopup(context, ref);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                    ),
                    if (unread > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: t.home.logout,
            child: Material(
              color: AppColors.surfaceElevatedOf(
                context,
              ).withValues(alpha: 0.65),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(authNotifierProvider.notifier).logout();
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: AnimatedLogoutIcon(size: 22, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBlock extends ConsumerWidget {
  const _WelcomeBlock({required this.snapshot, required this.t});

  final DashboardSnapshot snapshot;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = snapshot.user?.displayFirstName ?? '';
    final welcome = name.isEmpty
        ? t.dashboard.welcome_fallback
        : t.dashboard.welcome.replaceAll('{name}', name);
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    final roleLabel = switch (role) {
      WayoAdsAccountRole.creator => t.dashboard.account_creator,
      WayoAdsAccountRole.advertiser => t.dashboard.account_advertiser,
      _ => t.dashboard.account_advertiser,
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.dashboard.title, style: AppTextStyles.pageTitle(context)),
        const SizedBox(height: 6),
        Text(welcome, style: AppTextStyles.headlineMedium(context)),
        const SizedBox(height: 8),
        _AdvertiserRolePill(label: roleLabel),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.85 : 0.95,
                ),
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              t.dashboard.subtitle,
              style: AppTextStyles.bodyLarge(context).copyWith(
                color: AppColors.textSecondaryOf(context),
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdvertiserRolePill extends StatelessWidget {
  const _AdvertiserRolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 12, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({
    required this.snapshot,
    required this.moneyLocale,
    required this.appLocale,
  });

  final DashboardSnapshot snapshot;
  final String moneyLocale;
  final AppLocale appLocale;

  String get _walletMoneyLocale => wayoPublicMoneyLocale(appLocale);

  String get _walletCurrency =>
      snapshot.balance?.currency ?? kWayoPublicCurrency;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = snapshot.balance;
    final loading = b == null && snapshot.balanceError == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.dashboard.balance.title,
            style: AppTextStyles.headlineMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (loading)
            const _BalanceSectionSkeleton()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdvertiserWalletHero(
                  snapshot: snapshot,
                  currency: _walletCurrency,
                  moneyLocale: _walletMoneyLocale,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _AdvertiserMiniStatCard(
                        label: t.dashboard.balance.locked,
                        value: MoneyFormatter.format(
                          b?.locked ?? 0,
                          currency: _walletCurrency,
                          locale: _walletMoneyLocale,
                        ),
                        accent: AppColors.primaryDeep,
                        icon: Icons.lock_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdvertiserMiniStatCard(
                        label: t.dashboard.balance.spent,
                        value: MoneyFormatter.format(
                          b?.spent ?? 0,
                          currency: _walletCurrency,
                          locale: _walletMoneyLocale,
                        ),
                        accent: AppColors.primarySoft,
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdvertiserMiniStatCard(
                        label: t.advertiser_campaigns.title,
                        value: '${snapshot.campaignsTotalCount}',
                        accent: AppColors.primary,
                        icon: Icons.grid_view_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AdvertiserWalletHero extends StatelessWidget {
  const _AdvertiserWalletHero({
    required this.snapshot,
    required this.currency,
    required this.moneyLocale,
  });

  final DashboardSnapshot snapshot;
  final String currency;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = snapshot.balance;
    if (b == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white.withValues(alpha: 0.92),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.dashboard.balance.available,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  MoneyFormatter.format(
                    b.available,
                    currency: currency,
                    locale: moneyLocale,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvertiserMiniStatCard extends StatelessWidget {
  const _AdvertiserMiniStatCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.black : Colors.black).withValues(
              alpha: isDark ? 0.35 : 0.04,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.38 : 0.22),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryOf(context),
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.45),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(icon, color: accent, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineMedium(
                  context,
                ).copyWith(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceSectionSkeleton extends StatelessWidget {
  const _BalanceSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 124,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedOf(context),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignsSection extends ConsumerStatefulWidget {
  const _CampaignsSection({required this.snapshot, required this.isLoading});

  final DashboardSnapshot snapshot;
  final bool isLoading;

  @override
  ConsumerState<_CampaignsSection> createState() => _CampaignsSectionState();
}

class _CampaignsSectionState extends ConsumerState<_CampaignsSection> {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final page = ref.watch(advertiserDashboardCampaignPageProvider);
    final snap = widget.snapshot;
    final pageFetch = page == 1
        ? null
        : ref.watch(advertiserDashboardCampaignsPageFetchProvider(page));

    final list = page == 1
        ? snap.campaigns
        : pageFetch?.valueOrNull?.campaigns ?? const <CampaignSummary>[];

    final totalPages = page == 1
        ? snap.campaignsTotalPages
        : pageFetch?.valueOrNull?.totalPages ?? snap.campaignsTotalPages;

    final loadingExtra =
        page != 1 && (pageFetch?.isLoading ?? false) && list.isEmpty;
    final loading =
        widget.isLoading &&
        list.isEmpty &&
        snap.campaignsError == null &&
        page == 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.dashboard.campaigns.title,
                      style: AppTextStyles.headlineMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.dashboard.campaigns.subtitle,
                      style: AppTextStyles.bodyLarge(
                        context,
                      ).copyWith(
                        color: AppColors.textSecondaryOf(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/campaigns?view=browse'),
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: Text(t.advertiser_campaigns.view_browse),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            Skeletonizer(
              enabled: true,
              child: Column(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedOf(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (loadingExtra)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (page != 1 && pageFetch?.hasError == true)
            ErrorBanner(
              message: t.dashboard.errors.load_campaigns,
              retryLabel: t.dashboard.errors.retry,
              onRetry: () => ref.invalidate(
                advertiserDashboardCampaignsPageFetchProvider(page),
              ),
            )
          else if (list.isEmpty)
            _EmptyCampaigns()
          else
            AnimationLimiter(
              child: Column(
                children: [
                  ...List.generate(list.length, (index) {
                    final c = list[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 420),
                      child: SlideAnimation(
                        verticalOffset: 36,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CampaignTile(campaign: c),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 4),
                    _DashboardCampaignPaginationBar(
                      page: page,
                      totalPages: totalPages,
                      previousLabel: t.dashboard.campaigns.pagination_previous,
                      nextLabel: t.dashboard.campaigns.pagination_next,
                      pageLabel: (cur, tot) =>
                          t.dashboard.campaigns.pagination_page(
                            current: cur,
                            total: tot,
                          ),
                      onPrevious: page > 1
                          ? () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(
                                    advertiserDashboardCampaignPageProvider
                                        .notifier,
                                  )
                                  .state = page - 1;
                            }
                          : null,
                      onNext: page < totalPages
                          ? () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(
                                    advertiserDashboardCampaignPageProvider
                                        .notifier,
                                  )
                                  .state = page + 1;
                            }
                          : null,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardCampaignPaginationBar extends StatelessWidget {
  const _DashboardCampaignPaginationBar({
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
    );
  }
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({required this.campaign});

  final CampaignSummary campaign;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = campaign;
    final statusColor = _statusColor(c.status);
    return RepaintBoundary(
      child: Material(
        color: AppColors.surfaceElevatedOf(context),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              '/campaigns/${c.id}',
              extra: <String, String?>{
                'title': c.name,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: () {
                    final logo = resolveWayoAdsPublicUrl(c.brandLogoUrl);
                    final hasLogo = logo != null && logo.isNotEmpty;
                    return hasLogo
                        ? Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: CachedNetworkImage(
                                imageUrl: logo,
                                fit: BoxFit.contain,
                                memCacheWidth: 120,
                                memCacheHeight: 120,
                                errorWidget: (context, url, _) =>
                                    _coverThumb(c),
                              ),
                            ),
                          )
                        : _coverThumb(c);
                  }(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _localizedAdvertiserCampaignStatus(
                                c.status,
                                t,
                              ),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            switch (c.campaignType) {
                              CreatorCampaignType.link =>
                                t.creator.campaigns.type_link,
                              CreatorCampaignType.video =>
                                t.creator.campaigns.type_video,
                              CreatorCampaignType.shorts =>
                                t.creator.campaigns.type_shorts,
                              CreatorCampaignType.unknown => '—',
                            },
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.textSecondaryOf(context),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            t.dashboard.campaigns.creators.replaceAll(
                              '{count}',
                              '${c.creatorsCount}',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textMutedOf(context),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverThumb(CampaignSummary c) {
    final url = normalizeWayoAdsMediaUrl(c.coverUrl) ?? c.coverUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        memCacheWidth: 120,
        memCacheHeight: 120,
        errorWidget: (context, url, _) => _PlatformIcon(platform: c.platform),
      );
    }
    return SizedBox(
      width: 56,
      height: 56,
      child: _PlatformIcon(platform: c.platform),
    );
  }

  Color _statusColor(CampaignStatus status) {
    return switch (status.name) {
      'draft' => AppColors.textMuted,
      'active' => AppColors.success,
      'completed' => const Color(0xFF3B82F6),
      'paused' => AppColors.primary,
      _ => AppColors.textMuted,
    };
  }
}

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.platform});

  final CampaignPlatform platform;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (platform) {
      CampaignPlatform.youtube => Icons.play_circle_fill,
      CampaignPlatform.tiktok => Icons.music_note_rounded,
      CampaignPlatform.instagram => Icons.camera_alt_outlined,
      CampaignPlatform.unknown => Icons.campaign_outlined,
    };
    return Container(
      color: AppColors.black.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primary, size: 28),
    );
  }
}

class _EmptyCampaigns extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        Icon(
              Icons.folder_open_rounded,
              size: 72,
              color: AppColors.primary.withValues(alpha: 0.75),
            )
            .animate()
            .moveY(
              begin: 6,
              end: 0,
              duration: 900.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(),
        const SizedBox(height: 12),
        Text(
          t.dashboard.campaigns.empty_title,
          style: AppTextStyles.headlineMedium(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          t.dashboard.campaigns.empty_subtitle,
          style: AppTextStyles.bodyLarge(context),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
