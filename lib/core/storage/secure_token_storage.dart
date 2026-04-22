import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hardened secure storage for OAuth tokens (no iCloud sync, strong Android ciphers).
final class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? _defaultStorage;

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  static const _kAccess = 'wayo.access_token';
  static const _kRefresh = 'wayo.refresh_token';
  static const _kExpiry = 'wayo.expires_at';

  final FlutterSecureStorage _storage;

  /// Persists access, refresh, and absolute expiry.
  ///
  /// Writes are sequential (not parallel) to avoid Android encrypted-storage
  /// race conditions where concurrent `FlutterSecureStorage.write` calls can
  /// silently drop values on some OEM ROMs.
  Future<void> save({
    required String access,
    required String refresh,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
    await _storage.write(key: _kExpiry, value: expiresAt.toIso8601String());
  }

  Future<String?> readAccess() => _storage.read(key: _kAccess);

  Future<String?> readRefresh() => _storage.read(key: _kRefresh);

  Future<DateTime?> readExpiry() async {
    final raw = await _storage.read(key: _kExpiry);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> clear() => _storage.deleteAll();

  static const _kUserJson = 'wayo.auth_user_json';

  Future<void> writeUserJson(String json) =>
      _storage.write(key: _kUserJson, value: json);

  Future<String?> readUserJson() => _storage.read(key: _kUserJson);
}
