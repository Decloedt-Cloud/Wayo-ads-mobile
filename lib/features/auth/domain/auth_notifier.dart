import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/auth_force_logout_hub.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/network/auth_remote.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/push/push_registration_lifecycle.dart';
import '../../../core/push/user_push_notifications_preference.dart';
import '../../../core/push/wayo_push_device_register.dart';
import '../../../core/push/wayo_push_service.dart';
import '../../../core/push/system_push_permission.dart';
import '../../../core/result.dart';
import '../../../core/storage/secure_storage.dart';
import '../../chat/presentation/providers/chat_providers.dart';
import '../../creator/presentation/providers/creator_session_gate.dart';
import '../../account_deletion/presentation/providers/account_deletion_providers.dart';
import '../../creator_campaigns/presentation/providers/creator_campaigns_providers.dart';
import '../../creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../../creator_wallet/presentation/providers/creator_wallet_providers.dart';
import '../../wallet/presentation/providers/advertiser_wallet_providers.dart';
import '../../dashboard/data/dashboard_hive_store.dart';
import '../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../home_widgets/services/widget_refresh_service.dart';
import '../data/auth_login_method_store.dart';
import '../data/google_sign_in_facade.dart';
import '../data/models/app_user.dart';
import '../data/models/auth_response.dart';
import '../data/models/register_request.dart';
import '../../app_settings/data/mobile_session_register.dart';
import '../data/repositories/auth_repository.dart';
import '../passkey/passkey_exceptions.dart';
import '../passkey/passkey_service.dart';
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

/// Outcome of email/password registration (before optional OTP step).
enum RegisterOutcome {
  authenticated,
  needsEmailVerification,
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  /// Prevents overlapping email/password or Google login calls (double-tap / IME).
  bool _credentialLoginInFlight = false;

  /// Coalesce concurrent `/api/auth/user` pulls (avoids upstream 429 on cold start).
  Future<void>? _profileRefreshFut;

  /// Last successful [`refreshProfileFromAuthServer`] completion (JWT unchanged).
  DateTime? _lastProfileRefreshUtc;

  /// Starts of `GET /api/auth/user` — limits bursty [force: true] from tab switches / UI.
  DateTime? _lastAuthUserFetchStartUtc;

  /// After a Wayo-ads profile PATCH, Auth_Wayo can lag briefly. Prefer the local
  /// session name/avatar until this UTC instant, then take Auth as source of truth.
  DateTime? _localProfileOverrideUntil;

  static const Duration _localProfileOverrideTtl = Duration(seconds: 90);

