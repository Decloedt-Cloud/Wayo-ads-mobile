import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/storage/app_prefs.dart';
import '../../domain/app_settings_panel_design.dart';

const _kPanelDesignKey = 'app.settings_panel_design';

final appSettingsPanelDesignProvider =
    StateNotifierProvider<AppSettingsPanelDesignNotifier, AppSettingsPanelDesign>((ref) {
  return AppSettingsPanelDesignNotifier(ref.watch(appPrefsProvider));
});

class AppSettingsPanelDesignNotifier extends StateNotifier<AppSettingsPanelDesign> {
  AppSettingsPanelDesignNotifier(this._prefs) : super(_read(_prefs));

  final AppPrefs _prefs;

  static AppSettingsPanelDesign _read(AppPrefs p) {
    return AppSettingsPanelDesignStorage.fromStorage(p.getString(_kPanelDesignKey));
  }

  Future<void> setDesign(AppSettingsPanelDesign design) async {
    state = design;
    await _prefs.setString(_kPanelDesignKey, design.storageValue);
  }
}
