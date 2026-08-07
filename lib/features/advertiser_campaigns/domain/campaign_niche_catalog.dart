/// Same values as Wayo-ads `src/lib/campaign-niches.ts` / Prisma `CampaignNiche`.
///
/// Keep synced when the web catalog changes.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

const List<String> kCampaignNicheApiValues = [
  'FASHION_APPAREL',
  'BEAUTY_PERSONAL_CARE',
  'TECH_SOFTWARE_ELECTRONICS',
  'FOOD_BEVERAGE',
  'HEALTH_WELLNESS',
  'FITNESS_SPORTS',
  'HOME_LIVING',
  'TRAVEL_HOSPITALITY',
  'FINANCE_INSURANCE',
  'EDUCATION_LEARNING',
  'ENTERTAINMENT_MEDIA',
  'GAMING_ESPORTS',
  'AUTOMOTIVE',
  'PETS_ANIMALS',
  'BABY_FAMILY',
  'B2B_PROFESSIONAL',
  'ECOMMERCE_RETAIL',
  'NONPROFIT_CAUSE',
  'REAL_ESTATE',
  'CRYPTO_WEB3',
  'ART_DESIGN_PHOTOGRAPHY',
  'MUSIC_AUDIO',
  'LIFESTYLE_VLOGS',
  'DIY_CRAFTS',
  'ENVIRONMENT_SUSTAINABILITY',
  'OTHER',
];

/// Human-readable niche label for pickers (API value stays SCREAMING_SNAKE).
String campaignNicheDisplayLabel(String apiValue) {
  switch (apiValue) {
    case 'FASHION_APPAREL':
      return 'Fashion & Apparel';
    case 'BEAUTY_PERSONAL_CARE':
      return 'Beauty & Personal Care';
    case 'TECH_SOFTWARE_ELECTRONICS':
      return 'Tech, Software & Electronics';
    case 'FOOD_BEVERAGE':
      return 'Food & Beverage';
    case 'HEALTH_WELLNESS':
      return 'Health & Wellness';
    case 'FITNESS_SPORTS':
      return 'Fitness & Sports';
    case 'HOME_LIVING':
      return 'Home & Living';
    case 'TRAVEL_HOSPITALITY':
      return 'Travel & Hospitality';
    case 'FINANCE_INSURANCE':
      return 'Finance & Insurance';
    case 'EDUCATION_LEARNING':
      return 'Education & Learning';
    case 'ENTERTAINMENT_MEDIA':
      return 'Entertainment & Media';
    case 'GAMING_ESPORTS':
      return 'Gaming & Esports';
    case 'AUTOMOTIVE':
      return 'Automotive';
    case 'PETS_ANIMALS':
      return 'Pets & Animals';
    case 'BABY_FAMILY':
      return 'Baby & Family';
    case 'B2B_PROFESSIONAL':
      return 'B2B & Professional';
    case 'ECOMMERCE_RETAIL':
      return 'Ecommerce & Retail';
    case 'NONPROFIT_CAUSE':
      return 'Nonprofit & Cause';
    case 'REAL_ESTATE':
      return 'Real Estate';
    case 'CRYPTO_WEB3':
      return 'Crypto & Web3';
    case 'ART_DESIGN_PHOTOGRAPHY':
      return 'Art, Design & Photography';
    case 'MUSIC_AUDIO':
      return 'Music & Audio';
    case 'LIFESTYLE_VLOGS':
      return 'Lifestyle & Vlogs';
    case 'DIY_CRAFTS':
      return 'DIY & Crafts';
    case 'ENVIRONMENT_SUSTAINABILITY':
      return 'Environment & Sustainability';
    case 'OTHER':
      return 'Other';
    default:
      return apiValue.replaceAll('_', ' ');
  }
}

/// Canonical form for API niche enum strings (e.g. `TRAVEL_HOSPITALITY`).
String? normalizeCampaignNicheApiValue(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;
  return s.toUpperCase();
}

/// Trimmed location/geo label for comparisons (null when empty).
String? normalizeCampaignLocationValue(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;
  return s;
}

String? _locationScalarFromJson(dynamic v) =>
    normalizeCampaignLocationValue(_trimmedStringFromJson(v));

