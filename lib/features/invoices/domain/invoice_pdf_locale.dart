import '../../../i18n/strings.g.dart';

/// Wayo-ads invoice PDFs support French and English only.
/// Arabic app UI uses English invoices (same rule as the web app).
String invoicePdfLocaleForApp([AppLocale? locale]) {
  switch (locale ?? LocaleSettings.currentLocale) {
    case AppLocale.fr:
      return 'fr';
    case AppLocale.en:
    case AppLocale.ar:
      return 'en';
  }
}
