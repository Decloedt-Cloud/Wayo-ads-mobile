import 'app_update_status.dart';

/// Snapshot of a version check for the current platform.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.status,
    required this.currentBuild,
    required this.minimumBuild,
    required this.latestBuild,
    required this.storeUrl,
    this.message,
  });

  final AppUpdateStatus status;
  final int currentBuild;
  final int minimumBuild;
  final int latestBuild;
  final String storeUrl;
  final String? message;

  static const none = AppUpdateInfo(
    status: AppUpdateStatus.none,
    currentBuild: 0,
    minimumBuild: 0,
    latestBuild: 0,
    storeUrl: '',
  );

  bool get isRequired => status == AppUpdateStatus.required;
  bool get isOptional => status == AppUpdateStatus.optional;
}
