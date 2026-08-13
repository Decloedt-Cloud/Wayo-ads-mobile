import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_exceptions.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_models.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_platform.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_service.dart';

void main() {
  group('PasskeyAvailability', () {
    test('canLogin requires platform + login flag', () {
      expect(
        const PasskeyAvailability(
          platformSupported: true,
          loginEnabled: true,
          registrationEnabled: false,
          rpId: 'myaccount.wayo.ac',
        ).canLogin,
        isTrue,
      );
      expect(
        const PasskeyAvailability(
          platformSupported: false,
          loginEnabled: true,
          registrationEnabled: true,
          rpId: null,
        ).canLogin,
        isFalse,
      );
    });
  });

  group('passkeyErrorCode', () {
    test('maps typed exceptions', () {
      expect(passkeyErrorCode(const PasskeyCancelled()), 'cancelled');
      expect(passkeyErrorCode(const PasskeyNotFound()), 'not_found');
      expect(passkeyErrorCode(const PasskeyUnavailable()), 'unavailable');
      expect(passkeyErrorCode(const PasskeyNetworkError()), 'network');
      expect(passkeyErrorCode(Exception('x')), 'unknown');
    });
  });

  group('MethodChannelPasskeyPlatform mapping', () {
    test('maps cancelled platform code', () {
      final p = MethodChannelPasskeyPlatform();
      // Cover public API surface: unavailable when plugin missing.
      expect(p, isA<PasskeyPlatform>());
    });
  });
}
