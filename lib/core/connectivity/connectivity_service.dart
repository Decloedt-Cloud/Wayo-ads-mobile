import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'connectivity_status.dart';

/// Production connectivity tracker. Layers three signals:
///
/// 1. [Connectivity] stream — instant reaction to OS radio/wifi changes.
/// 2. Active probe via [InternetAddress.lookup] — guards against captive
///    portals and "wifi connected but no internet".
/// 3. Latency sampling — flags [ConnectivityStatus.weak] when probes are slow
///    (useful UX on flaky mobile networks / transit tunnels).
///
/// The service is intentionally framework-agnostic (pure Dart) so it can be
/// wrapped by any state container (Riverpod provider here).
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    Duration probeInterval = const Duration(seconds: 10),
    Duration probeTimeout = const Duration(seconds: 3),
    Duration reportDebounce = const Duration(seconds: 1),
    List<String> probeHosts = const [
      'cloudflare.com',
      'google.com',
      'one.one.one.one',
    ],
  }) : _connectivity = connectivity ?? Connectivity(),
       _probeInterval = probeInterval,
       _probeTimeout = probeTimeout,
       _reportDebounce = reportDebounce,
       _probeHosts = probeHosts;

  static const int kWeakLatencyMs = 900;

  final Connectivity _connectivity;
  final Duration _probeInterval;
  final Duration _probeTimeout;
  final Duration _reportDebounce;
  final List<String> _probeHosts;

  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _probeTimer;
  Timer? _debounceTimer;
  bool _probeInFlight = false;
  bool _started = false;
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  bool _radioUp = false;

  ConnectivityStatus get status => _status;

  /// Broadcast stream — emits only when the status actually changes.
  Stream<ConnectivityStatus> get onStatusChange => _controller.stream;

  /// Same as [onStatusChange] but emits [_status] immediately, so Riverpod listeners
  /// never miss the first [ConnectivityService.start] emission (broadcast streams do not replay).
  Stream<ConnectivityStatus> get onStatusChangeWithCurrent async* {
    yield _status;
    yield* _controller.stream;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final initial = await _connectivity.checkConnectivity();
    _radioUp = _hasUsableRadio(initial);
    if (_radioUp) {
      unawaited(_probeNow(reason: 'start'));
    } else {
      _emit(ConnectivityStatus.offline);
    }

    _sub = _connectivity.onConnectivityChanged.listen(_onRadioChanged);
    _probeTimer = Timer.periodic(_probeInterval, (_) => _probeNow());
  }

  Future<void> stop() async {
    _started = false;
    await _sub?.cancel();
    _sub = null;
    _probeTimer?.cancel();
    _probeTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  /// Signal from app code (chat socket, Dio interceptor, any HTTP caller) that
  /// a remote request **just failed** with a network-shaped error. Schedules a
  /// debounced probe so the UI reflects the outage within ~1 s, even when the
  /// OS still reports the Wi-Fi radio as "connected" (captive portal, routeur
  /// sans WAN, etc.).
  void reportRemoteFailure([Object? error]) {
    if (!_started) return;
    if (kDebugMode && error != null) {
      debugPrint('[connectivity] remote failure hint: $error');
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_reportDebounce, () {
      unawaited(_probeNow(reason: 'remote_failure'));
    });
  }

  /// Force an immediate probe — call from a "Retry" button.
  Future<ConnectivityStatus> refresh() async {
    final results = await _connectivity.checkConnectivity();
    _radioUp = _hasUsableRadio(results);
    if (!_radioUp) {
      _emit(ConnectivityStatus.offline);
      return _status;
    }
    if (_status == ConnectivityStatus.offline ||
        _status == ConnectivityStatus.unknown) {
      _emit(ConnectivityStatus.reconnecting);
    }
    await _probeNow(reason: 'manual');
    return _status;
  }

  void _onRadioChanged(List<ConnectivityResult> results) {
    final up = _hasUsableRadio(results);
    if (up == _radioUp) {
      return;
    }
    _radioUp = up;
    if (!up) {
      _emit(ConnectivityStatus.offline);
      return;
    }
    _emit(ConnectivityStatus.reconnecting);
    unawaited(_probeNow(reason: 'radio_up'));
  }

  Future<void> _probeNow({String? reason}) async {
    if (_probeInFlight) return;
    _probeInFlight = true;
    try {
      if (!_radioUp) {
        _emit(ConnectivityStatus.offline);
        return;
      }
      final sw = Stopwatch()..start();
      final ok = await _ping();
      sw.stop();
      if (!ok) {
        _emit(ConnectivityStatus.offline);
        if (kDebugMode) {
          debugPrint('[connectivity] probe failed (reason=$reason)');
        }
        return;
      }
      if (sw.elapsedMilliseconds >= kWeakLatencyMs) {
        _emit(ConnectivityStatus.weak);
      } else {
        _emit(ConnectivityStatus.online);
      }
    } finally {
      _probeInFlight = false;
    }
  }

  Future<bool> _ping() async {
    for (final host in _probeHosts) {
      try {
        final result = await InternetAddress.lookup(
          host,
        ).timeout(_probeTimeout);
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  bool _hasUsableRadio(List<ConnectivityResult> results) {
    // iOS (incl. VPN / constrained paths) often reports [other] rather than [vpn].
    // Cold start can briefly yield an empty list before NWPath is ready — still run DNS probes
    // instead of treating the app as offline (full-screen blocker looked like a stuck splash).
    if (results.isEmpty) {
      return true;
    }
    var onlyNone = true;
    for (final r in results) {
      if (r == ConnectivityResult.none) continue;
      onlyNone = false;
      if (r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other ||
          r == ConnectivityResult.bluetooth ||
          r == ConnectivityResult.satellite) {
        return true;
      }
    }
    return false;
  }

  void _emit(ConnectivityStatus next) {
    if (next == _status) return;
    _status = next;
    _controller.add(next);
  }
}
