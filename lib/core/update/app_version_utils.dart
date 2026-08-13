import 'app_update_status.dart';

/// Parses `pubspec`-style versions (`1.0.1+35`) and compares build numbers.
abstract final class AppVersionUtils {
  static int parseBuildNumber(String version) {
    final trimmed = version.trim();
    if (trimmed.isEmpty) return 0;

    final plus = trimmed.lastIndexOf('+');
    if (plus >= 0 && plus < trimmed.length - 1) {
      return int.tryParse(trimmed.substring(plus + 1)) ?? 0;
    }
    return int.tryParse(trimmed) ?? 0;
  }

  /// Pure policy used by [AppUpdateService] and unit tests.
  ///
  /// - `current < minimum` (and minimum > 0) → [AppUpdateStatus.required]
  /// - else `current < latest` (and latest > 0) → [AppUpdateStatus.optional]
  /// - else → [AppUpdateStatus.none]
  static AppUpdateStatus resolveStatus({
    required int currentBuild,
    required int minimumBuild,
    required int latestBuild,
  }) {
    if (minimumBuild > 0 && currentBuild < minimumBuild) {
      return AppUpdateStatus.required;
    }
    if (latestBuild > 0 && currentBuild < latestBuild) {
      return AppUpdateStatus.optional;
    }
    return AppUpdateStatus.none;
  }

  static bool isBuildBelowMinimum({
    required int currentBuild,
    required int minimumBuild,
  }) {
    return resolveStatus(
          currentBuild: currentBuild,
          minimumBuild: minimumBuild,
          latestBuild: 0,
        ) ==
        AppUpdateStatus.required;
  }
}
