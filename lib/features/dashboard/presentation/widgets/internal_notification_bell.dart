import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_state_providers.dart';
import 'notification_center_popup.dart';

/// Notification bell + unread badge (advertiser, creator, superadmin dashboards).
class InternalNotificationBell extends ConsumerWidget {
  const InternalNotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(notificationsUnreadCountsProvider);
    final streamUnread =
        ref.watch(dashboardStreamProvider).valueOrNull?.unreadCount;
    final unread = counts.valueOrNull?.total ?? streamUnread ?? 0;

    return Material(
      color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.65),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          showNotificationCenterPopup(context, ref);
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
              ),
              if (unread > 0)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
