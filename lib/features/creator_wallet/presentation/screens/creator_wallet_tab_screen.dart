import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../domain/creator_business_profile.dart';
import '../../domain/creator_wallet_models.dart';
import '../providers/creator_wallet_providers.dart';
import '../widgets/business_info_cta.dart';
import '../widgets/business_info_dialog.dart';
import '../widgets/creator_stripe_connect_card.dart';
import '../widgets/creator_wallet_hero.dart';
import '../widgets/creator_withdraw_sheet.dart';
import '../widgets/creator_withdrawals_list.dart';

String _moneyLocale(AppLocale l) => switch (l) {
  AppLocale.en => 'en_US',
  AppLocale.fr => 'fr_FR',
  AppLocale.ar => 'ar_SA',
};

/// Creator **wallet** — balance, Stripe Connect, payout requests & history.
///
/// Data sources:
/// - `GET /api/creator/withdrawal` → balance + limits + history
/// - `GET /api/creator/stripe-connect/status` → onboarding flags
/// - `POST /api/creator/withdrawal` → new payout
/// - `POST /api/creator/stripe-connect/{onboard,login}` → signed Stripe URL
///
/// Real-time refresh is driven by the `private-creator.{userId}` Reverb channel
/// (`balance.updated`, `payout.*`, `stripe.*`) via [realtimeInvalidationProvider].
class CreatorWalletTabScreen extends ConsumerWidget {
  const CreatorWalletTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final pageAsync = ref.watch(creatorWalletPageProvider);
    final stripeAsync = ref.watch(creatorStripeStatusProvider);
    final profileAsync = ref.watch(creatorBusinessProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: CreatorColors.primaryOf(context),
        onRefresh: () async {
          ref.invalidate(creatorWalletPageProvider);
          ref.invalidate(creatorStripeStatusProvider);
          ref.invalidate(creatorBusinessProfileProvider);
          HapticFeedback.lightImpact();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 12,
                  20,
                  4,
                ),
                child: _Header(t: t),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: pageAsync.when(
                  loading: () => const _HeroSkeleton(),
                  error: (e, _) => ErrorBanner(
                    message: t.creator.wallet.load_error,
                    retryLabel: t.dashboard.errors.retry,
                    onRetry: () => ref.invalidate(creatorWalletPageProvider),
                  ),
                  data: (page) => _BalanceBlock(
                    page: page,
                    stripe:
                        stripeAsync.valueOrNull ??
                        CreatorStripeStatus.disconnected,
                    profile: profileAsync.valueOrNull,
                    moneyLocale: moneyLocale,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: profileAsync.when(
                  loading: () => const _CardSkeleton(height: 120),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (profile) {
                    // Business info acts as a gate before Stripe onboarding.
                    // Backend `/api/creator/stripe-connect/onboard` rejects the
                    // request with 400 if business info isn't complete.
                    if (!profile.businessInfoComplete) {
                      return BusinessInfoCta(
                        onPressed: () =>
                            _openBusinessInfoDialog(context, profile),
                      );
                    }
                    return stripeAsync.when(
                      loading: () => const _CardSkeleton(height: 120),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (s) => CreatorStripeConnectCard(status: s),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: pageAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (page) => _WithdrawalConditionsCard(
                    limits: page.limits,
                    currency: page.balance.currency,
                    moneyLocale: moneyLocale,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      t.creator.wallet.history_title,
                      style: AppTextStyles.headlineMedium(context),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: pageAsync.when(
                  loading: () => const _HistorySkeleton(),
                  error: (e, _) => ErrorBanner(
                    message: t.creator.wallet.history_load_error,
                    retryLabel: t.dashboard.errors.retry,
                    onRetry: () => ref.invalidate(creatorWalletPageProvider),
                  ),
                  data: (page) => CreatorWithdrawalsList(
                    items: page.withdrawals,
                    moneyLocale: moneyLocale,
                  ),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
          ],
        ),
      ),
    );
  }

  Future<void> _openBusinessInfoDialog(
    BuildContext context,
    CreatorBusinessProfile profile,
  ) async {
    HapticFeedback.lightImpact();
    await showBusinessInfoDialog(context, initial: profile);
    // The dialog itself invalidates the providers on success; nothing else to
    // do here. The Stripe card will appear automatically once
    // `businessInfoComplete == true`.
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.t});
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.nav.wallet, style: AppTextStyles.displayLarge(context)),
              const SizedBox(height: 4),
              Row(children: [_RolePill(label: t.dashboard.account_creator)]),
            ],
          ),
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

class _BalanceBlock extends ConsumerWidget {
  const _BalanceBlock({
    required this.page,
    required this.stripe,
    required this.profile,
    required this.moneyLocale,
  });

