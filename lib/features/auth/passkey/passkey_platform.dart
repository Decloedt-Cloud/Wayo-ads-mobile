import 'package:flutter/services.dart';

import 'passkey_exceptions.dart';

/// Native Credential Manager / AuthenticationServices bridge.
/// Private keys never enter Dart — only WebAuthn JSON in/out.
abstract interface class PasskeyPlatform {
  Future<bool> isAvailable();

  Future<String> createPasskey(String creationOptionsJson);

  Future<String> authenticate(String requestOptionsJson);
}

class MethodChannelPasskeyPlatform implements PasskeyPlatform {
  MethodChannelPasskeyPlatform({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('wayo/passkeys');

  final MethodChannel _channel;

  @override
  Future<bool> isAvailable() async {
    try {
      final v = await _channel.invokeMethod<bool>('isAvailable');
      return v ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String> createPasskey(String creationOptionsJson) =>
      _invokeCredential('create', creationOptionsJson);

  @override
  Future<String> authenticate(String requestOptionsJson) =>
      _invokeCredential('authenticate', requestOptionsJson);

  Future<String> _invokeCredential(String method, String optionsJson) async {
    try {
      final result = await _channel.invokeMethod<String>(method, {
        'requestJson': optionsJson,
      });
      if (result == null || result.isEmpty) {
        throw const PasskeyUnknownError('Empty credential response');
      }
      return result;
    } on MissingPluginException {
      throw const PasskeyUnavailable();
    } on PlatformException catch (e) {
      throw mapPasskeyPlatformException(e);
    }
  }
}

/// Visible for tests — maps native Credential Manager codes to domain errors.
PasskeyException mapPasskeyPlatformException(PlatformException e) {
  switch (e.code) {
    case 'cancelled':
    case 'CANCELED':
    case 'USER_CANCELED':
      return const PasskeyCancelled();
    case 'unavailable':
    case 'UNSUPPORTED':
      return PasskeyUnavailable(e.message);
    case 'no_credential':
    case 'NO_CREDENTIAL':
      return const PasskeyNotFound();
    case 'already_exists':
    case 'ALREADY_EXISTS':
    case 'DUPLICATE':
      return PasskeyAlreadyExists(e.message);
    case 'interrupted':
    case 'INTERRUPTED':
      return PasskeyInterrupted(e.message);
    case 'configuration':
      return PasskeyConfigurationError(e.message);
    default:
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('no credential') || msg.contains('nocredential')) {
        return const PasskeyNotFound();
      }
      if (msg.contains('already') ||
          msg.contains('déjà') ||
          msg.contains('dejà') ||
          msg.contains('exist')) {
        return PasskeyAlreadyExists(e.message);
      }
      if (msg.contains('cancel')) {
        return const PasskeyCancelled();
      }
      if (msg.contains('interrupt')) {
        return PasskeyInterrupted(e.message);
      }
      return PasskeyUnknownError(e.code);
  }
}
