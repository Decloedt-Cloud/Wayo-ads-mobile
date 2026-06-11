import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/auth/domain/apple_email_policy.dart';

void main() {
  test('detects Apple Hide My Email relay addresses', () {
    expect(
      isAppleHideMyEmailAddress('h267p4rtyh@privaterelay.appleid.com'),
      isTrue,
    );
    expect(
      isAppleHideMyEmailAddress('  User@PrivateRelay.AppleID.com  '),
      isTrue,
    );
    expect(isAppleHideMyEmailAddress('user@icloud.com'), isFalse);
    expect(isAppleHideMyEmailAddress(''), isFalse);
  });
}
