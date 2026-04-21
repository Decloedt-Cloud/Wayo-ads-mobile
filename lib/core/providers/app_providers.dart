import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../observability/crash_reporter.dart';
import '../storage/app_prefs.dart';
import '../../i18n/strings.g.dart';

/// Initialized in [main] via [ProviderScope] override.
final appPrefsProvider = Provider<AppPrefs>(
  (_) => throw UnimplementedError('Override appPrefsProvider in ProviderScope'),
);

/// Initialized in [main] via [ProviderScope] override.
final crashReporterProvider = Provider<CrashReporter>(
  (_) => throw UnimplementedError('Override crashReporterProvider in ProviderScope'),
);

const _kThemeKey = 'app.theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_readTheme(_prefs));

  final AppPrefs _prefs;

  static ThemeMode _readTheme(AppPrefs p) {
    return switch (p.getString(_kThemeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeKey, mode.name);
  }

  Future<void> toggle() async {
    final next = switch (state) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.system => ThemeMode.dark,
    };
    await set(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(appPrefsProvider));
});

const _kLocaleKey = 'app.locale';

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier(this._prefs) : super(_readLocale(_prefs)) {
    LocaleSettings.setLocaleSync(state);
  }

  final AppPrefs _prefs;

  static AppLocale _readLocale(AppPrefs p) {
    final raw = p.getString(_kLocaleKey);
    if (raw == null) {
      return AppLocaleUtils.findDeviceLocale();
    }
    return AppLocale.values.firstWhere(
      (l) => l.languageCode == raw,
      orElse: () => AppLocale.en,
    );
  }

  Future<void> set(AppLocale locale) async {
    state = locale;
    await LocaleSettings.setLocale(locale);
    await _prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  return LocaleNotifier(ref.watch(appPrefsProvider));
});
