void Function()? _onMaintenanceRecoveryProbe;

/// Registered by [MaintenanceGate] so Reverb / FCM maintenance-recovery signals
/// can trigger a health probe without import cycles.
void setMaintenanceRecoveryProbeHandler(void Function()? fn) {
  _onMaintenanceRecoveryProbe = fn;
}

void clearMaintenanceRecoveryProbeHandler() {
  _onMaintenanceRecoveryProbe = null;
}

void notifyMaintenanceRecoveryProbe() {
  _onMaintenanceRecoveryProbe?.call();
}
