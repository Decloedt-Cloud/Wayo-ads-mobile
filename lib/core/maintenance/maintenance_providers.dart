import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'maintenance_service.dart';

/// Same [MaintenanceService] instance for Dio interceptors and [MaintenanceGate].
///
/// Uses a plain [Provider] (not [ChangeNotifierProvider]) so disposing a
/// [ProviderContainer] never calls [ChangeNotifier.dispose] on the process-wide
/// singleton held by [MaintenanceServiceHolder].
final maintenanceServiceProvider = Provider<MaintenanceService>(
  (ref) => MaintenanceServiceHolder.instance,
);
