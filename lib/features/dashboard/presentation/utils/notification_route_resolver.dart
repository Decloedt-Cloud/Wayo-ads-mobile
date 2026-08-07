import 'dart:convert';

import '../../../../core/push/mobile_push_route_utils.dart';
import '../../../../core/push/wayo_push_intent.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../domain/entities/notification_item.dart';

/// Builds a [NotificationItem] from flattened FCM / local notification payload data.
NotificationItem notificationItemFromPushData(Map<String, dynamic> data) {
  final flat = flattenPushPayloadMap(data);
  final type = _pushTrimmed(flat['type']) ??
      _pushTrimmed(flat['notificationType']) ??
      _pushTrimmed(flat['notification_type']);
  final actionUrl =
      _pushTrimmed(flat['actionUrl']) ?? _pushTrimmed(flat['action_url']);
  final title = _pushTrimmed(flat['title']) ?? 'Notification';
  final body = _pushTrimmed(flat['body']) ?? ' ';
  final id = _pushTrimmed(flat['notificationId']) ??
      _pushTrimmed(flat['notification_id']) ??
      'push';

  final metadata = <String, dynamic>{};
  final nestedMeta = flat['metadata'];
  if (nestedMeta is Map) {
    metadata.addAll(Map<String, dynamic>.from(nestedMeta));
  } else if (nestedMeta is String && nestedMeta.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(nestedMeta);
      if (decoded is Map) {
        metadata.addAll(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }
  for (final key in const [
    'campaignId',
    'campaign_id',
    'applicationId',
    'application_id',
    'conversationId',
    'conversation_id',
  ]) {
    final v = flat[key];
    if (v != null) metadata.putIfAbsent(key, () => v);
  }

  return NotificationItem(
    id: id,
    title: title,
    body: body,
    isRead: false,
    type: type,
    actionUrl: actionUrl,
    metadata: metadata.isEmpty ? null : metadata,
  );
}

String? _pushTrimmed(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// Role-aware FCM / tray route — same rules as the in-app notification center.
String? resolvePushRouteForRole({
  Map<String, dynamic>? data,
  String? payload,
  required WayoAdsAccountRole role,
}) {
  Map<String, dynamic>? payloadData = data;
  payloadData ??= wayoRoutePushPayloadDataFromLocalPayload(payload);

  if (payloadData != null && role != WayoAdsAccountRole.unknown) {
    final route = resolveNotificationMobileRoute(
      notificationItemFromPushData(payloadData),
      role,
    );
    if (route != null) return route;
  }

  return resolveWayoPushRoute(data: data, payload: payload);
}

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
          (item.metadataApplicationId?.isNotEmpty ?? false) ||
          isCreatorOwnApplicationNotification(item)) {
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
          type.contains('VIDEO_SUBMITTED') ||
          type.contains('APPLICATION'))) {
    if (role == WayoAdsAccountRole.creator) {
      if (isCreatorOwnApplicationNotification(item)) {
        return '/creator/campaigns/$campId/application';
      }
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

  final conversationId = () {
    final m = item.metadata;
    if (m == null) return null;
    final raw = m['conversationId'] ?? m['conversation_id'];
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }();
  if (type.contains('CHAT') || type.contains('MESSAGE')) {
    if (conversationId != null) return '/chat/thread/$conversationId';
    return '/chat';
  }

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

/// Creator-facing application / submission status alerts.
bool isCreatorOwnApplicationNotification(NotificationItem item) {
  final type = (item.type ?? '').toUpperCase();
  if (type.contains('CREATOR_APPLICATION')) return true;
  if (type.contains('APPLICATION_APPROVED') && !type.contains('CREATOR_APPLIED')) {
    return true;
  }
  if (type.contains('APPLICATION_REJECTED')) return true;
  if (type.contains('APPLICATION_PENDING')) return true;
  if (type.contains('VIDEO_APPROVED')) return true;
  if (type.contains('VIDEO_REJECTED')) return true;
  if (type.contains('VIDEO_FLAGGED')) return true;
  return false;
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
