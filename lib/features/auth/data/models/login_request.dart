class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.app,
    this.appKey,
    this.forceWebLogout = false,
  });

  final String email;
  final String password;

  /// Auth_Wayo app slug (e.g. wayo_ads) — enables trusted-app rules when [appKey] matches.
  final String? app;

  /// Inter-service key from `dart_defines.json` / Auth — must match `WAYO_ADS_APP_KEY` on Laravel.
  final String? appKey;

  /// When true, Auth revokes the active Wayo-ads web OAuth session before issuing mobile tokens.
  final bool forceWebLogout;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    if (app != null && app!.trim().isNotEmpty) 'app': app!.trim(),
    if (appKey != null && appKey!.trim().isNotEmpty) 'app_key': appKey!.trim(),
    if (forceWebLogout) 'force_web_logout': true,
  };
}
