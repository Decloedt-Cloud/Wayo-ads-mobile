import '../config/auth_runtime_config.dart';

/// Parses `brandLogoUrl` from Wayo-ads payloads (camelCase or snake_case).
String? parseCampaignBrandLogoFromJson(Map<String, dynamic> m) {
  for (final k in <String>['brandLogoUrl', 'brand_logo_url']) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) {
      return v.trim();
    }
  }
  return null;
}

/// Builds an absolute URL for images served from Wayo-ads `/uploads/...`.
///
/// Prefer [AuthRuntimeConfig.resolvedWayoAdsPublicAssetOrigin] — never Laravel-only.
/// If absent, falls back to [AuthRuntimeConfig.resolvedWayoAdsBaseUrl] (legacy setups).
String? resolveWayoAdsPublicUrl(String? urlOrPath) {
  if (urlOrPath == null) {
    return null;
  }
  final raw = urlOrPath.trim();
  if (raw.isEmpty) {
    return null;
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }

  var origin = AuthRuntimeConfig.instance.resolvedWayoAdsPublicAssetOrigin;
  if (origin == null || origin.trim().isEmpty) {
    final fb = AuthRuntimeConfig.instance.resolvedWayoAdsBaseUrl.replaceAll(
      RegExp(r'/+$'),
      '',
    );
    if (fb.isEmpty) {
      return null;
    }
    origin = fb.endsWith('/api') ? fb.substring(0, fb.length - 4) : fb;
  }

  final trimmed = origin.replaceAll(RegExp(r'/+$'), '');
  if (raw.startsWith('/')) {
    return '$trimmed$raw';
  }
  return '$trimmed/$raw';
}

/// Use for covers, logos: absolute URLs unchanged; relatives resolved on Wayo-ads.
String? normalizeWayoAdsMediaUrl(String? urlOrPath) {
  if (urlOrPath == null) {
    return null;
  }
  final raw = urlOrPath.trim();
  if (raw.isEmpty) {
    return null;
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  return resolveWayoAdsPublicUrl(raw);
}
