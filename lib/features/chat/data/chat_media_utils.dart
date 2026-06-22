import 'package:flutter/foundation.dart';

import '../../../core/network/wayo_ads_public_url.dart';

bool _isLoopbackHost(String host) {
  final h = host.toLowerCase();
  return h == 'localhost' || h == '127.0.0.1' || h == '10.0.2.2' || h == '[::1]';
}

String _maybeRemapLoopbackHostForAndroidEmulator(String url) {
  if (kIsWeb) return url;
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

/// Same idea as `resolveChatMediaUrl` in Wayo-ads `chat-media-url.ts`.
///
/// Chat-service may return `file_url` as a full URL built from Laravel `APP_URL`
/// (e.g. `http://127.0.0.1:8000/storage/...`) while the app talks to another host
/// (`apiBaseUrl`). Only rewrite loopback `/storage/` hosts — Auth / Wayo-ads avatars
/// on production hosts must stay unchanged.
String resolveChatMediaUrl(String? path, String apiBaseUrl) {
  if (path == null || path.isEmpty) return '';
  final p = path.trim();
  final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  final baseUri = Uri.tryParse(base);

  if (p.startsWith('http://') || p.startsWith('https://')) {
    final uri = Uri.tryParse(p);
    if (uri != null &&
        uri.path.contains('/storage/') &&
        baseUri != null &&
        baseUri.host.isNotEmpty &&
        _isLoopbackHost(uri.host)) {
      return Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        path: uri.path,
        query: uri.query.isEmpty ? null : uri.query,
      ).toString();
    }
    return _maybeRemapLoopbackHostForAndroidEmulator(p);
  }

  if (p.startsWith('blob:') || p.startsWith('data:')) {
    return p;
  }

  final segment = p.startsWith('/') ? p : '/$p';
  return '$base$segment';
}

/// Profile photos in chat — Auth avatars, Wayo-ads `/uploads/`, or chat storage.
String resolveChatAvatarUrl(String? path, String chatApiBaseUrl) {
  if (path == null || path.isEmpty) return '';
  final t = path.trim();
  if (t.contains('/uploads/')) {
    final fromAds = normalizeWayoAdsMediaUrl(t);
    if (fromAds != null && fromAds.isNotEmpty) {
      return fromAds;
    }
  }
  return resolveChatMediaUrl(path, chatApiBaseUrl);
}

/// Storage-relative path for comparing caption vs attachment (ignores host).
String? chatMediaStoragePath(String? reference) {
  if (reference == null || reference.trim().isEmpty) return null;
  final t = reference.trim();
  final uri = Uri.tryParse(t);
  if (uri != null && uri.path.contains('/storage/')) {
    return uri.path;
  }
  if (t.startsWith('/storage/')) return t;
  return null;
}
