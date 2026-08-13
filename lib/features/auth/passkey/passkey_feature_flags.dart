/// Staged rollout flags for passkeys.
///
/// Prefer Auth_Wayo `passkeys/available` (`login_enabled` / `registration_enabled`)
/// for environment control. Compile-time dart-defines allow killing the client UI
/// without a store release. Safe defaults keep auth available if flags are unset.
abstract final class PasskeyFeatureFlags {
  static const loginKey = 'passkeyLoginEnabled';
  static const registrationKey = 'passkeyRegistrationEnabled';

  static const bool _loginCompile =
      bool.fromEnvironment('PASSKEY_LOGIN_ENABLED', defaultValue: true);
  static const bool _registrationCompile =
      bool.fromEnvironment('PASSKEY_REGISTRATION_ENABLED', defaultValue: true);

  static Future<({bool login, bool registration})> resolve() async {
    return (login: _loginCompile, registration: _registrationCompile);
  }
}
