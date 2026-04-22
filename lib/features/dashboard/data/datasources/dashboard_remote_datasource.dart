import 'package:dio/dio.dart';

import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/advertiser_balance.dart';
import '../../domain/entities/campaign_platform.dart';
import '../../domain/entities/campaign_status.dart';
import '../../domain/entities/campaign_summary.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/user_profile.dart';

/// Remote calls for dashboard (Auth_Wayo + Wayo-ads).
///
/// Paths align with `Wayo-ads/src/app/api/**` (Next.js App Router).
abstract interface class DashboardRemote {
  Future<UserProfile> fetchUser();

  Future<AdvertiserBalance> fetchBalance();

  Future<List<CampaignSummary>> fetchCampaigns({int page = 1, int limit = 10});

  Future<List<NotificationItem>> fetchNotifications({bool unreadOnly = false});

  Future<int> fetchUnreadCount();

  Future<void> markNotificationRead(String id);

  Future<void> markAllNotificationsRead();

  Future<void> dismissNotification(String id);
}

final class DashboardRemoteDatasource implements DashboardRemote {
  DashboardRemoteDatasource({required Dio authDio, required Dio adsDio})
    : _authDio = authDio,
      _adsDio = adsDio;

  final Dio _authDio;
  final Dio _adsDio;

  @override
  Future<UserProfile> fetchUser() async {
    final cfg = AuthRuntimeConfig.instance;
    final qp = <String, dynamic>{};
    if (cfg.authAppName.trim().isNotEmpty) {
      qp['app'] = cfg.authAppName.trim();
    }
    final res = await _authDio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.authHttpPath('user'),
      queryParameters: qp.isEmpty ? null : qp,
    );
    final data = res.data;
    if (data == null) {
      throw const ServerException('Empty user response');
    }
    if (data['success'] == false) {
      final msg = data['message'] as String? ?? 'Unauthorized';
      throw ServerException(msg);
    }
    // Auth_Wayo: { success, data: { user: { id, email, name, ... }, scopes } }
    final envelope = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    final userRaw = envelope['user'];
    final root = userRaw is Map<String, dynamic> ? userRaw : envelope;
    final idVal = root['id'];
    final id = idVal is int ? idVal : int.tryParse('$idVal') ?? 0;
    final name = root['name'] as String?;
    final first = root['first_name'] as String? ?? root['firstName'] as String?;
    return UserProfile(
      id: id,
      email: root['email'] as String? ?? '',
      firstName:
          first ??
          (name != null && name.trim().isNotEmpty
              ? name.trim().split(RegExp(r'\s+')).first
              : null),
      name: name,
      avatarUrl: root['avatar'] as String? ?? root['avatar_url'] as String?,
    );
  }

  @override
  Future<AdvertiserBalance> fetchBalance() async {
    final res = await _adsDio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.wallet),
    );
    final data = res.data;
    if (data == null) {
      throw const ServerException('Empty balance');
    }
    final w = data['wallet'];
    if (w is! Map<String, dynamic>) {
      throw const ServerException('Empty wallet');
    }
    double fromCents(dynamic v) =>
        (v is num ? v.toDouble() : double.tryParse('$v') ?? 0) / 100.0;
    return AdvertiserBalance(
      available: fromCents(w['availableCents']),
      locked: fromCents(w['pendingCents']),
      spent: 0,
      currency: (w['currency'] as String?)?.toUpperCase() ?? 'EUR',
    );
  }

  @override
  Future<List<CampaignSummary>> fetchCampaigns({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await _adsDio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.campaigns),
      queryParameters: {'advertiserOnly': 'true', 'page': page, 'limit': limit},
    );
    final data = res.data;
    if (data == null) {
      return const [];
    }
    dynamic list = data['campaigns'];
    if (list is! List<dynamic>) {
      list = data['data'] is List<dynamic>
          ? data['data'] as List<dynamic>
          : const [];
    }
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final id = '${m['id'] ?? ''}';
      final title = m['title'] as String? ?? m['name'] as String? ?? '';
      final platformStr = _primaryPlatformKey(m);
      return CampaignSummary(
        id: id,
        name: title,
        status: CampaignStatus.fromString(m['status'] as String?),
        platform: CampaignPlatform.fromString(platformStr),
        creatorsCount:
            (m['approvedCreators'] as num?)?.toInt() ??
            (m['approved_creators'] as num?)?.toInt() ??
            0,
        coverUrl: m['cover_url'] as String? ?? m['coverUrl'] as String?,
        createdAt: _parseDateTime(m['createdAt'] ?? m['created_at']),
        lockedBudgetCents: _parseCents(
          m['lockedBudget'] ?? m['lockedBudgetCents'],
        ),
        spentBudgetCents: _parseCents(
          m['spentBudgetCents'] ?? m['spentBudget'],
        ),
      );
    }).toList();
  }

  @override
  Future<List<NotificationItem>> fetchNotifications({
    bool unreadOnly = false,
  }) async {
    final qp = <String, dynamic>{'limit': 100};
    if (unreadOnly) {
      qp['status'] = 'UNREAD';
    }
    final res = await _adsDio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.notifications),
      queryParameters: qp,
    );
    final data = res.data;
    if (data == null) {
      return const [];
    }
    dynamic list = data['notifications'];
    if (list is! List<dynamic>) {
      list = const [];
    }
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final delivery = m['delivery'];
      var isRead = false;
      if (delivery is Map<String, dynamic>) {
        isRead = delivery['status'] == 'READ' || delivery['readAt'] != null;
      }
      return NotificationItem(
        id: '${m['id'] ?? ''}',
        title: m['title'] as String? ?? '',
        body: m['message'] as String? ?? m['body'] as String? ?? '',
        isRead: isRead,
        createdAt: _parseDateTime(m['createdAt'] ?? m['created_at']),
        priority: m['priority'] as String?,
        type: m['type'] as String?,
      );
    }).toList();
  }

  @override
  Future<int> fetchUnreadCount() async {
    final res = await _adsDio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.notificationsUnread,
      ),
    );
    final data = res.data;
    if (data == null) {
      return 0;
    }
    final t = data['total'];
    if (t is num) {
      return t.toInt();
    }
    final inner = data['data'];
    if (inner is Map && inner['count'] is num) {
      return (inner['count'] as num).toInt();
    }
    final c = data['count'];
    if (c is num) {
      return c.toInt();
    }
    return 0;
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _adsDio.post<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.notificationsMarkRead,
      ),
      data: <String, dynamic>{'notificationId': id},
    );
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _adsDio.post<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.notificationsMarkAllRead,
      ),
      data: <String, dynamic>{},
    );
  }

  @override
  Future<void> dismissNotification(String id) async {
    await _adsDio.post<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.notificationsDismiss,
      ),
      data: <String, dynamic>{'notificationId': id},
    );
  }

  static int _parseCents(dynamic v) {
    if (v == null) {
      return 0;
    }
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    return int.tryParse('$v') ?? 0;
  }

  static String _primaryPlatformKey(Map<String, dynamic> m) {
    final shorts = m['shortsPlatform'] as String?;
    if (shorts != null && shorts.trim().isNotEmpty) {
      return shorts.trim();
    }
    final platforms = m['platforms'] as String?;
    if (platforms != null && platforms.trim().isNotEmpty) {
      return platforms.split(',').first.trim();
    }
    final type = m['type'] as String?;
    if (type == 'VIDEO' || type == 'SHORTS') {
      return 'youtube';
    }
    return '';
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is String) {
      return DateTime.tryParse(v);
    }
    return null;
  }
}
