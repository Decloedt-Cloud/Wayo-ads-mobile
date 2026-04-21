import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../chat/presentation/providers/chat_providers.dart';
import '../dashboard/domain/entities/campaign_status.dart';
import '../dashboard/presentation/providers/dashboard_state_providers.dart';
import 'widgets/wayo_bottom_nav.dart';

/// Main shell with bottom navigation (Dashboard, Campaigns, Chat).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationUnread = ref.watch(
      dashboardStreamProvider.select(
        (async) => async.valueOrNull?.unreadCount ?? 0,
      ),
    );
    final chatUnread = ref
        .watch(chatConversationsProvider)
        .maybeWhen(
          data: (list) => list.fold<int>(0, (sum, c) => sum + c.unreadCount),
          orElse: () => 0,
        );
    final campaignsAttentionCount = ref.watch(
      dashboardStreamProvider.select(
        (async) =>
            async.valueOrNull?.campaigns
                .where((c) => c.status == CampaignStatus.draft)
                .length ??
            0,
      ),
    );

    return Scaffold(
      extendBody: true,
      body: SizedBox.expand(child: navigationShell),
      bottomNavigationBar: WayoBottomNav(
        navigationShell: navigationShell,
        notificationUnread: notificationUnread,
        chatUnread: chatUnread,
        campaignsAttentionCount: campaignsAttentionCount,
      ),
    );
  }
}
