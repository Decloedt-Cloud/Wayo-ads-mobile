import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/format/money_formatter.dart';
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
import '../../../app_settings/presentation/widgets/app_settings_side_panel.dart';
import '../widgets/animated_gradient_border.dart';
import '../widgets/error_banner.dart';

String _moneyLocale(AppLocale l) => switch (l) {
      AppLocale.en => 'en_US',
      AppLocale.fr => 'fr_FR',
      AppLocale.ar => 'ar_SA',
    };

/// Advertiser home — balance, campaigns, premium visuals.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final async = ref.watch(dashboardStreamProvider);

    ref.listen<AsyncValue<DashboardSnapshot>>(dashboardStreamProvider, (prev, next) {
      next.whenData((snap) async {
        final id = snap.user?.id;
        if (id != null) {
          await ref.read(wayoReverbRealtimeProvider).connectForUser(id);
        }
      });
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
                      style: AppTextStyles.displayLarge(context),
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
                      if (snap.balanceError != null)
                        ErrorBanner(
                          message: t.dashboard.errors.load_balance,
                          retryLabel: t.dashboard.errors.retry,
                          onRetry: () => ref.invalidate(dashboardStreamProvider),
                        ),
                      if (snap.campaignsError != null)
                        ErrorBanner(
                          message: t.dashboard.errors.load_campaigns,
                          retryLabel: t.dashboard.errors.retry,
                          onRetry: () => ref.invalidate(dashboardStreamProvider),
                        ),
                      _BalanceSection(
                        snapshot: snap,
                        moneyLocale: _moneyLocale(locale),
                      ),
                      _CampaignsSection(snapshot: snap, isLoading: async.isLoading),
                    ],
                  );
                },
                orElse: () => const SizedBox(height: 120),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  static Future<void> _refresh(WidgetRef ref) async {
    await ref.read(authNotifierProvider.notifier).refreshProfileFromAuthServer();
    ref.invalidate(dashboardStreamProvider);
    await ref.read(dashboardStreamProvider.future);
    HapticFeedback.lightImpact();
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardStreamProvider);
    final snap = async.valueOrNull;
    final unread = snap?.unreadCount ?? 0;
    final t = context.t;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 8),
      child: Row(
        children: [
          const WayoLogo(size: 36),
          const Spacer(),
          Tooltip(
            message: t.app_settings.title,
            child: Material(
              color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  showAppSettingsSidePanel(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.tune_rounded, color: AppColors.textPrimaryOf(context)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _AvatarBubble(
            imageUrl: snap?.user?.avatarUrl,
            label: snap?.user?.displayFirstName ?? snap?.user?.email ?? '',
            hasUnreadNotifications: unread > 0,
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.5),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/notifications');
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.notifications_none_rounded, color: AppColors.textPrimaryOf(context)),
                    if (unread > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
              color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.5),
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
                    color: AppColors.primary,
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

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.imageUrl,
    required this.label,
    this.hasUnreadNotifications = false,
  });

  final String? imageUrl;
  final String label;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context) {
    final initials = label.isNotEmpty ? label[0].toUpperCase() : '?';
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedGradientBorder(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 44,
                height: 44,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        memCacheHeight: 120,
                        errorWidget: (context, url, _) => _InitialsAvatar(initials: initials),
                      )
                    : _InitialsAvatar(initials: initials),
              ),
            ),
          ),
          if (hasUnreadNotifications)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
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
    final roleLine = switch (role) {
      WayoAdsAccountRole.creator => t.dashboard.account_creator,
      WayoAdsAccountRole.advertiser => t.dashboard.account_advertiser,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.dashboard.title, style: AppTextStyles.displayLarge(context)),
        const SizedBox(height: 6),
        Text(welcome, style: AppTextStyles.headlineMedium(context)),
        if (roleLine != null) ...[
          const SizedBox(height: 4),
          Text(
            roleLine,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(t.dashboard.subtitle, style: AppTextStyles.bodyLarge(context)),
      ],
    );
  }
}

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({required this.snapshot, required this.moneyLocale});

  final DashboardSnapshot snapshot;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = snapshot.balance;
    final loading = b == null && snapshot.balanceError == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.dashboard.balance.title, style: AppTextStyles.headlineMedium(context)),
          const SizedBox(height: 12),
          Skeletonizer(
            enabled: loading,
                child: Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        label: t.dashboard.balance.available,
                        amount: b?.available ?? 0,
                        currency: b?.currency ?? 'EUR',
                        moneyLocale: moneyLocale,
                        accent: const Color(0xFF10B981),
                        icon: Icons.account_balance_wallet_outlined,
                        shimmer: loading,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BalanceCard(
                        label: t.dashboard.balance.locked,
                        amount: b?.locked ?? 0,
                        currency: b?.currency ?? 'EUR',
                        moneyLocale: moneyLocale,
                        accent: AppColors.primary,
                        icon: Icons.lock_outline_rounded,
                        shimmer: loading,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BalanceCard(
                        label: t.dashboard.balance.spent,
                        amount: b?.spent ?? 0,
                        currency: b?.currency ?? 'EUR',
                        moneyLocale: moneyLocale,
                        accent: const Color(0xFF8B5CF6),
                        icon: Icons.trending_down_rounded,
                        shimmer: loading,
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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.moneyLocale,
    required this.accent,
    required this.icon,
    required this.shimmer,
  });

  final String label;
  final double amount;
  final String currency;
  final String moneyLocale;
  final Color accent;
  final IconData icon;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = MoneyFormatter.format(amount, currency: currency, locale: moneyLocale);
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimaryOf(context),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
    card = AnimatedGradientBorder(child: card);
    if (shimmer) {
      card = Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.02),
        highlightColor: accent.withValues(alpha: 0.12),
        period: const Duration(seconds: 2),
        child: card,
      );
    }
    return RepaintBoundary(child: card);
  }
}

