import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/push/wayo_push_intent.dart';

void main() {
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
}
