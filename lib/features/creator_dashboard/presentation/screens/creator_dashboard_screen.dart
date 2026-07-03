import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/widgets/animated_logout_icon.dart';
import '../../../../core/push/push_disabled_settings_badge.dart';
import '../../../app_settings/presentation/widgets/app_settings_side_panel.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../auth/presentation/widgets/wayo_logo.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../../dashboard/presentation/widgets/notification_center_popup.dart';
import '../../../shell/presentation/widgets/shell_tutorial_replay_scope.dart';
import '../../domain/creator_application.dart';
import '../../domain/creator_stats.dart';
import '../providers/creator_dashboard_providers.dart';

String _moneyLocale(AppLocale l) => switch (l) {
  AppLocale.en => 'en_US',
  AppLocale.fr => 'fr_FR',
  AppLocale.ar => 'ar_SA',
};

/// While the creator dashboard is the visible tab we refresh KPIs and
/// applications on this short cadence so an advertiser's approval / rejection
/// shows up without the user tapping refresh. Reverb push stays the fast path
/// (sub-second); this timer only insures against missing/renamed broadcasts.
///
/// Repositories are already rate-limited and deduplicated, so a short interval
/// here never translates into API spam — if nothing changed on the server the
/// request is collapsed.
const Duration _kCreatorDashboardFocusRefreshInterval = Duration(seconds: 18);

