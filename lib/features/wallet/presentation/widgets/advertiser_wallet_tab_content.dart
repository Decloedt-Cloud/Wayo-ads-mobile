import 'dart:math' as math;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/platform/android_window_insets.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/widgets/google_pay_button.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../creator_wallet/domain/creator_business_profile.dart';
import '../../../creator_wallet/presentation/providers/creator_wallet_providers.dart';
import '../../../creator_wallet/presentation/screens/business_info_screen.dart';
import '../../data/advertiser_wallet_repository.dart';
import '../../domain/advertiser_deposit_charge.dart';
import '../../domain/wallet_models.dart';
import '../../presentation/providers/advertiser_deposit_sync.dart';
import '../../presentation/providers/advertiser_wallet_providers.dart';
import '../../stripe/advertiser_stripe_deposit.dart';

enum _PayMethod { card, applePay, googlePay }

/// Advertiser wallet top-up rail — mirrors web `WalletFundingMethod`.
enum _FundingMethod { card, ach, wire }

const int _kWalletTxPageSize = 7;
/// Minimum top-up amount in minor units — mirrors server
/// `ADVERTISER_MIN_DEPOSIT_CENTS` (Wayo-ads `lib/finance/types.ts`).
const int _kMinDepositCents = 51;

const List<double> _kQuickDepositAmounts = [50, 100, 500];

/// Currencies with Stripe bank-transfer rails enabled — mirrors
/// `WIRE_DEPOSIT_CURRENCIES` (Wayo-ads `lib/finance/types.ts`).
const List<String> kWireDepositCurrencies = ['USD', 'EUR', 'GBP'];

/// Temporary: hide advertiser bank-wire ("virement") UI without deleting the flow.
/// Set to `true` to show wire funding again.
const bool kAdvertiserWireDepositUiEnabled = false;

bool _isWireDepositCurrencySupported(String currency) {
  return kWireDepositCurrencies.contains(currency.trim().toUpperCase());
}

bool _isWireDepositUiAvailable(String currency) {
  return kAdvertiserWireDepositUiEnabled &&
      _isWireDepositCurrencySupported(currency);
}

String _advertiserWalletMoneyLocale(String currency, String appMoneyLocale) {
  if (currency.toUpperCase() == kWayoPublicCurrency) {
    return wayoPublicMoneyLocale(AppLocale.en);
  }
  return appMoneyLocale;
}

