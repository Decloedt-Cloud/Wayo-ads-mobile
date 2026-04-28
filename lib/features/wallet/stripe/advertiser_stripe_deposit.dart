import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/stripe/stripe_mobile_config.dart';

/// Thin wrapper around [Stripe] for the advertiser wallet deposit flow.
///
/// Three payment paths:
///  * [presentCardPaymentSheet]   — Payment Sheet limited to cards (mirrors the web `CardElement`).
///  * [confirmWithApplePay]       — Native Apple Pay button (iOS only).
///  * [confirmWithGooglePay]      — Native Google Pay button (Android only).
final class AdvertiserStripeDeposit {
  const AdvertiserStripeDeposit._();

  static String _merchantCountryForCurrency(String currency) {
    switch (currency.toUpperCase()) {
      case 'GBP':
        return 'GB';
      case 'USD':
        return 'US';
      case 'EUR':
      default:
        return 'FR';
    }
  }

  /// Call once per session *before* any other Stripe method.
  static Future<void> ensureSdkReady({required String publishableKey}) async {
    Stripe.publishableKey = publishableKey;
    Stripe.urlScheme = kStripeUrlScheme;
    final mid = kStripeAppleMerchantId.trim();
    if (mid.isNotEmpty) {
      Stripe.merchantIdentifier = mid;
    }
    await Stripe.instance.applySettings();
  }

  /// Card-only Payment Sheet — equivalent of the web `CardElement` flow.
  ///
  /// Returns the chosen payment option label (e.g. `Visa ···· 4242`) on success,
  /// which can be stored locally when the user opts in to "save card".
  static Future<PaymentSheetPaymentOption?> presentCardPaymentSheet({
    required String clientSecret,
    required String currency,
  }) async {
    final appearance = PaymentSheetAppearance(
      colors: PaymentSheetAppearanceColors(
        primary: const Color(0xFFF4A237),
        componentBackground: const Color(0xFF1C1C1E),
        componentText: Colors.white,
        primaryText: Colors.white,
        placeholderText: const Color(0xFF8E8E93),
        icon: const Color(0xFFF4A237),
        error: const Color(0xFFFF4D4D),
      ),
      shapes: const PaymentSheetShape(borderRadius: 16),
    );
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Wayo Ads',
        style: ThemeMode.system,
        appearance: appearance,
      ),
    );
    return Stripe.instance.presentPaymentSheet();
  }

  /// Display string for the "saved card" banner after a **successful** deposit.
  ///
  /// Uses the Payment Sheet option label when present; otherwise falls back to
  /// [fallbackLabel]. Still requires the server to create the PaymentIntent with
  /// `setup_future_usage` when saving for Stripe’s Customer — see Wayo-ads
  /// `POST /api/wallet/deposit-intent` + `savePaymentMethod`.
  static Future<String> savedCardDisplayLabel({
    required String clientSecret,
    PaymentSheetPaymentOption? sheetOption,
    required String fallbackLabel,
  }) async {
    final direct = sheetOption?.label.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    try {
      final pi = await Stripe.instance.retrievePaymentIntent(clientSecret);
      final pm = pi.paymentMethodId;
      if (pm != null && pm.isNotEmpty) {
        return fallbackLabel;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Stripe] savedCardDisplayLabel retrievePaymentIntent: $e');
      }
    }
    return fallbackLabel;
  }

  /// Apple Pay — iOS with a configured [kStripeAppleMerchantId].
  static Future<bool> isApplePaySupported() async {
    try {
      if (!Platform.isIOS) {
        return false;
      }
      if (kStripeAppleMerchantId.trim().isEmpty) {
        return false;
      }
      return Stripe.instance.isPlatformPaySupported();
    } catch (_) {
      return false;
    }
  }

  /// Google Pay — Android with Play services + a Google Wallet account.
  static Future<bool> isGooglePaySupported() async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }
      return Stripe.instance.isPlatformPaySupported(
        googlePay: IsGooglePaySupportedParams(testEnv: _googlePayTestEnv),
      );
    } catch (_) {
      return false;
    }
  }

  /// Resolves Google Pay environment:
  ///  * explicit `STRIPE_GOOGLE_PAY_TEST_ENV=true/false` dart-define wins,
  ///  * otherwise falls back to [kDebugMode] (debug -> test, release -> prod).
  static bool get _googlePayTestEnv {
    final raw = kStripeGooglePayTestEnvRaw.trim().toLowerCase();
    if (raw == 'true' || raw == '1') {
      return true;
    }
    if (raw == 'false' || raw == '0') {
      return false;
    }
    return kDebugMode;
  }

  /// Native Apple Pay confirmation (iOS only).
  static Future<void> confirmWithApplePay({
    required String clientSecret,
    required String currency,
    required int amountCents,
  }) async {
    if (!Platform.isIOS) {
      throw const _PlatformPayUnavailable();
    }
    final country = _merchantCountryForCurrency(currency);
    final amountMajor = (amountCents / 100.0).toStringAsFixed(2);
    await Stripe.instance.confirmPlatformPayPaymentIntent(
      clientSecret: clientSecret,
      confirmParams: PlatformPayConfirmParams.applePay(
        applePay: ApplePayParams(
          merchantCountryCode: country,
          currencyCode: currency.toUpperCase(),
          cartItems: [
            ApplePayCartSummaryItem.immediate(
              label: 'Wayo Ads wallet deposit',
              amount: amountMajor,
            ),
          ],
        ),
      ),
    );
  }

  /// Native Google Pay confirmation (Android only).
  static Future<void> confirmWithGooglePay({
    required String clientSecret,
    required String currency,
  }) async {
    if (!Platform.isAndroid) {
      throw const _PlatformPayUnavailable();
    }
    final country = _merchantCountryForCurrency(currency);
    await Stripe.instance.confirmPlatformPayPaymentIntent(
      clientSecret: clientSecret,
      confirmParams: PlatformPayConfirmParams.googlePay(
        googlePay: GooglePayParams(
          merchantCountryCode: country,
          currencyCode: currency.toUpperCase(),
          testEnv: _googlePayTestEnv,
          merchantName: 'Wayo Ads',
        ),
      ),
    );
  }

  /// True for the common "user closed the sheet / cancelled the wallet" exceptions.
  static bool isUserCancelled(Object error) {
    if (error is StripeException) {
      final c = error.error.code;
      if (c == FailureCode.Canceled) {
        return true;
      }
      final msg = (error.error.localizedMessage ?? error.error.message ?? '')
          .toLowerCase();
      if (msg.contains('cancel')) {
        return true;
      }
    }
    return false;
  }

  /// Best-effort human-readable error message (for SnackBars).
  static String describeError(Object error) {
    if (error is StripeException) {
      final e = error.error;
      return e.localizedMessage?.isNotEmpty == true
          ? e.localizedMessage!
          : (e.message?.isNotEmpty == true
                ? e.message!
                : (e.declineCode ?? e.code.name));
    }
    return error.toString();
  }
}

class _PlatformPayUnavailable implements Exception {
  const _PlatformPayUnavailable();
  @override
  String toString() => 'Platform pay unavailable on this device.';
}
