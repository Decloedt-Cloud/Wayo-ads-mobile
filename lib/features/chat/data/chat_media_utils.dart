/// Same idea as `resolveMediaUrl` in `AdvertiserChatDialog.tsx`.
///
/// Chat-service may return `file_url` as a full URL built from Laravel `APP_URL`
/// (e.g. `http://127.0.0.1:8000/storage/...`) while the app talks to another host
/// (`apiBaseUrl`). Always serve `/storage/...` assets through [apiBaseUrl].
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
        baseUri.host.isNotEmpty) {
      return Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        path: uri.path,
        query: uri.query.isEmpty ? null : uri.query,
      ).toString();
    }
    return p;
  }

  if (p.startsWith('blob:') || p.startsWith('data:')) {
    return p;
  }

  final segment = p.startsWith('/') ? p : '/$p';
  return '$base$segment';
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
