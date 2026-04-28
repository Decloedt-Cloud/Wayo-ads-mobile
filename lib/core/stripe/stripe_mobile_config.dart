/// Build-time Stripe / Apple Pay options (mobile).
///
/// Set [STRIPE_APPLE_MERCHANT_ID] to your Apple Pay merchant id (e.g. `merchant.com.wayo.app`)
/// after enabling Apple Pay in Xcode and in the Stripe Dashboard.
const String kStripeAppleMerchantId = String.fromEnvironment(
  'STRIPE_APPLE_MERCHANT_ID',
  defaultValue: '',
);

/// Must match iOS `CFBundleURLSchemes` / Android Auth scheme for return URLs.
const String kStripeUrlScheme = String.fromEnvironment(
  'STRIPE_URL_SCHEME',
  defaultValue: 'com.wayo.wayoadsgo',
);

/// Google Pay environment.
///
/// `"true"`  -> test environment (no real charges, no merchant approval needed).
/// `"false"` -> production Google Pay (merchant must be approved in
///              https://pay.google.com/business/console).
///
/// Empty string (default) -> falls back to [kDebugMode] at runtime.
const String kStripeGooglePayTestEnvRaw = String.fromEnvironment(
  'STRIPE_GOOGLE_PAY_TEST_ENV',
  defaultValue: '',
);

/// Optional Google Pay merchant id (from the Google Pay Business Console,
/// e.g. `BCR2DN...`). Only useful after production approval — in test env
/// Stripe does not require it.
const String kStripeGooglePayMerchantId = String.fromEnvironment(
  'STRIPE_GOOGLE_PAY_MERCHANT_ID',
  defaultValue: '',
);
