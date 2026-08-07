import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'maintenance_data_refresh.dart';

/// Owns post-maintenance remote-data refresh using a real Riverpod [Ref].
///
/// [MaintenanceGate] must only call [recoverNow] — never pass [WidgetRef]
/// into helpers typed as [Ref].
class MaintenanceRecoveryCoordinator {
  MaintenanceRecoveryCoordinator(this._ref);

  final Ref _ref;

  bool _inFlight = false;
  Future<void>? _ongoing;

  /// True while a recovery invalidation pass is running (tests / diagnostics).
  bool get isRecovering => _inFlight;

  /// Deduped recovery. Safe to call from post-frame callbacks.
  ///
  /// Concurrent callers share one [Future] so a synchronous invalidation body
  /// cannot run twice when [recoverNow] is invoked twice in the same turn.
  Future<void> recoverNow() {
    final existing = _ongoing;
    if (existing != null) {
      if (kDebugMode) {
        debugPrint('[MaintenanceRecovery] skip — recovery already in flight');
      }
      return existing;
    }

    _inFlight = true;
    late final Future<void> future;
    future =
        Future<void>(() {
          if (kDebugMode) {
            debugPrint(
              '[MaintenanceRecovery] invalidate remote data providers',
            );
          }
          refreshAppDataAfterMaintenanceRecovery(_ref);
        }).whenComplete(() {
          if (identical(_ongoing, future)) {
            _ongoing = null;
          }
          _inFlight = false;
        });
    _ongoing = future;
    return future;
  }
}

final maintenanceRecoveryCoordinatorProvider =
    Provider<MaintenanceRecoveryCoordinator>((ref) {
      return MaintenanceRecoveryCoordinator(ref);
    });
