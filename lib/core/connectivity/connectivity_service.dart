import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../config/auth_runtime_config.dart';
import '../observability/app_log.dart';
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
    Duration probeTimeout = const Duration(seconds: 5),
    Duration reportDebounce = const Duration(seconds: 2),
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
  Timer? _confirmOfflineTimer;
  Timer? _foregroundProbeTimer;
  Timer? _radioDownDebounce;
  bool _probeInFlight = false;
  bool _probePending = false;
  int _consecutiveProbeFailures = 0;
  bool _started = false;
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  bool _radioUp = false;

  /// Debounce brief OS "none" blips (common on Android/iOS resume) before blocking UI.
  static const Duration kRadioDownDebounce = Duration(milliseconds: 2500);

  /// Failed probes required before treating reachability as lost (avoids DNS blips).
  static const int kOfflineAfterFailedProbes = 3;

  /// Grace after a successful online probe — transient API/DNS blips stay non-blocking.
  static const Duration kOnlineGrace = Duration(seconds: 45);

  ConnectivityStatus get status => _status;

  /// Whether the OS reports an active network interface (Wi‑Fi, mobile, etc.).
  bool get radioUp => _radioUp;

  DateTime? _lastOnlineAt;

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
    _applyRadioState(_hasUsableRadio(initial), debounceDown: true);
    if (_radioUp) {
      unawaited(_probeNow(reason: 'start'));
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
    _confirmOfflineTimer?.cancel();
    _confirmOfflineTimer = null;
    _foregroundProbeTimer?.cancel();
    _foregroundProbeTimer = null;
    _radioDownDebounce?.cancel();
    _radioDownDebounce = null;
  }

  /// Call when the app returns to foreground — delayed probe avoids false offline
  /// while the OS network stack and DNS are still waking up.
  void onAppForeground() {
    if (!_started) return;
    _consecutiveProbeFailures = 0;
    _confirmOfflineTimer?.cancel();
    _foregroundProbeTimer?.cancel();
    _foregroundProbeTimer = Timer(const Duration(milliseconds: 1500), () {
      unawaited(_probeNow(reason: 'foreground'));
    });
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
    if (kWayoDiagnosticsLogging && error != null) {
      wayoDiagPrint('[connectivity] remote failure hint: $error', name: 'wayo.net');
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_reportDebounce, () {
      unawaited(_probeNow(reason: 'remote_failure'));
    });
  }

  /// Force an immediate probe — call from a "Retry" button.
  Future<ConnectivityStatus> refresh() async {
    final results = await _connectivity.checkConnectivity();
    _applyRadioState(_hasUsableRadio(results));
    if (!_radioUp) {
      _emitOfflineIfRadioDown();
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
    _applyRadioState(_hasUsableRadio(results));
  }

  /// Updates [_radioUp]. Radio-up is immediate; radio-down is debounced to ignore flaps.
  void _applyRadioState(bool up, {bool debounceDown = false}) {
    if (up) {
      _radioDownDebounce?.cancel();
      _radioDownDebounce = null;
      if (_radioUp) return;
      _radioUp = true;
      _emit(ConnectivityStatus.reconnecting);
      unawaited(_probeNow(reason: 'radio_up'));
      return;
    }

    if (!_radioUp) return;

    void markRadioDown() {
      _radioUp = false;
      _consecutiveProbeFailures = 0;
      _confirmOfflineTimer?.cancel();
      _emitOfflineIfRadioDown();
    }

    if (!debounceDown) {
      markRadioDown();
      return;
    }

    _radioDownDebounce?.cancel();
    _radioDownDebounce = Timer(kRadioDownDebounce, () async {
      final again = await _connectivity.checkConnectivity();
      if (_hasUsableRadio(again)) {
        _applyRadioState(true);
        return;
      }
      markRadioDown();
    });
  }

  /// Full-screen offline only when the OS reports no usable network interface.
  void _emitOfflineIfRadioDown() {
    if (_radioUp) {
      _emit(ConnectivityStatus.weak);
      return;
    }
    _emit(ConnectivityStatus.offline);
  }

  /// Probe failures while Wi‑Fi/mobile is still up → weak banner, not full blocker.
  void _emitUnreachable() {
    if (_radioUp) {
      _emit(ConnectivityStatus.weak);
    } else {
      _emit(ConnectivityStatus.offline);
    }
  }

  Future<void> _probeNow({String? reason}) async {
    if (_probeInFlight) {
      _probePending = true;
      return;
    }
    _probeInFlight = true;
    try {
      if (!_radioUp) {
        _consecutiveProbeFailures = 0;
        _confirmOfflineTimer?.cancel();
        _emitOfflineIfRadioDown();
        return;
      }
      final sw = Stopwatch()..start();
      final ok = await _probeReachability();
      sw.stop();
      if (!ok) {
        _consecutiveProbeFailures++;
        if (kWayoDiagnosticsLogging) {
          wayoDiagPrint(
            '[connectivity] probe failed (reason=$reason, streak=$_consecutiveProbeFailures)',
            name: 'wayo.net',
          );
        }
        if (_status == ConnectivityStatus.offline ||
            _status == ConnectivityStatus.weak) {
          _emitUnreachable();
          return;
        }
        final inGrace = _lastOnlineAt != null &&
            DateTime.now().difference(_lastOnlineAt!) < kOnlineGrace;
        final threshold = inGrace
            ? kOfflineAfterFailedProbes + 1
            : kOfflineAfterFailedProbes;
        if (_consecutiveProbeFailures >= threshold) {
          _consecutiveProbeFailures = 0;
          _confirmOfflineTimer?.cancel();
          _emitUnreachable();
          return;
        }
        if (_status == ConnectivityStatus.online ||
            _status == ConnectivityStatus.reconnecting ||
            _status == ConnectivityStatus.unknown) {
          _emit(ConnectivityStatus.weak);
        }
        _confirmOfflineTimer?.cancel();
        _confirmOfflineTimer = Timer(const Duration(seconds: 3), () {
          unawaited(_probeNow(reason: 'confirm_offline'));
        });
        return;
      }
      _consecutiveProbeFailures = 0;
      _confirmOfflineTimer?.cancel();
      _lastOnlineAt = DateTime.now();
      if (sw.elapsedMilliseconds >= kWeakLatencyMs) {
        _emit(ConnectivityStatus.weak);
      } else {
        _emit(ConnectivityStatus.online);
      }
    } finally {
      _probeInFlight = false;
      if (_probePending) {
        _probePending = false;
        unawaited(_probeNow(reason: 'pending'));
      }
    }
  }

  Future<bool> _probeReachability() async {
    if (await _pingDns()) return true;
    if (await _probeHttpEndpoints()) return true;
    return _probePublicInternet();
  }

  Future<bool> _pingDns() async {
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

  /// DNS can fail on some carriers while HTTPS to our API still works.
  Future<bool> _probeHttpEndpoints() async {
    final runtime = AuthRuntimeConfig.instance;
    final origins = <String>{};
    void addOrigin(String? raw) {
      final trimmed = raw?.trim() ?? '';
      if (trimmed.isEmpty) return;
      origins.add(_originOnly(trimmed));
    }

    addOrigin(runtime.authWayoBaseUrl);
    addOrigin(runtime.resolvedWayoAdsBaseUrl);
    addOrigin(runtime.resolvedWayoAdsPublicAssetOrigin);
    if (origins.isEmpty) return false;

    final dio = Dio(
      BaseOptions(
        connectTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
        sendTimeout: _probeTimeout,
        followRedirects: true,
        maxRedirects: 2,
        validateStatus: (code) => code != null && code < 500,
        headers: const {
          'Accept': '*/*',
          'X-Client': 'wayo-ads-go',
        },
      ),
    );
    try {
      for (final origin in origins) {
        for (final path in const ['/', '/api/health', '/health']) {
          try {
            final response = await dio.get<dynamic>('$origin$path');
            if (response.statusCode != null && response.statusCode! < 500) {
              return true;
            }
          } on DioException catch (e) {
            if (e.response != null && e.response!.statusCode != null) {
              if (e.response!.statusCode! < 500) return true;
            }
            continue;
          } catch (_) {
            continue;
          }
        }
      }
    } finally {
      dio.close(force: true);
    }
    return false;
  }

  /// Lightweight HTTPS check when DNS or Wayo hosts fail (validates real internet).
  Future<bool> _probePublicInternet() async {
    const urls = [
      'https://cloudflare.com/cdn-cgi/trace',
      'https://www.google.com/generate_204',
    ];
    final dio = Dio(
      BaseOptions(
        connectTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
        sendTimeout: _probeTimeout,
        followRedirects: true,
        maxRedirects: 2,
        validateStatus: (code) => code != null && code < 500,
        headers: const {'Accept': '*/*', 'X-Client': 'wayo-ads-go'},
      ),
    );
    try {
      for (final url in urls) {
        try {
          final response = await dio.get<dynamic>(url);
          if (response.statusCode != null && response.statusCode! < 500) {
            return true;
          }
        } on DioException catch (e) {
          if (e.response != null && e.response!.statusCode != null) {
            if (e.response!.statusCode! < 500) return true;
          }
        } catch (_) {
          continue;
        }
      }
    } finally {
      dio.close(force: true);
    }
    return false;
  }

  String _originOnly(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return url;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  bool _hasUsableRadio(List<ConnectivityResult> results) {
    // iOS (incl. VPN / constrained paths) often reports [other] rather than [vpn].
    // Cold start can briefly yield an empty list before NWPath is ready — still run DNS probes
    // instead of treating the app as offline (full-screen blocker looked like a stuck splash).
    if (results.isEmpty) {
      return true;
    }
    for (final r in results) {
      if (r == ConnectivityResult.none) continue;
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
