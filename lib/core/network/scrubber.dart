const String kRedacted = '***REDACTED***';

const Set<String> _sensitiveKeysLower = {
  'authorization',
  'cookie',
  'set-cookie',
  'password',
  'password_confirmation',
  'access_token',
  'refresh_token',
  'reset_token',
  'otp',
  'token',
  'secret',
  'x-app-key',
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
