/// Visual treatment for the settings side panel (user-selectable, persisted).
enum AppSettingsPanelDesign {
  /// Frosted layers, soft gradients, luminous accents — “luxury consumer” feel.
  glassLuxury,

  /// Flat surfaces, crisp borders, neutral typography — “B2B / fintech” feel.
  minimalCorporate,
}

extension AppSettingsPanelDesignStorage on AppSettingsPanelDesign {
  static const storageValueGlass = 'glass';
  static const storageValueCorporate = 'corporate';

  String get storageValue => switch (this) {
    AppSettingsPanelDesign.glassLuxury => storageValueGlass,
    AppSettingsPanelDesign.minimalCorporate => storageValueCorporate,
  };

  static AppSettingsPanelDesign fromStorage(String? raw) => switch (raw) {
    storageValueCorporate => AppSettingsPanelDesign.minimalCorporate,
    _ => AppSettingsPanelDesign.glassLuxury,
  };
}
