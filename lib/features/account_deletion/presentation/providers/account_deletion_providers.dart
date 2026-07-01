import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/auth_notifier.dart';
import '../../../../core/network/auth_force_logout_hub.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../data/account_deletion_remote_datasource.dart';
import '../../domain/account_deletion_anonymized.dart';
import '../../domain/account_deletion_realtime.dart' as deletion_rt;

final accountDeletionRemoteProvider = Provider<AccountDeletionRemoteDatasource>(
  (ref) => AccountDeletionRemoteDatasource(ref.watch(wayoAdsDioProvider)),
);

/// Applies Reverb / FCM deletion signals, then confirms via profile GET (web parity).
void applyAccountDeletionRealtimeSignal(
  Ref ref,
  Map<String, dynamic> payload,
) {
  ref
      .read(accountDeletionScheduledAtProvider.notifier)
      .applyRealtimeSignal(payload);
}

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
  DateTime? _lastLocalScheduleAt;

  /// After [setScheduledAt], ignore profile polls that still return null briefly
  /// (covers CDN/replica lag after OAuth re-auth delete on mobile).
  static const _localScheduleGrace = Duration(minutes: 3);

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
    _lastLocalScheduleAt = DateTime.now();
    state = value;
    _ensurePollTimer(authenticated: true);
  }

  void applyFromProfile(DateTime? deletionRequestedAt) {
    _bumpMutationGeneration();
    if (deletionRequestedAt != null) {
      _lastLocalScheduleAt = null;
      state = deletionRequestedAt;
    } else if (state == null) {
      state = null;
    } else if (!_withinLocalScheduleGrace) {
      state = null;
    }
    _ensurePollTimer(authenticated: _lastUserId != null);
  }

  bool get _withinLocalScheduleGrace {
    final at = _lastLocalScheduleAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < _localScheduleGrace;
  }

  void clearScheduledAt() {
    _bumpMutationGeneration();
    _lastLocalScheduleAt = null;
    state = null;
    _ensurePollTimer(authenticated: _lastUserId != null);
  }

  /// Reverb / FCM instant update — then [syncFromRemote] confirms (web parity).
  void applyRealtimeSignal(Map<String, dynamic> payload) {
    if (isAccountDeletionCompletedPayload(payload)) {
      clearScheduledAt();
      notifyAuthForceLogout();
      return;
    }
    if (deletion_rt.isAccountDeletionCancelledNotificationPayload(payload)) {
      clearScheduledAt();
    } else {
      final parsed = deletion_rt.extractAccountDeletionStateFromPayload(payload);
      if (parsed.hasExplicitState && parsed.deletionRequestedAt != null) {
        setScheduledAt(parsed.deletionRequestedAt!);
      } else if (deletion_rt.isAccountDeletionScheduledNotificationPayload(payload)) {
        setScheduledAt(DateTime.now().toUtc());
      } else if (parsed.hasExplicitState) {
        applyFromProfile(parsed.deletionRequestedAt);
      }
    }
    unawaited(syncFromRemote());
  }

  Future<void> syncFromRemote({bool bypassCache = true}) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) {
      _bumpMutationGeneration();
      _lastLocalScheduleAt = null;
      state = null;
      return;
    }
    final startGen = _gen;
    try {
      final ds = ref.read(accountDeletionRemoteProvider);
      final p = await ds.fetchProfile(bypassCache: bypassCache);
      if (startGen != _gen) return;
      if (p.isAnonymized) {
        clearScheduledAt();
        notifyAuthForceLogout();
        return;
      }
      final remote = p.deletionRequestedAt;
      if (remote != null) {
        _lastLocalScheduleAt = null;
        state = remote;
        return;
      }
      if (state == null || !_withinLocalScheduleGrace) {
        state = remote;
      }
    } catch (_) {
      if (startGen != _gen) return;
    }
  }
}
