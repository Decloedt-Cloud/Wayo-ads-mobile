import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../creator_wallet/presentation/screens/creator_wallet_tab_screen.dart';
import '../../../dashboard/data/repositories/dashboard_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../widgets/advertiser_wallet_tab_content.dart';

String _moneyLocale(AppLocale l) => switch (l) {
  AppLocale.en => 'en_US',
  AppLocale.fr => 'fr_FR',
  AppLocale.ar => 'ar_SA',
};

/// Wallet tab — [WayoAdsAccountRole.advertiser]: full wallet + Stripe / Apple Pay / Google Pay.
/// Other roles: read-only balance from dashboard stream.
class WalletTabScreen extends ConsumerWidget {
  const WalletTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final async = ref.watch(dashboardStreamProvider);
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    final roleLine = switch (role) {
      WayoAdsAccountRole.creator => t.dashboard.account_creator,
      WayoAdsAccountRole.advertiser => t.dashboard.account_advertiser,
      _ => null,
    };

    if (role == WayoAdsAccountRole.advertiser) {
      return Scaffold(
        appBar: AppBar(title: Text(t.nav.wallet), elevation: 0),
        body: const AdvertiserWalletTabContent(),
      );
    }

    if (role == WayoAdsAccountRole.creator) {
      return const CreatorWalletTabScreen();
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.nav.wallet), elevation: 0),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref
              .read(authNotifierProvider.notifier)
              .refreshProfileFromAuthServer();
          ref.invalidate(dashboardStreamProvider);
          await ref.read(dashboardStreamProvider.future);
          HapticFeedback.lightImpact();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            if (roleLine != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  roleLine,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: AppColors.textSecondaryOf(context)),
                ),
              ),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) =>
                  Text('$e', style: AppTextStyles.bodyLarge(context)),
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
                    _NonAdvertiserBalanceBlock(
                      snapshot: snap,
                      moneyLocale: moneyLocale,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NonAdvertiserBalanceBlock extends StatelessWidget {
  const _NonAdvertiserBalanceBlock({
    required this.snapshot,
    required this.moneyLocale,
  });

  final DashboardSnapshot snapshot;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = snapshot.balance;
    final loading = b == null && snapshot.balanceError == null;
    final currency = b?.currency ?? 'EUR';
    final hasBalance = b != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.dashboard.balance.title,
          style: AppTextStyles.headlineMedium(context),
        ),
        const SizedBox(height: 16),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (!hasBalance)
          Text(
            t.dashboard.errors.load_balance,
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(color: AppColors.textSecondaryOf(context)),
          )
        else
          Column(
            children: [
              _WalletMetricTile(
                label: t.dashboard.balance.available,
                value: MoneyFormatter.format(
                  b.available,
                  currency: currency,
                  locale: moneyLocale,
                ),
                icon: Icons.account_balance_wallet_outlined,
                accent: const Color(0xFF10B981),
              ),
              const SizedBox(height: 10),
              _WalletMetricTile(
                label: t.dashboard.balance.locked,
                value: MoneyFormatter.format(
                  b.locked,
                  currency: currency,
                  locale: moneyLocale,
                ),
                icon: Icons.lock_outline_rounded,
                accent: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _WalletMetricTile(
                label: t.dashboard.balance.spent,
                value: MoneyFormatter.format(
                  b.spent,
                  currency: currency,
                  locale: moneyLocale,
                ),
                icon: Icons.trending_down_rounded,
                accent: const Color(0xFF8B5CF6),
              ),
            ],
          ),
      ],
    );
  }
}

class _WalletMetricTile extends StatelessWidget {
  const _WalletMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: AppColors.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.headlineMedium(
                      context,
                    ).copyWith(fontSize: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
