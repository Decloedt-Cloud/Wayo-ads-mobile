import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'maintenance_service.dart';

/// Same [MaintenanceService] instance for Dio interceptors and [MaintenanceGate].
final maintenanceServiceProvider = ChangeNotifierProvider<MaintenanceService>(
  (ref) => MaintenanceServiceHolder.instance,
);