class _CampaignsSection extends StatelessWidget {
  const _CampaignsSection({required this.snapshot, required this.isLoading});

  final DashboardSnapshot snapshot;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final list = snapshot.campaigns;
    final loading =
        isLoading && list.isEmpty && snapshot.campaignsError == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.dashboard.campaigns.title, style: AppTextStyles.headlineMedium(context)),
          const SizedBox(height: 4),
          Text(t.dashboard.campaigns.subtitle, style: AppTextStyles.bodyLarge(context)),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (list.isEmpty)
            _EmptyCampaigns()
          else
            AnimationLimiter(
              child: Column(
                children: List.generate(list.length, (index) {
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
              ),
            ),
        ],
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              '/campaigns/${c.id}',
              extra: <String, String?>{'coverUrl': c.coverUrl, 'title': c.name},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Hero(
                  tag: 'campaign_cover_${c.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: c.coverUrl != null && c.coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: c.coverUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            memCacheWidth: 120,
                            memCacheHeight: 120,
                            errorWidget: (context, url, _) => _PlatformIcon(platform: c.platform),
                          )
                        : SizedBox(
                            width: 56,
                            height: 56,
                            child: _PlatformIcon(platform: c.platform),
                          ),
                  ),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              c.status.name,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t.dashboard.campaigns.creators
                                .replaceAll('{count}', '${c.creatorsCount}'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMutedOf(context),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMutedOf(context)),
              ],
            ),
          ),
        ),
      ),
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
      color: AppColors.surfaceOf(context),
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
        Icon(Icons.folder_open_rounded, size: 72, color: AppColors.textMutedOf(context))
            .animate()
            .moveY(begin: 6, end: 0, duration: 900.ms, curve: Curves.easeOutCubic)
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
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => GoRouter.of(context).go('/campaigns'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(t.dashboard.campaigns.create_cta),
        ),
      ],
    );
  }
}
