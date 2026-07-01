import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../data/user_profile_remote_datasource.dart';
import '../../domain/wayo_ads_user_profile.dart';

/// Warm the profile cache before navigating to [ProfileSettingsScreen].
void prefetchUserProfile(WidgetRef ref) {
  unawaited(ref.read(userProfileProvider.future));
}

Future<void>? _profileRemoteSyncFut;

/// Pulls Wayo-ads profile + mirrors name/avatar into the auth session (web parity).
Future<void> syncUserProfileFromRemote(
  Ref ref, {
  bool refreshAuth = true,
}) async {
  if (_profileRemoteSyncFut != null) {
    await _profileRemoteSyncFut;
    return;
  }
  final fut = () async {
    await ref.read(userProfileProvider.notifier).syncRemoteAndAuth(
          refreshAuth: refreshAuth,
        );
  }();
  _profileRemoteSyncFut = fut;
  try {
    await fut;
  } finally {
    if (identical(_profileRemoteSyncFut, fut)) {
      _profileRemoteSyncFut = null;
    }
  }
}

final userProfileRemoteProvider = Provider<UserProfileRemoteDatasource>(
  (ref) => UserProfileRemoteDatasource(ref.watch(wayoAdsDioProvider)),
);

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, WayoAdsUserProfile>(
      UserProfileNotifier.new,
    );

class UserProfileNotifier extends AsyncNotifier<WayoAdsUserProfile> {
  @override
  Future<WayoAdsUserProfile> build() async {
    ref.keepAlive();
    return _load(force: false);
  }

  Future<WayoAdsUserProfile> _load({required bool force}) {
    return ref
        .read(userProfileRemoteProvider)
        .fetchProfile(bypassCache: force);
  }

  Future<void> refresh({bool force = true}) async {
    final previous = state;
    state = const AsyncValue<WayoAdsUserProfile>.loading().copyWithPrevious(previous);
    state = await AsyncValue.guard(() => _load(force: force));
  }

  /// Background sync — no loading spinner (foreground poll / Reverb).
  Future<void> syncFromRemote() async {
    try {
      final updated = await _load(force: true);
      final prev = state.valueOrNull;
      final sameName = prev?.name == updated.name;
      final sameImage = prev?.image == updated.image;
      if (prev != null && sameName && sameImage) {
        return;
      }
      state = AsyncData(updated);
      await _mirrorProfileIntoAuth(updated);
    } catch (_) {
      // Best-effort — foreground poll retries on the next tick.
    }
  }

  /// Wayo-ads profile + optional Auth_Wayo refresh (web / Reverb parity).
  Future<void> syncRemoteAndAuth({bool refreshAuth = true}) async {
    await syncFromRemote();
    if (refreshAuth) {
      await ref
          .read(authNotifierProvider.notifier)
          .refreshProfileFromAuthServer(force: false);
    }
  }

  Future<void> _mirrorProfileIntoAuth(WayoAdsUserProfile updated) async {
    final resolvedAvatar = normalizeWayoAdsMediaUrl(updated.image);
    final noImage = updated.image == null || updated.image!.trim().isEmpty;
    await ref.read(authNotifierProvider.notifier).applyLocalProfileUpdate(
          name: updated.name,
          imageUrl: resolvedAvatar,
          removeImage: noImage,
        );
  }

  Future<WayoAdsUserProfile> save({
    required String name,
    String? imageBase64,
    bool removeImage = false,
  }) async {
    final trimmed = name.trim();
    final updated = await ref.read(userProfileRemoteProvider).updateProfile(
          name: trimmed,
          image: imageBase64,
          removeImage: removeImage,
        );
    state = AsyncData(updated);
    await _mirrorProfileIntoAuth(updated);
    await ref
        .read(authNotifierProvider.notifier)
        .refreshProfileFromAuthServer(force: true);
    return updated;
  }
}
