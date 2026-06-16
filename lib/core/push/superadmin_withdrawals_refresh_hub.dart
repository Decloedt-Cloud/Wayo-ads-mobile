void Function()? _onSuperadminWithdrawalsRefresh;

/// Registered by [RealtimeDashboardWire] so FCM / push navigation can refresh
/// the superadmin payouts list without import cycles.
void setSuperadminWithdrawalsRefreshHandler(void Function()? fn) {
  _onSuperadminWithdrawalsRefresh = fn;
}

void clearSuperadminWithdrawalsRefreshHandler() {
  _onSuperadminWithdrawalsRefresh = null;
}

void notifySuperadminWithdrawalsRefresh() {
  _onSuperadminWithdrawalsRefresh?.call();
}
