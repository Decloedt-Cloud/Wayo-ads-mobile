import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for a human-readable card label after a successful Payment Sheet
/// (e.g. "Visa ···· 4242") when the user opts in to "save card".
///
/// [FlutterSecureStorage] is preferred; if it fails (some Android devices), we
/// fall back to [SharedPreferences] (less private but still app-scoped).
///
/// Server may expose the same in [GET /api/wallet]; the UI prefers server
/// [AdvertiserWalletPageData.savedCardHint] over this.
final class WalletSavedCardLocal {
  WalletSavedCardLocal._();

  static const _secureKey = 'advertiser_wallet_saved_card_label';
  static const _prefsKey = 'advertiser_wallet_saved_card_label_v1';

  static final FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<String?> read() async {
    try {
      final s = await _secure.read(key: _secureKey);
      if (s != null && s.isNotEmpty) {
        return s;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WalletSavedCardLocal] secure read: $e');
      }
    }
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString(_prefsKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WalletSavedCardLocal] prefs read: $e');
      }
      return null;
    }
  }

  static Future<void> write(String displayLabel) async {
    try {
      await _secure.write(key: _secureKey, value: displayLabel);
      try {
        final p = await SharedPreferences.getInstance();
        await p.setString(_prefsKey, displayLabel);
      } catch (_) {
        // Primary path succeeded.
      }
      return;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WalletSavedCardLocal] secure write, trying prefs: $e');
      }
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, displayLabel);
  }

  static Future<void> clear() async {
    try {
      await _secure.delete(key: _secureKey);
    } catch (_) {}
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_prefsKey);
    } catch (_) {}
  }
}
