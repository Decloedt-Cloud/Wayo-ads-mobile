import '../../../auth/domain/wayo_ads_account_role.dart';

/// Role of the conversation partner, shown as a badge in chat.
enum ChatPartnerRole { creator, advertiser, admin }

/// Maps marketing DB `roles` string (e.g. `USER,SUPERADMIN`) to a badge role.
///
/// Superadmin is shown as **Admin** (web parity). Prefer advertiser over creator
/// when both are present.
ChatPartnerRole? chatPartnerRoleFromAppRoles(String? rolesRaw) {
  if (rolesRaw == null || rolesRaw.trim().isEmpty) return null;
  final upper = rolesRaw.toUpperCase();
  if (upper.contains('SUPERADMIN') ||
      RegExp(r'(^|,)\s*ADMIN\s*(,|$)').hasMatch(upper)) {
    return ChatPartnerRole.admin;
  }
  if (upper.contains('ADVERTISER')) return ChatPartnerRole.advertiser;
  if (upper.contains('CREATOR')) return ChatPartnerRole.creator;
  return null;
}

/// Infers the partner's role from the signed-in user's role (creator ↔ advertiser).
///
/// Prefer [chatPartnerRoleFromAppRoles] when marketing roles are available —
/// required for superadmin ↔ anyone chats (badge **Admin** / Creator / Advertiser).
ChatPartnerRole? chatPartnerRoleFor(WayoAdsAccountRole myRole) {
  switch (myRole) {
    case WayoAdsAccountRole.advertiser:
      return ChatPartnerRole.creator;
    case WayoAdsAccountRole.creator:
      return ChatPartnerRole.advertiser;
    case WayoAdsAccountRole.superAdmin:
    case WayoAdsAccountRole.user:
    case WayoAdsAccountRole.unknown:
      return null;
  }
}

/// Resolve badge: marketing roles first, then opposite-role inference.
ChatPartnerRole? resolveChatPartnerRole({
  required WayoAdsAccountRole myRole,
  String? partnerAppRoles,
}) {
  return chatPartnerRoleFromAppRoles(partnerAppRoles) ??
      chatPartnerRoleFor(myRole);
}
