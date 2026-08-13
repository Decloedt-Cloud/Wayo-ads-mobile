import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class PasskeyAvailability {
  const PasskeyAvailability({
    required this.platformSupported,
    required this.loginEnabled,
    required this.registrationEnabled,
    required this.rpId,
  });

  final bool platformSupported;
  final bool loginEnabled;
  final bool registrationEnabled;
  final String? rpId;

  bool get canLogin => platformSupported && loginEnabled;
  bool get canRegister => platformSupported && registrationEnabled;
}

class PasskeyAuthOptions {
  const PasskeyAuthOptions({
    required this.challengeId,
    required this.optionsJson,
  });

  final String challengeId;
  final String optionsJson;

  factory PasskeyAuthOptions.fromData(Map<String, dynamic> data) {
    final options = data['options'];
    return PasskeyAuthOptions(
      challengeId: data['challenge_id'] as String,
      optionsJson: options is String ? options : jsonEncode(options),
    );
  }
}

class PasskeyCredentialJson {
  const PasskeyCredentialJson(this.json);
  final String json;

  Map<String, dynamic> asMap() =>
      jsonDecode(json) as Map<String, dynamic>;
}

/// Server-side passkey metadata for management UI (no crypto material).
class PasskeyInfo {
  const PasskeyInfo({
    required this.id,
    required this.name,
    this.provider,
    this.platform,
    this.deviceName,
    this.authenticator,
    this.createdAt,
    this.lastUsedAt,
  });

  final int id;

  /// Friendly name (user-editable Wayo metadata).
  final String name;
  final String? provider;
  final String? platform;
  final String? deviceName;
  final String? authenticator;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;

  String get friendlyName => name;

  /// Prefer user rename; else provider / authenticator label; never claim "device-only".
  String get displayTitle {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_isDefaultName(trimmed)) {
      return trimmed;
    }
    return providerLabel ??
        (authenticator?.trim().isNotEmpty == true ? authenticator!.trim() : null) ??
        (trimmed.isNotEmpty ? trimmed : 'Passkey');
  }

  String? get displaySubtitle {
    final device = deviceName?.trim();
    if (device != null &&
        device.isNotEmpty &&
        device.toLowerCase() != displayTitle.toLowerCase()) {
      return device;
    }
    return null;
  }

  String? get providerLabel {
    switch (provider) {
      case 'google_password_manager':
        return 'Google Password Manager';
      case 'samsung_pass':
        return 'Samsung Pass';
      case 'icloud_keychain':
        return 'iCloud Keychain';
      case 'windows_hello':
        return 'Windows Hello';
      case 'hardware_security_key':
        return 'Security key';
      case 'unknown':
      case null:
      case '':
        return null;
      default:
        return provider;
    }
  }

  static bool _isDefaultName(String value) {
    final v = value.toLowerCase();
    return v == 'passkey' ||
        v == 'clé d’accès' ||
        v == "clé d'accès" ||
        v == 'cle d’accès' ||
        v == "cle d'acces";
  }

  /// Client platform hint for registration metadata (informational).
  static String currentPlatformHint() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
    } catch (_) {}
    return 'unknown';
  }

  factory PasskeyInfo.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : rawId is num
            ? rawId.toInt()
            : int.tryParse('$rawId') ?? 0;
    final friendly = json['friendly_name'] as String? ??
        json['name'] as String? ??
        'Passkey';
    return PasskeyInfo(
      id: id,
      name: friendly,
      provider: json['provider'] as String?,
      platform: json['platform'] as String?,
      deviceName: json['device_name'] as String?,
      authenticator: json['authenticator'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      lastUsedAt: DateTime.tryParse(json['last_used_at'] as String? ?? ''),
    );
  }
}
