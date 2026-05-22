import '../../../../core/push/mobile_push_route_utils.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../domain/entities/notification_item.dart';

/// Best mobile route for a notification (URL, metadata, type, role).
String? resolveNotificationMobileRoute(
  NotificationItem item,
  WayoAdsAccountRole role,
) {
  final fromUrl = normalizeMobilePushRoute(item.actionUrl);
  if (fromUrl != null) return fromUrl;

  final campId = item.metadataCampaignId;
  final appId = item.metadataApplicationId;
  final type = (item.type ?? '').toUpperCase();

  if (campId != null &&
      campId.isNotEmpty &&
      (item.isCreatorAppliedNotification ||
          type.contains('CREATOR_APPLIED') ||
          type.contains('APPLICATION'))) {
    if (role == WayoAdsAccountRole.creator) {
      if (appId != null && appId.isNotEmpty) {
        return '/creator/campaigns/$campId/application';
      }
      return '/creator/campaigns/$campId';
    }
    return '/campaigns/$campId';
  }

  if (campId != null && campId.isNotEmpty) {
    return role == WayoAdsAccountRole.creator
        ? '/creator/campaigns/$campId'
        : '/campaigns/$campId';
  }

  if ((type.contains('WITHDRAW') || type.contains('STRIPE_PAYOUT')) &&
      role == WayoAdsAccountRole.superAdmin) {
    return '/superadmin/withdrawals';
  }

  if (type.contains('WALLET') ||
      type.contains('DEPOSIT') ||
      type.contains('CREDIT') ||
      type.contains('EARNING') ||
      type.contains('WITHDRAW') ||
      type.contains('PAYOUT') ||
      type.contains('BUDGET')) {
    return '/wallet';
  }

  if (type.contains('INVOICE')) return '/invoices';

  if (type.contains('CHAT') || type.contains('MESSAGE')) return '/chat';

  if (type.contains('CAMPAIGN') ||
      type.contains('VIDEO') ||
      type.contains('CREATOR')) {
    return role == WayoAdsAccountRole.creator ? '/dashboard' : '/campaigns';
  }

  if (type.contains('FRAUD') ||
      type.contains('SUSPICIOUS') ||
      type.contains('FLAGGED')) {
    return role == WayoAdsAccountRole.superAdmin
        ? '/superadmin/withdrawals'
        : '/dashboard';
  }

  return null;
}

bool notificationCanNavigate(NotificationItem item, WayoAdsAccountRole role) {
  return resolveNotificationMobileRoute(item, role) != null;
}
