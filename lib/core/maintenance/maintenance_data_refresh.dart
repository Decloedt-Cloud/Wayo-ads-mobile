import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/advertiser_campaigns/presentation/providers/advertiser_campaigns_providers.dart';
import '../../features/advertiser_video_reviews/presentation/providers/advertiser_video_reviews_providers.dart';
import '../../features/chat/presentation/providers/chat_providers.dart';
import '../../features/creator_campaigns/presentation/providers/creator_campaigns_providers.dart';
import '../../features/creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../../features/creator_trust/data/creator_trust_remote.dart';
import '../../features/creator_wallet/presentation/providers/creator_wallet_providers.dart';
import '../../features/dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../features/invoices/presentation/providers/invoices_providers.dart';
import '../../features/profile/presentation/providers/user_profile_providers.dart';
import '../../features/superadmin/presentation/providers/superadmin_providers.dart';
import '../../features/wallet/presentation/providers/advertiser_wallet_providers.dart';
import '../../features/youtube_connection/presentation/providers/youtube_providers.dart';

/// Remote-data providers refreshed after maintenance ends.
///
/// Does **not** touch auth, tokens, navigation, locale/theme, or session gates.
/// Observed providers rebuild immediately; others reload on next read.
void refreshAppDataAfterMaintenanceRecovery(Ref ref) {
  ref.read(dashboardRateLimiterProvider).reset();
  ref.read(creatorRateLimiterProvider).reset();
  ref.read(creatorCampaignsRateLimiterProvider).reset();
  ref.read(notificationsRateLimiterProvider).reset();
  ref.read(requestDeduplicatorProvider).clear();

  // Dashboard / advertiser
  ref.invalidate(dashboardStreamProvider);
  ref.invalidate(advertiserWalletPageProvider);
  ref.invalidate(advertiserCampaignsPagedProvider);
  ref.invalidate(advertiserCampaignsCountsProvider);
  ref.invalidate(advertiserDashboardCampaignsPageFetchProvider);
  ref.invalidate(advertiserCampaignDetailProvider);
  ref.read(advertiserBrowseCampaignPageProvider.notifier).state = 1;
  ref.invalidate(advertiserBrowseCampaignsPagedProvider);
  invalidateAdvertiserVideoReviewsProviders(ref);

  // Creator
  ref.invalidate(creatorStatsProvider);
  ref.invalidate(creatorApplicationsProvider);
  ref.invalidate(creatorWalletPageProvider);
  ref.invalidate(creatorBrowseCampaignsPagedProvider);
  ref.invalidate(creatorStripeStatusProvider);
  ref.invalidate(creatorBusinessProfileProvider);
  ref.invalidate(creatorCampaignDetailProvider);
  ref.invalidate(creatorMySubmissionsProvider);
  ref.invalidate(creatorTrustScoreProvider);
  ref.invalidate(youtubeChannelStatusProvider);

  // Shared remote surfaces
  ref.invalidate(invoicesControllerProvider);
  ref.invalidate(notificationsListProvider);
  ref.invalidate(notificationsUnreadCountsProvider);
  ref.invalidate(userProfileProvider);
  ref.invalidate(chatConversationsProvider);
  ref.invalidate(chatBootstrapProvider);

  invalidateSuperadminRealtimePanels(ref);
}
