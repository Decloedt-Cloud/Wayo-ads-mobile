import '../../../../core/config/auth_runtime_config.dart';

/// Builds the Wayo-ads federated logout URL (same as web sign-in "switch account").
abstract final class WayoWebLogoutUrls {
  static const String _fallbackOrigin = 'https://wayo-ads.com';
  static const String _signinPath = '/auth/signin';

  static String federatedLogoutUrl({String? serverProvided}) {
    final fromServer = serverProvided?.trim();
    if (fromServer != null && fromServer.isNotEmpty) {
      return fromServer;
    }
    final origin =
        AuthRuntimeConfig.instance.resolvedWayoAdsPublicAssetOrigin ??
        _fallbackOrigin;
    final base = origin.replaceAll(RegExp(r'/+$'), '');
    final redirect = Uri.encodeComponent(_signinPath);
    return '$base/api/auth/federated-logout?redirect_to=$redirect';
  }
}
