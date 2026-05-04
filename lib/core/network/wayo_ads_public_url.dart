import 'package:flutter/foundation.dart';

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

/// Cover / thumbnail from campaign JSON (`GET /api/campaigns`, detail, …).
///
/// Wayo-ads has no persisted `coverUrl` field; creatives are usually under
/// [assets] (see Prisma `CampaignAsset`) while the square logo lives in
/// [brandLogoUrl] (`POST /api/campaigns/upload-logo` → `/uploads/campaign-logos/…`).
String? parseCampaignCoverUrlFromJson(Map<String, dynamic> m) {
  for (final k in ['coverUrl', 'cover_url', 'coverImageUrl', 'cover_image_url']) {
    final v = m[k];
    if (v is String) {
      final t = v.trim();
      if (t.isNotEmpty) {
        return t;
      }
    }
  }
  final assets = m['assets'];
  if (assets is List<dynamic>) {
    String? fallbackUrl;
    for (final e in assets) {
      if (e is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(e);
      final u = map['url'];
      if (u is! String) {
        continue;
      }
      final urlTrim = u.trim();
      if (urlTrim.isEmpty) {
        continue;
      }
      final type = '${map['type'] ?? ''}'.toUpperCase();
      if (type == 'IMAGE' || type == 'BRAND_GUIDELINES') {
        return urlTrim;
      }
      fallbackUrl ??= urlTrim;
    }
    if (fallbackUrl != null) {
      return fallbackUrl;
    }
  }
  return null;
}

String _normalizeUrlSchemeForNetwork(String raw) {
  final t = raw.trim();
  if (t.startsWith('//')) {
    return 'https:$t';
  }
  return t;
}

String _maybeRemapLoopbackHostForAndroidEmulator(String url) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return url;
  }
  try {
    final u = Uri.parse(url);
    if (!u.hasScheme || !(u.scheme == 'http' || u.scheme == 'https')) {
      return url;
    }
    final h = u.host.toLowerCase();
    if (h == 'localhost' || h == '127.0.0.1') {
      return u.replace(host: '10.0.2.2').toString();
    }
  } catch (_) {}
  return url;
}

/// Builds an absolute URL for images served from Wayo-ads `/uploads/...`.
///
/// Prefer [AuthRuntimeConfig.resolvedWayoAdsPublicAssetOrigin] — never Laravel-only.
/// If absent, falls back to [AuthRuntimeConfig.resolvedWayoAdsBaseUrl] (legacy setups).
String? resolveWayoAdsPublicUrl(String? urlOrPath) {
  if (urlOrPath == null) {
    return null;
  }
  final raw = _normalizeUrlSchemeForNetwork(urlOrPath);
  if (raw.isEmpty) {
    return null;
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return _maybeRemapLoopbackHostForAndroidEmulator(raw);
  }
  if (raw.startsWith('data:')) {
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
    return _maybeRemapLoopbackHostForAndroidEmulator('$trimmed$raw');
  }
  return _maybeRemapLoopbackHostForAndroidEmulator('$trimmed/$raw');
}

/// Use for covers, logos: absolute URLs unchanged; relatives resolved on Wayo-ads.
String? normalizeWayoAdsMediaUrl(String? urlOrPath) {
  if (urlOrPath == null) {
    return null;
  }
  final raw = _normalizeUrlSchemeForNetwork(urlOrPath);
  if (raw.isEmpty) {
    return null;
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return _maybeRemapLoopbackHostForAndroidEmulator(raw);
  }
  if (raw.startsWith('data:')) {
    return raw;
  }
  return resolveWayoAdsPublicUrl(raw);
}
