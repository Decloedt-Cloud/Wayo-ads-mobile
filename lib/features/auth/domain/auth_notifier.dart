import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/auth_force_logout_hub.dart';
import '../../../core/network/auth_remote.dart';
import '../../../core/result.dart';
import '../../../core/storage/secure_storage.dart';
import '../../chat/presentation/providers/chat_providers.dart';
import '../../dashboard/data/dashboard_hive_store.dart';
import '../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../data/google_sign_in_facade.dart';
import '../data/models/app_user.dart';
import '../data/models/auth_response.dart';
import '../data/repositories/auth_repository.dart';
import 'wayo_ads_account_role.dart';

part 'auth_notifier.g.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AppUser user;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  /// Prevents overlapping email/password or Google login calls (double-tap / IME).
  bool _credentialLoginInFlight = false;

  /// Coalesce concurrent `/api/auth/user` pulls (avoids upstream 429 on cold start).
  Future<void>? _profileRefreshFut;

  /// Last successful [`refreshProfileFromAuthServer`] completion (JWT unchanged).
  DateTime? _lastProfileRefreshUtc;

  @override
  Future<AuthState> build() async {
    setAuthForceLogoutHandler(forceLogout);
    ref.onDispose(clearAuthForceLogoutHandler);

    try {
      return await _restoreSessionOnColdStart().timeout(
        const Duration(seconds: 25),
      );
    } on TimeoutException catch (e, st) {
      if (kDebugMode) {
        debugPrint('Auth cold start timed out (clearing local session): $e\n$st');
      }
      final storage = ref.read(secureStorageProvider);
      await storage.clearAll();
      return const AuthUnauthenticated();
    }
  }

  Future<AuthState> _restoreSessionOnColdStart() async {
    final storage = ref.read(secureStorageProvider);
    final access = await storage.getAccessToken();
    if (access == null || access.isEmpty) {
      return const AuthUnauthenticated();
    }

    final userJson = await storage.getUserJson();
    if (userJson == null || userJson.isEmpty) {
      await storage.clearAll();
      return const AuthUnauthenticated();
    }

    AppUser? existingUser;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      existingUser = AppUser.fromJson(map);
    } catch (_) {
      await storage.clearAll();
      return const AuthUnauthenticated();
    }

    final expired = await storage.isTokenExpired();
    if (expired) {
      final refreshed = await AuthRemote.refreshFromStorage(storage);
      switch (refreshed) {
        case Success(:final data):
          final merged = _preserveExistingRoleIfNeeded(existingUser, data.user);
          await _persistAuthWithUser(storage, data, merged);
          return AuthAuthenticated(merged);
        case Failure():
          await storage.clearAll();
          return const AuthUnauthenticated();
      }
    }

    return AuthAuthenticated(existingUser);
  }

  Future<void> login(String email, String password) async {
    if (_credentialLoginInFlight) {
      return;
    }
    _credentialLoginInFlight = true;
    try {
      state = const AsyncValue.data(AuthLoading());
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.login(email: email, password: password);
      switch (result) {
        case Success(:final data):
          await DashboardHiveStore.clearAll();
          await _persistAuth(ref.read(secureStorageProvider), data);
          invalidateChatProviders(ref);
          try {
            await _bootstrapChatAfterLogin();
          } catch (_) {}
          state = AsyncValue.data(AuthAuthenticated(data.user));
          await refreshProfileFromAuthServer(force: true);
          _invalidateDashboardProviders();
        case Failure(:final error):
          state = AsyncValue.error(error, StackTrace.current);
      }
    } finally {
      _credentialLoginInFlight = false;
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    if (_credentialLoginInFlight) {
      return;
    }
    _credentialLoginInFlight = true;
    try {
      state = const AsyncValue.data(AuthLoading());
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.loginWithGoogle(idToken: idToken);
      switch (result) {
        case Success(:final data):
          await DashboardHiveStore.clearAll();
          await _persistAuth(ref.read(secureStorageProvider), data);
          invalidateChatProviders(ref);
          try {
            await _bootstrapChatAfterLogin();
          } catch (_) {}
          state = AsyncValue.data(AuthAuthenticated(data.user));
          await refreshProfileFromAuthServer(force: true);
          _invalidateDashboardProviders();
        case Failure(:final error):
          state = AsyncValue.error(error, StackTrace.current);
      }
    } finally {
      _credentialLoginInFlight = false;
    }
  }

  Future<void> loginWithApple({
    required String identityToken,
    required String rawNonce,
    String? authorizationCode,
    String? appleUserId,
  }) async {
    if (_credentialLoginInFlight) {
      return;
    }
    _credentialLoginInFlight = true;
    try {
      state = const AsyncValue.data(AuthLoading());
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.loginWithApple(
        identityToken: identityToken,
        rawNonce: rawNonce,
        authorizationCode: authorizationCode,
        appleUserId: appleUserId,
      );
      switch (result) {
        case Success(:final data):
          await DashboardHiveStore.clearAll();
          await _persistAuth(ref.read(secureStorageProvider), data);
          invalidateChatProviders(ref);
          try {
            await _bootstrapChatAfterLogin();
          } catch (_) {}
          state = AsyncValue.data(AuthAuthenticated(data.user));
          await refreshProfileFromAuthServer(force: true);
          _invalidateDashboardProviders();
        case Failure(:final error):
          state = AsyncValue.error(error, StackTrace.current);
      }
    } finally {
      _credentialLoginInFlight = false;
    }
  }

  /// Lets Auth / Wayo-ads persist the session before [GET /api/chat/token] to avoid
  /// transient 500s right after password or Google sign-in.
  Future<void> _bootstrapChatAfterLogin() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await ref.read(chatBootstrapProvider.future);
  }

  /// Clears a failed login state (e.g. after rate-limit cooldown ends).
  void clearLoginError() {
    if (!state.hasError) return;
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  /// Reloads profile + roles from Auth_Wayo `GET /api/auth/user` (keeps tokens).
  ///
  /// If Auth_Wayo returns no role but the current user already has one (e.g. saved
  /// via Wayo-ads fallback), the existing role is preserved. This handles the case
  /// where the role is stored only in Wayo-ads and Auth_Wayo doesn't know about it.
  ///
  /// [force] — skip client-side throttle (pull-to-refresh, post-login sync).
  Future<void> refreshProfileFromAuthServer({bool force = false}) async {
    if (_profileRefreshFut != null) {
      await _profileRefreshFut;
      return;
    }

    if (!force &&
        _lastProfileRefreshUtc != null &&
        DateTime.now().toUtc().difference(_lastProfileRefreshUtc!) <
            const Duration(seconds: 75)) {
      return;
    }

    final fut = Future<void>(() async {
      final snap = state.valueOrNull;
      if (snap is! AuthAuthenticated) {
        return;
      }
      final currentUser = snap.user;
      final result = await ref.read(authRepositoryProvider).fetchCurrentUser();
      switch (result) {
        case Success(:final data):
          final merged = _preserveExistingRoleIfNeeded(currentUser, data);
          await _persistUserOnly(merged);
          _lastProfileRefreshUtc = DateTime.now().toUtc();
        case Failure():
          break;
      }
    });

    _profileRefreshFut = fut;
    try {
      await fut;
    } finally {
      if (identical(_profileRefreshFut, fut)) {
        _profileRefreshFut = null;
      }
    }
  }

  /// If [freshUser] has no role but [currentUser] does, keep the existing role.
  /// This prevents losing a role that was saved only in Wayo-ads (not Auth_Wayo).
  AppUser _preserveExistingRoleIfNeeded(
    AppUser currentUser,
    AppUser freshUser,
  ) {
    if (freshUser.wayoAdsRole != WayoAdsAccountRole.unknown) {
      return freshUser;
    }
    if (currentUser.wayoAdsRole == WayoAdsAccountRole.unknown) {
      return freshUser;
    }
    return freshUser.withWayoAdsRolePatchedFromApiString(
      currentUser.wayoAdsRole.name.toUpperCase(),
    );
  }

  /// After onboarding API returns an updated [AppUser] (role / email verification).
  Future<void> applyOnboardingUser(AppUser user) => _persistUserOnly(user);

  Future<void> _persistUserOnly(AppUser user) async {
    await ref
        .read(secureStorageProvider)
        .saveUserJson(jsonEncode(user.toJson()));
    state = AsyncValue.data(AuthAuthenticated(user));
  }

  Future<void> logout() async {
    _lastProfileRefreshUtc = null;
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Token may already be invalid; still clear local session.
    }
    await DashboardHiveStore.clearAll();
    await ref.read(secureStorageProvider).clearAll();
    state = const AsyncValue.data(AuthUnauthenticated());
    _invalidateDashboardAndChatProviders();
    await GoogleSignInFacade.signOutFromGoogle();
  }

  void forceLogout() {
    _lastProfileRefreshUtc = null;
    state = const AsyncValue.data(AuthUnauthenticated());
    unawaited(_clearLocalSessionAfterForcedLogout());
  }

  Future<void> _clearLocalSessionAfterForcedLogout() async {
    await DashboardHiveStore.clearAll();
    await ref.read(secureStorageProvider).clearAll();
    _invalidateDashboardAndChatProviders();
    await GoogleSignInFacade.signOutFromGoogle();
  }

  /// Dashboard tiles only — chat is reset separately on login (see [login] / [loginWithGoogle]).
  void _invalidateDashboardProviders() {
    ref.invalidate(dashboardStreamProvider);
    ref.invalidate(notificationsListProvider);
  }

  void _invalidateDashboardAndChatProviders() {
    _invalidateDashboardProviders();
    invalidateChatProviders(ref);
  }

  Future<void> _persistAuth(
    SecureStorageService storage,
    AuthResponse auth,
  ) async {
    await storage.saveAuthSession(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      expiresIn: auth.expiresIn,
      userJson: auth.user.toJson(),
    );
    // Warm read: some devices briefly return null on the first interceptor read
    // right after parallel secure-storage writes.
    await storage.getAccessToken();
  }

  /// Like [_persistAuth] but uses a custom [user] instead of [auth.user].
  /// Used when preserving the existing role during token refresh.
  Future<void> _persistAuthWithUser(
    SecureStorageService storage,
    AuthResponse auth,
    AppUser user,
  ) async {
    await storage.saveAuthSession(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      expiresIn: auth.expiresIn,
      userJson: user.toJson(),
    );
    await storage.getAccessToken();
  }
}
