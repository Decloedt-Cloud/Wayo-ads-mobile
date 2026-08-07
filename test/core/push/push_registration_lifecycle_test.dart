import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/push/push_registration_lifecycle.dart';

void main() {
  group('PushRegistrationGate', () {
    setUp(() {
      // Reset between tests by allowing after any prior block.
      PushRegistrationGate.allow(reason: 'test_reset');
    });

    test('block increments generation and prevents registration until allow', () {
      final before = PushRegistrationGate.generation;
      PushRegistrationGate.block(reason: 'logout');
      expect(PushRegistrationGate.isBlocked, isTrue);
      expect(PushRegistrationGate.generation, greaterThan(before));

      final mid = PushRegistrationGate.beginAttempt();
      PushRegistrationGate.block(reason: 'force_logout');
      expect(PushRegistrationGate.generation, isNot(mid));

      PushRegistrationGate.allow(reason: 'login');
      expect(PushRegistrationGate.isBlocked, isFalse);
    });

    test('unregister reasons are explicit enums', () {
      expect(PushUnregisterReason.logout.name, 'logout');
      expect(PushUnregisterReason.forceLogout.name, 'forceLogout');
      expect(PushUnregisterReason.userDisabled.name, 'userDisabled');
      expect(PushRegisterReason.appStart.name, 'appStart');
      expect(PushRegisterReason.tokenRefresh.name, 'tokenRefresh');
    });
  });
}
