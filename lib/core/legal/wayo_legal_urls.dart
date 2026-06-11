import '../config/auth_runtime_config.dart';
import '../../i18n/strings.g.dart';

/// Legal documents hosted on the Wayo-ads web app (same content as wayo-ads.com).
enum WayoLegalDocument { terms, privacy }

abstract final class WayoLegalUrls {
  static const String _fallbackOrigin = 'https://wayo-ads.com';

  static String get origin {
    final fromConfig = AuthRuntimeConfig.instance.resolvedWayoAdsPublicAssetOrigin;
    if (fromConfig != null && fromConfig.isNotEmpty) {
      return fromConfig;
    }
    return _fallbackOrigin;
  }

  static String pathFor(WayoLegalDocument document, AppLocale locale) {
    final segment = switch (document) {
      WayoLegalDocument.terms => 'terms',
      WayoLegalDocument.privacy => 'privacy',
    };
    if (locale == AppLocale.en) {
      return '/$segment';
    }
    return '/${locale.languageCode}/$segment';
  }

  static Uri uriFor(WayoLegalDocument document, AppLocale locale) {
    return Uri.parse('$origin${pathFor(document, locale)}');
  }
}
