import '../constants/app_constants.dart' as ac;

/// Optional Passport / Auth_Wayo fields so the API uses the **mobile** OAuth client
/// and [ac.authOAuthRedirectUri] instead of defaulting to the web callback
/// (`https://ads.wayo.agency/api/auth/callback/wayo-auth`).
///
/// Configure via `--dart-define` / `--dart-define-from-file`:
/// `AUTH_OAUTH_CLIENT_ID`, `AUTH_OAUTH_REDIRECT_URI`, optionally `AUTH_OAUTH_CLIENT_SECRET`.
///
/// **Security:** `client_secret` in a shipped app is extractable; prefer a public /
/// PKCE client on the backend when possible.
Map<String, dynamic> wayoAuthOAuthJsonExtras() {
  final out = <String, dynamic>{};
  final id = ac.authOAuthClientId.trim();
  final uri = ac.authOAuthRedirectUri.trim();
  final secret = ac.authOAuthClientSecret.trim();
  if (id.isNotEmpty) {
    out['client_id'] = id;
  }
  if (uri.isNotEmpty) {
    out['redirect_uri'] = uri;
  }
  if (secret.isNotEmpty) {
    out['client_secret'] = secret;
  }
  return out;
}

Map<String, dynamic> mergeWayoAuthPayload(Map<String, dynamic> base) {
  final extra = wayoAuthOAuthJsonExtras();
  if (extra.isEmpty) {
    return base;
  }
  return <String, dynamic>{...base, ...extra};
}