  @override
  Future<AuthState> build() async {
    setAuthForceLogoutHandler(forceLogout);
    ref.onDispose(clearAuthForceLogoutHandler);

    setFcmTokenBackendRegistrationCallback(
      (
        _, {
        PushRegisterReason reason = PushRegisterReason.tokenRefresh,
      }) =>
          _syncPushTokenBestEffort(reason: reason),
    );
    ref.onDispose(() => setFcmTokenBackendRegistrationCallback(null));

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
          AuthInterceptor.resetSessionState();
          allowPushRegistrationAfterAuth();
          final merged = _preserveExistingRoleIfNeeded(existingUser, data.user);
          await _persistAuthWithUser(storage, data, merged);
          unawaited(_syncPushTokenBestEffort(reason: PushRegisterReason.appStart));
          _registerMobileSessionBestEffort();
          return AuthAuthenticated(merged);
        case Failure():
          await storage.clearAll();
          return const AuthUnauthenticated();
      }
    }

    // Session valid — reset any stale invalidation flags.
    AuthInterceptor.resetSessionState();
    allowPushRegistrationAfterAuth();
    unawaited(_syncPushTokenBestEffort(reason: PushRegisterReason.appStart));
    _registerMobileSessionBestEffort();
    return AuthAuthenticated(existingUser);
  }

  void _registerMobileSessionBestEffort() {
    unawaited(
      registerMobileWayoSession(
        wayoAdsDio: ref.read(wayoAdsDioProvider),
        storage: ref.read(secureStorageProvider),
      ).catchError((_) {}),
    );
  }

  Future<void> login(String email, String password) async {
    if (_credentialLoginInFlight) {
      return;
    }
    _credentialLoginInFlight = true;
    try {
      state = const AsyncValue.data(AuthLoading());
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.login(
        email: email,
        password: password,
      );
      switch (result) {
        case Success(:final data):
          await _finalizeSuccessfulLogin(
            data,
            loginMethod: AuthLoginMethod.email,
          );
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
          await _finalizeSuccessfulLogin(
            data,
            loginMethod: AuthLoginMethod.google,
          );
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
          await _finalizeSuccessfulLogin(
            data,
            loginMethod: AuthLoginMethod.apple,
          );
        case Failure(:final error):
          state = AsyncValue.error(error, StackTrace.current);
      }
    } finally {
      _credentialLoginInFlight = false;
    }
  }

  /// Native WebAuthn / passkey login via Auth_Wayo (same Passport session as password/OAuth).
  Future<void> loginWithPasskey() async {
    if (_credentialLoginInFlight) {
      return;
    }
    _credentialLoginInFlight = true;
    try {
      state = const AsyncValue.data(AuthLoading());
      final data =
          await ref.read(passkeyServiceProvider).loginWithPasskey();
      await _finalizeSuccessfulLogin(
        data,
        loginMethod: AuthLoginMethod.passkey,
      );
    } on PasskeyCancelled {
      state = const AsyncValue.data(AuthUnauthenticated());
      rethrow;
    } on PasskeyException {
      state = const AsyncValue.data(AuthUnauthenticated());
      rethrow;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _credentialLoginInFlight = false;
    }
  }

  /// Email/password signup — role is chosen before this step (web parity).
  Future<RegisterOutcome?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (_credentialLoginInFlight) {
      // Avoid a silent no-op if a previous auth call is still winding down.
      var spins = 0;
      while (_credentialLoginInFlight && spins < 40) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        spins++;
      }
      if (_credentialLoginInFlight) {
        state = AsyncValue.error(
          const ServerException('Registration already in progress'),
          StackTrace.current,
        );
        return null;
      }
    }
    _credentialLoginInFlight = true;
    try {
      state = const AsyncValue.data(AuthLoading());
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.register(
        RegisterRequest(
          name: name.trim(),
          email: email.trim(),
          password: password,
          role: role,
        ),
      );
      switch (result) {
        case Success():
          // Web parity: register never opens a session — OTP first, then login
          // (mobile `app_key` can return tokens + email_verified before OTP).
          state = const AsyncValue.data(AuthUnauthenticated());
          return RegisterOutcome.needsEmailVerification;
        case Failure(:final error):
          state = AsyncValue.error(error, StackTrace.current);
          return null;
      }
    } finally {
      _credentialLoginInFlight = false;
    }
  }

  /// OAuth signup after role pick — applies role when Auth returns `unknown`.
  Future<void> signupWithGoogle(String idToken, String role) async {
    await loginWithGoogle(idToken);
    if (state.hasError) return;
    await _ensureWayoAdsRoleAfterSignup(role);
  }

  Future<void> signupWithApple({
    required String role,
    required String identityToken,
    required String rawNonce,
    String? authorizationCode,
    String? appleUserId,
  }) async {
    await loginWithApple(
      identityToken: identityToken,
      rawNonce: rawNonce,
      authorizationCode: authorizationCode,
      appleUserId: appleUserId,
    );
    if (state.hasError) return;
    await _ensureWayoAdsRoleAfterSignup(role);
  }

  Future<void> _ensureWayoAdsRoleAfterSignup(String role) async {
    final snap = state.valueOrNull;
    if (snap is! AuthAuthenticated) return;
    if (snap.user.wayoAdsRole != WayoAdsAccountRole.unknown) return;
    final r = await ref.read(authRepositoryProvider).setWayoAdsAppRole(role);
    switch (r) {
      case Success(:final data):
        await applyOnboardingUser(data);
      case Failure():
        break;
    }
  }

  /// Shared login finalization: saves tokens, updates state, triggers background tasks.
  ///
  /// - Clears stale session data
  /// - Saves tokens to secure storage
  /// - Waits briefly for token propagation to all Dio interceptors
  /// - Sets authenticated state (triggers dependent providers)
  /// - Triggers background tasks (chat, push) without blocking
  ///
  /// Note: We skip `refreshProfileFromAuthServer` here because:
  /// 1. The login response already contains fresh user data
  /// 2. Calling it immediately risks 429 rate limits on `/api/auth/user`
  /// 3. The web version doesn't make this extra call either
  Future<void> _finalizeSuccessfulLogin(
    AuthResponse data, {
    AuthLoginMethod? loginMethod,
  }) async {
    if (loginMethod != null) {
      unawaited(AuthLoginMethodStore.save(loginMethod));
    }
    AuthInterceptor.resetSessionState();
    _resetDashboardNetworkSpacing();
    await resetPushDeliveryForAccountSwitch();
    allowPushRegistrationAfterAuth();
    await dismissAllWayoLocalPushNotifications();
    await DashboardHiveStore.clearAll();
    markSessionBootstrapStarted(ref);
    ref.read(chatPostLoginGateProvider.notifier).state = DateTime.now();
    invalidateChatProvidersSync(ref);
    await _persistAuth(ref.read(secureStorageProvider), data);
    // Brief delay so secure storage + Dio interceptors see the new access token.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _lastProfileRefreshUtc = DateTime.now().toUtc();
    _lastAuthUserFetchStartUtc = DateTime.now().toUtc();
    state = AsyncValue.data(AuthAuthenticated(data.user));
    invalidateRoleSessionProviders(ref);
    unawaited(_bootstrapChatAfterLogin().catchError((_) {}));
    _invalidateDashboardProviders();
    if (data.user.wayoAdsRole == WayoAdsAccountRole.creator) {
      unawaited(_prefetchCreatorWalletAfterLogin());
    }
    unawaited(_syncPushTokenBestEffort(reason: PushRegisterReason.login));
    _registerMobileSessionBestEffort();
    // Clear previous account widget snapshot before publishing the new one.
    final accountHash = sha256
        .convert(utf8.encode('${data.user.id}'))
        .toString()
        .substring(0, 12);
    unawaited(() async {
      await ref.read(widgetRefreshServiceProvider).onAccountSwitch(accountHash);
      await ref.read(widgetRefreshServiceProvider).refresh(force: true);
    }());
  }

  /// Lets Auth / Wayo-ads persist the session before [GET /api/chat/token] to avoid
  /// transient 500s right after password or Google sign-in.
  Future<void> _prefetchCreatorWalletAfterLogin() async {
    try {
      await ref.read(creatorWalletPageProvider.future);
    } catch (_) {}
  }

  Future<void> _bootstrapChatAfterLogin() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (var round = 0; round < 2; round++) {
      try {
        await ref.read(chatBootstrapProvider.future);
        await ref.read(chatConversationsProvider.future);
        ref.read(chatPostLoginGateProvider.notifier).state = null;
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[Chat] post-login warmup failed (round ${round + 1}): $e',
          );
        }
        ref.invalidate(chatBootstrapProvider);
        ref.invalidate(chatConversationsProvider);
        if (round == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
    ref.read(chatPostLoginGateProvider.notifier).state = null;
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

    final now = DateTime.now().toUtc();
    if (!force &&
        _lastProfileRefreshUtc != null &&
        now.difference(_lastProfileRefreshUtc!) <
            const Duration(seconds: 150)) {
      return;
    }
    if (force &&
        _lastAuthUserFetchStartUtc != null &&
        now.difference(_lastAuthUserFetchStartUtc!) <
            const Duration(seconds: 10)) {
      return;
    }
    _lastAuthUserFetchStartUtc = now;

    final fut = Future<void>(() async {
      final snap = state.valueOrNull;
      if (snap is! AuthAuthenticated) {
        return;
      }
      final currentUser = snap.user;
      final result = await ref.read(authRepositoryProvider).fetchCurrentUser();
      switch (result) {
        case Success(:final data):
          final merged = _mergeAuthRefreshPreservingSessionProfile(
            currentUser,
            data,
          );
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

  /// Auth_Wayo `GET /user` can lag behind a fresh Wayo-ads profile PATCH (avatar/name).
  /// Outside that short window, prefer Auth so greetings/settings never stick on an old name.
  AppUser _mergeAuthRefreshPreservingSessionProfile(
    AppUser current,
    AppUser fresh,
  ) {
    final merged = _preserveExistingRoleIfNeeded(current, fresh);
    final sessionName = current.name?.trim();
    final authName = merged.name?.trim();
    final overrideActive = _localProfileOverrideUntil != null &&
        DateTime.now().toUtc().isBefore(_localProfileOverrideUntil!);

    if (overrideActive) {
      return AppUser(
        id: merged.id,
        email: merged.email,
        name: (sessionName != null && sessionName.isNotEmpty)
            ? current.name
            : merged.name,
        // Keep local avatar (including cleared) until Auth catches up.
        avatar: current.avatar,
        wayoAdsRole: merged.wayoAdsRole,
        appRoles: merged.appRoles,
        emailVerified: merged.emailVerified,
        pendingOnboarding: merged.pendingOnboarding,
      );
    }

    if (authName != null &&
        authName.isNotEmpty &&
        sessionName != null &&
        sessionName.isNotEmpty &&
        authName == sessionName) {
      _localProfileOverrideUntil = null;
    }

    return AppUser(
      id: merged.id,
      email: merged.email,
      name: (authName != null && authName.isNotEmpty) ? merged.name : current.name,
      avatar: merged.avatar ?? current.avatar,
      wayoAdsRole: merged.wayoAdsRole,
      appRoles: merged.appRoles,
      emailVerified: merged.emailVerified,
      pendingOnboarding: merged.pendingOnboarding,
    );
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
  Future<void> applyOnboardingUser(AppUser user) async {
    AuthInterceptor.resetSessionState();
    markSessionBootstrapStarted(ref);
    ref.read(chatPostLoginGateProvider.notifier).state = DateTime.now();
    await _persistUserOnly(user);
    await refreshAuthSessionAfterRoleChange(user);
    ref.read(accountDeletionScheduledAtProvider.notifier).clearScheduledAt();
    await refreshProfileFromAuthServer(force: true);
    invalidateRoleSessionProviders(ref);
    _invalidateDashboardProviders();
    if (user.wayoAdsRole == WayoAdsAccountRole.creator) {
      unawaited(_warmCreatorSessionAfterOnboarding());
    } else if (user.wayoAdsRole == WayoAdsAccountRole.advertiser) {
      unawaited(_prefetchAdvertiserWalletAfterLogin());
    }
    unawaited(_bootstrapChatAfterLogin().catchError((_) {}));
    unawaited(
      ref
          .read(accountDeletionScheduledAtProvider.notifier)
          .syncFromRemote(bypassCache: true)
          .catchError((_) {}),
    );
    unawaited(_syncPushTokenBestEffort(reason: PushRegisterReason.login));
  }

  /// Refreshes JWT after role onboarding so Wayo-ads mutations see CREATOR/ADVERTISER claims.
  Future<bool> refreshAuthSessionAfterRoleChange([AppUser? knownUser]) async {
    final snap = state.valueOrNull;
    final current = knownUser ??
        (snap is AuthAuthenticated ? snap.user : null);
    if (current == null) return false;

    final storage = ref.read(secureStorageProvider);
    final refreshed = await AuthRemote.refreshFromStorage(storage);
    switch (refreshed) {
      case Success(:final data):
        AuthInterceptor.resetSessionState();
        var merged = _preserveExistingRoleIfNeeded(current, data.user);
        if (merged.wayoAdsRole == WayoAdsAccountRole.unknown &&
            current.wayoAdsRole != WayoAdsAccountRole.unknown) {
          merged = current;
        }
        await _persistAuthWithUser(storage, data, merged);
        state = AsyncValue.data(AuthAuthenticated(merged));
        return true;
      case Failure():
        return false;
    }
  }

  /// Provisions Wayo-ads creator endpoints after role pick (delete → re-login path).
  Future<void> _warmCreatorSessionAfterOnboarding() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    try {
      await ref.read(creatorApplicationsProvider.future);
    } catch (_) {}
    const browseKey = (
      page: 1,
      search: '',
      typeApi: null,
      nicheApi: null,
      countryApi: null,
    );
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await ref.read(creatorBrowseCampaignsPagedProvider(browseKey).future);
        return;
      } catch (_) {
        if (attempt >= 4) break;
        ref.invalidate(creatorBrowseCampaignsPagedProvider);
        await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
      }
    }
    try {
      await ref.read(creatorWalletPageProvider.future);
    } catch (_) {}
  }

  Future<void> _prefetchAdvertiserWalletAfterLogin() async {
    try {
      await ref.read(advertiserWalletPageProvider.future);
    } catch (_) {}
  }

  /// Mirrors Wayo-ads profile PATCH into the local auth session (header, settings).
  Future<void> applyLocalProfileUpdate({
    String? name,
    String? imageUrl,
    bool removeImage = false,
  }) async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) return;
    final u = current.user;
    _localProfileOverrideUntil =
        DateTime.now().toUtc().add(_localProfileOverrideTtl);
    await _persistUserOnly(
      AppUser(
        id: u.id,
        email: u.email,
        name: name ?? u.name,
        avatar: removeImage ? null : (imageUrl ?? u.avatar),
        wayoAdsRole: u.wayoAdsRole,
        appRoles: u.appRoles,
        emailVerified: u.emailVerified,
        pendingOnboarding: u.pendingOnboarding,
      ),
    );
  }

  Future<void> _persistUserOnly(AppUser user) async {
    await ref
        .read(secureStorageProvider)
        .saveUserJson(jsonEncode(user.toJson()));
    state = AsyncValue.data(AuthAuthenticated(user));
  }

  Future<void> logout() async {
    _lastProfileRefreshUtc = null;
    _lastAuthUserFetchStartUtc = null;
    _localProfileOverrideUntil = null;
    // Block token-refresh re-register BEFORE DELETE, then clear auth.
    await unregisterWayoPushDeviceOnLogout(
      wayoAdsDio: ref.read(wayoAdsDioProvider),
      prefs: ref.read(appPrefsProvider),
      reason: PushUnregisterReason.logout,
    );
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Token may already be invalid; still clear local session.
    }
    await DashboardHiveStore.clearAll();
    await ref.read(secureStorageProvider).clearAll();
    unawaited(AuthLoginMethodStore.clear());
    state = const AsyncValue.data(AuthUnauthenticated());
    clearSessionBootstrap(ref);
    invalidateRoleSessionProviders(ref);
    _invalidateDashboardAndChatProviders();
    await GoogleSignInFacade.signOutFromGoogle();
    unawaited(ref.read(widgetRefreshServiceProvider).clearForLogout());
  }

  void forceLogout() {
    _resetDashboardNetworkSpacing();
    _lastProfileRefreshUtc = null;
    _lastAuthUserFetchStartUtc = null;
    _localProfileOverrideUntil = null;
    // Block registration immediately so in-flight token refresh cannot POST.
    PushRegistrationGate.block(reason: 'force_logout');
    unawaited(deactivatePushDelivery());
    unawaited(dismissAllWayoLocalPushNotifications());
    unawaited(AuthLoginMethodStore.clear());
    state = const AsyncValue.data(AuthUnauthenticated());
    clearSessionBootstrap(ref);
    unawaited(_clearLocalSessionAfterForcedLogout());
  }

  Future<void> _clearLocalSessionAfterForcedLogout() async {
    await unregisterWayoPushDeviceOnLogout(
      wayoAdsDio: ref.read(wayoAdsDioProvider),
      prefs: ref.read(appPrefsProvider),
      reason: PushUnregisterReason.forceLogout,
    );
    await DashboardHiveStore.clearAll();
    await ref.read(secureStorageProvider).clearAll();
    clearSessionBootstrap(ref);
    invalidateRoleSessionProviders(ref);
    _invalidateDashboardAndChatProviders();
    await GoogleSignInFacade.signOutFromGoogle();
    unawaited(ref.read(widgetRefreshServiceProvider).clearForLogout());
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

  void _resetDashboardNetworkSpacing() {
    ref.read(dashboardRateLimiterProvider).reset();
    ref.read(notificationsRateLimiterProvider).reset();
    ref.read(requestDeduplicatorProvider).clear();
  }

  /// Re-registers FCM with Wayo-ads after the app returns to foreground.
  /// Heals stale/missing server tokens without requiring the user to toggle push.
  Future<void> syncPushRegistrationOnResume() =>
      _syncPushTokenBestEffort(reason: PushRegisterReason.resumeRefresh);

  Future<void> _syncPushTokenBestEffort({
    PushRegisterReason reason = PushRegisterReason.login,
  }) async {
    try {
      final auth = ref.read(authNotifierProvider).valueOrNull;
      if (auth is! AuthAuthenticated) {
        logPushLifecycle('sync: skipped — not authenticated');
        return;
      }
      if (PushRegistrationGate.isBlocked) {
        // Reopen for intentional auth-ready / foreground / heal syncs only.
        // Never reopen when the user opted out of push.
        final mayReopen = reason == PushRegisterReason.login ||
            reason == PushRegisterReason.appStart ||
            reason == PushRegisterReason.resumeRefresh ||
            reason == PushRegisterReason.forceHeal ||
            reason == PushRegisterReason.tokenRefresh ||
            reason == PushRegisterReason.userEnabled;
        if (mayReopen) {
          final prefs = ref.read(appPrefsProvider);
          if (!await isUserPushNotificationsEnabled(prefs)) {
            logPushLifecycle(
              'sync: skipped — gate blocked + user disabled '
              '(reason=${reason.name})',
            );
            return;
          }
          allowPushRegistrationAfterAuth();
        } else {
          logPushLifecycle(
            'sync: skipped — gate blocked reason=${reason.name}',
          );
          return;
        }
      }
      if (!wayoFirebaseCoreReady) {
        await initializeFirebaseForPush();
      }
      if (!wayoFirebaseCoreReady) {
        logPushLifecycle('sync: skipped — Firebase not ready');
        return;
      }
      await attachForegroundFcmHandlers();
      final prefs = ref.read(appPrefsProvider);
      if (!await isUserPushNotificationsEnabled(prefs)) {
        logPushLifecycle('sync: skipped — user disabled push');
        return;
      }
      var osGranted = await areSystemPushNotificationsGranted();
      if (!osGranted && Platform.isIOS && wayoFirebaseCoreReady) {
        osGranted = await requestSystemPushPermission();
      }
      if (!osGranted && Platform.isIOS) {
        logPushLifecycle(
          'sync: iOS notification permission not granted — skipping register',
        );
        return;
      }
      if (!osGranted && Platform.isAndroid) {
        logPushLifecycle(
          'sync: Android POST_NOTIFICATIONS not granted — continuing register',
        );
      }
      final ok = await ensureWayoPushDeviceRegistered(
        wayoAdsDio: ref.read(wayoAdsDioProvider),
        prefs: prefs,
        reason: reason,
      );
      logPushLifecycle('sync: register result=$ok reason=${reason.name}');
    } catch (e, st) {
      logPushLifecycle('sync: failed: $e', error: e, stackTrace: st);
    }
  }
}
