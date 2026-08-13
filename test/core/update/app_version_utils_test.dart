import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/update/app_update_status.dart';
import 'package:wayoadsgo/core/update/app_version_utils.dart';

void main() {
  group('AppVersionUtils.parseBuildNumber', () {
    test('parses plain build', () {
      expect(AppVersionUtils.parseBuildNumber('25'), 25);
    });

    test('parses pubspec style version+build', () {
      expect(AppVersionUtils.parseBuildNumber('1.3.3+25'), 25);
    });

    test('returns 0 on invalid', () {
      expect(AppVersionUtils.parseBuildNumber(''), 0);
      expect(AppVersionUtils.parseBuildNumber('abc'), 0);
    });
  });

  group('AppVersionUtils.resolveStatus', () {
    test('Test A — none when equal', () {
      expect(
        AppVersionUtils.resolveStatus(
          currentBuild: 10,
          minimumBuild: 10,
          latestBuild: 10,
        ),
        AppUpdateStatus.none,
      );
    });

    test('Test B — optional when below latest only', () {
      expect(
        AppVersionUtils.resolveStatus(
          currentBuild: 10,
          minimumBuild: 10,
          latestBuild: 11,
        ),
        AppUpdateStatus.optional,
      );
    });

    test('Test C — required when below minimum', () {
      expect(
        AppVersionUtils.resolveStatus(
          currentBuild: 9,
          minimumBuild: 10,
          latestBuild: 11,
        ),
        AppUpdateStatus.required,
      );
    });

    test('special case build 20/21/22', () {
      expect(
        AppVersionUtils.resolveStatus(
          currentBuild: 20,
          minimumBuild: 21,
          latestBuild: 22,
        ),
        AppUpdateStatus.required,
      );
      expect(
        AppVersionUtils.resolveStatus(
          currentBuild: 21,
          minimumBuild: 21,
          latestBuild: 22,
        ),
        AppUpdateStatus.optional,
      );
      expect(
        AppVersionUtils.resolveStatus(
          currentBuild: 22,
          minimumBuild: 21,
          latestBuild: 22,
        ),
        AppUpdateStatus.none,
      );
    });

    test('zero thresholds never force or soft-prompt', () {
      expect(
        AppVersionUtils.resolveStatus(
          currentBuild: 5,
          minimumBuild: 0,
          latestBuild: 0,
        ),
        AppUpdateStatus.none,
      );
    });
  });
}