String? _trimmedStringFromJson(dynamic v) {
  if (v == null) return null;
  if (v is String) {
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
  if (v is num || v is bool) {
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
  return null;
}

Map<String, dynamic>? _objectMapFromJsonValue(dynamic v) {
  if (v is Map) {
    return Map<String, dynamic>.from(v);
  }
  if (v is String) {
    final t = v.trim();
    if (t.length >= 2 && t.startsWith('{')) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
  }
  return null;
}

bool _jsonTruthy(dynamic v) {
  if (v == true || v == 1) return true;
  if (v is String) {
    final s = v.toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

const int _kLocationMissLogCap = 40;
int _locationMissLogsPrinted = 0;

void _debugLogLocationMiss(Map<String, dynamic> m, String? debugSource) {
  if (!kDebugMode) return;
  if (_locationMissLogsPrinted > _kLocationMissLogCap) {
    return;
  }
  if (_locationMissLogsPrinted == _kLocationMissLogCap) {
    debugPrint(
      '[WayoAds][campaignLocation] further UNRESOLVED logs suppressed '
      '(cap $_kLocationMissLogCap). Hot restart resets.',
    );
    _locationMissLogsPrinted++;
    return;
  }
  _locationMissLogsPrinted++;
  final id = m['id']?.toString() ?? '?';
  final titleRaw = (m['title'] ?? m['name'])?.toString();
  String? titleShort;
  if (titleRaw == null || titleRaw.isEmpty) {
    titleShort = null;
  } else if (titleRaw.length > 36) {
    titleShort = '${titleRaw.substring(0, 36)}…';
  } else {
    titleShort = titleRaw;
  }

  final allKeys = m.keys.map((k) => k.toString()).toList()..sort();
  final hints = allKeys.where((k) {
    final s = k.toLowerCase();
    return s.contains('loc') ||
        s.contains('geo') ||
        s.contains('country') ||
        s.contains('target') ||
        s.contains('region') ||
        s.contains('global') ||
        s.contains('audience') ||
        s.contains('place') ||
        s.contains('market') ||
        s.contains('territory');
  }).toList();

  debugPrint(
    '[WayoAds][campaignLocation] UNRESOLVED '
    'source=${debugSource ?? '?'} id=$id '
    'title=${titleShort ?? '—'}',
  );
  debugPrint('[WayoAds][campaignLocation]   hint-like keys: $hints');
  if (allKeys.length > 60) {
    debugPrint(
      '[WayoAds][campaignLocation]   all keys (first 60/${allKeys.length}): '
      '${allKeys.take(60).toList()}',
    );
  } else {
    debugPrint(
      '[WayoAds][campaignLocation]   all keys (${allKeys.length}): $allKeys',
    );
  }
  for (final root in const [
    'targeting',
    'finance',
    'metadata',
    'audience',
    'geoTargeting',
    'geo_targeting',
  ]) {
    final raw = m[root];
    final inner = _objectMapFromJsonValue(raw);
    if (inner != null && inner.isNotEmpty) {
      final sub = inner.keys.map((k) => k.toString()).toList()..sort();
      debugPrint('[WayoAds][campaignLocation]   nested.$root keys: $sub');
    } else if (raw != null) {
      debugPrint(
        '[WayoAds][campaignLocation]   $root: ${raw.runtimeType} '
        '(non-map / empty after decode)',
      );
    }
  }
}

/// Wayo-ads campaign JSON uses geo fields at the root: [targetCity],
/// [targetCountryCode], [isGeoTargeted], [targetLatitude], [targetRadiusKm].
String? _locationFromWayoAdsGeoFields(Map<String, dynamic> map) {
  final city = _trimmedStringFromJson(map['targetCity']);
  final countryCode = _trimmedStringFromJson(map['targetCountryCode']);
  final geo = map['isGeoTargeted'];
  final explicitlyNotGeo =
      geo == false ||
      geo == 0 ||
      (geo is String &&
          const {'false', '0', 'no'}.contains(geo.toLowerCase().trim()));

  if (explicitlyNotGeo) {
    if ((city != null && city.isNotEmpty) ||
        (countryCode != null && countryCode.isNotEmpty)) {
      if (city != null &&
          city.isNotEmpty &&
          countryCode != null &&
          countryCode.isNotEmpty) {
        return normalizeCampaignLocationValue('$city, $countryCode');
      }
      if (city != null && city.isNotEmpty) {
        return normalizeCampaignLocationValue(city);
      }
      return normalizeCampaignLocationValue(countryCode);
    }
    return 'Global';
  }

  if (city != null &&
      city.isNotEmpty &&
      countryCode != null &&
      countryCode.isNotEmpty) {
    return normalizeCampaignLocationValue('$city, $countryCode');
  }
  if (city != null && city.isNotEmpty) {
    return normalizeCampaignLocationValue(city);
  }
  if (countryCode != null && countryCode.isNotEmpty) {
    return normalizeCampaignLocationValue(countryCode);
  }

  final lat = map['targetLatitude'];
  final lon = map['targetLongitude'];
  if (lat != null && lon != null) {
    final radius = _trimmedStringFromJson(map['targetRadiusKm']);
    if (radius != null && radius.isNotEmpty) {
      return normalizeCampaignLocationValue('≈$radius km radius');
    }
  }

  return null;
}

String? _locationFromStringListJson(dynamic list) {
  if (list is! List) return null;
  final parts = <String>[];
  for (final e in list) {
    if (e is Map) {
      final om = Map<String, dynamic>.from(e);
      final nested = _locationScalarFromJson(
        om['label'] ??
            om['name'] ??
            om['displayName'] ??
            om['display_name'] ??
            om['title'] ??
            om['country'] ??
            om['countryName'] ??
            om['country_name'] ??
            om['countryCode'] ??
            om['country_code'] ??
            om['code'] ??
            om['region'] ??
            om['iso2'] ??
            om['isoCode'] ??
            om['iso_code'],
      );
      if (nested != null) parts.add(nested);
    } else {
      final s = _locationScalarFromJson(e);
      if (s != null) parts.add(s);
    }
  }
  if (parts.isEmpty) return null;
  return normalizeCampaignLocationValue(parts.join(', '));
}

/// Geo / location label from any campaign-shaped JSON (list row or `GET :id`).
///
/// Tries many keys used across Wayo-ads / ad stacks and shallow nested maps
/// (`targeting`, `audience`, …) so list, detail, and filters stay aligned.
///
/// In **debug mode only**, if no location is found, prints `[WayoAds][campaignLocation]`
/// lines to the **Flutter** tool output (visible in a debug session: `flutter run`,
/// VS Code / Android Studio **Debug Console** — not a plain `dart` script terminal).
String? campaignLocationFromCampaignJson(
  Map<String, dynamic> m, {
  String? debugSource,
}) {
  final result = _resolveCampaignLocationFromJson(m);
  if (result == null && kDebugMode) {
    _debugLogLocationMiss(m, debugSource);
  }
  return result;
}

String? _resolveCampaignLocationFromJson(Map<String, dynamic> m) {
  const scalarKeys = [
    'targetLocation',
    'target_location',
    'targetLocationLabel',
    'target_location_label',
    'locationLabel',
    'location_label',
    'location',
    'geo',
    'geoLabel',
    'geo_label',
    'targetRegion',
    'target_region',
    'region',
    'targetCountry',
    'target_country',
    'audienceCountry',
    'audience_country',
    'audienceLocation',
    'audience_location',
    'geographicLocation',
    'geographic_location',
    'country',
    'countryName',
    'country_name',
    'countryCode',
    'country_code',
    'market',
    'territory',
    'city',
    'locale',
    'primaryCountry',
    'primary_country',
    'globalRegion',
    'global_region',
  ];

  const listKeys = [
    'targetLocations',
    'target_locations',
    'targetCountries',
    'target_countries',
    'regions',
    'countries',
    'countryCodes',
    'country_codes',
    'audienceCountries',
    'audience_countries',
  ];

  const nestedRoots = [
    'targeting',
    'geoTargeting',
    'geo_targeting',
    'audience',
    'locationTargeting',
    'location_targeting',
    'campaignTargeting',
    'campaign_targeting',
    'metadata',
    'settings',
    'delivery',
    'placement',
    'include',
  ];

  String? tryMap(Map<String, dynamic> map) {
    final wayoGeo = _locationFromWayoAdsGeoFields(map);
    if (wayoGeo != null) return wayoGeo;

    if (_jsonTruthy(map['global']) ||
        _jsonTruthy(map['worldwide']) ||
        _jsonTruthy(map['targetGlobal']) ||
        _jsonTruthy(map['target_global']) ||
        _jsonTruthy(map['globalTargeting']) ||
        _jsonTruthy(map['global_targeting'])) {
      return 'Global';
    }
    for (final key in listKeys) {
      final fromList = _locationFromStringListJson(map[key]);
      if (fromList != null) return fromList;
    }
    for (final key in scalarKeys) {
      final s = _locationScalarFromJson(map[key]);
      if (s != null) return s;
    }
    for (final objKey in ['location', 'geo', 'region', 'targetLocation']) {
      final o = map[objKey];
      if (o is Map) {
        final om = Map<String, dynamic>.from(o);
        for (final k in [
          'label',
          'name',
          'displayName',
          'display_name',
          'title',
          'country',
          'countryName',
          'country_name',
          'code',
        ]) {
          final s = _locationScalarFromJson(om[k]);
          if (s != null) return s;
        }
      }
    }
    for (final lk in ['locations', 'regions', 'countries']) {
      final fromList = _locationFromStringListJson(map[lk]);
      if (fromList != null) return fromList;
    }
    return null;
  }

  final direct = tryMap(m);
  if (direct != null) return direct;

  for (final root in nestedRoots) {
    final inner = _objectMapFromJsonValue(m[root]);
    if (inner != null) {
      final nested = tryMap(inner);
      if (nested != null) return nested;
    }
  }

  return null;
}

/// Fallback label when no dedicated i18n exists (readable English-style title).
String campaignNicheFallbackLabel(String apiValue) {
  final canon = normalizeCampaignNicheApiValue(apiValue);
  if (canon == null || canon.isEmpty) return '—';
  return canon
      .split('_')
      .where((s) => s.isNotEmpty)
      .map(
        (w) => w.length == 1
            ? w.toUpperCase()
            : '${w[0]}${w.substring(1).toLowerCase()}',
      )
      .join(' ');
}
