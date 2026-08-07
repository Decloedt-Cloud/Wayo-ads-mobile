import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account_deletion/presentation/providers/account_deletion_providers.dart';
import '../../advertiser_campaigns/presentation/providers/advertiser_campaigns_providers.dart';
import '../../advertiser_video_reviews/presentation/providers/advertiser_video_reviews_providers.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/wayo_ads_account_role.dart';
import '../../creator_campaigns/presentation/providers/creator_campaigns_providers.dart';
import '../../creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../../creator_wallet/presentation/providers/creator_wallet_providers.dart';
import '../../wallet/presentation/providers/advertiser_wallet_providers.dart';
import '../../../../core/network/auth_force_logout_hub.dart';
import '../../../../core/network/auth_remote.dart';
import '../../../../core/push/account_deletion_refresh_hub.dart';
import '../../../../core/push/session_revocation_refresh_hub.dart';
import '../../../../core/push/superadmin_withdrawals_refresh_hub.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../app_settings/presentation/providers/active_sessions_providers.dart';
import '../../superadmin/presentation/providers/superadmin_providers.dart';
import '../../profile/presentation/providers/user_profile_providers.dart';
import 'providers/dashboard_state_providers.dart';
import 'providers/notifications_feed_providers.dart';
import '../../shell/presentation/providers/shell_navigation_providers.dart';

/// How often we refresh superadmin panels while the app is foregrounded.
const Duration _kForegroundSuperadminRefreshInterval = Duration(seconds: 12);

/// Safety-net poll while foregrounded. Reverb push is the fast path; this only
/// catches missed events and keeps badge counts fresh without hammering every tab.
const Duration _kForegroundSafetyNetInterval = Duration(seconds: 45);

/// Safety-net interval for the session-revocation watchdog while foregrounded.
///
/// Real-time revocation is delivered by push (Reverb `sessions.changed` in
/// foreground, FCM data message in background — both routed to
/// [_runSessionRevocationCheck]). This slow poll + the immediate check on resume
/// only exist to catch the rare case where BOTH the socket and the push were
/// missed. It deliberately stays infrequent to spare mobile battery/network.
const Duration _kSessionWatchdogInterval = Duration(seconds: 15);

