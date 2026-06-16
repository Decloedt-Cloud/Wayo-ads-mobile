import '../../../auth/domain/wayo_ads_account_role.dart';

/// Role of the conversation partner, shown as a badge in chat.
enum ChatPartnerRole { creator, advertiser }

/// Infers the partner's role from the signed-in user's role.
///
/// Wayo chat is collaboration between an advertiser and a creator, so the
/// partner is always the opposite role. Returns `null` for superadmin / unknown
/// where the opposite role can't be inferred confidently.
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
