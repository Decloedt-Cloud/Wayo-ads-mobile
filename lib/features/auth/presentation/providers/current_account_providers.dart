import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../domain/auth_notifier.dart';
import '../models/logged_account_info.dart';
import '../../domain/wayo_ads_account_role.dart';

/// Logged-in [AppUser], or `null` if not authenticated.
final Provider<AppUser?> currentAppUserProvider = Provider<AppUser?>((ref) {
  final auth = ref.watch(authNotifierProvider);
  return auth.maybeWhen(
    data: (s) => s is AuthAuthenticated ? s.user : null,
    orElse: () => null,
  );
});

/// **Identity + role** for the active session — use this to branch creator vs advertiser.
final Provider<LoggedAccountInfo?> loggedAccountInfoProvider =
    Provider<LoggedAccountInfo?>((ref) {
  final u = ref.watch(currentAppUserProvider);
  if (u == null) {
    return null;
  }
  return LoggedAccountInfo.fromAppUser(u);
});

/// Resolved Wayo Ads role for the current session (creator vs advertiser, etc.).
final Provider<WayoAdsAccountRole> currentWayoAdsAccountRoleProvider =
    Provider<WayoAdsAccountRole>((ref) {
  return ref.watch(currentAppUserProvider)?.wayoAdsRole ??
      WayoAdsAccountRole.unknown;
});
