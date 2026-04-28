import 'wayo_ads_account_role.dart';
import '../data/models/app_user.dart';

/// Keys Auth_Wayo may return in [AppUser.pendingOnboarding] (ordered).
const String kOnboardingSelectRole = 'select_role';
const String kOnboardingVerifyEmail = 'verify_email';

/// First destination after login (Wayo-ads + Auth_Wayo: role then email OTP, if needed).
String? onboardingRedirectPath(AppUser u) {
  for (final step in u.pendingOnboarding) {
    if (step == kOnboardingSelectRole) {
      return '/onboarding/wayo-ads-role';
    }
    if (step == kOnboardingVerifyEmail) {
      return '/onboarding/verify-email-otp';
    }
  }
  if (u.wayoAdsRole == WayoAdsAccountRole.unknown) {
    return '/onboarding/wayo-ads-role';
  }
  if (u.mustVerifyEmail) {
    return '/onboarding/verify-email-otp';
  }
  return null;
}
