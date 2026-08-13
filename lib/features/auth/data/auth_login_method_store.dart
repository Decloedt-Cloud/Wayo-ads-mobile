import 'package:shared_preferences/shared_preferences.dart';

/// Last successful sign-in method on this device (used for account-deletion re-auth UX).
enum AuthLoginMethod {
  email,
  google,
  apple,
  passkey;

  static AuthLoginMethod? tryParse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'email':
        return AuthLoginMethod.email;
      case 'google':
        return AuthLoginMethod.google;
      case 'apple':
        return AuthLoginMethod.apple;
      case 'passkey':
        return AuthLoginMethod.passkey;
      default:
        return null;
    }
  }
}

abstract final class AuthLoginMethodStore {
  static const _key = 'auth.last_login_method';

  static Future<void> save(AuthLoginMethod method) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, method.name);
  }

  static Future<AuthLoginMethod?> read() async {
    final p = await SharedPreferences.getInstance();
    return AuthLoginMethod.tryParse(p.getString(_key));
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
