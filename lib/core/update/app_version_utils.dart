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

  static bool isBuildBelowMinimum({
    required int currentBuild,
    required int minimumBuild,
  }) {
    if (minimumBuild <= 0) return false;
    return currentBuild < minimumBuild;
  }
}
