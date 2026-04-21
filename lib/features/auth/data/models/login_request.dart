class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.app,
    this.appKey,
  });

  final String email;
  final String password;

  /// Auth_Wayo app slug (e.g. wayo_ads) — enables trusted-app rules when [appKey] matches.
  final String? app;

  /// Inter-service key from `dart_defines.json` / Auth — must match `WAYO_ADS_APP_KEY` on Laravel.
  final String? appKey;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (app != null && app!.trim().isNotEmpty) 'app': app!.trim(),
        if (appKey != null && appKey!.trim().isNotEmpty) 'app_key': appKey!.trim(),
      };
}
