import '../../../../core/push/mobile_push_route_utils.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../domain/entities/notification_item.dart';

/// Best mobile route for a notification (URL, metadata, type, role).
String? resolveNotificationMobileRoute(
  NotificationItem item,
  WayoAdsAccountRole role,
) {
  final type = (item.type ?? '').toUpperCase();
  final campId = item.metadataCampaignId;

  // Wayo-ads `CAMPAIGN_ACTIVATED` broadcast ("New Campaign Available") targets creators.
  if (isCreatorCampaignBrowseNotification(item)) {
    if (role == WayoAdsAccountRole.creator &&
        campId != null &&
        campId.isNotEmpty) {
      return '/creator/campaigns/$campId';
    }
    return role == WayoAdsAccountRole.creator ? '/dashboard' : '/campaigns';
  }

  final fromUrl = normalizeMobilePushRoute(item.actionUrl);
  var route = fromUrl;

  if (route == null) {
    route = _routeFromMetadata(item, role, type, campId);
  }

  if (route == null) return null;

  return remapCampaignRouteForRole(route, role, item);
}

/// Re-maps web `/campaigns/:id` links to the correct mobile screen for [role].
String remapCampaignRouteForRole(
  String route,
  WayoAdsAccountRole role,
  NotificationItem item,
) {
  final base = route.split('?').first;

  if (role == WayoAdsAccountRole.creator) {
    final advMatch = RegExp(r'^/campaigns/([^/?#]+)$').firstMatch(base);
    if (advMatch != null) {
      final id = advMatch.group(1)!;
      if (base.contains('application') ||
          (item.metadataApplicationId?.isNotEmpty ?? false)) {
        return '/creator/campaigns/$id/application';
      }
      return '/creator/campaigns/$id';
    }
    return route;
  }

  if (role == WayoAdsAccountRole.advertiser) {
    if (isCreatorCampaignBrowseNotification(item)) {
      return '/campaigns';
    }
    final creMatch = RegExp(r'^/creator/campaigns/([^/?#]+)').firstMatch(base);
    if (creMatch != null && item.isCreatorAppliedNotification) {
      return '/campaigns/${creMatch.group(1)}';
    }
  }

  return route;
}

String? _routeFromMetadata(
  NotificationItem item,
  WayoAdsAccountRole role,
  String type,
  String? campId,
) {
  final appId = item.metadataApplicationId;

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
    return '$kSuperadminHomeRoute?tab=withdrawals';
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
        ? '$kSuperadminHomeRoute?tab=withdrawals'
        : '/dashboard';
  }

  return null;
}

/// Creator marketplace alerts (e.g. `CAMPAIGN_ACTIVATED` role broadcast).
bool isCreatorCampaignBrowseNotification(NotificationItem item) {
  final type = (item.type ?? '').toUpperCase();
  if (type.contains('CAMPAIGN_ACTIVATED')) return true;
  if (type.contains('NEW_CAMPAIGN')) return true;

  final title = item.title.trim().toLowerCase();
  if (title == 'new campaign available') return true;

  return false;
}

bool notificationCanNavigate(NotificationItem item, WayoAdsAccountRole role) {
  return resolveNotificationMobileRoute(item, role) != null;
}
