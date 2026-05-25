/// Compile-time configuration via `--dart-define(-from-file=…)`.
///
/// Runtime values from `dart_defines.json` (asset overlay) are merged in
/// [AuthRuntimeConfig.ensureLoaded] for URLs, Sentry, and certificate pins.
abstract final class AppConfig {
  static const String authBaseUrl = String.fromEnvironment('AUTH_BASE_URL');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String sentryEnv = String.fromEnvironment(
    'SENTRY_ENV',
    defaultValue: 'staging',
  );
  static const String appRelease = String.fromEnvironment(
    'APP_RELEASE',
    defaultValue: 'wayo-ads-go@1.0.0+1',
  );
  static const String certPinPrimary = String.fromEnvironment(
    'CERT_PIN_PRIMARY',
  );
  static const String certPinBackup = String.fromEnvironment('CERT_PIN_BACKUP');

  /// Optional third pin (e.g. separate TLS cert for chat API).
  static const String certPinExtra = String.fromEnvironment('CERT_PIN_EXTRA');

  /// Optional fourth pin (e.g. **origin** cert while [certPinPrimary] is the **public/CDN** leaf).
  static const String certPinAlt = String.fromEnvironment('CERT_PIN_ALT');

  /// Wayo-ads (Next.js) API origin — advertiser dashboard calls.
  static const String wayoAdsApiBaseUrl = String.fromEnvironment(
    'WAYO_ADS_API_BASE_URL',
  );

  /// Laravel Reverb / Pusher-compatible realtime config.
  static const String reverbHost = String.fromEnvironment('REVERB_HOST');
  static const String reverbKey = String.fromEnvironment('REVERB_KEY');
  static const String reverbPort = String.fromEnvironment(
    'REVERB_PORT',
    defaultValue: '443',
  );
  static const String reverbScheme = String.fromEnvironment(
    'REVERB_SCHEME',
    defaultValue: 'https',
  );

  static bool get reverbConfigured =>
      reverbKey.isNotEmpty && reverbHost.isNotEmpty;

  static bool get sentryEnabled => sentryDsn.isNotEmpty;

  static List<String> get pinnedKeys =>
      [certPinPrimary, certPinBackup, certPinExtra, certPinAlt]
          .where((s) => s.isNotEmpty)
          .toList();

  static bool get pinningEnabled => pinnedKeys.isNotEmpty;

  /// Certificate pinning is permanently disabled.
  /// To re-enable, change this to `false` and configure CERT_PIN_* values.
  static const bool disableCertPinning = true;
}
