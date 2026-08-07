/// Deep link scheme for in-app YouTube OAuth (FlutterWebAuth2).
abstract final class YouTubeOAuthConfig {
  static const String callbackScheme = 'com.wayo.wayoadsgo';
  static const String redirectUri = '$callbackScheme:/youtube-oauth';

  /// Sent to Wayo-ads `connect?returnApp=` so mobile-callback returns here.
  static const String returnApp = 'adsgo';
}
