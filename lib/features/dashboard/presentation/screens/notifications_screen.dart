import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/dashboard_state_providers.dart';
import '../widgets/creator_application_notification_actions.dart';

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
        title: Builder(
          builder: (context) {
            final role = GoRouterState.of(context).uri.queryParameters['role'];
            final String? subtitle = switch (role) {
              'creator' => t.dashboard.account_creator,
              'advertiser' => t.dashboard.account_advertiser,
              _ => null,
            };
            if (subtitle == null) {
              return Text(
                t.dashboard.notifications_title,
                style: AppTextStyles.pageTitle(context),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.dashboard.notifications_title,
                  style: AppTextStyles.pageTitle(context),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            );
          },
        ),
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
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = list[i];
                return _NotificationTile(
                  item: n,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    if (!n.isRead) {
                      await ref
                          .read(notificationsRepositoryProvider)
                          .markRead(n.id);
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
    return Card(
      elevation: 0,
      color: item.isRead
          ? AppColors.surfaceElevatedOf(context)
          : AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isRead
              ? AppColors.borderOf(context).withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!item.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 15,
                      ),
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                    CreatorApplicationNotificationActions(item: item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
