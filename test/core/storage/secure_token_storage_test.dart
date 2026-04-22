import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/storage/secure_token_storage.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('save / read cycle', () async {
    final storage = SecureTokenStorage();
    final at = DateTime.utc(2030, 1, 1);
    await storage.save(access: 'a1', refresh: 'r1', expiresAt: at);
    expect(await storage.readAccess(), 'a1');
    expect(await storage.readRefresh(), 'r1');
    expect(await storage.readExpiry(), at);
  });

  test('clear removes keys', () async {
    final storage = SecureTokenStorage();
    await storage.save(
      access: 'a',
      refresh: 'r',
      expiresAt: DateTime.utc(2028),
    );
    await storage.clear();
    expect(await storage.readAccess(), isNull);
    expect(await storage.readRefresh(), isNull);
    expect(await storage.readExpiry(), isNull);
  });

  test('readAccess and readExpiry return null when absent', () async {
    final storage = SecureTokenStorage();
    expect(await storage.readAccess(), isNull);
    expect(await storage.readExpiry(), isNull);
  });
}
