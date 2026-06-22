import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/push/wayo_push_intent.dart';

void main() {
  group('WayoRoutePushPayload', () {
    test('CAMPAIGN_ACTIVATED with advertiser actionUrl opens creator detail', () {
      final payload = WayoRoutePushPayload.fromMessageData({
        'type': 'CAMPAIGN_ACTIVATED',
        'route': '/campaigns/camp-123',
        'actionUrl': '/campaigns/camp-123',
        'campaignId': 'camp-123',
        'title': 'New Campaign Available',
      });
      expect(payload?.route, '/creator/campaigns/camp-123');
    });

    test('CAMPAIGN_ACTIVATED FCM data prefers metadata campaignId', () {
      final route = resolveWayoPushRoute(
        data: {
          'type': 'CAMPAIGN_ACTIVATED',
          'actionUrl': '/campaigns/camp-456',
          'metadata': '{"campaignId":"camp-456"}',
        },
      );
      expect(route, '/creator/campaigns/camp-456');
    });

    test('CREATOR_APPLIED still opens advertiser campaign detail', () {
      final payload = WayoRoutePushPayload.fromMessageData({
        'type': 'CREATOR_APPLIED',
        'route': '/campaigns/camp-9',
        'campaignId': 'camp-9',
      });
      expect(payload?.route, '/campaigns/camp-9');
    });
  });

  group('isSelfInitiatedWalletFcmPayload', () {
    test('detects advertiser deposit confirmation', () {
      expect(
        isSelfInitiatedWalletFcmPayload({'type': 'WALLET_CREDITED'}),
        isTrue,
      );
    });

    test('detects creator withdrawal request confirmation', () {
      expect(
        isSelfInitiatedWalletFcmPayload({'type': 'WITHDRAWAL_REQUESTED'}),
        isTrue,
      );
    });

    test('keeps admin withdrawal alerts', () {
      expect(
        isSelfInitiatedWalletFcmPayload({
          'type': 'WITHDRAWAL_REQUESTED',
          'route': '/superadmin/withdrawals',
        }),
        isFalse,
      );
    });

    test('ignores unrelated notifications', () {
      expect(
        isSelfInitiatedWalletFcmPayload({'type': 'CAMPAIGN_ACTIVATED'}),
        isFalse,
      );
    });
  });

  group('isCreatorYoutubeConnectFcmPayload', () {
    test('detects YOUTUBE_DISCONNECTED type', () {
      expect(
        isCreatorYoutubeConnectFcmPayload({
          'type': 'YOUTUBE_DISCONNECTED',
          'title': 'YouTube Channel Disconnected',
        }),
        isTrue,
      );
    });

    test('detects youtube actionUrl', () {
      expect(
        isCreatorYoutubeConnectFcmPayload({
          'type': 'SYSTEM_ALERT',
          'actionUrl': '/settings/youtube',
        }),
        isTrue,
      );
    });

    test('detects connect-youtube route', () {
      expect(
        isCreatorYoutubeConnectFcmPayload({
          'route': '/dashboard/creator/connect-youtube',
        }),
        isTrue,
      );
    });

    test('ignores unrelated campaign notifications', () {
      expect(
        isCreatorYoutubeConnectFcmPayload({
          'type': 'CAMPAIGN_ACTIVATED',
          'actionUrl': '/creator/campaigns/abc',
        }),
        isFalse,
      );
    });
  });

  group('shouldSkipDuplicateFcmLocalTray', () {
    test('skips when OS already shows background notification', () {
      expect(
        shouldSkipDuplicateFcmLocalTray(hasDisplayNotificationPayload: true),
        isTrue,
      );
    });

    test('still shows local tray in foreground', () {
      expect(
        shouldSkipDuplicateFcmLocalTray(
          hasDisplayNotificationPayload: true,
          foreground: true,
        ),
        isFalse,
      );
    });

    test('shows local tray for data-only background', () {
      expect(
        shouldSkipDuplicateFcmLocalTray(hasDisplayNotificationPayload: false),
        isFalse,
      );
    });
  });

  group('wayoFcmTrayNotificationId', () {
    test('uses stable notificationId from FCM data', () {
      final a = wayoFcmTrayNotificationId({'notificationId': 'notif-123'});
      final b = wayoFcmTrayNotificationId({'notificationId': 'notif-123'});
      expect(a, b);
    });
  });
}
