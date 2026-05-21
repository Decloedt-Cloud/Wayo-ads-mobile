import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value store for app settings (theme, locale).
/// Use [AppPrefs.shared] when the platform channel works; [AppPrefs.memory] as fallback
/// (e.g. Android Pigeon `channel-error` after hot restart — prefs are not persisted until a full reinstall/cold start).
abstract class AppPrefs {
  const AppPrefs();

  factory AppPrefs.shared(SharedPreferences prefs) = _SharedPreferencesAppPrefs;

  factory AppPrefs.memory() = _MemoryAppPrefs;

  String? getString(String key);

  Future<void> setString(String key, String value);

  int getInt(String key, {int defaultValue = 0});

  Future<void> setInt(String key, int value);
}

final class _SharedPreferencesAppPrefs extends AppPrefs {
  _SharedPreferencesAppPrefs(this._inner) : super();

  final SharedPreferences _inner;

  @override
  String? getString(String key) => _inner.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _inner.setString(key, value);
  }

  @override
  int getInt(String key, {int defaultValue = 0}) =>
      _inner.getInt(key) ?? defaultValue;

  @override
  Future<void> setInt(String key, int value) async {
    await _inner.setInt(key, value);
  }
}

final class _MemoryAppPrefs extends AppPrefs {
  _MemoryAppPrefs() : super();

  final Map<String, String> _m = {};

  @override
  String? getString(String key) => _m[key];

  @override
  Future<void> setString(String key, String value) async {
    _m[key] = value;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    final raw = _m[key];
    if (raw == null) return defaultValue;
    return int.tryParse(raw) ?? defaultValue;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _m[key] = '$value';
  }
}
