import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_exceptions.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_models.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_platform.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_service.dart';

void main() {
  group('PasskeyAvailability', () {
    test('passkey exists path — can login when supported + enabled', () {
      const a = PasskeyAvailability(
        platformSupported: true,
        loginEnabled: true,
        registrationEnabled: true,
        rpId: 'myaccount.wayo.ac',
      );
      expect(a.canLogin, isTrue);
      expect(a.canRegister, isTrue);
    });

    test('no passkey platform — cannot login', () {
      const a = PasskeyAvailability(
        platformSupported: false,
        loginEnabled: true,
        registrationEnabled: true,
        rpId: null,
      );
      expect(a.canLogin, isFalse);
    });
  });

  group('mapPasskeyPlatformException', () {
    test('NoCredentialException → PasskeyNotFound', () {
      final e = mapPasskeyPlatformException(
        PlatformException(code: 'no_credential'),
      );
      expect(e, isA<PasskeyNotFound>());
    });

    test('user cancellation → PasskeyCancelled', () {
      expect(
        mapPasskeyPlatformException(PlatformException(code: 'cancelled')),
        isA<PasskeyCancelled>(),
      );
    });

    test('interrupted → PasskeyInterrupted', () {
      expect(
        mapPasskeyPlatformException(PlatformException(code: 'interrupted')),
        isA<PasskeyInterrupted>(),
      );
    });

    test('unknown backend-like code → PasskeyUnknownError', () {
      expect(
        mapPasskeyPlatformException(PlatformException(code: 'DOM_ERROR')),
        isA<PasskeyUnknownError>(),
      );
    });
  });

  group('passkeyErrorCode', () {
    test('maps domain errors for analytics', () {
      expect(passkeyErrorCode(const PasskeyNotFound()), 'not_found');
      expect(passkeyErrorCode(const PasskeyCancelled()), 'cancelled');
      expect(passkeyErrorCode(const PasskeyInterrupted()), 'interrupted');
      expect(passkeyErrorCode(const PasskeyServerRejected()), 'rejected');
    });
  });

  group('PasskeyAuthOptions', () {
    test('parses registration/auth options payload', () {
      final opts = PasskeyAuthOptions.fromData({
        'challenge_id': '11111111-1111-4111-8111-111111111111',
        'options': {'challenge': 'abc', 'rpId': 'myaccount.wayo.ac'},
      });
      expect(opts.challengeId, startsWith('1111'));
      expect(opts.optionsJson, contains('challenge'));
    });
  });
}
