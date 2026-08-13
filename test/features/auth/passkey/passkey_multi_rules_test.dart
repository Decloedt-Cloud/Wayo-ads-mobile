import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_exceptions.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_models.dart';
import 'package:wayoadsgo/features/auth/passkey/passkey_service.dart';

void main() {
  group('PasskeyInfo multi-passkey display', () {
    test('parses friendly metadata without crypto fields', () {
      final info = PasskeyInfo.fromJson({
        'id': '12',
        'friendly_name': 'Mon Samsung',
        'provider': 'google_password_manager',
        'platform': 'android',
        'device_name': 'Galaxy A35',
        'created_at': '2026-08-12T10:00:00+00:00',
        'last_used_at': '2026-08-12T12:00:00+00:00',
      });
      expect(info.id, 12);
      expect(info.displayTitle, 'Mon Samsung');
      expect(info.displaySubtitle, 'Galaxy A35');
      expect(info.providerLabel, 'Google Password Manager');
    });

    test('prefers provider label over default friendly name', () {
      final info = PasskeyInfo.fromJson({
        'id': 1,
        'name': 'Clé d’accès',
        'provider': 'samsung_pass',
        'platform': 'android',
      });
      expect(info.displayTitle, 'Samsung Pass');
    });

    test('supports many credentials in a list shape', () {
      final list = List.generate(
        10,
        (i) => PasskeyInfo.fromJson({
          'id': i + 1,
          'friendly_name': 'Key ${i + 1}',
          'provider': i.isEven
              ? 'google_password_manager'
              : 'icloud_keychain',
        }),
      );
      expect(list, hasLength(10));
      expect(list.where((e) => e.provider == 'google_password_manager'),
          hasLength(5));
    });
  });

  group('passkeyErrorCode', () {
    test('maps multi-passkey management errors', () {
      expect(passkeyErrorCode(const PasskeyCancelled()), 'cancelled');
      expect(passkeyErrorCode(const PasskeyNotFound()), 'not_found');
      expect(passkeyErrorCode(const PasskeyLastCredential()), 'last_credential');
      expect(passkeyErrorCode(const PasskeyLimitReached()), 'limit_reached');
      expect(passkeyErrorCode(const PasskeyServerRejected()), 'rejected');
      expect(passkeyErrorCode(const PasskeyNetworkError()), 'network');
    });
  });
}
