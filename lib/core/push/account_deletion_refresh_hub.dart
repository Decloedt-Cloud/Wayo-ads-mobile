typedef AccountDeletionRefreshHandler =
    void Function(Map<String, dynamic>? payload);

AccountDeletionRefreshHandler? _onAccountDeletionStateChanged;

/// Registered by [RealtimeDashboardWire] so FCM / local handlers can refresh
/// the account soft-delete banner without import cycles.
void setAccountDeletionRefreshHandler(AccountDeletionRefreshHandler? fn) {
  _onAccountDeletionStateChanged = fn;
}

void clearAccountDeletionRefreshHandler() {
  _onAccountDeletionStateChanged = null;
}

void notifyAccountDeletionStateChanged([Map<String, dynamic>? payload]) {
  _onAccountDeletionStateChanged?.call(payload);
}
