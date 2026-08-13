import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auth_response.dart';
import 'passkey_api.dart';
import 'passkey_exceptions.dart';
import 'passkey_models.dart';
import 'passkey_platform.dart';

final passkeyPlatformProvider = Provider<PasskeyPlatform>((ref) {
  return MethodChannelPasskeyPlatform();
});

final passkeyServiceProvider = Provider<PasskeyService>((ref) {
  return PasskeyService(
    api: ref.watch(passkeyApiProvider),
    platform: ref.watch(passkeyPlatformProvider),
  );
});

class PasskeyService {
  PasskeyService({
    required PasskeyApi api,
    required PasskeyPlatform platform,
  })  : _api = api,
        _platform = platform;

  final PasskeyApi _api;
  final PasskeyPlatform _platform;

  Future<PasskeyAvailability> availability() async {
    final supported = await _platform.isAvailable();
    try {
      final flags = await _api.fetchServerFlags();
      return PasskeyAvailability(
        platformSupported: supported,
        loginEnabled: flags.loginEnabled,
        registrationEnabled: flags.registrationEnabled,
        rpId: flags.rpId,
      );
    } catch (_) {
      return PasskeyAvailability(
        platformSupported: supported,
        loginEnabled: true,
        registrationEnabled: true,
        rpId: null,
      );
    }
  }

  /// Full usernameless login → Auth_Wayo Passport session payload.
  Future<AuthResponse> loginWithPasskey() async {
    final opts = await _api.authenticateOptions();
    final credentialJson = await _platform.authenticate(opts.optionsJson);
    final credential = jsonDecode(credentialJson) as Map<String, dynamic>;
    return _api.authenticateVerify(
      challengeId: opts.challengeId,
      credential: credential,
    );
  }

  Future<PasskeyInfo> createPasskey({required String friendlyName}) async {
    final opts = await _api.registerOptions();
    final credentialJson = await _platform.createPasskey(opts.optionsJson);
    final credential = jsonDecode(credentialJson) as Map<String, dynamic>;
    return _api.registerVerify(
      challengeId: opts.challengeId,
      name: friendlyName,
      credential: credential,
      // Informational only — Auth_Wayo never keys uniqueness on provider/platform.
      platform: PasskeyInfo.currentPlatformHint(),
    );
  }

  Future<List<PasskeyInfo>> listPasskeys() => _api.list();

  Future<void> renamePasskey(int id, String name) => _api.rename(id, name);

  Future<void> revokePasskey(int id) => _api.revoke(id);
}

/// Map domain errors to short user-facing copy (i18n applied at call site).
String passkeyErrorCode(Object error) {
  if (error is PasskeyCancelled) return 'cancelled';
  if (error is PasskeyUnavailable) return 'unavailable';
  if (error is PasskeyNotFound) return 'not_found';
  if (error is PasskeyInterrupted) return 'interrupted';
  if (error is PasskeyExpiredChallenge) return 'expired';
  if (error is PasskeyNetworkError) return 'network';
  if (error is PasskeyLastCredential) return 'last_credential';
  if (error is PasskeyLimitReached) return 'limit_reached';
  if (error is PasskeyAlreadyExists) return 'already_exists';
  if (error is PasskeyServerRejected) return 'rejected';
  if (error is PasskeyConfigurationError) return 'configuration';
  return 'unknown';
}
