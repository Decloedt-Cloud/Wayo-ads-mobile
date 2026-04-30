import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local JSON cache with TTL for dashboard SWR (Hive).
///
/// **SECURITY:** The box is encrypted with AES-256. The encryption key is
/// generated once and stored in [FlutterSecureStorage] (Keychain on iOS,
/// EncryptedSharedPreferences on Android).
abstract final class DashboardHiveStore {
  static const _ttl = Duration(minutes: 5);
  static const _boxName = 'wayo_dashboard_encrypted';
  static const _keyStorageKey = 'wayo.hive_encryption_key';
  static Box<String>? _box;

  /// Retrieves or generates a 256-bit AES key for Hive encryption.
  static Future<Uint8List> _getOrCreateEncryptionKey() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );

    final existing = await storage.read(key: _keyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      final bytes = base64Decode(existing);
      if (bytes.length == 32) {
        return Uint8List.fromList(bytes);
      }
    }

    // Generate a new 256-bit key
    final newKey = Hive.generateSecureKey();
    await storage.write(key: _keyStorageKey, value: base64Encode(newKey));
    return Uint8List.fromList(newKey);
  }

  static Future<void> init() async {
    if (_box != null) return;
    final key = await _getOrCreateEncryptionKey();
    _box = await Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );
  }

  static String? readFresh(String key) {
    final b = _box;
    if (b == null) {
      return null;
    }
    final raw = b.get(key);
    if (raw == null) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse(map['at'] as String? ?? '');
      if (at == null || DateTime.now().difference(at) > _ttl) {
        return null;
      }
      return map['payload'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, String payloadJson) async {
    final b = _box;
    if (b == null) {
      return;
    }
    final envelope = jsonEncode({
      'at': DateTime.now().toIso8601String(),
      'payload': payloadJson,
    });
    await b.put(key, envelope);
  }

  /// Clears all dashboard SWR entries (e.g. after login / logout / account switch).
  static Future<void> clearAll() async {
    final b = _box;
    if (b == null) {
      return;
    }
    await b.clear();
  }
}
