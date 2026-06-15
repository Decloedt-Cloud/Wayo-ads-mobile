import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/push/wayo_push_intent.dart';

void main() {
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
