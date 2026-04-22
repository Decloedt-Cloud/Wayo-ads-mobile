import '../../../../core/config/auth_runtime_config.dart';
import '../../domain/wayo_ads_account_role.dart';
import 'app_role_entry.dart';

String _wayoAdsAppSlug() {
  final s = AuthRuntimeConfig.instance.authAppName.trim();
  return s.isNotEmpty ? s : 'wayo_ads';
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    this.wayoAdsRole = WayoAdsAccountRole.unknown,
    this.appRoles = const [],
  });

  final int id;
  final String email;
  final String? name;
  final String? avatar;

  /// Role for Wayo Ads (`AUTH_APP_NAME` / `wayo_ads`), from `app_roles` / `app_role` in Auth_Wayo.
  final WayoAdsAccountRole wayoAdsRole;

  /// All per-app roles returned by the auth API (`app_roles`).
  final List<AppRoleEntry> appRoles;

  bool get isCreator => wayoAdsRole == WayoAdsAccountRole.creator;

  bool get isAdvertiser => wayoAdsRole == WayoAdsAccountRole.advertiser;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    final id = idVal is int ? idVal : int.tryParse('$idVal') ?? 0;
    final roles = _parseAppRoles(json);
    final role = _resolveWayoAdsRole(json, roles);
    return AppUser(
      id: id,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      wayoAdsRole: role,
      appRoles: roles,
    );
  }

  static List<AppRoleEntry> _parseAppRoles(Map<String, dynamic> json) {
    final raw = json['app_roles'];
    if (raw is List<dynamic>) {
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => AppRoleEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    // Some JSON encoders turn lists into { "0": {...}, "1": {...} }
    if (raw is Map) {
      return raw.values
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => AppRoleEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static WayoAdsAccountRole _resolveWayoAdsRole(
    Map<String, dynamic> json,
    List<AppRoleEntry> roles,
  ) {
    for (final e in roles) {
      if (e.app == _wayoAdsAppSlug()) {
        return WayoAdsAccountRole.fromApiString(e.role);
      }
    }
    final single = json['app_role'] as String?;
    if (single != null && single.isNotEmpty) {
      return WayoAdsAccountRole.fromApiString(single);
    }
    final stored = json['wayo_ads_role'] as String?;
    if (stored != null && stored.isNotEmpty) {
      return WayoAdsAccountRole.fromStorageString(stored);
    }
    return WayoAdsAccountRole.unknown;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (name != null) 'name': name,
    if (avatar != null) 'avatar': avatar,
    'wayo_ads_role': wayoAdsRole.name,
    if (_apiRoleForWayoAds() != null) 'app_role': _apiRoleForWayoAds(),
    'app_roles': appRoles.map((e) => e.toJson()).toList(),
  };

  /// Persisted shape compatible with Auth_Wayo (`CREATOR` / `ADVERTISER`).
  String? _apiRoleForWayoAds() {
    return switch (wayoAdsRole) {
      WayoAdsAccountRole.creator => 'CREATOR',
      WayoAdsAccountRole.advertiser => 'ADVERTISER',
      WayoAdsAccountRole.superAdmin => 'SUPERADMIN',
      WayoAdsAccountRole.user => 'USER',
      WayoAdsAccountRole.unknown => null,
    };
  }
}
