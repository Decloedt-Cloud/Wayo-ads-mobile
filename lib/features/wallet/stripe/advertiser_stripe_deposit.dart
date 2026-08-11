import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/platform/android_window_insets.dart';
import '../../../core/stripe/stripe_mobile_config.dart';
import '../../../core/theme/app_colors.dart';

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

  static SystemUiOverlayStyle _overlayFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final nav = isDark ? AppColors.black : Colors.white;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: nav,
      systemNavigationBarDividerColor: nav,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  /// Stripe Link / Payment Sheet draw under the Android nav bar when
  /// MainActivity is edge-to-edge (`setDecorFitsSystemWindows(false)`).
  /// [SystemChrome] alone does not flip that flag — we toggle it natively.
  /// Failures here must never abort ACH/card present (native crash risk).
  static Future<T> _withNavBarSafeChrome<T>(
    Future<T> Function() action, {
    required Brightness brightness,
  }) async {
    final android = !kIsWeb && Platform.isAndroid;
    final ios = !kIsWeb && Platform.isIOS;
    if (android) {
      try {
        await AndroidWindowInsets.setDecorFitsSystemWindows(true);
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        SystemChrome.setSystemUIOverlayStyle(_overlayFor(brightness));
        // Give native chrome + content padding a frame to settle before Stripe opens.
        await Future<void>.delayed(const Duration(milliseconds: 120));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Stripe] nav-bar chrome prepare failed: $e');
        }
      }
    } else if (ios) {
      // Keep system UI visible so Stripe sheets can respect the home indicator.
      try {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        SystemChrome.setSystemUIOverlayStyle(_overlayFor(brightness));
      } catch (_) {}
    }
    try {
      return await action();
    } finally {
      if (android) {
        try {
          // Restore app chrome *before* flipping edge-to-edge so Android does
          // not briefly paint a light system window behind Flutter.
          SystemChrome.setSystemUIOverlayStyle(_overlayFor(brightness));
          await WidgetsBinding.instance.endOfFrame;
          await AndroidWindowInsets.setDecorFitsSystemWindows(false);
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          SystemChrome.setSystemUIOverlayStyle(_overlayFor(brightness));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[Stripe] nav-bar chrome restore failed: $e');
          }
        }
      } else if (ios) {
        try {
          SystemChrome.setSystemUIOverlayStyle(_overlayFor(brightness));
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        } catch (_) {}
      }
    }
  }

  /// Match Stripe sheet chrome to the *app* theme — never [ThemeMode.system].
  /// System light + dark app caused a bright white flash when the sheet closed.
  static PaymentSheetAppearance _appearanceFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return PaymentSheetAppearance(
        colors: PaymentSheetAppearanceColors(
          primary: const Color(0xFFF4A237),
          background: const Color(0xFF0A0A0A),
          componentBackground: const Color(0xFF1C1C1E),
          componentText: Colors.white,
          primaryText: Colors.white,
          secondaryText: const Color(0xFFAEAEB2),
          placeholderText: const Color(0xFF8E8E93),
          icon: const Color(0xFFF4A237),
          error: const Color(0xFFFF4D4D),
        ),
        shapes: const PaymentSheetShape(borderRadius: 16),
      );
    }
    return PaymentSheetAppearance(
      colors: PaymentSheetAppearanceColors(
        primary: const Color(0xFFF4A237),
        background: Colors.white,
        componentBackground: const Color(0xFFF2F2F7),
        componentText: Colors.black,
        primaryText: Colors.black,
        secondaryText: const Color(0xFF6C6C70),
        placeholderText: const Color(0xFF8E8E93),
        icon: const Color(0xFFF4A237),
        error: const Color(0xFFFF4D4D),
      ),
      shapes: const PaymentSheetShape(borderRadius: 16),
    );
  }

  /// Card-only Payment Sheet for a one-off wallet top-up (no in-app card storage).
  static Future<void> presentCardPaymentSheet({
    required String clientSecret,
    required String currency,
    Brightness brightness = Brightness.dark,
  }) =>
      _withNavBarSafeChrome(
        () async {
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'Wayo Ads',
              style: brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              appearance: _appearanceFor(brightness),
              // iOS: required for 3DS / redirect PMs (Stripe native maps `{scheme}://safepay`).
              // Without this, Payment Sheet often works on Android but fails on iOS after authentication.
              returnURL: Platform.isIOS ? '$kStripeUrlScheme://safepay' : null,
            ),
          );
          await Stripe.instance.presentPaymentSheet();
        },
        brightness: brightness,
      );

  /// ACH (`us_bank_account`) Payment Sheet — mirrors web Payment Element for ACH.
  ///
  /// Must use [allowsDelayedPaymentMethods]; ACH PIs are not card-capable, so the
  /// card-only sheet fails. Settlement is async (1–3 business days).
  static Future<void> presentAchPaymentSheet({
    required String clientSecret,
    Brightness brightness = Brightness.dark,
  }) =>
      _withNavBarSafeChrome(
        () async {
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'Wayo Ads',
              style: brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              appearance: _appearanceFor(brightness),
              allowsDelayedPaymentMethods: true,
              returnURL: Platform.isIOS ? '$kStripeUrlScheme://safepay' : null,
            ),
          );
          await Stripe.instance.presentPaymentSheet();
        },
        brightness: brightness,
      );

  static String? get _iosReturnUrl =>
      Platform.isIOS ? '$kStripeUrlScheme://safepay' : null;

  /// One-click pay with a saved Stripe payment method id.
  ///
  /// On iOS, 3DS may return [PaymentIntentsStatus.RequiresAction] — without
  /// [handleNextAction] + return URL the UI spins forever (no Payment Sheet).
  static Future<void> confirmSavedCard({
    required String clientSecret,
    required String paymentMethodId,
  }) async {
    var paymentIntent = await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: PaymentMethodParams.cardFromMethodId(
        paymentMethodData: PaymentMethodDataCardFromMethod(
          paymentMethodId: paymentMethodId,
        ),
      ),
    );

    if (paymentIntent.status == PaymentIntentsStatus.RequiresAction) {
      paymentIntent = await Stripe.instance.handleNextAction(
        clientSecret,
        returnURL: _iosReturnUrl,
      );
    }

    if (paymentIntent.status != PaymentIntentsStatus.Succeeded &&
        paymentIntent.status != PaymentIntentsStatus.Processing) {
      throw StripeException(
        error: LocalizedErrorMessage(
          code: FailureCode.Failed,
          localizedMessage:
              'Payment was not completed (${paymentIntent.status.name}).',
        ),
      );
    }
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
    Brightness brightness = Brightness.dark,
  }) =>
      _withNavBarSafeChrome(
        () async {
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
        },
        brightness: brightness,
      );

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

  static String describeError(Object error) {
    if (error is StripeException) {
      final e = error.error;
      if (e.localizedMessage?.isNotEmpty == true) {
        return e.localizedMessage!;
      }
      if (e.message?.isNotEmpty == true) {
        return e.message!;
      }
      return e.declineCode ?? e.code.name;
    }
    if (error is _PlatformPayUnavailable) {
      return error.toString();
    }
    return error.toString();
  }
}

final class _PlatformPayUnavailable implements Exception {
  const _PlatformPayUnavailable();

  @override
  String toString() => 'Platform pay is unavailable on this device';
}
