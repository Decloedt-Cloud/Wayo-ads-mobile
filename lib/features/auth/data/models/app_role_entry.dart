/// One row from Auth_Wayo `app_roles` (per-app role).
class AppRoleEntry {
  const AppRoleEntry({required this.app, required this.role});

  final String app;
  final String role;

  factory AppRoleEntry.fromJson(Map<String, dynamic> json) {
    return AppRoleEntry(
      app: json['app'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'app': app, 'role': role};
}
