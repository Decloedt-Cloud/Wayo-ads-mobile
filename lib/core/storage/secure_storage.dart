import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'secure_token_storage.dart';

part 'secure_storage.g.dart';

@Riverpod(keepAlive: true)
SecureStorageService secureStorage(SecureStorageRef ref) {
  return SecureStorageService(SecureTokenStorage());
}

/// Typed wrapper around [SecureTokenStorage] for auth tokens and cached user.
///
/// **SECURITY NOTE — In-memory token caching:**
/// Access and refresh tokens are cached in [_cachedAccessToken] and
/// [_cachedRefreshToken] after the first read to avoid repeated secure-storage
/// I/O. This is a deliberate performance trade-off.
///
/// **Risk:** On a rooted/jailbroken device, an attacker with memory-dump
/// capabilities could extract these tokens from the process heap.
///
/// **Mitigations:**
/// - Tokens are short-lived (access ~15 min, refresh ~7 days server-side).
/// - [clearAll] wipes both cache and persistent storage on logout.
/// - The underlying [SecureTokenStorage] uses OS-level encryption at rest.
///
/// If your threat model includes sophisticated local attackers, consider
/// re-reading from secure storage on each call (slower) or using hardware-
/// backed attestation (e.g., Android StrongBox / iOS Secure Enclave).
class SecureStorageService {
  SecureStorageService(this._tokens);

  final SecureTokenStorage _tokens;

  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await _tokens.save(
      access: accessToken,
      refresh: refreshToken,
      expiresAt: expiresAt,
    );
  }

  Future<void> saveUserJson(String json) async {
    await _tokens.writeUserJson(json);
  }

  Future<String?> getUserJson() => _tokens.readUserJson();

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    final val = await _tokens.readAccess();
    _cachedAccessToken = val;
    return val;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    final val = await _tokens.readRefresh();
    _cachedRefreshToken = val;
    return val;
  }

  /// Uses stored [expires_at] ISO8601; treats missing expiry as expired.
  Future<bool> isTokenExpired() async {
    final at = await _tokens.readExpiry();
    if (at == null) {
      return true;
    }
    return !at.isAfter(DateTime.now());
  }

  Future<void> clearAll() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await _tokens.clear();
  }

  /// Persists [user] as JSON alongside tokens (already saved separately).
  Future<void> saveAuthSession({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required Map<String, dynamic> userJson,
  }) async {
    await saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
    await saveUserJson(jsonEncode(userJson));
  }
}
