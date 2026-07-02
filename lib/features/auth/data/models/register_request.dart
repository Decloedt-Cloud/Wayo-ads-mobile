class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.app,
    this.appKey,
  });

  final String name;
  final String email;
  final String password;

  /// `CREATOR` or `ADVERTISER` — same as web `/auth/signup?role=`.
  final String role;
  final String? app;
  final String? appKey;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (app != null && app!.trim().isNotEmpty) 'app': app!.trim(),
        if (appKey != null && appKey!.trim().isNotEmpty) 'app_key': appKey!.trim(),
      };
}
