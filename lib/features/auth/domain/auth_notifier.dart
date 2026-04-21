import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/auth_force_logout_hub.dart';
import '../../../core/network/auth_remote.dart';
import '../../../core/result.dart';
import '../../../core/storage/secure_storage.dart';
import '../../chat/presentation/providers/chat_providers.dart';
import '../../dashboard/data/dashboard_hive_store.dart';
import '../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../data/models/app_user.dart';
import '../data/models/auth_response.dart';
import '../data/repositories/auth_repository.dart';

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

  @override
  Future<AuthState> build() async {
    setAuthForceLogoutHandler(forceLogout);
    ref.onDispose(clearAuthForceLogoutHandler);

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

    final expired = await storage.isTokenExpired();
    if (expired) {
      final refreshed = await AuthRemote.refreshFromStorage(storage);
      switch (refreshed) {
        case Success(:final data):
          await _persistAuth(storage, data);
          return AuthAuthenticated(data.user);
        case Failure():
          await storage.clearAll();
          return const AuthUnauthenticated();
      }
    }

    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      final user = AppUser.fromJson(map);
      return AuthAuthenticated(user);
    } catch (_) {
      await storage.clearAll();
      return const AuthUnauthenticated();
    }
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
            await ref.read(chatBootstrapProvider.future);
          } catch (_) {}
          state = AsyncValue.data(AuthAuthenticated(data.user));
          await refreshProfileFromAuthServer();
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
            await ref.read(chatBootstrapProvider.future);
          } catch (_) {}
          state = AsyncValue.data(AuthAuthenticated(data.user));
          await refreshProfileFromAuthServer();
          _invalidateDashboardProviders();
        case Failure(:final error):
          state = AsyncValue.error(error, StackTrace.current);
      }
    } finally {
      _credentialLoginInFlight = false;
    }
  }

  /// Clears a failed login state (e.g. after rate-limit cooldown ends).
  void clearLoginError() {
    if (!state.hasError) return;
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  /// Reloads profile + roles from Auth_Wayo `GET /api/auth/user` (keeps tokens).
  Future<void> refreshProfileFromAuthServer() async {
    final s = state.valueOrNull;
    if (s is! AuthAuthenticated) {
      return;
    }
    final result = await ref.read(authRepositoryProvider).fetchCurrentUser();
    switch (result) {
      case Success(:final data):
        await _persistUserOnly(data);
      case Failure():
        break;
    }
  }

  Future<void> _persistUserOnly(AppUser user) async {
    await ref.read(secureStorageProvider).saveUserJson(jsonEncode(user.toJson()));
    state = AsyncValue.data(AuthAuthenticated(user));
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Token may already be invalid; still clear local session.
    }
    await DashboardHiveStore.clearAll();
    await ref.read(secureStorageProvider).clearAll();
    state = const AsyncValue.data(AuthUnauthenticated());
    _invalidateDashboardAndChatProviders();
  }

  void forceLogout() {
    state = const AsyncValue.data(AuthUnauthenticated());
    unawaited(_clearLocalSessionAfterForcedLogout());
  }

  Future<void> _clearLocalSessionAfterForcedLogout() async {
    await DashboardHiveStore.clearAll();
    await ref.read(secureStorageProvider).clearAll();
    _invalidateDashboardAndChatProviders();
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

  Future<void> _persistAuth(SecureStorageService storage, AuthResponse auth) async {
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
}
