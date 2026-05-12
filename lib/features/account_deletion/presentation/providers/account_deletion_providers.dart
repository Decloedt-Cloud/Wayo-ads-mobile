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

  void _bumpMutationGeneration() {
    _gen++;
  }

  @override
  DateTime? build() {
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
      return null;
    }

    if (_lastUserId != userId) {
      _lastUserId = userId;
      _bumpMutationGeneration();
      Future<void>.microtask(() => syncFromRemote(bypassCache: true));
      return null;
    }

    return state;
  }

  void setScheduledAt(DateTime value) {
    _bumpMutationGeneration();
    state = value;
  }

  void applyFromProfile(DateTime? deletionRequestedAt) {
    _bumpMutationGeneration();
    state = deletionRequestedAt;
  }

  void clearScheduledAt() {
    _bumpMutationGeneration();
    state = null;
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
