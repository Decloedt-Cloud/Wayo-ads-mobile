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
import '../../../../core/push/superadmin_withdrawals_refresh_hub.dart';
import '../../superadmin/presentation/providers/superadmin_providers.dart';
import 'providers/dashboard_state_providers.dart';
import 'providers/notifications_feed_providers.dart';

/// How often we refresh superadmin panels while the app is foregrounded.
const Duration _kForegroundSuperadminRefreshInterval = Duration(seconds: 8);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(authNotifierProvider).valueOrNull;
      if (s is AuthAuthenticated) {
        _connectReverbBestEffort(s.user.id);
        _startForegroundPolling();
      }
    });
  }

  @override
  void dispose() {
    clearSuperadminWithdrawalsRefreshHandler();
    _foregroundPollTimer?.cancel();
    _foregroundPollTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state != AppLifecycleState.resumed) {
      _foregroundPollTimer?.cancel();
      _foregroundPollTimer = null;
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
  }

  void _startForegroundPolling() {
    _foregroundPollTimer?.cancel();
    final role = ref.read(authNotifierProvider).valueOrNull;
    final interval = role is AuthAuthenticated &&
            role.user.wayoAdsRole == WayoAdsAccountRole.superAdmin
        ? _kForegroundSuperadminRefreshInterval
        : const Duration(seconds: 20);
    _foregroundPollTimer = Timer.periodic(
      interval,
      (_) {
        if (!mounted) return;
        if (_lifecycle != AppLifecycleState.resumed) return;
        final s = ref.read(authNotifierProvider).valueOrNull;
        if (s is! AuthAuthenticated) return;
        _refreshAdvertiserNow();
      },
    );
  }

  /// Soft refresh — rate limiters inside each repository prevent API spam.
  ///
  /// Invalidates role-specific providers so only the relevant screens
  /// hit the network (e.g. a creator never fires advertiser campaign fetches).
  void _refreshAdvertiserNow() {
    unawaited(
      ref.read(accountDeletionScheduledAtProvider.notifier).syncFromRemote(),
    );
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
      invalidateSuperadminRealtimePanels(ref);
    } else {
      ref.invalidate(advertiserWalletPageProvider);
      ref.invalidate(creatorBusinessProfileProvider);
      ref.invalidate(advertiserCampaignsPagedProvider);
      ref.invalidate(advertiserCampaignsCountsProvider);
      ref.invalidate(advertiserCampaignDetailProvider);
      invalidateAdvertiserVideoReviews(ref);
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
        } else {
          _disconnectReverbBestEffort();
          _foregroundPollTimer?.cancel();
          _foregroundPollTimer = null;
        }
      });
    });

    return widget.child;
  }
}
