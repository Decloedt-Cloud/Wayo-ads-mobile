import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../../../../core/network/rate_limiter.dart';
import '../../../../core/network/request_deduplicator.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/realtime/reverb_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../domain/advertiser_campaigns_page_result.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notifications_page_result.dart';
import '../../../account_deletion/presentation/providers/account_deletion_providers.dart';
import '../../../advertiser_campaigns/presentation/providers/advertiser_campaigns_providers.dart';
import '../../../advertiser_video_reviews/presentation/providers/advertiser_video_reviews_providers.dart';
import '../../../advertiser_video_reviews/presentation/providers/advertiser_video_reviews_realtime.dart';
import '../../../creator_campaigns/presentation/providers/creator_campaigns_providers.dart';
import '../../../creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../../../creator_wallet/presentation/providers/creator_wallet_providers.dart';
import '../../../invoices/presentation/providers/invoices_providers.dart';
import '../../../wallet/presentation/providers/advertiser_wallet_providers.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../superadmin/presentation/providers/superadmin_providers.dart';
import '../../../../core/push/wayo_push_intent.dart';

final requestDeduplicatorProvider = Provider<RequestDeduplicator>((ref) {
  ref.keepAlive();
  return RequestDeduplicator();
});

final dashboardRateLimiterProvider = Provider<RateLimiter>((ref) {
  ref.keepAlive();
  return RateLimiter(minInterval: const Duration(seconds: 2));
});

final notificationsRateLimiterProvider = Provider<RateLimiter>((ref) {
  ref.keepAlive();
  return RateLimiter(minInterval: const Duration(seconds: 2));
});