String _formatAdvertiserWalletAmount(
  double amount,
  String currency,
  String appMoneyLocale,
) {
  return MoneyFormatter.format(
    amount,
    currency: currency,
    locale: _advertiserWalletMoneyLocale(currency, appMoneyLocale),
  );
}

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
  String? _dismissedPendingIntentId;
  _FundingMethod _fundingMethod = _FundingMethod.card;
  bool _useSavedCard = false;
  String? _selectedSavedCardId;
  bool _savedCardBusy = false;
  DepositIntentResult? _wireIntent;
  bool _wireBusy = false;
  final Set<String> _reconcilingIntentIds = {};

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
    invalidateAdvertiserWalletDepositSync(ref);
    await ref.read(advertiserWalletPageProvider.future);
  }

  /// Clears amount input and hides pending checkout after a completed/cancelled flow.
  void _clearDepositCheckout({String? dismissIntentId}) {
    _amountCtrl.clear();
    _dismissedPendingIntentId = dismissIntentId;
    _wireIntent = null;
    _useSavedCard = false;
    _selectedSavedCardId = null;
    invalidateAdvertiserWalletDepositSync(ref);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _restoreUiAfterStripeSheet() async {
    // Stripe Payment Sheet / Link Financial Connections can leave a dim
    // overlay or broken edge-to-edge insets on Android — restore chrome.
    FocusManager.instance.primaryFocus?.unfocus();
    final brightness =
        mounted ? Theme.of(context).brightness : Brightness.dark;
    final isDark = brightness == Brightness.dark;
    final nav = isDark ? AppColors.black : Colors.white;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: nav,
        systemNavigationBarDividerColor: nav,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
    await AndroidWindowInsets.setDecorFitsSystemWindows(false);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onDepositSucceeded({String? completedIntentId}) async {
    _clearDepositCheckout(dismissIntentId: completedIntentId);
    await _restoreUiAfterStripeSheet();
    await _refresh();
    if (!mounted) {
      return;
    }
    final pending = ref.read(advertiserPendingDepositProvider).valueOrNull;
    if (pending == null) {
      setState(() => _dismissedPendingIntentId = null);
    }
  }

  void _toast(String msg) {
    if (!mounted) {
      return;
    }
    WayoToast.info(context, msg);
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
    if (cfg.keysMismatch) {
      _toast(t.advertiser_wallet.stripe_keys_mismatch);
      return null;
    }
    await AdvertiserStripeDeposit.ensureSdkReady(
      publishableKey: cfg.publishableKey!,
    );
    return cfg;
  }

  Future<void> _confirmStripePayment({
    required DepositIntentResult intent,
    required _PayMethod method,
    String depositMethod = AdvertiserDepositMethod.card,
  }) async {
    final brightness = Theme.of(context).brightness;
    switch (method) {
      case _PayMethod.card:
        if (depositMethod == AdvertiserDepositMethod.ach) {
          await AdvertiserStripeDeposit.presentAchPaymentSheet(
            clientSecret: intent.clientSecret,
            brightness: brightness,
          );
        } else {
          await AdvertiserStripeDeposit.presentCardPaymentSheet(
            clientSecret: intent.clientSecret,
            currency: intent.currency,
            brightness: brightness,
          );
        }
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
          brightness: brightness,
        );
        break;
    }
  }

  DepositIntentResult _intentFromPending(AdvertiserPendingDeposit pending) {
    return DepositIntentResult(
      intentId: pending.intentId,
      clientSecret: pending.clientSecret,
      amountCents: pending.totalAmountCents,
      currency: pending.currency,
      canSimulate: false,
      walletAmountCents: pending.walletAmountCents,
      bankFeeCents: pending.bankFeeCents,
    );
  }

  /// Resume an in-progress deposit (GET /api/wallet/deposit-intent).
  Future<void> _completePendingDeposit({
    required AdvertiserPendingDeposit pending,
    required _PayMethod method,
    required bool canSimulate,
  }) async {
    if (_busyMethod != null) {
      return;
    }
    final t = context.t;
    setState(() => _busyMethod = method);
    final repo = ref.read(advertiserWalletRepositoryProvider);
    final intent = _intentFromPending(pending);
    try {
      if (canSimulate) {
        await repo.simulatePspSuccess(intent.intentId);
        if (!mounted) {
          return;
        }
        _toast(t.advertiser_wallet.success);
        await _onDepositSucceeded(completedIntentId: intent.intentId);
        return;
      }

      final cfg = await _ensureStripeReady();
      if (cfg == null) {
        return;
      }

      try {
        await _confirmStripePayment(
          intent: intent,
          method: method,
          depositMethod: pending.depositMethod,
        );
      } on StripeException catch (e) {
        if (AdvertiserStripeDeposit.isUserCancelled(e)) {
          invalidateAdvertiserWalletDepositSync(ref);
          await _restoreUiAfterStripeSheet();
          return;
        }
        final msg = AdvertiserStripeDeposit.describeError(e);
        _toast(msg);
        return;
      }

      await repo.confirmDeposit(intent.intentId);
      if (!mounted) {
        return;
      }
      if (pending.depositMethod == AdvertiserDepositMethod.ach) {
        _toast(t.advertiser_wallet.deposit_pending);
        await _refresh();
      } else {
        _toast(t.advertiser_wallet.success);
        await _onDepositSucceeded(completedIntentId: intent.intentId);
      }
    } on ServerException catch (e) {
      _toast(e.message.isNotEmpty ? e.message : t.advertiser_wallet.failed);
    } catch (e) {
      final msg = AdvertiserStripeDeposit.describeError(e);
      _toast(msg.isNotEmpty ? msg : t.advertiser_wallet.failed);
    } finally {
      if (mounted) {
        setState(() => _busyMethod = null);
      }
    }
  }

  Future<void> _cancelPendingDeposit(AdvertiserPendingDeposit pending) async {
    _clearDepositCheckout(dismissIntentId: pending.intentId);
    try {
      await ref
          .read(advertiserWalletRepositoryProvider)
          .cancelDepositIntent(pending.intentId);
    } catch (_) {
      // UI already closed — server may have cleared the intent earlier.
    }
    invalidateAdvertiserWalletDepositSync(ref);
    if (mounted) {
      setState(() => _dismissedPendingIntentId = null);
    }
  }

  void _toastMinDeposit(String currency, String moneyLocale) {
    final t = context.t;
    final amountLabel = _formatAdvertiserWalletAmount(
      _kMinDepositCents / 100.0,
      currency,
      moneyLocale,
    );
    _toast(t.advertiser_wallet.min_deposit.replaceAll('{amount}', amountLabel));
  }

  /// Wire: create the deposit intent and show bank routing instructions —
  /// bypasses the Stripe SDK entirely (mirrors web `AddFundsPanel`).
  Future<void> _submitWire({
    required String currency,
    required String moneyLocale,
  }) async {
    if (!kAdvertiserWireDepositUiEnabled) {
      return;
    }
    if (_wireBusy || _busyMethod != null) {
      return;
    }
    final cents = _amountToCents(_amountCtrl.text);
    if (cents == null || cents < _kMinDepositCents) {
      _toastMinDeposit(currency, moneyLocale);
      return;
    }
    setState(() => _wireBusy = true);
    final t = context.t;
    final repo = ref.read(advertiserWalletRepositoryProvider);
    try {
      final intent = await repo.createDepositIntent(
        amountCents: cents,
        currency: currency,
        depositMethod: AdvertiserDepositMethod.wire,
      );
      invalidateAdvertiserWalletDepositSync(ref);
      if (!mounted) {
        return;
      }
      if (intent.bankTransferInstructions == null) {
        _toast(t.advertiser_wallet.failed);
        return;
      }
      setState(() => _wireIntent = intent);
    } on ServerException catch (e) {
      _toast(e.message.isNotEmpty ? e.message : t.advertiser_wallet.failed);
    } catch (_) {
      _toast(t.advertiser_wallet.failed);
    } finally {
      if (mounted) {
        setState(() => _wireBusy = false);
      }
    }
  }

  /// User acknowledged the wire transfer was initiated — keep the deposit
  /// pending server-side (webhook credits once Stripe confirms funds).
  void _acknowledgeWireAwaiting() {
    _clearDepositCheckout();
  }

  Future<void> _copyToClipboard(String value) async {
    final t = context.t;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    WayoToast.info(context, t.advertiser_wallet.wire_copied_desc);
  }

  Future<void> _openHostedInstructions(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// One-click pay with a saved Stripe card (mirrors creator-studio
  /// `confirmSavedCard`).
  Future<void> _payWithSavedCard({
    required String currency,
    required String moneyLocale,
  }) async {
    if (_savedCardBusy || _busyMethod != null || _selectedSavedCardId == null) {
      return;
    }
    final cents = _amountToCents(_amountCtrl.text);
    if (cents == null || cents < _kMinDepositCents) {
      _toastMinDeposit(currency, moneyLocale);
      return;
    }
    final t = context.t;
    setState(() => _savedCardBusy = true);
    final repo = ref.read(advertiserWalletRepositoryProvider);
    try {
      final intent = await repo.createDepositIntent(
        amountCents: cents,
        currency: currency,
        depositMethod: AdvertiserDepositMethod.card,
      );
      invalidateAdvertiserWalletDepositSync(ref);

      if (intent.canSimulate) {
        await repo.simulatePspSuccess(intent.intentId);
        if (!mounted) {
          return;
        }
        _toast(t.advertiser_wallet.success);
        await _onDepositSucceeded(completedIntentId: intent.intentId);
        return;
      }

      final cfg = await _ensureStripeReady();
      if (cfg == null) {
        return;
      }

      try {
        await AdvertiserStripeDeposit.confirmSavedCard(
          clientSecret: intent.clientSecret,
          paymentMethodId: _selectedSavedCardId!,
        );
      } on StripeException catch (e) {
        if (AdvertiserStripeDeposit.isUserCancelled(e)) {
          invalidateAdvertiserWalletDepositSync(ref);
          await _restoreUiAfterStripeSheet();
          return;
        }
        _toast(AdvertiserStripeDeposit.describeError(e));
        return;
      }

      await repo.confirmDeposit(intent.intentId);
      if (!mounted) {
        return;
      }
      _toast(t.advertiser_wallet.success);
      await _onDepositSucceeded(completedIntentId: intent.intentId);
    } on ServerException catch (e) {
      _toast(e.message.isNotEmpty ? e.message : t.advertiser_wallet.failed);
    } catch (e) {
      final msg = AdvertiserStripeDeposit.describeError(e);
      _toast(msg.isNotEmpty ? msg : t.advertiser_wallet.failed);
    } finally {
      if (mounted) {
        setState(() => _savedCardBusy = false);
      }
    }
  }

  Future<void> _confirmDeleteCard(WalletSavedCard card) async {
    final t = context.t;
    final confirmed = await showWayoConfirmDialog(
      context: context,
      title: t.advertiser_wallet.remove_card_confirm_title,
      message: t.advertiser_wallet.remove_card_confirm_desc
          .replaceAll('{brand}', card.displayBrand)
          .replaceAll('{last4}', card.last4),
      cancelLabel: t.advertiser_wallet.cancel,
      confirmLabel: t.advertiser_wallet.remove_card_confirm_action,
      tone: WayoDialogTone.destructive,
    );
    if (confirmed) {
      await _deleteSavedCard(card);
    }
  }

  Future<void> _deleteSavedCard(WalletSavedCard card) async {
    final t = context.t;
    final repo = ref.read(advertiserWalletRepositoryProvider);
    try {
      await repo.deleteSavedCard(card.id);
      if (_selectedSavedCardId == card.id) {
        _selectedSavedCardId = null;
      }
      ref.invalidate(advertiserSavedCardsProvider);
      if (!mounted) {
        return;
      }
      _toast(
        t.advertiser_wallet.card_removed_desc.replaceAll('{last4}', card.last4),
      );
    } on ServerException catch (e) {
      _toast(e.message.isNotEmpty ? e.message : t.advertiser_wallet.card_remove_failed);
    } catch (_) {
      _toast(t.advertiser_wallet.card_remove_failed);
    }
  }

  /// [POST /api/wallet/deposits/:intentId/reconcile] — manual settle retry
  /// for a deposit stuck in PENDING (surfaced from the ACH/wire banners).
  Future<void> _reconcile(String intentId) async {
    if (_reconcilingIntentIds.contains(intentId)) {
      return;
    }
    final t = context.t;
    setState(() => _reconcilingIntentIds.add(intentId));
    final repo = ref.read(advertiserWalletRepositoryProvider);
    try {
      final status = await repo.reconcileDeposit(intentId);
      if (!mounted) {
        return;
      }
      if (status.toUpperCase() == 'ATTRIBUTED' ||
          status.toUpperCase() == 'RECONCILED' ||
          status.toUpperCase() == 'SUCCEEDED') {
        _toast(t.advertiser_wallet.reconcile_success);
        await _refresh();
      } else {
        _toast(t.advertiser_wallet.reconcile_still_pending);
      }
    } on ServerException catch (e) {
      _toast(e.message.isNotEmpty ? e.message : t.advertiser_wallet.reconcile_failed);
    } catch (_) {
      _toast(t.advertiser_wallet.reconcile_failed);
    } finally {
      if (mounted) {
        setState(() => _reconcilingIntentIds.remove(intentId));
      }
    }
  }

  /// Create PI + confirm with either Payment Sheet (card/ACH) or native Apple/Google Pay.
  Future<void> _submit({
    required _PayMethod method,
    required String currency,
    String depositMethod = AdvertiserDepositMethod.card,
    String moneyLocale = 'en_US',
  }) async {
    if (_busyMethod != null) {
      return;
    }
    final t = context.t;
    final cents = _amountToCents(_amountCtrl.text);
    if (cents == null || cents < _kMinDepositCents) {
      _toastMinDeposit(currency, moneyLocale);
      return;
    }
    setState(() => _busyMethod = method);
    final repo = ref.read(advertiserWalletRepositoryProvider);
    try {
      final intent = await repo.createDepositIntent(
        amountCents: cents,
        currency: currency,
        depositMethod: depositMethod,
      );
      invalidateAdvertiserWalletDepositSync(ref);

      // Dev / mock PSP path — no Stripe SDK at all.
      if (intent.canSimulate) {
        await repo.simulatePspSuccess(intent.intentId);
        if (!mounted) {
          return;
        }
        _toast(t.advertiser_wallet.success);
        await _onDepositSucceeded(completedIntentId: intent.intentId);
        return;
      }

      final cfg = await _ensureStripeReady();
      if (cfg == null) {
        return;
      }

      try {
        await _confirmStripePayment(
          intent: intent,
          method: method,
          depositMethod: depositMethod,
        );
      } on StripeException catch (e) {
        if (AdvertiserStripeDeposit.isUserCancelled(e)) {
          invalidateAdvertiserWalletDepositSync(ref);
          await _restoreUiAfterStripeSheet();
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
      if (depositMethod == AdvertiserDepositMethod.ach) {
        final amountLabel = _formatAdvertiserWalletAmount(
          intent.amountCents / 100.0,
          intent.currency,
          moneyLocale,
        );
        _toast(
          t.advertiser_wallet.ach_processing_banner
              .replaceAll('{amount}', amountLabel),
        );
        await _restoreUiAfterStripeSheet();
        await _refresh();
      } else {
        _toast(t.advertiser_wallet.success);
        await _onDepositSucceeded(completedIntentId: intent.intentId);
      }
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
            final pendingAsync = businessReady
                ? ref.watch(advertiserPendingDepositProvider)
                : const AsyncValue<AdvertiserPendingDeposit?>.data(null);
            final AdvertiserPendingDeposit? activePending =
                pendingAsync.valueOrNull != null &&
                    pendingAsync.valueOrNull!.intentId !=
                        _dismissedPendingIntentId
                ? pendingAsync.valueOrNull
                : null;
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
                        if (businessReady)
                          Builder(
                            builder: (context) {
                              final snapshot = ref
                                  .watch(advertiserPendingDepositsSnapshotProvider)
                                  .valueOrNull;
                              if (snapshot == null ||
                                  (snapshot.achProcessing.isEmpty &&
                                      (!kAdvertiserWireDepositUiEnabled ||
                                          snapshot.wireAwaiting.isEmpty))) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    for (final item in snapshot.achProcessing)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _PendingMethodBanner(
                                          description: t
                                              .advertiser_wallet
                                              .ach_processing_banner
                                              .replaceAll(
                                                '{amount}',
                                                _formatAdvertiserWalletAmount(
                                                  item.amountCents / 100.0,
                                                  item.currency,
                                                  moneyLocale,
                                                ),
                                              ),
                                          busy: _reconcilingIntentIds.contains(
                                            item.intentId,
                                          ),
                                          reconcileLabel:
                                              t.advertiser_wallet.reconcile_button,
                                          onReconcile: () =>
                                              _reconcile(item.intentId),
                                        ),
                                      ),
                                    if (kAdvertiserWireDepositUiEnabled)
                                      for (final item in snapshot.wireAwaiting)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: _PendingMethodBanner(
                                            description: t
                                                .advertiser_wallet
                                                .wire_awaiting_banner
                                                .replaceAll(
                                                  '{amount}',
                                                  _formatAdvertiserWalletAmount(
                                                    item.amountCents / 100.0,
                                                    item.currency,
                                                    moneyLocale,
                                                  ),
                                                ),
                                            busy: _reconcilingIntentIds.contains(
                                              item.intentId,
                                            ),
                                            reconcileLabel:
                                                t.advertiser_wallet.reconcile_button,
                                            onReconcile: () =>
                                                _reconcile(item.intentId),
                                          ),
                                        ),
                                  ],
                                ),
                              );
                            },
                          ),
                        if (activePending != null && businessReady) ...[
                          _PendingDepositCheckout(
                            pending: activePending,
                            moneyLocale: moneyLocale,
                            isDark: isDark,
                            t: t,
                            data: data,
                            busyMethod: _busyMethod,
                            onCard: () => _completePendingDeposit(
                              pending: activePending,
                              method: _PayMethod.card,
                              canSimulate: data.canSimulate,
                            ),
                            onApplePay: () => _completePendingDeposit(
                              pending: activePending,
                              method: _PayMethod.applePay,
                              canSimulate: data.canSimulate,
                            ),
                            onGooglePay: () => _completePendingDeposit(
                              pending: activePending,
                              method: _PayMethod.googlePay,
                              canSimulate: data.canSimulate,
                            ),
                            onCancel: () => _cancelPendingDeposit(activePending),
                          ),
                        ] else if (kAdvertiserWireDepositUiEnabled &&
                            _wireIntent != null &&
                            businessReady) ...[
                          _WireInstructionsPanel(
                            instructions: _wireIntent!.bankTransferInstructions!,
                            amountLabel: _formatAdvertiserWalletAmount(
                              _wireIntent!.amountCents / 100.0,
                              _wireIntent!.currency,
                              moneyLocale,
                            ),
                            t: t,
                            onCopy: _copyToClipboard,
                            onOpenHosted: _openHostedInstructions,
                            onDone: _acknowledgeWireAwaiting,
                          ),
                        ] else ...[
                          Text(
                            t.advertiser_wallet.amount_label,
                            style: AppTextStyles.caption(
                              context,
                            ).copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountCtrl,
                            readOnly: !businessReady,
                            onTap: !businessReady
                                ? () => _openBusinessProfileEditor()
                                : null,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              prefixText:
                                  '${MoneyFormatter.currencySymbol(c)} ',
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
                              for (final amount in _kQuickDepositAmounts)
                                _QuickChip(
                                  label: _formatAdvertiserWalletAmount(
                                    amount,
                                    c,
                                    moneyLocale,
                                  ),
                                  onTap: businessReady
                                      ? () => _amountCtrl.text =
                                          amount.truncateToDouble() == amount
                                          ? amount.toInt().toString()
                                          : amount.toString()
                                      : _openBusinessProfileEditor,
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
                            const SizedBox(height: 20),
                            _FundingMethodSelector(
                              selected: _fundingMethod == _FundingMethod.wire &&
                                      !kAdvertiserWireDepositUiEnabled
                                  ? _FundingMethod.card
                                  : _fundingMethod,
                              achAvailable: c.toUpperCase() == 'USD',
                              wireAvailable: _isWireDepositUiAvailable(c),
                              t: t,
                              onSelect: (m) {
                                if (!kAdvertiserWireDepositUiEnabled &&
                                    m == _FundingMethod.wire) {
                                  return;
                                }
                                if (m == _fundingMethod) {
                                  return;
                                }
                                setState(() {
                                  _fundingMethod = m;
                                  _useSavedCard = false;
                                  _selectedSavedCardId = null;
                                });
                              },
                            ),
                          ],
                          if (businessReady &&
                              !(_fundingMethod == _FundingMethod.wire &&
                                  kAdvertiserWireDepositUiEnabled)) ...[
                            Builder(
                              builder: (context) {
                                final walletCents =
                                    _amountToCents(_amountCtrl.text);
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
                                    fundingMethod: _fundingMethod,
                                  ),
                                );
                              },
                            ),
                          ],
                          if (businessReady) ...[
                            const SizedBox(height: 24),
                            if (kAdvertiserWireDepositUiEnabled &&
                                _fundingMethod == _FundingMethod.wire)
                              _WireCta(
                                busy: _wireBusy,
                                label: t.advertiser_wallet.funding_wire_title,
                                onPressed: () => _submitWire(
                                  currency: c,
                                  moneyLocale: moneyLocale,
                                ),
                              )
                            else if (_fundingMethod == _FundingMethod.ach)
                              _AchCta(
                                busy: _busyMethod == _PayMethod.card,
                                label: t.advertiser_wallet.funding_ach_title,
                                onPressed: () => _submit(
                                  method: _PayMethod.card,
                                  currency: c,
                                  depositMethod: AdvertiserDepositMethod.ach,
                                  moneyLocale: moneyLocale,
                                ),
                              )
                            else
                              Builder(
                                builder: (context) {
                                  final cardsAsync = ref.watch(
                                    advertiserSavedCardsProvider(true),
                                  );
                                  final cards =
                                      cardsAsync.valueOrNull?.cards ??
                                      const <WalletSavedCard>[];
                                  if (cards.isNotEmpty &&
                                      _selectedSavedCardId == null &&
                                      !cardsAsync.isLoading) {
                                    final preferred = cards.firstWhere(
                                      (card) => card.isDefault,
                                      orElse: () => cards.first,
                                    );
                                    WidgetsBinding.instance.addPostFrameCallback((
                                      _,
                                    ) {
                                      if (mounted) {
                                        setState(() {
                                          _selectedSavedCardId = preferred.id;
                                          _useSavedCard = true;
                                        });
                                      }
                                    });
                                  }
                                  if (cardsAsync.isLoading) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        t.advertiser_wallet.saved_cards_loading,
                                        style: AppTextStyles.caption(
                                          context,
                                        ).copyWith(
                                          color: AppColors.textMutedOf(context),
                                        ),
                                      ),
                                    );
                                  }
                                  if (cards.isEmpty || !_useSavedCard) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (cards.isNotEmpty) ...[
                                          Align(
                                            alignment: AlignmentDirectional.centerEnd,
                                            child: TextButton(
                                              onPressed: () => setState(() {
                                                _useSavedCard = true;
                                                _selectedSavedCardId ??=
                                                    cards
                                                        .firstWhere(
                                                          (card) => card.isDefault,
                                                          orElse: () => cards.first,
                                                        )
                                                        .id;
                                              }),
                                              child: Text(
                                                t.advertiser_wallet.use_saved_card,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        _WalletPayStrip(
                                          data: data,
                                          t: t,
                                          busyMethod: _busyMethod,
                                          onCard: () => _submit(
                                            method: _PayMethod.card,
                                            currency: c,
                                            moneyLocale: moneyLocale,
                                          ),
                                          onApplePay: () => _submit(
                                            method: _PayMethod.applePay,
                                            currency: c,
                                            moneyLocale: moneyLocale,
                                          ),
                                          onGooglePay: () => _submit(
                                            method: _PayMethod.googlePay,
                                            currency: c,
                                            moneyLocale: moneyLocale,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return _SavedCardsList(
                                    cards: cards,
                                    selectedId: _selectedSavedCardId,
                                    busy: _savedCardBusy,
                                    t: t,
                                    payLabel: () {
                                      final walletCents = _amountToCents(
                                        _amountCtrl.text,
                                      );
                                      if (walletCents == null ||
                                          walletCents < _kMinDepositCents) {
                                        return t.advertiser_wallet.pay_with_card;
                                      }
                                      final charge = estimateAdvertiserDepositCharge(
                                        walletAmountCents: walletCents,
                                      );
                                      return _formatAdvertiserWalletAmount(
                                        charge.totalChargedCents / 100.0,
                                        c,
                                        moneyLocale,
                                      );
                                    }(),
                                    onSelect: (id) =>
                                        setState(() => _selectedSavedCardId = id),
                                    onDelete: _confirmDeleteCard,
                                    onUseNewCard: () =>
                                        setState(() => _useSavedCard = false),
                                    onPay: () => _payWithSavedCard(
                                      currency: c,
                                      moneyLocale: moneyLocale,
                                    ),
                                  );
                                },
                              ),
                          ] else ...[
                            const SizedBox(height: 24),
                            _WalletPayStripPlaceholder(t: t),
                          ],
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

/// Resume UI when [GET /api/wallet/deposit-intent] returns an open Stripe PI.
class _PendingDepositCheckout extends StatelessWidget {
  static String _amountLabel(
    int walletAmountCents,
    String currency,
    String moneyLocale,
  ) {
    return _formatAdvertiserWalletAmount(
      walletAmountCents / 100.0,
      currency,
      moneyLocale,
    );
  }
  const _PendingDepositCheckout({
    required this.pending,
    required this.moneyLocale,
    required this.isDark,
    required this.t,
    required this.data,
    required this.busyMethod,
    required this.onCard,
    required this.onApplePay,
    required this.onGooglePay,
    required this.onCancel,
  });

  final AdvertiserPendingDeposit pending;
  final String moneyLocale;
  final bool isDark;
  final Translations t;
  final AdvertiserWalletPageData data;
  final _PayMethod? busyMethod;
  final VoidCallback onCard;
  final VoidCallback onApplePay;
  final VoidCallback onGooglePay;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final walletLabel = _amountLabel(
      pending.walletAmountCents,
      pending.currency,
      moneyLocale,
    );
    final charge = AdvertiserDepositCharge(
      walletAmountCents: pending.walletAmountCents,
      totalChargedCents: pending.totalAmountCents > 0
          ? pending.totalAmountCents
          : pending.walletAmountCents,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFF4A237).withValues(alpha: isDark ? 0.12 : 0.14),
            border: Border.all(
              color: const Color(0xFFF4A237).withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: const Color(0xFFF4A237),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.advertiser_wallet.deposit_pending,
                    style: AppTextStyles.headlineMedium(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.advertiser_wallet.deposit_resume_hint.replaceAll(
                  '{amount}',
                  walletLabel,
                ),
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DepositPaymentSummary(
          charge: charge,
          currency: pending.currency,
          moneyLocale: moneyLocale,
          t: t,
          isDark: isDark,
          fundingMethod: switch (pending.depositMethod) {
            AdvertiserDepositMethod.ach => _FundingMethod.ach,
            AdvertiserDepositMethod.wire => _FundingMethod.wire,
            _ => _FundingMethod.card,
          },
        ),
        const SizedBox(height: 24),
        _WalletPayStrip(
          data: data,
          t: t,
          busyMethod: busyMethod,
          onCard: onCard,
          onApplePay: onApplePay,
          onGooglePay: onGooglePay,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: busyMethod != null ? null : onCancel,
            child: Text(
              t.advertiser_wallet.deposit_cancel,
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ),
      ],
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
class _WalletPayStrip extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isSim = data.canSimulate;
    final cardBusy = busyMethod == _PayMethod.card;
    final appleBusy = busyMethod == _PayMethod.applePay;
    final googleBusy = busyMethod == _PayMethod.googlePay;
    final anyBusy = busyMethod != null;

    // Always show card + the platform wallet (iOS: Apple Pay, Android: Google Pay).
    // Do not hide Apple Pay when canSimulate is true — App Review must be able to
    // locate the PassKit / Apple Pay entry on advertiser Wallet deposits.
    final showApple = Platform.isIOS;
    final showGoogle = Platform.isAndroid;
    final showWallet = showApple || showGoogle;
    final stripeTestMode =
        ref.watch(walletPspConfigProvider).valueOrNull?.isTestMode ?? false;

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
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: cardBusy
              ? const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
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
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isSim
                          ? t.advertiser_wallet.test_pay
                          : t.advertiser_wallet.pay_with_card,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
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
        if (showApple && stripeTestMode) ...[
          const SizedBox(height: 8),
          Text(
            t.advertiser_wallet.apple_pay_test_hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
        if (showGoogle)
          GooglePayButton(
            payWithPrefix: t.advertiser_wallet.google_pay_with_prefix,
            busy: googleBusy,
            disabled: anyBusy,
            onPressed: anyBusy ? null : onGooglePay,
            style: GooglePayButtonStyle.dark,
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
    this.fundingMethod = _FundingMethod.card,
  });

  final AdvertiserDepositCharge charge;
  final String currency;
  final String moneyLocale;
  final Translations t;
  final bool isDark;
  final _FundingMethod fundingMethod;

  String _money(int cents) {
    return _formatAdvertiserWalletAmount(
      cents / 100.0,
      currency,
      moneyLocale,
    );
  }

  String get _netNote {
    switch (fundingMethod) {
      case _FundingMethod.ach:
        return t.advertiser_wallet.deposit_ach_net_note;
      case _FundingMethod.wire:
        return t.advertiser_wallet.deposit_wire_net_note;
      case _FundingMethod.card:
        return t.advertiser_wallet.deposit_net_note;
    }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
                child: _DepositBreakdownRow(
                  label: t.advertiser_wallet.payment_deposit_amount,
                  value: _money(charge.walletAmountCents),
                  muted: muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: panelBg.withValues(alpha: isDark ? 0.65 : 1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderOf(context).withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _netNote,
                  style: AppTextStyles.caption(context).copyWith(
                    color: muted,
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DepositBreakdownRow extends StatelessWidget {
  const _DepositBreakdownRow({
    required this.label,
    required this.value,
    required this.muted,
  });

  final String label;
  final String value;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: muted,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTextStyles.bodyLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
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
            _formatAdvertiserWalletAmount(a, c, moneyLocale),
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
            _formatAdvertiserWalletAmount(p, c, moneyLocale),
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
    final t = context.t;
    final c = row.currency;
    final signed = row.amountCents;
    final major = signed / 100.0;
    final s = _formatAdvertiserWalletAmount(
      major.abs(),
      c,
      moneyLocale,
    );
    final prefix = signed < 0 ? '−' : '+';
    final dateStr = row.createdAt != null
        ? DateFormat.yMMMd(
            moneyLocale,
          ).add_Hm().format(row.createdAt!.toLocal())
        : '';
    final isDeposit = row.type.toUpperCase() == 'DEPOSIT';
    final isPending = (row.status ?? '').toUpperCase() == 'PENDING';
    final charged = row.chargedCents;
    final fee = row.stripeFeeCents;
    final muted = AppColors.textSecondaryOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.description.isNotEmpty
                          ? row.description
                          : (dateStr.isNotEmpty ? dateStr : ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isPending ? s : '$prefix$s',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isPending
                          ? const Color(0xFFF59E0B)
                          : signed >= 0
                              ? const Color(0xFF10B981)
                              : AppColors.textPrimaryOf(context),
                    ),
                  ),
                  if (!isPending &&
                      isDeposit &&
                      charged != null &&
                      charged > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${t.advertiser_wallet.payment_charged}: ${_formatAdvertiserWalletAmount(charged / 100.0, c, moneyLocale)}',
                      style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  if (!isPending && fee != null && fee > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${t.advertiser_wallet.payment_stripe_fee}: −${_formatAdvertiserWalletAmount(fee / 100.0, c, moneyLocale)}',
                      style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card / ACH / wire funding-method radio group — mirrors web `AddFundsPanel`
/// `FundingMethodRow`.
class _FundingMethodSelector extends StatelessWidget {
  const _FundingMethodSelector({
    required this.selected,
    required this.achAvailable,
    required this.wireAvailable,
    required this.t,
    required this.onSelect,
  });

  final _FundingMethod selected;
  final bool achAvailable;
  final bool wireAvailable;
  final Translations t;
  final ValueChanged<_FundingMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _FundingMethodRow(
            selected: selected == _FundingMethod.card,
            icon: Icons.credit_card_rounded,
            title: t.advertiser_wallet.funding_card_title,
            badge: t.advertiser_wallet.funding_card_badge,
            detail: t.advertiser_wallet.funding_card_desc,
            onTap: () => onSelect(_FundingMethod.card),
          ),
          Divider(
            height: 1,
            color: AppColors.borderOf(context).withValues(alpha: 0.5),
          ),
          _FundingMethodRow(
            selected: selected == _FundingMethod.ach,
            disabled: !achAvailable,
            icon: Icons.account_balance_rounded,
            title: t.advertiser_wallet.funding_ach_title,
            badge: t.advertiser_wallet.funding_ach_badge,
            detail: achAvailable
                ? t.advertiser_wallet.funding_ach_eta
                : t.advertiser_wallet.funding_ach_usd_only,
            onTap: achAvailable ? () => onSelect(_FundingMethod.ach) : null,
          ),
          if (kAdvertiserWireDepositUiEnabled) ...[
            Divider(
              height: 1,
              color: AppColors.borderOf(context).withValues(alpha: 0.5),
            ),
            _FundingMethodRow(
              selected: selected == _FundingMethod.wire,
              disabled: !wireAvailable,
              icon: Icons.account_balance_wallet_outlined,
              title: t.advertiser_wallet.funding_wire_title,
              badge: t.advertiser_wallet.funding_wire_badge,
              detail: wireAvailable
                  ? t.advertiser_wallet.funding_wire_eta
                  : t.advertiser_wallet.funding_wire_currency_only.replaceAll(
                      '{currencies}',
                      kWireDepositCurrencies.join(', '),
                    ),
              onTap: wireAvailable ? () => onSelect(_FundingMethod.wire) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _FundingMethodRow extends StatelessWidget {
  const _FundingMethodRow({
    required this.selected,
    required this.icon,
    required this.title,
    required this.badge,
    required this.detail,
    required this.onTap,
    this.disabled = false,
  });

  final bool selected;
  final bool disabled;
  final IconData icon;
  final String title;
  final String badge;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.textMutedOf(context);
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.14)
                        : AppColors.surfaceElevatedOf(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: selected ? AppColors.primary : muted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              badge.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: AppTextStyles.caption(context).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.4,
                                color: selected ? AppColors.primary : muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: muted, height: 1.3, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.borderOf(context),
                      width: 1.4,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchCta extends StatelessWidget {
  const _AchCta({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_rounded, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
    );
  }
}

class _WireCta extends StatelessWidget {
  const _WireCta({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
    );
  }
}

/// Saved Stripe cards list — tap to select, one-click Pay, swipe-free delete.
class _SavedCardsList extends StatelessWidget {
  const _SavedCardsList({
    required this.cards,
    required this.selectedId,
    required this.busy,
    required this.t,
    required this.payLabel,
    required this.onSelect,
    required this.onDelete,
    required this.onUseNewCard,
    required this.onPay,
  });

  final List<WalletSavedCard> cards;
  final String? selectedId;
  final bool busy;
  final Translations t;
  final String payLabel;
  final ValueChanged<String> onSelect;
  final ValueChanged<WalletSavedCard> onDelete;
  final VoidCallback onUseNewCard;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final card in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selectedId == card.id
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: busy ? null : () => onSelect(card.id),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card_rounded,
                        size: 22,
                        color: selectedId == card.id
                            ? AppColors.primary
                            : AppColors.textMutedOf(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${card.displayBrand} •••• ${card.last4}',
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyLarge(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceOf(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                card.isDefault
                                    ? t.advertiser_wallet.default_card_badge
                                    : t.advertiser_wallet.saved_card_badge,
                                style: AppTextStyles.caption(context).copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMutedOf(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: busy ? null : () => onDelete(card),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        color: AppColors.textMutedOf(context),
                        tooltip: t.advertiser_wallet.remove_card,
                      ),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedId == card.id
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: selectedId == card.id
                                ? AppColors.primary
                                : AppColors.borderOf(context),
                            width: 1.4,
                          ),
                        ),
                        child: selectedId == card.id
                            ? const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: busy ? null : onUseNewCard,
            child: Text(t.advertiser_wallet.use_new_card),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: busy || selectedId == null ? null : onPay,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Text(
                  t.advertiser_wallet.pay_with_saved_card
                      .replaceAll(
                        '{brand}',
                        cards
                            .firstWhere(
                              (c) => c.id == selectedId,
                              orElse: () => cards.first,
                            )
                            .displayBrand,
                      )
                      .replaceAll(
                        '{last4}',
                        cards
                            .firstWhere(
                              (c) => c.id == selectedId,
                              orElse: () => cards.first,
                            )
                            .last4,
                      ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Wire / bank-transfer routing instructions — mirrors web `WireInstructionsPanel`.
class _WireInstructionsPanel extends StatelessWidget {
  const _WireInstructionsPanel({
    required this.instructions,
    required this.amountLabel,
    required this.t,
    required this.onCopy,
    required this.onOpenHosted,
    required this.onDone,
  });

  final BankTransferFundingInstructions instructions;
  final String amountLabel;
  final Translations t;
  final void Function(String) onCopy;
  final void Function(String) onOpenHosted;
  final VoidCallback onDone;

  String _networkLabel(String network) {
    switch (network) {
      case 'swift':
        return t.advertiser_wallet.wire_network_swift;
      case 'aba':
        return t.advertiser_wallet.wire_network_aba;
      case 'iban':
        return t.advertiser_wallet.wire_network_iban;
      case 'sort_code':
        return t.advertiser_wallet.wire_network_sort_code;
      default:
        return t.advertiser_wallet.wire_network_other.replaceAll(
          '{network}',
          network,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.advertiser_wallet.wire_awaiting_title,
                style: AppTextStyles.headlineMedium(context).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.advertiser_wallet.wire_awaiting_desc,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _WireCopyRow(
          label: t.advertiser_wallet.wire_exact_amount,
          value: amountLabel,
          copyLabel: t.advertiser_wallet.wire_copy_action,
          onCopy: onCopy,
        ),
        if (instructions.reference != null &&
            instructions.reference!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _WireCopyRow(
            label: t.advertiser_wallet.wire_reference,
            value: instructions.reference!,
            copyLabel: t.advertiser_wallet.wire_copy_action,
            onCopy: onCopy,
            emphasized: true,
          ),
          const SizedBox(height: 6),
          Text(
            t.advertiser_wallet.wire_reference_required_hint,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textSecondaryOf(context),
              height: 1.3,
            ),
          ),
        ],
        for (final addr in instructions.addresses) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderOf(context).withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _networkLabel(addr.network),
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                if (addr.accountHolderName != null)
                  _WireCopyRow(
                    label: t.advertiser_wallet.wire_account_holder,
                    value: addr.accountHolderName!,
                    copyLabel: t.advertiser_wallet.wire_copy_action,
                    onCopy: onCopy,
                  ),
                if (addr.bankName != null) ...[
                  const SizedBox(height: 8),
                  _WireCopyRow(
                    label: t.advertiser_wallet.wire_bank_name,
                    value: addr.bankName!,
                    copyLabel: t.advertiser_wallet.wire_copy_action,
                    onCopy: onCopy,
                  ),
                ],
                if (addr.routingNumber != null) ...[
                  const SizedBox(height: 8),
                  _WireCopyRow(
                    label: t.advertiser_wallet.wire_routing_number,
                    value: addr.routingNumber!,
                    copyLabel: t.advertiser_wallet.wire_copy_action,
                    onCopy: onCopy,
                  ),
                ],
                if (addr.sortCode != null) ...[
                  const SizedBox(height: 8),
                  _WireCopyRow(
                    label: t.advertiser_wallet.wire_sort_code,
                    value: addr.sortCode!,
                    copyLabel: t.advertiser_wallet.wire_copy_action,
                    onCopy: onCopy,
                  ),
                ],
                if (addr.accountNumber != null) ...[
                  const SizedBox(height: 8),
                  _WireCopyRow(
                    label: t.advertiser_wallet.wire_account_number,
                    value: addr.accountNumber!,
                    copyLabel: t.advertiser_wallet.wire_copy_action,
                    onCopy: onCopy,
                  ),
                ],
                if (addr.swiftCode != null) ...[
                  const SizedBox(height: 8),
                  _WireCopyRow(
                    label: t.advertiser_wallet.wire_swift_code,
                    value: addr.swiftCode!,
                    copyLabel: t.advertiser_wallet.wire_copy_action,
                    onCopy: onCopy,
                  ),
                ],
                if (addr.iban != null) ...[
                  const SizedBox(height: 8),
                  _WireCopyRow(
                    label: t.advertiser_wallet.wire_iban,
                    value: addr.iban!,
                    copyLabel: t.advertiser_wallet.wire_copy_action,
                    onCopy: onCopy,
                  ),
                ],
                if (addr.bic != null) ...[
                  const SizedBox(height: 8),
                  _WireCopyRow(
                    label: t.advertiser_wallet.wire_bic,
                    value: addr.bic!,
                    copyLabel: t.advertiser_wallet.wire_copy_action,
                    onCopy: onCopy,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (instructions.hostedInstructionsUrl != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => onOpenHosted(instructions.hostedInstructionsUrl!),
              child: Text(t.advertiser_wallet.wire_hosted_instructions),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onDone,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          child: Text(
            t.advertiser_wallet.wire_done_button,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _WireCopyRow extends StatelessWidget {
  const _WireCopyRow({
    required this.label,
    required this.value,
    required this.copyLabel,
    required this.onCopy,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final String copyLabel;
  final void Function(String) onCopy;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: emphasized
            ? accent.withValues(alpha: 0.08)
            : AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(12),
        border: emphasized
            ? Border.all(color: accent.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onCopy(value),
            icon: const Icon(Icons.copy_rounded, size: 16),
            tooltip: copyLabel,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// ACH-processing / wire-awaiting deposit banner with a manual reconcile CTA.
class _PendingMethodBanner extends StatelessWidget {
  const _PendingMethodBanner({
    required this.description,
    required this.busy,
    required this.reconcileLabel,
    required this.onReconcile,
  });

  final String description;
  final bool busy;
  final String reconcileLabel;
  final VoidCallback onReconcile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0EA5E9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: busy ? null : onReconcile,
            child: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(reconcileLabel),
          ),
        ],
      ),
    );
  }
}
