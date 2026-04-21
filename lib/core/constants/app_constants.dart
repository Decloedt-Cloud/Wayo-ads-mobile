/// Build-time configuration via `--dart-define-from-file=dart_defines.json`.
///
/// // TODO(dev): confirm Auth_Wayo base URL and env-specific values for each flavor.
const String authWayoBaseUrl = String.fromEnvironment(
  'AUTH_WAYO_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

/// Optional primary brand color override (hex without #), e.g. `6C47FF`.
const String wayoPrimaryColorHex = String.fromEnvironment(
  'WAYO_PRIMARY_COLOR',
  defaultValue: '6C47FF',
);

/// OAuth app slug for Auth_Wayo (e.g. wayo_ads).
const String authAppName = String.fromEnvironment(
  'AUTH_APP_NAME',
  defaultValue: 'wayo_ads',
);

/// Same value as `WAYO_ADS_APP_KEY` on Auth_Wayo — enables trusted-app behaviour (verified email, roles).
const String wayoAdsAppKey = String.fromEnvironment(
  'WAYO_ADS_APP_KEY',
  defaultValue: '',
);

/// Google Cloud **Web client ID** (must match Auth_Wayo `GOOGLE_CLIENT_ID`). Used so the ID token `aud` matches the backend.
const String authGoogleServerClientId = String.fromEnvironment(
  'AUTH_GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '',
);
