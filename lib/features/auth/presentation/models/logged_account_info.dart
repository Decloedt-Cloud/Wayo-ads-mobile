import 'package:flutter/foundation.dart';

import '../../data/models/app_role_entry.dart';
import '../../data/models/app_user.dart';
import '../../domain/wayo_ads_account_role.dart';

/// Snapshot of the **logged-in** Wayo account: identity + Wayo Ads role (creator / advertiser).
///
/// Use [loggedAccountInfoProvider] for a single place to branch UI or logic.
@immutable
class LoggedAccountInfo {
  const LoggedAccountInfo({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    required this.wayoAdsRole,
    required this.appRoles,
  });

  factory LoggedAccountInfo.fromAppUser(AppUser user) {
    return LoggedAccountInfo(
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatar,
      wayoAdsRole: user.wayoAdsRole,
      appRoles: List<AppRoleEntry>.unmodifiable(user.appRoles),
    );
  }

  final int id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final WayoAdsAccountRole wayoAdsRole;
  final List<AppRoleEntry> appRoles;

  bool get isCreator => wayoAdsRole == WayoAdsAccountRole.creator;

  bool get isAdvertiser => wayoAdsRole == WayoAdsAccountRole.advertiser;

  bool get isSuperAdmin => wayoAdsRole == WayoAdsAccountRole.superAdmin;

  /// `true` when Auth_Wayo returned a CREATOR/ADVERTISER (or other) role for Wayo Ads.
  bool get hasResolvedWayoAdsRole => wayoAdsRole != WayoAdsAccountRole.unknown;
}