  final CreatorWalletPage page;
  final CreatorStripeStatus stripe;
  final CreatorBusinessProfile? profile;
  final String moneyLocale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final balance = page.balance;
    final limits = page.limits;
    final businessReady = profile?.businessInfoComplete ?? false;
    final canWithdraw =
        businessReady &&
        stripe.canWithdraw &&
        balance.availableCents >= limits.minimumWithdrawalCents;

    final reasonForDisabled = _disabledReason(
      t,
      balance,
      limits,
      stripe,
      businessReady: businessReady,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CreatorWalletHero(balance: balance, moneyLocale: moneyLocale),
        const SizedBox(height: 12),
        _WithdrawButton(
          enabled: canWithdraw,
          onPressed: canWithdraw
              ? () async {
                  final ok = await showCreatorWithdrawSheet(
                    context,
                    page: page,
                    moneyLocale: moneyLocale,
                  );
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text(
                          t.creator.wallet.withdraw_success,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                }
              : null,
          label: t.creator.wallet.withdraw_button,
          minAmount: MoneyFormatter.format(
            limits.minimumWithdrawal,
            currency: balance.currency,
            locale: moneyLocale,
          ),
        ),
        if (reasonForDisabled != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textMutedOf(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reasonForDisabled,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String? _disabledReason(
    Translations t,
    CreatorBalance balance,
    CreatorPlatformLimits limits,
    CreatorStripeStatus stripe, {
    required bool businessReady,
  }) {
    if (!businessReady) {
      return t.creator.wallet.withdraw_reason_business_info;
    }
    if (!stripe.connected) {
      return t.creator.wallet.withdraw_reason_stripe;
    }
    if (!stripe.onboardingCompleted || stripe.requirementsDue) {
      return t.creator.wallet.withdraw_reason_stripe_incomplete;
    }
    if (!stripe.payoutsEnabled) {
      return t.creator.wallet.withdraw_reason_payouts_disabled;
    }
    if (balance.availableCents < limits.minimumWithdrawalCents) {
      return t.creator.wallet.withdraw_reason_below_min.replaceAll(
        '{min}',
        MoneyFormatter.format(
          limits.minimumWithdrawal,
          currency: balance.currency,
          locale: 'fr_FR',
        ),
      );
    }
    return null;
  }
}

class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton({
    required this.enabled,
    required this.onPressed,
    required this.label,
    required this.minAmount,
  });

  final bool enabled;
  final VoidCallback? onPressed;
  final String label;
  final String minAmount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.call_made_rounded, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? CreatorColors.primaryOf(context)
              : AppColors.surfaceElevatedOf(context),
          foregroundColor: enabled
              ? Colors.white
              : AppColors.textMutedOf(context),
          disabledBackgroundColor: AppColors.surfaceElevatedOf(context),
          disabledForegroundColor: AppColors.textMutedOf(context),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Read-only card summarising the platform withdrawal rules (minimum amount,
/// platform fee, processing time). Values come from `GET /api/creator/withdrawal`
/// so they stay in sync with the backend; the processing time is a static SLA.
class _WithdrawalConditionsCard extends StatelessWidget {
  const _WithdrawalConditionsCard({
    required this.limits,
    required this.currency,
    required this.moneyLocale,
  });

  final CreatorPlatformLimits limits;
  final String currency;
  final String moneyLocale;

  String _formatFee(BuildContext context) {
    final t = context.t;
    final rate = limits.platformFeeRate;
    final percent = rate <= 1 ? rate * 100.0 : rate;
    final rounded = percent.toStringAsFixed(
      percent.truncateToDouble() == percent ? 0 : 1,
    );
    final description = limits.platformFeeDescription?.trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }
    return t.creator.wallet.conditions_fee_value(percent: '$rounded%');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final accent = CreatorColors.primaryOf(context);
    final minAmount = MoneyFormatter.format(
      limits.minimumWithdrawal,
      currency: currency,
      locale: moneyLocale,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceElevatedOf(context),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.verified_outlined, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.creator.wallet.conditions_title,
                      style: AppTextStyles.labelLarge(
                        context,
                      ).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.creator.wallet.conditions_subtitle,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ConditionRow(
            icon: Icons.payments_outlined,
            label: t.creator.wallet.conditions_min_label,
            value: minAmount,
          ),
          const SizedBox(height: 8),
          _ConditionRow(
            icon: Icons.percent_rounded,
            label: t.creator.wallet.conditions_fee_label,
            value: _formatFee(context),
          ),
          const SizedBox(height: 8),
          _ConditionRow(
            icon: Icons.schedule_rounded,
            label: t.creator.wallet.conditions_processing_label,
            value: t.creator.wallet.conditions_processing_value,
          ),
        ],
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMutedOf(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(color: AppColors.textSecondaryOf(context), fontSize: 13),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelLarge(
            context,
          ).copyWith(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 64,
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
