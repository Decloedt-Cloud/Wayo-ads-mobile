import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/auth_notifier.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../data/account_deletion_remote_datasource.dart';

final accountDeletionRemoteProvider = Provider<AccountDeletionRemoteDatasource>(
  (ref) => AccountDeletionRemoteDatasource(ref.watch(wayoAdsDioProvider)),
);

/// Server `deletionRequestedAt` — **[DateTime?]` state, not [AsyncValue]** — so the
/// shell banner rebuilds **immediately** on schedule/cancel (no loading slot).
///
/// Watches only [AuthAuthenticated.user.id]. Coalesces HTTP via [_gen] so stale
/// responses never overwrite [setScheduledAt] / [applyFromProfile].
final accountDeletionScheduledAtProvider =
    NotifierProvider<AccountDeletionScheduledAtNotifier, DateTime?>(
      AccountDeletionScheduledAtNotifier.new,
    );

class AccountDeletionScheduledAtNotifier extends Notifier<DateTime?> {
  int _gen = 0;
  int? _lastUserId;
  Timer? _pollTimer;

  // PERF: this periodic poll is only a fallback — Reverb realtime + app-resume
  // sync already make cross-device schedule/cancel near-instant. A 2-minute
  // backstop keeps cross-device detection without waking the network every 30s.
  static const _pollInterval = Duration(minutes: 2);

  void _bumpMutationGeneration() {
    _gen++;
  }

  /// Web parity: poll the profile periodically while authenticated (not only when
  /// a deletion is already scheduled) so a deletion requested from another device
  /// (web / other phone) is detected. Reverb + app-resume sync make it instant
  /// when available; this timer is just the fallback ([_pollInterval]).
  void _ensurePollTimer({required bool authenticated}) {
    if (!authenticated) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(_pollInterval, (_) {
      unawaited(syncFromRemote());
    });
  }

  @override
  DateTime? build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });

    final userId = ref.watch(
      authNotifierProvider.select((async) {
        final v = async.valueOrNull;
        if (v is AuthAuthenticated) return v.user.id;
        return null;
      }),
    );

    if (userId == null) {
      _bumpMutationGeneration();
      _lastUserId = null;
      _ensurePollTimer(authenticated: false);
      return null;
    }

    if (_lastUserId != userId) {
      _lastUserId = userId;
      _bumpMutationGeneration();
      _ensurePollTimer(authenticated: true);
      Future<void>.microtask(() => syncFromRemote(bypassCache: true));
      return null;
    }

    _ensurePollTimer(authenticated: true);
    return state;
  }

  void setScheduledAt(DateTime value) {
    _bumpMutationGeneration();
    state = value;
    _ensurePollTimer(authenticated: true);
  }

  void applyFromProfile(DateTime? deletionRequestedAt) {
    _bumpMutationGeneration();
    state = deletionRequestedAt;
    _ensurePollTimer(authenticated: _lastUserId != null);
  }

  void clearScheduledAt() {
    _bumpMutationGeneration();
    state = null;
    _ensurePollTimer(authenticated: _lastUserId != null);
  }

  Future<void> syncFromRemote({bool bypassCache = true}) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) {
      _bumpMutationGeneration();
      state = null;
      return;
    }
    final startGen = _gen;
    try {
      final ds = ref.read(accountDeletionRemoteProvider);
      final p = await ds.fetchProfile(bypassCache: bypassCache);
      if (startGen != _gen) return;
      state = p.deletionRequestedAt;
    } catch (_) {
      if (startGen != _gen) return;
    }
  }
}
