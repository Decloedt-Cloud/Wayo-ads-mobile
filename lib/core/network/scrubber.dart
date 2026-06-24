const String kRedacted = '***REDACTED***';

/// Keys that should be redacted from logs, Sentry reports, and debug output.
///
/// Add any field name that could contain sensitive data. Matching is
/// case-insensitive.
const Set<String> _sensitiveKeysLower = {
  // Auth headers
  'authorization',
  'cookie',
  'set-cookie',
  'x-app-key',
  'x-api-key',

  // Tokens
  'token',
  'access_token',
  'refresh_token',
  'reset_token',
  'id_token',
  'bearer',

  // Push / device identifiers (FCM registration tokens are device secrets)
  'fcm_token',
  'fcmtoken',
  'device_token',
  'push_token',
  'registration_token',

  // Passwords and secrets
  'password',
  'password_confirmation',
  'old_password',
  'new_password',
  'secret',
  'client_secret',
  'api_key',
  'apikey',
  'app_key',
  'private_key',

  // OTP / verification
  'otp',
  'code',
  'verification_code',
  'pin',

  // Personal / financial data
  'email',
  'phone',
  'ssn',
  'card',
  'card_number',
  'cvv',
  'cvc',
  'expiry',
  'account_number',
  'routing_number',
  'iban',
};

bool _isSensitiveKey(String key) =>
    _sensitiveKeysLower.contains(key.toLowerCase().trim());

/// Returns a deep copy with sensitive map keys redacted (case-insensitive).
///
/// Maps and lists are traversed recursively. The original [input] is never modified.
Map<String, dynamic> scrub(dynamic input) {
  if (input is Map) {
    final m = <String, dynamic>{};
    for (final e in input.entries) {
      final k = '${e.key}';
      if (_isSensitiveKey(k)) {
        m[k] = kRedacted;
      } else {
        m[k] = _scrubValue(e.value);
      }
    }
    return m;
  }
  if (input is List) {
    return {'items': _scrubList(input)};
  }
  return {'value': input};
}

dynamic _scrubValue(dynamic value) {
  if (value is Map) {
    final m = <String, dynamic>{};
    for (final e in value.entries) {
      final k = '${e.key}';
      if (_isSensitiveKey(k)) {
        m[k] = kRedacted;
      } else {
        m[k] = _scrubValue(e.value);
      }
    }
    return m;
  }
  if (value is List) {
    return _scrubList(value);
  }
  return value;
}

List<dynamic> _scrubList(List<dynamic> value) =>
    value.map(_scrubValue).toList(growable: false);

/// Converts scrubbed map values to [String] for HTTP header maps.
Map<String, String> scrubToStringHeaders(Map<String, dynamic> headers) {
  return headers.map((k, v) {
    if (v == null) {
      return MapEntry(k, '');
    }
    if (v is String) {
      return MapEntry(k, v);
    }
    return MapEntry(k, v.toString());
  });
}