/// Global Reverb: connects as soon as the user is signed in (any tab), not only on [DashboardScreen].
class RealtimeDashboardWire extends ConsumerStatefulWidget {
  const RealtimeDashboardWire({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RealtimeDashboardWire> createState() =>
      _RealtimeDashboardWireState();
}

class _RealtimeDashboardWireState extends ConsumerState<RealtimeDashboardWire>
    with WidgetsBindingObserver {
  Timer? _foregroundPollTimer;
  Timer? _sessionWatchdogTimer;
  bool _sessionCheckInFlight = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  void _connectReverbBestEffort(int userId) {
    unawaited(
      ref.read(wayoReverbRealtimeProvider).connectForUser(userId),
    );
  }

  void _disconnectReverbBestEffort() {
    unawaited(ref.read(wayoReverbRealtimeProvider).disconnect());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setSuperadminWithdrawalsRefreshHandler(() {
      if (!mounted) return;
      invalidateSuperadminWithdrawalData(ref);
    });
    // FCM `sessions.changed` control message → refresh the active sessions list
    // and re-validate this session (force logout if it was the one revoked).
    setSessionsChangedHandler(() {
      if (!mounted) return;
      ref.invalidate(activeSessionsProvider);
      unawaited(_runSessionRevocationCheck());
    });
    setAccountDeletionRefreshHandler((payload) {
      if (!mounted) return;
      final notifier = ref.read(accountDeletionScheduledAtProvider.notifier);
      if (payload != null && payload.isNotEmpty) {
        notifier.applyRealtimeSignal(payload);
      } else {
        unawaited(notifier.syncFromRemote());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(authNotifierProvider).valueOrNull;
      if (s is AuthAuthenticated) {
        _connectReverbBestEffort(s.user.id);
        _startForegroundPolling();
        _startSessionWatchdog();
      }
    });
  }

  @override
  void dispose() {
    clearSuperadminWithdrawalsRefreshHandler();
    clearSessionsChangedHandler();
    clearAccountDeletionRefreshHandler();
    _foregroundPollTimer?.cancel();
    _foregroundPollTimer = null;
    _stopSessionWatchdog();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state != AppLifecycleState.resumed) {
      _foregroundPollTimer?.cancel();
      _foregroundPollTimer = null;
      _stopSessionWatchdog();
      return;
    }
    if (!mounted) return;
    final s = ref.read(authNotifierProvider).valueOrNull;
    if (s is! AuthAuthenticated) {
      return;
    }
    // WebSockets are often closed while the app is in background; reconnect on resume.
    _connectReverbBestEffort(s.user.id);
    _refreshAdvertiserNow();
    _startForegroundPolling();
    // Catch a revoke that happened while the app was backgrounded immediately,
    // then resume periodic checks.
    _startSessionWatchdog();
  }

  void _startForegroundPolling() {
    _foregroundPollTimer?.cancel();
    final role = ref.read(authNotifierProvider).valueOrNull;
    final interval = role is AuthAuthenticated &&
            role.user.wayoAdsRole == WayoAdsAccountRole.superAdmin
        ? _kForegroundSuperadminRefreshInterval
        : _kForegroundSafetyNetInterval;
    _foregroundPollTimer = Timer.periodic(
      interval,
      (_) {
        if (!mounted) return;
        if (_lifecycle != AppLifecycleState.resumed) return;
        final s = ref.read(authNotifierProvider).valueOrNull;
        if (s is! AuthAuthenticated) return;
        _refreshForegroundSafetyNet();
      },
    );
  }

  /// Session-revocation watchdog (parity with web `SessionRevocationWatchdog`).
  ///
  /// Runs an immediate authoritative check, then re-checks every
  /// [_kSessionWatchdogInterval] while foregrounded. Only runs while the app is
  /// resumed and the user is authenticated.
  void _startSessionWatchdog() {
    _sessionWatchdogTimer?.cancel();
    unawaited(_runSessionRevocationCheck());
    _sessionWatchdogTimer = Timer.periodic(_kSessionWatchdogInterval, (_) {
      if (!mounted) return;
      if (_lifecycle != AppLifecycleState.resumed) return;
      unawaited(_runSessionRevocationCheck());
    });
  }

  void _stopSessionWatchdog() {
    _sessionWatchdogTimer?.cancel();
    _sessionWatchdogTimer = null;
  }

  /// Directly asks Auth_Wayo whether the current access token is still valid.
  ///
  /// Bypasses the app [Dio] interceptor (no refresh, no cooldown, no rate
  /// limiter) so a remote revoke ends the session in near real time. Only an
  /// explicit rejection ([TokenValidity.invalid]) forces logout — a network /
  /// timeout / 5xx ([TokenValidity.indeterminate]) never does.
  Future<void> _runSessionRevocationCheck() async {
    if (!mounted) return;
    if (_sessionCheckInFlight) return;
    if (ref.read(authNotifierProvider).valueOrNull is! AuthAuthenticated) return;
    _sessionCheckInFlight = true;
    try {
      final token = await ref.read(secureStorageProvider).getAccessToken();
      if (token == null || token.isEmpty) return;
      final validity = await AuthRemote.verifyAccessToken(token);
      if (!mounted) return;
      if (validity == TokenValidity.invalid) {
        notifyAuthForceLogout();
      }
    } catch (_) {
      // Inconclusive — never force logout.
    } finally {
      _sessionCheckInFlight = false;
    }
  }

  /// Full refresh on resume / explicit pull — invalidates role-specific providers.
  void _refreshAdvertiserNow() {
    unawaited(
      ref.read(accountDeletionScheduledAtProvider.notifier).syncFromRemote(),
    );
    unawaited(ref.read(userProfileProvider.notifier).syncRemoteAndAuth());
    ref.invalidate(dashboardStreamProvider);
    ref.invalidate(notificationsListProvider);
    ref.invalidate(notificationsUnreadCountsProvider);
    ref.invalidate(notificationsFeedProvider);
    final role = ref.read(authNotifierProvider).valueOrNull is AuthAuthenticated
        ? (ref.read(authNotifierProvider).valueOrNull as AuthAuthenticated)
              .user
              .wayoAdsRole
        : WayoAdsAccountRole.unknown;
    if (role == WayoAdsAccountRole.creator) {
      ref.invalidate(creatorStatsProvider);
      ref.invalidate(creatorApplicationsProvider);
      ref.invalidate(creatorWalletPageProvider);
      ref.invalidate(creatorStripeStatusProvider);
      ref.invalidate(creatorBusinessProfileProvider);
      ref.invalidate(creatorBrowseCampaignsPagedProvider);
      // Detail + submissions: both are family providers; invalidating the
      // family re-fetches every currently-watched instance (e.g. the detail
      // screen the creator is looking at right now).
      ref.invalidate(creatorCampaignDetailProvider);
      ref.invalidate(creatorMySubmissionsProvider);
    } else if (role == WayoAdsAccountRole.superAdmin) {
      invalidateSuperadminRealtimePanelsForWidget(ref);
    } else {
      ref.invalidate(advertiserWalletPageProvider);
      ref.invalidate(creatorBusinessProfileProvider);
      ref.invalidate(advertiserCampaignsPagedProvider);
      ref.invalidate(advertiserCampaignsCountsProvider);
      ref.invalidate(advertiserCampaignDetailProvider);
      invalidateAdvertiserVideoReviews(ref);
    }
  }

  /// Lightweight periodic refresh — only touches data for the visible tab plus
  /// global badge counts. Avoids rebuild/API storms on off-screen tabs.
  void _refreshForegroundSafetyNet() {
    ref.invalidate(notificationsUnreadCountsProvider);
    ref.invalidate(dashboardStreamProvider);

    final role = ref.read(authNotifierProvider).valueOrNull is AuthAuthenticated
        ? (ref.read(authNotifierProvider).valueOrNull as AuthAuthenticated)
              .user
              .wayoAdsRole
        : WayoAdsAccountRole.unknown;
    final tab = ref.read(shellCurrentIndexProvider);

    switch (tab) {
      case 0:
        if (role == WayoAdsAccountRole.creator) {
          ref.invalidate(creatorStatsProvider);
          ref.invalidate(creatorApplicationsProvider);
        } else if (role == WayoAdsAccountRole.superAdmin) {
          invalidateSuperadminRealtimePanelsForWidget(ref);
        } else if (role == WayoAdsAccountRole.advertiser) {
          ref.invalidate(advertiserWalletPageProvider);
        }
      case 1:
        if (role == WayoAdsAccountRole.creator) {
          ref.invalidate(creatorBrowseCampaignsPagedProvider);
          ref.invalidate(creatorApplicationsProvider);
        } else if (role == WayoAdsAccountRole.advertiser) {
          ref.invalidate(advertiserCampaignsPagedProvider);
          ref.invalidate(advertiserCampaignsCountsProvider);
        }
      case 2:
        if (role == WayoAdsAccountRole.creator) {
          ref.invalidate(creatorWalletPageProvider);
          ref.invalidate(creatorStripeStatusProvider);
        } else if (role == WayoAdsAccountRole.advertiser) {
          ref.invalidate(advertiserWalletPageProvider);
        }
      case 3:
        break;
      case 4:
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeInvalidationProvider);

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      next.whenData((s) {
        if (s is AuthAuthenticated) {
          _connectReverbBestEffort(s.user.id);
          _startForegroundPolling();
          _startSessionWatchdog();
        } else {
          _disconnectReverbBestEffort();
          _foregroundPollTimer?.cancel();
          _foregroundPollTimer = null;
          _stopSessionWatchdog();
        }
      });
    });

    return widget.child;
  }
}
