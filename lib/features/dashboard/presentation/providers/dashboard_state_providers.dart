import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/rate_limiter.dart';
import '../../../../core/network/request_deduplicator.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/realtime/reverb_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../domain/entities/notification_item.dart';

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
    authDio: ref.watch(dioProvider),
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

/// SWR stream for dashboard (Hive + network + rate limits).
final dashboardStreamProvider = StreamProvider<DashboardSnapshot>((ref) {
  ref.keepAlive();
  return ref.watch(dashboardRepositoryProvider).watchDashboard();
});

final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationItem>>((ref) {
      return ref.watch(notificationsRepositoryProvider).fetchNotifications();
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

/// Listens to Reverb and invalidates dashboard providers (no [StreamProvider] — avoids hanging tests).
final realtimeInvalidationProvider = Provider<void>((ref) {
  final sub = ref.watch(wayoReverbRealtimeProvider).signals.listen((sig) {
    if (sig.name.startsWith('pusher:')) {
      return;
    }
    final name = sig.name;
    final notif = _isNotificationCreatedRealtimeEvent(name);
    if (name == 'balance.updated' || name == 'campaign.updated' || notif) {
      ref.invalidate(dashboardStreamProvider);
    }
    if (notif) {
      ref.invalidate(notificationsListProvider);
    }
  });
  ref.onDispose(sub.cancel);
});
