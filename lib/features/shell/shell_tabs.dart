import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advertiser_campaigns/presentation/screens/advertiser_campaigns_screen.dart';
import '../auth/data/models/app_user.dart';
import '../auth/domain/wayo_ads_account_role.dart';
import '../chat/presentation/screens/chat_inbox_screen.dart';
import '../creator_campaigns/presentation/screens/creator_campaigns_tab_screen.dart';
import '../dashboard/presentation/providers/dashboard_state_providers.dart';
import 'shell_tab_signed_in_gate.dart';

/// Campaigns tab — role-branching:
/// - [WayoAdsAccountRole.advertiser] → [AdvertiserCampaignsScreen] (browse + create drafts).
/// - [WayoAdsAccountRole.creator] → [CreatorCampaignsTabScreen] (browse + apply).
class CampaignsTabScreen extends ConsumerWidget {
  const CampaignsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShellTabSignedInGate(
      builder: (context, ref, AppUser user) {
        if (user.wayoAdsRole == WayoAdsAccountRole.creator) {
          return const CreatorCampaignsTabScreen();
        }
        ref.watch(dashboardStreamProvider);
        return const AdvertiserCampaignsScreen();
      },
    );
  }
}

/// Chat tab — Wayo chat-service (same contract as Wayo-ads web).
class ChatTabScreen extends StatelessWidget {
  const ChatTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatInboxScreen();
  }
}
