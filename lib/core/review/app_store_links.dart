import 'dart:io';

/// Public store identifiers and deep links for Wayo Ads mobile.
abstract final class AppStoreLinks {
  /// Numeric App Store id (App Store Connect → App Information).
  static const iosAppStoreId = '6766541639';

  static const androidPackageId = 'ma.wayo.wayoadsgo';

  static const iosListingUrl = 'https://apps.apple.com/app/id$iosAppStoreId';

  /// Opens the App Store review sheet when launched externally on iOS.
  static const iosReviewUrl =
      'https://apps.apple.com/app/id$iosAppStoreId?action=write-review';

  static const androidListingUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// Best URL for an explicit "Rate the app" tap on the current platform.
  static String? reviewUrlForCurrentPlatform() {
    if (Platform.isIOS) return iosReviewUrl;
    if (Platform.isAndroid) return androidListingUrl;
    return null;
  }
}
