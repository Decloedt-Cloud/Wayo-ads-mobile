import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advertiser_campaigns/presentation/screens/advertiser_campaigns_screen.dart';
import '../chat/presentation/screens/chat_inbox_screen.dart';
import '../dashboard/presentation/providers/dashboard_state_providers.dart';

/// Campaigns tab — advertiser read-only list (`GET /api/campaigns`).
class CampaignsTabScreen extends ConsumerWidget {
  const CampaignsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dashboardStreamProvider);
    return const AdvertiserCampaignsScreen();
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
