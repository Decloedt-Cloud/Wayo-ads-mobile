import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/auth/domain/wayo_ads_account_role.dart';
import 'package:wayoadsgo/features/dashboard/domain/entities/notification_item.dart';
import 'package:wayoadsgo/features/dashboard/presentation/utils/notification_route_resolver.dart';

NotificationItem _item({
  String? type,
  String? actionUrl,
  Map<String, dynamic>? metadata,
  String title = 'New Campaign Available',
}) {
  return NotificationItem(
    id: 'n1',
    title: title,
    body: 'body',
    isRead: false,
    type: type,
    actionUrl: actionUrl,
    metadata: metadata,
  );
}

void main() {
  test('CAMPAIGN_ACTIVATED opens creator campaign detail for creators', () {
    final route = resolveNotificationMobileRoute(
      _item(
        type: 'CAMPAIGN_ACTIVATED',
        actionUrl: '/campaigns/camp-123',
        metadata: {'campaignId': 'camp-123'},
      ),
      WayoAdsAccountRole.creator,
    );
    expect(route, '/creator/campaigns/camp-123');
  });

  test('CAMPAIGN_ACTIVATED does not open foreign advertiser detail', () {
    final route = resolveNotificationMobileRoute(
      _item(
        type: 'CAMPAIGN_ACTIVATED',
        actionUrl: '/campaigns/camp-123',
        metadata: {'campaignId': 'camp-123'},
      ),
      WayoAdsAccountRole.advertiser,
    );
    expect(route, '/campaigns');
  });

  test('CREATOR_APPLIED opens advertiser campaign detail', () {
    final route = resolveNotificationMobileRoute(
      _item(
        type: 'CREATOR_APPLIED',
        actionUrl: '/campaigns/camp-9?tab=applications',
        metadata: {'campaignId': 'camp-9'},
        title: 'New Creator Application',
      ),
      WayoAdsAccountRole.advertiser,
    );
    expect(route, '/campaigns/camp-9');
  });

  test('web campaign link remapped for creator role', () {
    final route = resolveNotificationMobileRoute(
      _item(
        type: 'CREATOR_APPLICATION_APPROVED',
        actionUrl: '/campaigns/camp-55',
        metadata: {'campaignId': 'camp-55'},
        title: 'Application approved',
      ),
      WayoAdsAccountRole.creator,
    );
    expect(route, '/creator/campaigns/camp-55');
  });
}
