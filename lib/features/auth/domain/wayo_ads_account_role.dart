/// Role for the Wayo Ads app on Auth_Wayo (`user_app_roles` / `app_role` in API).
enum WayoAdsAccountRole {
  creator,
  advertiser,
  superAdmin,
  user,
  unknown;

  static WayoAdsAccountRole fromApiString(String? s) {
    switch ((s ?? '').trim().toUpperCase()) {
      case 'CREATOR':
        return WayoAdsAccountRole.creator;
      case 'ADVERTISER':
        return WayoAdsAccountRole.advertiser;
      case 'SUPERADMIN':
        return WayoAdsAccountRole.superAdmin;
      case 'USER':
        return WayoAdsAccountRole.user;
      default:
        return WayoAdsAccountRole.unknown;
    }
  }

  /// Stable value for JSON cache (same as enum name).
  static WayoAdsAccountRole fromStorageString(String? s) {
    if (s == null || s.isEmpty) {
      return WayoAdsAccountRole.unknown;
    }
    for (final v in WayoAdsAccountRole.values) {
      if (v.name == s) {
        return v;
      }
    }
    return WayoAdsAccountRole.unknown;
  }
}
