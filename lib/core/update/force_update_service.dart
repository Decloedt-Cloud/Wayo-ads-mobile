import 'app_update_info.dart';
import 'app_update_service.dart';
import 'force_update_config.dart';

/// Legacy facade — prefer [AppUpdateService.checkForUpdate].
@Deprecated('Use AppUpdateService.checkForUpdate()')
abstract final class ForceUpdateService {
  static Future<ForceUpdateConfig> evaluate() async {
    final info = await AppUpdateService.checkForUpdate();
    if (!info.isRequired) return ForceUpdateConfig.disabled;
    return ForceUpdateConfig(
      required: true,
      minimumBuild: info.minimumBuild,
      storeUrl: info.storeUrl,
    );
  }
}

/// Compatibility helper for older call sites.
extension AppUpdateInfoForceX on AppUpdateInfo {
  ForceUpdateConfig get asForceUpdateConfig {
    if (!isRequired) return ForceUpdateConfig.disabled;
    return ForceUpdateConfig(
      required: true,
      minimumBuild: minimumBuild,
      storeUrl: storeUrl,
    );
  }
}
