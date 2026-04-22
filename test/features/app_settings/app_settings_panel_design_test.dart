import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/app_settings/domain/app_settings_panel_design.dart';

void main() {
  group('AppSettingsPanelDesignStorage', () {
    test('fromStorage maps persisted values', () {
      expect(
        AppSettingsPanelDesignStorage.fromStorage(
          AppSettingsPanelDesignStorage.storageValueCorporate,
        ),
        AppSettingsPanelDesign.minimalCorporate,
      );
      expect(
        AppSettingsPanelDesignStorage.fromStorage(null),
        AppSettingsPanelDesign.glassLuxury,
      );
      expect(
        AppSettingsPanelDesignStorage.fromStorage(''),
        AppSettingsPanelDesign.glassLuxury,
      );
      expect(
        AppSettingsPanelDesignStorage.fromStorage('unknown'),
        AppSettingsPanelDesign.glassLuxury,
      );
    });

    test('storageValue round-trips', () {
      expect(
        AppSettingsPanelDesignStorage.fromStorage(
          AppSettingsPanelDesign.glassLuxury.storageValue,
        ),
        AppSettingsPanelDesign.glassLuxury,
      );
      expect(
        AppSettingsPanelDesignStorage.fromStorage(
          AppSettingsPanelDesign.minimalCorporate.storageValue,
        ),
        AppSettingsPanelDesign.minimalCorporate,
      );
    });
  });
}
