/// Single source of truth for the app's network connectivity state.
enum ConnectivityStatus {
  /// First observation not yet received — UI should show nothing.
  unknown,

  /// Device advertises at least one network AND a reachability ping succeeded.
  online,

  /// Device advertises no usable network (none of wifi/mobile/ethernet/vpn).
  offline,

  /// App is currently retrying after a loss — shown right after `offline`
  /// while a ping is in flight and the network just came back.
  reconnecting,

  /// Device claims to be online but the last probe was slow/intermittent
  /// (latency above [ConnectivityService.kWeakLatencyMs] or a probe failed
  /// then succeeded within the same window).
  weak,
}

extension ConnectivityStatusX on ConnectivityStatus {
  bool get isOnline =>
      this == ConnectivityStatus.online || this == ConnectivityStatus.weak;
  bool get isOffline => this == ConnectivityStatus.offline;
  bool get isReconnecting => this == ConnectivityStatus.reconnecting;
  bool get isWeak => this == ConnectivityStatus.weak;
}
