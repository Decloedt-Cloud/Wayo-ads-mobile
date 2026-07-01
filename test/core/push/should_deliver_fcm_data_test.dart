import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayoadsgo/core/push/wayo_push_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('shouldDeliverFcmData', () {
    test('delivers when push-device register not finished yet', () async {
      final ok = await shouldDeliverFcmData({
        'type': 'CREATOR_APPLIED',
        'recipientUserId': 'user-new',
      });
      expect(ok, isTrue);
    });

    test('blocks when external delivery suppressed (logout)', () async {
      await deactivatePushDelivery();
      final ok = await shouldDeliverFcmData({'type': 'CREATOR_APPLIED'});
      expect(ok, isFalse);
    });

    test('delivers after recipient mismatch and clears stale registration', () async {
      await activatePushDeliveryForWayoUser('user-old');
      final ok = await shouldDeliverFcmData({
        'type': 'CREATOR_APPLIED',
        'recipientUserId': 'user-new',
      });
      expect(ok, isTrue);
      expect(await readRegisteredPushWayoUserId(), isNull);
    });

    test('delivers when registered recipient matches', () async {
      await activatePushDeliveryForWayoUser('user-1');
      final ok = await shouldDeliverFcmData({
        'type': 'CREATOR_APPLIED',
        'recipientUserId': 'user-1',
      });
      expect(ok, isTrue);
    });
  });
}
