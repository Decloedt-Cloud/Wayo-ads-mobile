import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/push/mobile_push_route_utils.dart';
import '../../../../router/app_router.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../domain/entities/notification_item.dart';
import '../utils/notification_route_resolver.dart';
import '../providers/dashboard_state_providers.dart';
import '../providers/notifications_feed_providers.dart';

void navigateNotificationRoute(GoRouter router, String route) {
  navigateWayoPushRoute(router, route);
}

Future<void> openNotificationItem(WidgetRef ref, NotificationItem item) async {
  if (item.isUnread) {
    await ref.read(notificationsRepositoryProvider).markRead(item.id);
    invalidateAllNotifications(ref);
  }

  final role = ref.read(currentWayoAdsAccountRoleProvider);
  final route = resolveNotificationMobileRoute(item, role);
  if (route == null) return;

  navigateNotificationRoute(ref.read(goRouterProvider), route);
}
