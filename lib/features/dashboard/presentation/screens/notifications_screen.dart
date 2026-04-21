import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/dashboard_state_providers.dart';

/// Simple notifications list with mark-as-read.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final async = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: Text(t.dashboard.notifications_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(notificationsListProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(notificationsListProvider);
          await ref.read(notificationsListProvider.future);
        },
        child: async.when(
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(t.dashboard.notifications_empty)),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final n = list[i];
                return _NotificationTile(
                  item: n,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    if (!n.isRead) {
                      await ref.read(notificationsRepositoryProvider).markRead(n.id);
                      ref.invalidate(notificationsListProvider);
                      ref.invalidate(dashboardStreamProvider);
                    }
                  },
                );
              },
            );
          },
          loading: () => const Skeletonizer(
                enabled: true,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(title: Text('x'), subtitle: Text('y')),
                      ListTile(title: Text('x'), subtitle: Text('y')),
                    ],
                  ),
                ),
              ),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: item.isRead ? null : AppColors.primary.withValues(alpha: 0.06),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
          color: AppColors.textPrimaryOf(context),
        ),
      ),
      subtitle: Text(item.body, maxLines: 3, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