/// Creator **home** — KPIs + active applications.
///
/// Backed by `/api/creator/stats` and `/api/creator/applications`.
/// Real-time updates arrive via the private Reverb channel
/// `private-creator.{userId}` (see [realtimeInvalidationProvider]) and a
/// short local polling loop active only while this screen is mounted + the
/// app is resumed (see [_kCreatorDashboardFocusRefreshInterval]).
class CreatorDashboardScreen extends ConsumerStatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  ConsumerState<CreatorDashboardScreen> createState() =>
      _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends ConsumerState<CreatorDashboardScreen>
    with WidgetsBindingObserver {
  Timer? _focusPollTimer;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshNow();
      _startFocusPolling();
    });
  }

  @override
  void dispose() {
    _focusPollTimer?.cancel();
    _focusPollTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      _refreshNow();
      _startFocusPolling();
    } else {
      _focusPollTimer?.cancel();
      _focusPollTimer = null;
    }
  }

  void _startFocusPolling() {
    _focusPollTimer?.cancel();
    _focusPollTimer = Timer.periodic(_kCreatorDashboardFocusRefreshInterval, (
      _,
    ) {
      if (!mounted) return;
      if (_lifecycle != AppLifecycleState.resumed) return;
      _refreshNow();
    });
  }

  /// Invalidates applications + KPIs so they re-fetch on the next frame.
  /// Safe to call frequently — [CreatorDashboardRepository] deduplicates
  /// in-flight requests and enforces a 2 s rate limit per endpoint.
  void _refreshNow() {
    if (isSessionBootstrapActive(ref)) return;
    ref.invalidate(creatorApplicationsProvider);
    ref.invalidate(creatorStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final statsAsync = ref.watch(creatorStatsProvider);
    final applicationsAsync = ref.watch(creatorApplicationsProvider);

    ref.listen(chatPostLoginGateProvider, (previous, gateAt) {
      if (gateAt == null) return;
      scheduleCreatorRetryAfterBootstrap(ref, () {
        if (!context.mounted) return;
        if (ref.read(creatorStatsProvider).hasError) {
          ref.invalidate(creatorStatsProvider);
        }
        if (ref.read(creatorApplicationsProvider).hasError) {
          ref.invalidate(creatorApplicationsProvider);
        }
      });
    });

    ref.listen(creatorStatsProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) {
          if (!shouldSuppressCreatorLoadError(ref, e)) return;
          scheduleCreatorRetryAfterBootstrap(ref, () {
            if (!context.mounted) return;
            ref.invalidate(creatorStatsProvider);
          });
        },
      );
    });

    ref.listen(creatorApplicationsProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) {
          if (!shouldSuppressCreatorLoadError(ref, e)) return;
          scheduleCreatorRetryAfterBootstrap(ref, () {
            if (!context.mounted) return;
            ref.invalidate(creatorApplicationsProvider);
          });
        },
      );
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: CreatorColors.primaryOf(context),
        onRefresh: () async {
          await ref
              .read(authNotifierProvider.notifier)
              .refreshProfileFromAuthServer(force: true);
          ref.invalidate(creatorStatsProvider);
          ref.invalidate(creatorApplicationsProvider);
          ref.invalidate(dashboardStreamProvider);
          HapticFeedback.lightImpact();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: _CreatorHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _WelcomeBlock(t: t),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: statsAsync.when(
                  loading: () => const _StatsSkeleton(),
                  error: (e, _) {
                    if (shouldSuppressCreatorLoadError(ref, e)) {
                      return const _StatsSkeleton();
                    }
                    return ErrorBanner(
                      message: t.dashboard.errors.load_balance,
                      retryLabel: t.dashboard.errors.retry,
                      onRetry: () => ref.invalidate(creatorStatsProvider),
                    );
                  },
                  data: (s) =>
                      _StatsSection(stats: s, moneyLocale: moneyLocale),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  t.creator.applications.section_title,
                  style: AppTextStyles.headlineMedium(context),
                ),
              ),
            ),
            applicationsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _ApplicationsSkeleton(),
                ),
              ),
              error: (e, _) {
                if (shouldSuppressCreatorLoadError(ref, e)) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _ApplicationsSkeleton(),
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ErrorBanner(
                      message: t.creator.applications.load_error,
                      retryLabel: t.dashboard.errors.retry,
                      onRetry: () =>
                          ref.invalidate(creatorApplicationsProvider),
                    ),
                  ),
                );
              },
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _ApplicationsEmpty(t: t),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      return AnimationConfiguration.staggeredList(
                        position: i,
                        duration: const Duration(milliseconds: 420),
                        child: SlideAnimation(
                          verticalOffset: 36,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ApplicationTile(app: list[i]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorHeader extends ConsumerWidget {
  const _CreatorHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final async = ref.watch(dashboardStreamProvider);
    final snap = async.valueOrNull;
    final unread = snap?.unreadCount ?? 0;
    final replayOnboardingTour =
        ShellTutorialReplayScope.maybeOf(context)?.replay;
    final accent = CreatorColors.primaryOf(context);
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
                ).withValues(alpha: 0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showAppSettingsSidePanel(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.textPrimaryOf(context),
                    ),
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
                  ).withValues(alpha: 0.5),
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
                          color: accent.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Material(
            color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.5),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => showNotificationCenterPopup(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimaryOf(context),
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
              ).withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(authNotifierProvider.notifier).logout();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: AnimatedLogoutIcon(
                    size: 22,
                    color: CreatorColors.primaryOf(context),
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

class _WelcomeBlock extends ConsumerWidget {
  const _WelcomeBlock({required this.t});

  final Translations t;

  static String? _firstName(String? full) {
    final trimmed = full?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final space = trimmed.indexOf(RegExp(r'\s+'));
    return space == -1 ? trimmed : trimmed.substring(0, space);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider);
    final firstName = _firstName(user?.name) ?? '';
    final welcome = firstName.isEmpty
        ? t.dashboard.welcome_fallback
        : t.dashboard.welcome.replaceAll('{name}', firstName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.creator.dashboard.title,
          style: AppTextStyles.pageTitle(context),
        ),
        const SizedBox(height: 6),
        Text(welcome, style: AppTextStyles.headlineMedium(context)),
        const SizedBox(height: 8),
        _RolePill(label: t.dashboard.account_creator),
        const SizedBox(height: 6),
        Text(
          t.creator.dashboard.subtitle,
          style: AppTextStyles.bodyLarge(context),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CreatorColors.primaryOf(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: CreatorColors.primaryOf(context).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 12,
            color: CreatorColors.primaryOf(context),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: CreatorColors.primaryOf(context),
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

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats, required this.moneyLocale});

  final CreatorStats stats;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EarningsHero(stats: stats, moneyLocale: moneyLocale),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: t.creator.stats.validated_views,
                value: '${stats.validatedViews}',
                accent: CreatorColors.primaryOf(context),
                icon: Icons.visibility_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: t.creator.stats.validation_rate,
                value: '${(stats.validationRate * 100).toStringAsFixed(1)}%',
                accent: const Color(0xFF10B981),
                icon: Icons.verified_user_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: t.creator.stats.approved_campaigns,
                value: '${stats.approvedApplications}',
                accent: const Color(0xFF8B5CF6),
                icon: Icons.campaign_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EarningsHero extends StatelessWidget {
  const _EarningsHero({required this.stats, required this.moneyLocale});

  final CreatorStats stats;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: CreatorColors.primaryGradient,
              ),
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
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.creator.stats.earnings_title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  MoneyFormatter.format(
                    stats.totalEarnings,
                    currency: stats.currency,
                    locale: moneyLocale,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                if (stats.pendingEarningsCents > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${t.creator.stats.pending}: ${MoneyFormatter.format(stats.pendingEarnings, currency: stats.currency, locale: moneyLocale)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.04,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        height: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
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
                ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
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
                    height: 84,
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

class _ApplicationsSkeleton extends StatelessWidget {
  const _ApplicationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationsEmpty extends StatelessWidget {
  const _ApplicationsEmpty({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: AppColors.textMutedOf(context),
          ),
          const SizedBox(height: 10),
          Text(
            t.creator.applications.empty_title,
            style: AppTextStyles.headlineMedium(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            t.creator.applications.empty_subtitle,
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(color: AppColors.textSecondaryOf(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.app});

  final CreatorApplication app;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final status = app.status;
    final (statusLabel, statusColor) = _statusStyle(context, status, t);
    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          FocusManager.instance.primaryFocus?.unfocus();
          final id = app.campaignId.trim();
          if (id.isEmpty) return;
          context.push(
            '/creator/campaigns/$id',
            extra: <String, Object?>{
              'title': app.campaignTitle,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: app.coverUrl != null && app.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl:
                              normalizeWayoAdsMediaUrl(app.coverUrl) ??
                              app.coverUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 96,
                          memCacheHeight: 96,
                          errorWidget: (c, u, e) => _FallbackThumb(),
                        )
                      : _FallbackThumb(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.campaignTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
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
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (app.advertiserName != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              app.advertiserName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textMutedOf(context),
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusStyle(
    BuildContext context,
    CreatorApplicationStatus status,
    Translations t,
  ) {
    return switch (status) {
      CreatorApplicationStatus.approved => (
        t.creator.applications.status_approved,
        AppColors.success,
      ),
      CreatorApplicationStatus.pending => (
        t.creator.applications.status_pending,
        CreatorColors.primaryOf(context),
      ),
      CreatorApplicationStatus.rejected => (
        t.creator.applications.status_rejected,
        AppColors.error,
      ),
      CreatorApplicationStatus.withdrawn => (
        t.creator.applications.status_withdrawn,
        AppColors.textMutedOf(context),
      ),
      CreatorApplicationStatus.unknown => (
        t.creator.applications.status_unknown,
        AppColors.textMutedOf(context),
      ),
    };
  }
}

class _FallbackThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: CreatorColors.primaryOf(context).withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(
        Icons.campaign_outlined,
        color: CreatorColors.primaryOf(context),
        size: 22,
      ),
    );
  }
}
