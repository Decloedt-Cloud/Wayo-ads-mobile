/// Same idea as `resolveMediaUrl` in `AdvertiserChatDialog.tsx`.
String resolveChatMediaUrl(String? path, String apiBaseUrl) {
  if (path == null || path.isEmpty) return '';
  final p = path.trim();
  if (p.startsWith('http://') ||
      p.startsWith('https://') ||
      p.startsWith('blob:') ||
      p.startsWith('data:')) {
    return p;
  }
  final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  final segment = p.startsWith('/') ? p : '/$p';
  return '$base$segment';
}
