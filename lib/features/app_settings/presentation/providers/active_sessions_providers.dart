import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/active_sessions_remote.dart';
import '../../data/mobile_session_register.dart';

final activeSessionsRemoteProvider = Provider<ActiveSessionsRemote>((ref) {
  return ActiveSessionsRemote(ref.watch(wayoAdsDioProvider));
});

/// This device's server-side session id (saved at registration).
///
/// Used by the sessions UI as an authoritative "this device" fallback so the
/// current device can never be shown with a revoke button — even if the server
/// failed to mark it `current` (e.g. the `X-Wayo-Session-Id` header was missing
/// because registration hadn't completed yet).
final mobileSessionIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  return ref.watch(secureStorageProvider).getMobileSessionId();
});

final activeSessionsProvider =
    FutureProvider.autoDispose<List<ActiveSession>>((ref) async {
      // Make sure THIS device is registered before listing. Registration is
      // idempotent server-side; doing it here (and awaiting) guarantees the
      // `X-Wayo-Session-Id` header is present on the list request so the server
      // can reliably flag the current session. This fixes the race where the
      // current device showed a "Revoke" button and could log itself out.
      final storage = ref.watch(secureStorageProvider);
      final existing = await storage.getMobileSessionId();
      if (existing == null || existing.isEmpty) {
        await registerMobileWayoSession(
          wayoAdsDio: ref.watch(wayoAdsDioProvider),
          storage: storage,
        );
        ref.invalidate(mobileSessionIdProvider);
      }
      return ref.watch(activeSessionsRemoteProvider).fetchSessions();
    });
