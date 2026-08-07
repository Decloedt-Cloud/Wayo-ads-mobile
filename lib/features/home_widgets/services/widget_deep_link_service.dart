/// Maps `wayoads://…` widget deep links to go_router locations.
abstract final class WidgetDeepLinkService {
  static const scheme = 'wayoads';

  /// Pending URI when the app was cold-started from a widget (before auth ready).
  static Uri? _pending;

  static Uri? get pending => _pending;

  static void stashPending(Uri? uri) {
    if (uri == null) return;
    if (!_isWayoAdsWidgetUri(uri)) return;
    _pending = uri;
  }

  /// Keep pending without clearing (for retry until router/auth ready).
  static void keepPending(Uri uri) {
    if (!_isWayoAdsWidgetUri(uri)) return;
    _pending = uri;
  }

  static Uri? takePending() {
    final u = _pending;
    _pending = null;
    return u;
  }

  static bool _isWayoAdsWidgetUri(Uri uri) {
    final s = uri.scheme.toLowerCase();
    if (s == scheme || s == 'com.wayo.wayoadsgo') return true;
    // Some OEMs deliver host-only or path-only; accept empty scheme with known host.
    if (s.isEmpty && uri.host.isNotEmpty) {
      final h = uri.host.toLowerCase();
      return h == 'dashboard' ||
          h == 'campaigns' ||
          h == 'wallet' ||
          h == 'analytics' ||
          h == 'home';
    }
    return false;
  }

  /// Returns an in-app path such as `/dashboard`, or null if unrecognized.
  ///
  /// [role] should be `creator` | `advertiser` | `superAdmin` | …
  static String? routeForUri(Uri uri, {String role = 'advertiser'}) {
    if (!_isWayoAdsWidgetUri(uri)) return null;

    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    final key = host.isNotEmpty ? host : (segments.isEmpty ? '' : segments.first);
    final rest = host.isNotEmpty
        ? segments
        : (segments.length <= 1 ? const <String>[] : segments.sublist(1));

    final isCreator = role == 'creator';
    final isSuperAdmin = role == 'superAdmin';

    switch (key) {
      case '':
      case 'dashboard':
      case 'home':
        if (isSuperAdmin) return '/superadmin';
        return '/dashboard';
      case 'campaigns':
        if (rest.isNotEmpty && (rest.first == 'create' || rest.first == 'new')) {
          if (isCreator) return '/campaigns';
          if (isSuperAdmin) return '/superadmin';
          return '/advertiser/campaigns/new';
        }
        return '/campaigns';
      case 'analytics':
        if (isCreator) return '/creator/analytics';
        if (isSuperAdmin) return '/superadmin';
        return '/dashboard';
      case 'wallet':
        if (isSuperAdmin) return '/superadmin';
        return '/wallet';
      default:
        return isSuperAdmin ? '/superadmin' : '/dashboard';
    }
  }

  static Uri uriForRoute(String path) {
    switch (path) {
      case '/campaigns':
        return Uri(scheme: scheme, host: 'campaigns');
      case '/advertiser/campaigns/new':
        return Uri(scheme: scheme, host: 'campaigns', path: '/create');
      case '/wallet':
        return Uri(scheme: scheme, host: 'wallet');
      case '/creator/analytics':
        return Uri(scheme: scheme, host: 'analytics');
      case '/dashboard':
      default:
        return Uri(scheme: scheme, host: 'dashboard');
    }
  }
}