final dashboardRemoteDatasourceProvider = Provider<DashboardRemote>((ref) {
  return DashboardRemoteDatasource(
    authRepository: ref.watch(authRepositoryProvider),
    adsDio: ref.watch(wayoAdsDioProvider),
  );
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  ref.keepAlive();
  return DashboardRepositoryImpl(
    remote: ref.watch(dashboardRemoteDatasourceProvider),
    deduplicator: ref.watch(requestDeduplicatorProvider),
    rateLimiter: ref.watch(dashboardRateLimiterProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(
    remote: ref.watch(dashboardRemoteDatasourceProvider),
    deduplicator: ref.watch(requestDeduplicatorProvider),
    rateLimiter: ref.watch(notificationsRateLimiterProvider),
  );
});

/// Advertiser dashboard campaign list page (1-based). [dashboardStreamProvider] always loads page 1; this drives extra pages.
final advertiserDashboardCampaignPageProvider = StateProvider<int>((ref) => 1);

/// Single page of advertiser campaigns for the dashboard (10 per page).
final advertiserDashboardCampaignsPageFetchProvider = FutureProvider.autoDispose
    .family<AdvertiserCampaignsPageResult, int>((ref, page) async {
      return ref
          .watch(dashboardRemoteDatasourceProvider)
          .fetchCampaignsPage(page: page, limit: 10);
    });

/// SWR stream for dashboard (Hive + network + rate limits).
final dashboardStreamProvider = StreamProvider<DashboardSnapshot>((ref) {
  ref.keepAlive();
  return ref.watch(dashboardRepositoryProvider).watchDashboard();
});

final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationItem>>((ref) {
      return ref.watch(notificationsRepositoryProvider).fetchNotifications();
    });

/// Unread badge for notification bell (all roles including superadmin).
final notificationsUnreadCountsProvider =
    FutureProvider.autoDispose<NotificationsUnreadCounts>((ref) {
      return ref.watch(notificationsRepositoryProvider).fetchUnreadCounts();
    });

final wayoReverbRealtimeProvider = Provider<WayoReverbRealtime>((ref) {
  final rt = WayoReverbRealtime(ref.watch(secureStorageProvider));
  ref.onDispose(() {
    unawaited(rt.dispose());
  });
  return rt;
});

/// Matches Wayo-ads / Laravel notification broadcasts (event names are not always `notification.created`).
bool _isNotificationCreatedRealtimeEvent(String name) {
  final n = name.toLowerCase();
  if (n == 'notification.created') return true;
  if (n == 'usernotificationcreated' ||
      n.endsWith('.usernotificationcreated')) {
    return true;
  }
  if (n.contains('notification') && n.contains('created')) return true;
  if (n.contains('notification') && n.contains('new')) return true;
  return false;
}

/// Listens to Reverb and invalidates dashboard, wallet, campaigns, creator
/// KPIs, applications, and notifications.
final realtimeInvalidationProvider = Provider<void>((ref) {
  final sub = ref.watch(wayoReverbRealtimeProvider).signals.listen((sig) {
    if (sig.name.startsWith('pusher:')) {
      return;
    }
    final name = sig.name;
    final lower = name.toLowerCase();
    final channelLower = sig.channelName?.toLowerCase() ?? '';
    final fromCreatorChannel = channelLower.contains('creator');
    final fromAdvertiserChannel = channelLower.contains('advertiser');
    final videoReviewEvent = shouldRefreshAdvertiserVideoReviews(sig);
    if (kDebugMode) {
      debugPrint(
        '[WayoReverb] event=${sig.name} channel=${sig.channelName ?? '(none)'}',
      );
    }
    final notif = _isNotificationCreatedRealtimeEvent(name);
    final balanceEvent =
        name == 'balance.updated' ||
        (lower.contains('balance') && lower.contains('updat'));
    final campaignEvent =
        name == 'campaign.updated' ||
        (lower.contains('campaign') &&
            (lower.contains('updat') ||
                lower.contains('creat') ||
                lower.contains('delet')));
    // Creator-specific events: application.updated, submission.reviewed,
    // payout.updated, stats.refreshed, analytics.refreshed.
    final applicationEvent =
        lower.contains('application') &&
        (lower.contains('updat') ||
            lower.contains('approv') ||
            lower.contains('reject') ||
            lower.contains('creat'));
    final submissionEvent =
        lower.contains('submission') &&
        (lower.contains('updat') || lower.contains('review'));
    final creatorVideoStatusEvent = shouldRefreshCreatorVideoSubmissions(sig.raw);
    final payoutEvent =
        lower.contains('payout') &&
        (lower.contains('updat') || lower.contains('complet'));
    final statsEvent = lower.contains('stats') || lower.contains('analytics');

    if (balanceEvent || campaignEvent || notif) {
      ref.invalidate(dashboardStreamProvider);
    }
    if (balanceEvent) {
      ref.invalidate(advertiserWalletPageProvider);
    }
    // Invoices are created automatically on the backend whenever a wallet
    // deposit, campaign hold or creator withdrawal completes. Any of these
    // events is a strong signal that a new invoice exists for this user — so
    // we refresh the list eagerly without waiting for the 60s foreground poll.
    if (balanceEvent || payoutEvent) {
      ref.invalidate(invoicesControllerProvider);
    }
    if (campaignEvent || statsEvent) {
      ref.invalidate(advertiserCampaignsPagedProvider);
      ref.invalidate(advertiserCampaignsCountsProvider);
      ref.invalidate(advertiserDashboardCampaignsPageFetchProvider);
      ref.invalidate(advertiserCampaignDetailProvider);
      invalidateAdvertiserBrowseCampaigns(ref);
      final authCampaign = ref.read(authNotifierProvider).valueOrNull;
      if (authCampaign is AuthAuthenticated &&
          authCampaign.user.wayoAdsRole == WayoAdsAccountRole.superAdmin) {
        invalidateSuperadminBrowseCampaigns(ref);
      }
    }
    if (videoReviewEvent || (fromAdvertiserChannel && submissionEvent)) {
      invalidateAdvertiserVideoReviewsProviders(ref);
    }
    if (notif) {
      ref.invalidate(notificationsListProvider);
      ref.invalidate(notificationsUnreadCountsProvider);
      final auth = ref.read(authNotifierProvider).valueOrNull;
      final isSuperadmin = auth is AuthAuthenticated &&
          auth.user.wayoAdsRole == WayoAdsAccountRole.superAdmin;
      if (isSuperadmin || isWithdrawalNotificationPayload(sig.raw)) {
        invalidateSuperadminWithdrawalData(ref);
      }
    }

    final withdrawalEvent = lower.contains('withdrawal') &&
        (lower.contains('creat') ||
            lower.contains('updat') ||
            lower.contains('approv') ||
            lower.contains('cancel') ||
            lower.contains('paid') ||
            lower.contains('valid') ||
            lower.contains('complet') ||
            lower.contains('request'));
    if (withdrawalEvent) {
      invalidateSuperadminWithdrawalData(ref);
    }

    // Creator providers — invalidate on specific events OR when the event
    // comes from the creator channel (covers backend event rename drift).
    if (fromCreatorChannel || statsEvent || payoutEvent || balanceEvent) {
      ref.invalidate(creatorStatsProvider);
    }
    if (fromCreatorChannel ||
        applicationEvent ||
        submissionEvent ||
        campaignEvent ||
        // Wayo-ads frequently ships an application state change as a generic
        // user notification (e.g. `notification.created` with type
        // `APPLICATION_APPROVED`). Refresh the list so the dashboard pill
        // (approved / pending / rejected) stays truthful without a manual pull.
        notif) {
      ref.invalidate(creatorApplicationsProvider);
    }
    // Creator campaigns browse list — refresh whenever a campaign starts or
    // ends (creator eligibility changes) or when the creator applies / gets
    // approved / rejected (stale pills / badges).
    if (fromCreatorChannel || campaignEvent || applicationEvent) {
      ref.invalidate(creatorBrowseCampaignsPagedProvider);
    }
    // Submission reviews update the `myVideos` list inside the detail view;
    // invalidate the family wholesale so open screens re-fetch lazily.
    if (fromCreatorChannel ||
        submissionEvent ||
        applicationEvent ||
        creatorVideoStatusEvent) {
      ref.invalidate(creatorCampaignDetailProvider);
      ref.invalidate(creatorMySubmissionsProvider);
    }
    // Creator wallet — balance changes (payouts, ledger credits) and Stripe
    // onboarding webhooks all flip the same knobs on the backend.
    if (fromCreatorChannel || balanceEvent || payoutEvent) {
      ref.invalidate(creatorWalletPageProvider);
    }
    if (fromCreatorChannel ||
        (lower.contains('stripe') && lower.contains('connect')) ||
        (lower.contains('account') && lower.contains('updat')) ||
        lower.contains('payouts.enabled') ||
        lower.contains('charges.enabled')) {
      ref.invalidate(creatorStripeStatusProvider);
    }
    // Business profile changes rarely — only when explicitly edited or when
    // the backend rewrites it (e.g. currency sync from a payout).
    if (fromCreatorChannel ||
        (lower.contains('business') && lower.contains('profile')) ||
        (lower.contains('business') && lower.contains('updat'))) {
      ref.invalidate(creatorBusinessProfileProvider);
    }

    final accountDeletionEvent = lower.contains('deletion') ||
        (lower.contains('account') &&
            (lower.contains('delete') || lower.contains('purge')));
    if (accountDeletionEvent) {
      unawaited(
        ref.read(accountDeletionScheduledAtProvider.notifier).syncFromRemote(),
      );
    }
  });
  ref.onDispose(sub.cancel);
});

/// Clears cached creator dashboard + campaigns reads after logout / account switch.
void invalidateCreatorSessionProviders(Ref ref) {
  ref.read(creatorRateLimiterProvider).reset();
  ref.read(creatorCampaignsRateLimiterProvider).reset();
  ref.read(requestDeduplicatorProvider).clear();
  ref.read(creatorBrowseCampaignPageProvider.notifier).state = 1;
  ref.read(creatorBrowseCampaignSearchQueryProvider.notifier).state = '';
  Future.microtask(() {
    ref.invalidate(creatorStatsProvider);
    ref.invalidate(creatorApplicationsProvider);
    ref.invalidate(creatorBrowseCampaignsPagedProvider);
    ref.invalidate(creatorCampaignDetailProvider);
    ref.invalidate(creatorMySubmissionsProvider);
    ref.invalidate(creatorTrackingLinksProvider);
  });
}

/// Clears advertiser dashboard reads after logout / account switch.
void invalidateAdvertiserSessionProviders(Ref ref) {
  ref.read(dashboardRateLimiterProvider).reset();
  ref.read(advertiserDashboardCampaignPageProvider.notifier).state = 1;
  ref.read(advertiserCampaignsViewModeProvider.notifier).state =
      AdvertiserCampaignsViewMode.mine;
  ref.read(advertiserBrowseCampaignPageProvider.notifier).state = 1;
  ref.read(advertiserBrowseCampaignSearchProvider.notifier).state = '';
  resetAdvertiserBrowseExplorerFilters(ref);
  Future.microtask(() {
    ref.invalidate(advertiserDashboardCampaignsPageFetchProvider);
    ref.invalidate(dashboardStreamProvider);
    ref.invalidate(advertiserBrowseCampaignsPagedProvider);
  });
}

/// Clears superadmin panel reads after logout / account switch.
void invalidateSuperadminSessionProviders(Ref ref) {
  Future.microtask(() {
    invalidateSuperadminRealtimePanels(ref);
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(payoutStatsProvider);
  });
}

/// All role-specific caches — call after login state + tokens are ready, or on logout.
void invalidateRoleSessionProviders(Ref ref) {
  invalidateCreatorSessionProviders(ref);
  invalidateCreatorWalletProviders(ref);
  invalidateAdvertiserSessionProviders(ref);
  invalidateSuperadminSessionProviders(ref);
}
