import 'dart:math' as math;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../creator_wallet/domain/creator_business_profile.dart';
import '../../../creator_wallet/presentation/providers/creator_wallet_providers.dart';
import '../../../creator_wallet/presentation/screens/business_info_screen.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../data/advertiser_wallet_repository.dart';
import '../../domain/advertiser_deposit_charge.dart';
import '../../domain/wallet_models.dart';
import '../../presentation/providers/advertiser_wallet_providers.dart';
import '../../stripe/advertiser_stripe_deposit.dart';

enum _PayMethod { card, applePay, googlePay }

const int _kWalletTxPageSize = 7;
/// Minimum top-up amount in minor units (e.g. cents): 50.00 in wallet currency.
const int _kMinDepositCents = 5000;

/// Advertiser-only wallet: balance, transactions, Stripe card + Apple Pay / Google Pay.
class AdvertiserWalletTabContent extends ConsumerStatefulWidget {
  const AdvertiserWalletTabContent({super.key});

  @override
  ConsumerState<AdvertiserWalletTabContent> createState() =>
      _AdvertiserWalletTabContentState();
}

class _AdvertiserWalletTabContentState
    extends ConsumerState<AdvertiserWalletTabContent> {
  final _amountCtrl = TextEditingController();
  _PayMethod? _busyMethod;
  int _txPage = 0;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    super.dispose();
  }

  int? _amountToCents(String raw) {
    final s = raw.replaceAll(',', '.').trim();
    if (s.isEmpty) {
      return null;
    }
    final v = double.tryParse(s);
    if (v == null) {
      return null;
    }
    return (v * 100).round();
  }

  Future<void> _refresh() async {
    ref.invalidate(advertiserWalletPageProvider);
    ref.invalidate(dashboardStreamProvider);
    await ref.read(advertiserWalletPageProvider.future);
  }

  void _toast(String msg) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String _txLabel(String type, Translations t) {
    final u = type.toUpperCase();
    if (u.contains('DEPOSIT')) {
      return t.advertiser_wallet.tx_deposit;
    }
    if (u.contains('WITHDRAW')) {
      return t.advertiser_wallet.tx_withdrawal;
    }
    return t.advertiser_wallet.tx_other;
  }

  Future<WalletPspConfig?> _ensureStripeReady() async {
    final t = context.t;
    final cfg = await ref.read(walletPspConfigProvider.future);
    if (!cfg.isStripe || (cfg.publishableKey?.isEmpty ?? true)) {
      _toast(t.advertiser_wallet.stripe_unavailable);
      return null;
    }
    await AdvertiserStripeDeposit.ensureSdkReady(
      publishableKey: cfg.publishableKey!,
    );
    return cfg;
  }

  /// Create PI + confirm with either Payment Sheet (card) or native Apple/Google Pay.
  Future<void> _submit({
    required _PayMethod method,
    required String currency,
  }) async {
    if (_busyMethod != null) {
      return;
    }
    final t = context.t;
    final cents = _amountToCents(_amountCtrl.text);
    if (cents == null || cents < _kMinDepositCents) {
      _toast(t.advertiser_wallet.min_deposit);
      return;
    }
    setState(() => _busyMethod = method);
    final repo = ref.read(advertiserWalletRepositoryProvider);
    try {
      final intent = await repo.createDepositIntent(
        amountCents: cents,
        currency: currency,
      );

      // Dev / mock PSP path — no Stripe SDK at all.
      if (intent.canSimulate) {
        await repo.simulatePspSuccess(intent.intentId);
        if (!mounted) {
          return;
        }
        _toast(t.advertiser_wallet.success);
        await _refresh();
        return;
      }

      final cfg = await _ensureStripeReady();
      if (cfg == null) {
        return;
      }

      try {
        switch (method) {
          case _PayMethod.card:
            await AdvertiserStripeDeposit.presentCardPaymentSheet(
              clientSecret: intent.clientSecret,
              currency: intent.currency,
            );
            break;
          case _PayMethod.applePay:
            await AdvertiserStripeDeposit.confirmWithApplePay(
              clientSecret: intent.clientSecret,
              currency: intent.currency,
              amountCents: intent.amountCents,
            );
            break;
          case _PayMethod.googlePay:
            await AdvertiserStripeDeposit.confirmWithGooglePay(
              clientSecret: intent.clientSecret,
              currency: intent.currency,
            );
            break;
        }
      } on StripeException catch (e) {
        if (AdvertiserStripeDeposit.isUserCancelled(e)) {
          return;
        }
        final msg = AdvertiserStripeDeposit.describeError(e);
        _toast(msg);
        if (kDebugMode) {
          debugPrint('[Stripe] payment error: $msg');
        }
        return;
      }

      await repo.confirmDeposit(intent.intentId);
      if (!mounted) {
        return;
      }
      _toast(t.advertiser_wallet.success);

      await _refresh();
    } on ServerException catch (e) {
      _toast(e.message.isNotEmpty ? e.message : t.advertiser_wallet.failed);
    } catch (e) {
      final msg = AdvertiserStripeDeposit.describeError(e);
      _toast(msg.isNotEmpty ? msg : t.advertiser_wallet.failed);
      if (kDebugMode) {
        debugPrint('[Wallet] deposit error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busyMethod = null);
      }
    }
  }

  Future<void> _openBusinessProfileEditor() async {
    final user = ref.read(currentAppUserProvider);
    if (user == null || !mounted) {
      return;
    }
    CreatorBusinessProfile initial;
    try {
      initial = await ref.read(creatorBusinessProfileProvider.future);
    } catch (_) {
      initial = CreatorBusinessProfile.empty();
    }
    final useGlobal = user.shouldUseAdvertiserGlobalBusinessSchema;
    final ok = await openBusinessInfoScreen(
      context,
      initial: initial,
      useGlobalBilling: useGlobal,
    );
    if (!mounted || !ok) {
      return;
    }
    ref.invalidate(creatorBusinessProfileProvider);
    ref.invalidate(advertiserWalletPageProvider);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final AppLocale appLoc = ref.watch(localeProvider);
    final moneyLocale = switch (appLoc) {
      AppLocale.en => 'en_US',
      AppLocale.fr => 'fr_FR',
      AppLocale.ar => 'ar_SA',
    };
    final async = ref.watch(advertiserWalletPageProvider);
    return async.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            e is ServerException ? e.message : t.advertiser_wallet.failed,
            style: AppTextStyles.bodyLarge(context),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _refresh,
            child: Text(t.dashboard.errors.retry),
          ),
        ],
      ),
      data: (data) {
        final profileAsync = ref.watch(creatorBusinessProfileProvider);
        return profileAsync.when(
          loading: () => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _HeroHeader(
                  data: data,
                  moneyLocale: moneyLocale,
                  isDark: isDark,
                  t: t,
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(40, 48, 40, 0),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          error: (err, _) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(creatorBusinessProfileProvider);
              await _refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _HeroHeader(
                  data: data,
                  moneyLocale: moneyLocale,
                  isDark: isDark,
                  t: t,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BusinessProfileLoadError(
                        message: err is ServerException
                            ? err.message
                            : t.advertiser_wallet.business_profile_error,
                        onRetry: () => ref.invalidate(creatorBusinessProfileProvider),
                        t: t,
                      ),
                      const SizedBox(height: 20),
                      _BusinessInfoRequiredGate(
                        onComplete: _openBusinessProfileEditor,
                        t: t,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          data: (profile) {
            final businessReady = profile.businessInfoComplete;
            final c = data.balance.currency;
            final nTx = data.transactions.length;
            final maxTxPage = nTx == 0 ? 0 : (nTx - 1) ~/ _kWalletTxPageSize;
            if (_txPage > maxTxPage) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _txPage = maxTxPage);
                }
              });
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  _HeroHeader(
                    data: data,
                    moneyLocale: moneyLocale,
                    isDark: isDark,
                    t: t,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!businessReady) ...[
                          _BusinessInfoRequiredGate(
                            onComplete: _openBusinessProfileEditor,
                            t: t,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          t.advertiser_wallet.amount_label,
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondaryOf(context)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountCtrl,
                          readOnly: !businessReady,
                          onTap: !businessReady ? () => _openBusinessProfileEditor() : null,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          ],
                          decoration: InputDecoration(
                            prefixText: '$c ',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            hintText: '0.00',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _QuickChip(
                              label: t.advertiser_wallet.quick_50,
                              onTap: businessReady
                                  ? () => _amountCtrl.text = '50'
                                  : () {
                                      _openBusinessProfileEditor();
                                    },
                            ),
                            _QuickChip(
                              label: t.advertiser_wallet.quick_100,
                              onTap: businessReady
                                  ? () => _amountCtrl.text = '100'
                                  : () {
                                      _openBusinessProfileEditor();
                                    },
                            ),
                            _QuickChip(
                              label: t.advertiser_wallet.quick_250,
                              onTap: businessReady
                                  ? () => _amountCtrl.text = '250'
                                  : () {
                                      _openBusinessProfileEditor();
                                    },
                            ),
                          ],
                        ),
                        if (data.canSimulate) ...[
                          const SizedBox(height: 8),
                          Text(
                            t.advertiser_wallet.test_hint,
                            style: AppTextStyles.caption(
                              context,
                            ).copyWith(color: AppColors.textMutedOf(context)),
                          ),
                        ],
                        if (businessReady) ...[
                          Builder(
                            builder: (context) {
                              final walletCents = _amountToCents(_amountCtrl.text);
                              if (walletCents == null ||
                                  walletCents < _kMinDepositCents) {
                                return const SizedBox.shrink();
                              }
                              final charge = estimateAdvertiserDepositCharge(
                                walletAmountCents: walletCents,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: _DepositPaymentSummary(
                                  charge: charge,
                                  currency: c,
                                  moneyLocale: moneyLocale,
                                  t: t,
                                  isDark: isDark,
                                ),
                              );
                            },
                          ),
                        ],
                        if (businessReady) ...[
                          const SizedBox(height: 24),
                          _WalletPayStrip(
                            data: data,
                            t: t,
                            busyMethod: _busyMethod,
                            onCard: () =>
                                _submit(method: _PayMethod.card, currency: c),
                            onApplePay: () =>
                                _submit(method: _PayMethod.applePay, currency: c),
                            onGooglePay: () =>
                                _submit(method: _PayMethod.googlePay, currency: c),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          _WalletPayStripPlaceholder(t: t),
                        ],
                        const SizedBox(height: 28),
                        Text(
                          t.advertiser_wallet.tx_title,
                          style: AppTextStyles.headlineMedium(
                            context,
                          ).copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 12),
                        _RecentActivityPager(
                          transactions: data.transactions,
                          moneyLocale: moneyLocale,
                          pageIndex: _txPage,
                          onPageIndexChange: (p) => setState(() => _txPage = p),
                          txLabel: _txLabel,
                          t: t,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BusinessProfileLoadError extends StatelessWidget {
  const _BusinessProfileLoadError({
    required this.message,
    required this.onRetry,
    required this.t,
  });

  final String message;
  final VoidCallback onRetry;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.bodyLarge(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(t.dashboard.errors.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compliance gate before wallet top-up (mirrors Wayo-ads web wallet).
class _BusinessInfoRequiredGate extends StatelessWidget {
  const _BusinessInfoRequiredGate({
    required this.onComplete,
    required this.t,
    required this.isDark,
  });

  final VoidCallback onComplete;
  final Translations t;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1814),
                  const Color(0xFF252015).withValues(alpha: 0.95),
                  const Color(0xFF0D0D0D),
                ]
              : [
                  const Color(0xFFFFF8ED),
                  const Color(0xFFFFEFD6),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: const Color(0xFFF4A237).withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF059669),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.advertiser_wallet.business_profile_gate_title,
                        style: AppTextStyles.headlineMedium(context).copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.advertiser_wallet.business_profile_gate_body,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          height: 1.4,
                          color: AppColors.textSecondaryOf(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.textMutedOf(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.advertiser_wallet.business_profile_gate_secure,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textMutedOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onComplete,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                t.advertiser_wallet.business_profile_gate_cta,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletPayStripPlaceholder extends StatelessWidget {
  const _WalletPayStripPlaceholder({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.85),
        ),
        color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color: AppColors.textMutedOf(context),
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              t.advertiser_wallet.pay_locked_until_business,
              style: AppTextStyles.bodyLarge(context).copyWith(
                color: AppColors.textMutedOf(context),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary card CTA, optional native wallet, modern glass + gradient.
class _WalletPayStrip extends StatelessWidget {
  const _WalletPayStrip({
    required this.data,
    required this.t,
    required this.busyMethod,
    required this.onCard,
    required this.onApplePay,
    required this.onGooglePay,
  });

  final AdvertiserWalletPageData data;
  final Translations t;
  final _PayMethod? busyMethod;
  final VoidCallback onCard;
  final VoidCallback onApplePay;
  final VoidCallback onGooglePay;

  @override
  Widget build(BuildContext context) {
    final isSim = data.canSimulate;
    final cardBusy = busyMethod == _PayMethod.card;
    final appleBusy = busyMethod == _PayMethod.applePay;
    final googleBusy = busyMethod == _PayMethod.googlePay;
    final anyBusy = busyMethod != null;

    // Always show card + the platform wallet (iOS: Apple Pay, Android: Google Pay)
    // when not in dev/mock mode — not gated on isPlatformPaySupported.
    final showApple = !isSim && Platform.isIOS;
    final showGoogle = !isSim && Platform.isAndroid;
    final showWallet = showApple || showGoogle;

    const cardRadius = 22.0;

    final cardCta = Material(
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        onTap: anyBusy ? null : onCard,
        borderRadius: BorderRadius.circular(cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD08A), Color(0xFFF4A237), Color(0xFFE08B12)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF4A237).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: cardBusy
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.black87,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.credit_card_rounded,
                      color: Colors.black87,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isSim
                          ? t.advertiser_wallet.test_pay
                          : t.advertiser_wallet.pay_with_card,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.2,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    if (!showWallet) {
      return cardCta;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cardCta,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.borderOf(context).withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                t.advertiser_wallet.or,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textMutedOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.borderOf(context).withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (showApple)
          _NativeWalletCta(
            busy: appleBusy,
            anyBusy: anyBusy,
            onPressed: onApplePay,
            label: t.advertiser_wallet.pay_with_apple,
            isApple: true,
          ),
        if (showGoogle)
          _NativeWalletCta(
            busy: googleBusy,
            anyBusy: anyBusy,
            onPressed: onGooglePay,
            label: t.advertiser_wallet.pay_with_google,
            isApple: false,
          ),
      ],
    );
  }
}

class _NativeWalletCta extends StatelessWidget {
  const _NativeWalletCta({
    required this.busy,
    required this.anyBusy,
    required this.onPressed,
    required this.label,
    required this.isApple,
  });

  final bool busy;
  final bool anyBusy;
  final VoidCallback onPressed;
  final String label;
  final bool isApple;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0C0C0C),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: anyBusy ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFFFAFAFA),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isApple
                          ? Icons.apple
                          : Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFFFAFAFA),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RecentActivityPager extends StatelessWidget {
  const _RecentActivityPager({
    required this.transactions,
    required this.moneyLocale,
    required this.pageIndex,
    required this.onPageIndexChange,
    required this.txLabel,
    required this.t,
  });

  final List<WalletTransactionRow> transactions;
  final String moneyLocale;
  final int pageIndex;
  final ValueChanged<int> onPageIndexChange;
  final String Function(String, Translations) txLabel;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Text(
        t.advertiser_wallet.tx_empty,
        style: AppTextStyles.bodyLarge(
          context,
        ).copyWith(color: AppColors.textMutedOf(context)),
      );
    }
    final n = transactions.length;
    final maxPage = (n - 1) ~/ _kWalletTxPageSize;
    final p = pageIndex.clamp(0, maxPage);
    final start = p * _kWalletTxPageSize;
    final end = math.min(start + _kWalletTxPageSize, n);
    final slice = transactions.sublist(start, end);
    final totalPages = maxPage + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final x in slice)
          _TxRow(
            row: x,
            moneyLocale: moneyLocale,
            typeLabel: txLabel(x.type, t),
          ),
        if (n > _kWalletTxPageSize) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PagerIcon(
                icon: Icons.chevron_left_rounded,
                tooltip: t.advertiser_wallet.tx_prev,
                enabled: p > 0,
                onPressed: p > 0
                    ? () {
                        onPageIndexChange(p - 1);
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                t.advertiser_wallet.tx_page(current: p + 1, total: totalPages),
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(width: 8),
              _PagerIcon(
                icon: Icons.chevron_right_rounded,
                tooltip: t.advertiser_wallet.tx_next,
                enabled: p < maxPage,
                onPressed: p < maxPage
                    ? () {
                        onPageIndexChange(p + 1);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PagerIcon extends StatelessWidget {
  const _PagerIcon({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceElevatedOf(context),
        foregroundColor: AppColors.textPrimaryOf(
          context,
        ).withValues(alpha: enabled ? 1 : 0.35),
      ),
      icon: Icon(icon, size: 28),
    );
  }
}

class _DepositPaymentSummary extends StatelessWidget {
  const _DepositPaymentSummary({
    required this.charge,
    required this.currency,
    required this.moneyLocale,
    required this.t,
    required this.isDark,
  });

  final AdvertiserDepositCharge charge;
  final String currency;
  final String moneyLocale;
  final Translations t;
  final bool isDark;

  String _money(int cents) {
    return MoneyFormatter.format(
      cents / 100.0,
      currency: currency,
      locale: moneyLocale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelBg = isDark
        ? const Color(0xFF242424)
        : AppColors.surfaceElevatedOf(context);
    final cardBg = isDark
        ? const Color(0xFF141414)
        : AppColors.surfaceOf(context);
    final muted = AppColors.textSecondaryOf(context);
    final primary = AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                t.advertiser_wallet.payment_title,
                style: AppTextStyles.headlineMedium(context).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            t.advertiser_wallet.payment_total,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _money(charge.totalChargedCents),
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium(context).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderOf(context).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                _DepositBreakdownRow(
                  label: t.advertiser_wallet.payment_deposit_amount,
                  value: _money(charge.walletAmountCents),
                  muted: muted,
                ),
                if (charge.bankFeeCents > 0) ...[
                  const SizedBox(height: 10),
                  _DepositBreakdownRow(
                    label: t.advertiser_wallet.payment_bank_fee,
                    value: _money(charge.bankFeeCents),
                    muted: muted,
                    accentColor: primary,
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

class _DepositBreakdownRow extends StatelessWidget {
  const _DepositBreakdownRow({
    required this.label,
    required this.value,
    required this.muted,
    this.accentColor,
  });

  final String label;
  final String value;
  final Color muted;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.caption(context).copyWith(
      color: muted,
      fontSize: accentColor != null ? 12 : 14,
    );
    final valueStyle = AppTextStyles.bodyLarge(context).copyWith(
      fontWeight: FontWeight.w600,
      fontSize: accentColor != null ? 12 : 14,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (accentColor != null)
          Container(
            width: 2,
            height: 18,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: accentColor!.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 8),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.data,
    required this.moneyLocale,
    required this.isDark,
    required this.t,
  });

  final AdvertiserWalletPageData data;
  final String moneyLocale;
  final bool isDark;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final c = data.balance.currency;
    final a = data.balance.available;
    final p = data.balance.locked;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E1B16), Color(0xFF2A2318), Color(0xFF0F0F0F)]
              : const [Color(0xFFFFF6E8), Color(0xFFFFE8CC), Color(0xFFFFFFFF)],
        ),
        border: Border.all(
          color: const Color(0xFFF4A237).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.advertiser_wallet.hero_title,
            style: AppTextStyles.headlineMedium(context).copyWith(
              fontSize: 14,
              letterSpacing: 0.4,
              color: const Color(0xFFF4A237),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.advertiser_wallet.hero_subtitle,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.textSecondaryOf(context), height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            t.advertiser_wallet.available,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.textMutedOf(context)),
          ),
          const SizedBox(height: 4),
          Text(
            MoneyFormatter.format(a, currency: c, locale: moneyLocale),
            style: AppTextStyles.displayLarge(
              context,
            ).copyWith(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            t.advertiser_wallet.pending,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.textMutedOf(context)),
          ),
          const SizedBox(height: 4),
          Text(
            MoneyFormatter.format(p, currency: c, locale: moneyLocale),
            style: AppTextStyles.headlineMedium(context).copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.row,
    required this.moneyLocale,
    required this.typeLabel,
  });

  final WalletTransactionRow row;
  final String moneyLocale;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final c = row.currency;
    final signed = row.amountCents;
    final major = signed / 100.0;
    final s = MoneyFormatter.format(
      major.abs(),
      currency: c,
      locale: moneyLocale,
    );
    final prefix = signed < 0 ? '−' : '+';
    final dateStr = row.createdAt != null
        ? DateFormat.yMMMd(
            moneyLocale,
          ).add_Hm().format(row.createdAt!.toLocal())
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          title: Text(
            typeLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            row.description.isNotEmpty
                ? row.description
                : (dateStr.isNotEmpty ? dateStr : ''),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 13,
            ),
          ),
          trailing: Text(
            '$prefix$s',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: signed >= 0
                  ? const Color(0xFF10B981)
                  : AppColors.textPrimaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}
