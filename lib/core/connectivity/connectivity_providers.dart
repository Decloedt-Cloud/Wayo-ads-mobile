import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';
import 'connectivity_status.dart';

/// Long-lived connectivity service — started once, disposed on app exit.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  unawaited(service.start());
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

/// Whether the OS still reports Wi‑Fi / mobile data (vs airplane mode).
final connectivityRadioUpProvider = Provider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).radioUp;
});

/// Broadcast current status; UI watches this.
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChangeWithCurrent;
});
