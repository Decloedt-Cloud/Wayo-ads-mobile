import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/advertiser_balance.dart';
import '../../domain/entities/campaign_platform.dart';
import '../../domain/entities/campaign_status.dart';
import '../../domain/entities/campaign_summary.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/advertiser_campaigns_page_result.dart';

/// Remote calls for dashboard (Auth_Wayo + Wayo-ads).
///
/// Paths align with `Wayo-ads/src/app/api/**` (Next.js App Router).
abstract interface class DashboardRemote {
  Future<UserProfile> fetchUser();

  Future<AdvertiserBalance> fetchBalance();

  Future<AdvertiserCampaignsPageResult> fetchCampaignsPage({
    int page = 1,
    int limit = 10,
  });

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
  Future<AdvertiserCampaignsPageResult> fetchCampaignsPage({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await _adsDio.get<Map<String, dynamic>>(
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.campaigns),
      queryParameters: {'advertiserOnly': 'true', 'page': page, 'limit': limit},
    );
    final data = res.data;
    if (data == null) {
      return AdvertiserCampaignsPageResult(
        campaigns: const [],
        total: 0,
        page: page,
        totalPages: 1,
      );
    }
    dynamic list = data['campaigns'];
    if (list is! List<dynamic>) {
      list = data['data'] is List<dynamic>
          ? data['data'] as List<dynamic>
          : const [];
    }
    final campaigns = list.map((e) {
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
        coverUrl: parseCampaignCoverUrlFromJson(m) ??
            m['cover_url'] as String? ??
            m['coverUrl'] as String? ??
            m['coverImageUrl'] as String?,
        brandLogoUrl: parseCampaignBrandLogoFromJson(m),
        campaignType: CreatorCampaignType.fromApi(m['type']),
        createdAt: _parseDateTime(m['createdAt'] ?? m['created_at']),
        lockedBudgetCents: _parseCents(
          m['lockedBudget'] ?? m['lockedBudgetCents'],
        ),
        spentBudgetCents: _parseCents(
          m['spentBudgetCents'] ?? m['spentBudget'],
        ),
      );
    }).toList();

    final total = _parseInt(data['total'], campaigns.length);
    final pageNum = _parseInt(data['page'], page);
    var totalPages = _parseInt(data['totalPages'], 0);
    if (totalPages < 1) {
      totalPages = total > 0 ? (total + limit - 1) ~/ limit : 1;
    }

    AdvertiserBudgetRollup? rollup;
    final rawRollup = data['budgetRollup'];
    if (rawRollup is Map) {
      final rm = Map<String, dynamic>.from(rawRollup);
      rollup = AdvertiserBudgetRollup(
        lockedCents: _parseCents(rm['lockedCents']),
        spentCents: _parseCents(rm['spentCents']),
      );
    }

    return AdvertiserCampaignsPageResult(
      campaigns: campaigns,
      total: total,
      page: pageNum,
      totalPages: totalPages,
      budgetRollup: rollup,
    );
  }

  static int _parseInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
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
      final meta = _mergeNotificationMetadata(m);
      return NotificationItem(
        id: '${m['id'] ?? ''}',
        title: m['title'] as String? ?? '',
        body: m['message'] as String? ?? m['body'] as String? ?? '',
        isRead: isRead,
        createdAt: _parseDateTime(m['createdAt'] ?? m['created_at']),
        priority: m['priority'] as String?,
        type: m['type'] as String? ?? m['notificationType'] as String?,
        actionUrl: m['actionUrl'] as String?,
        metadata: meta,
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

  /// Normalises notification payload for mobile: some APIs put `campaignId` / `applicationId`
  /// on the root object, expose `meta`/`payload`, or JSON-stringify metadata.
  static Map<String, dynamic>? _mergeNotificationMetadata(
    Map<String, dynamic> envelope,
  ) {
    Map<String, dynamic>? parseMap(dynamic raw) {
      if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return null;
    }

    final rawMeta =
        envelope['metadata'] ?? envelope['meta'] ?? envelope['payload'];
    Map<String, dynamic>? parsed;
    if (rawMeta is String && rawMeta.trim().isNotEmpty) {
      try {
        final d = jsonDecode(rawMeta.trim());
        if (d is Map) {
          parsed = Map<String, dynamic>.from(d);
        }
      } catch (_) {}
    }
    parsed ??= parseMap(rawMeta);

    final out = <String, dynamic>{};
    if (parsed != null) {
      out.addAll(parsed);
    }
    void takeFromRoot(String canonical, List<String> keys) {
      for (final k in keys) {
        final v = envelope[k];
        if (v != null) {
          out[canonical] = v;
          return;
        }
      }
    }

    takeFromRoot('campaignId', ['campaignId', 'campaign_id']);
    takeFromRoot('applicationId', [
      'applicationId',
      'application_id',
      'creatorApplicationId',
      'creator_application_id',
    ]);

    final dataBlock = envelope['data'];
    if (dataBlock is Map) {
      final dm = Map<String, dynamic>.from(dataBlock);
      void pickFromBlock(String canon, List<String> keys) {
        for (final k in keys) {
          final v = dm[k];
          if (v != null) {
            out.putIfAbsent(canon, () => v);
            return;
          }
        }
      }

      pickFromBlock('campaignId', ['campaignId', 'campaign_id']);
      pickFromBlock('applicationId', [
        'applicationId',
        'application_id',
        'creatorApplicationId',
      ]);
      if (!out.containsKey('application')) {
        final a = dm['application'];
        if (a is Map) {
          out['application'] = Map<String, dynamic>.from(a);
        }
      }
    }

    final appTop = envelope['application'];
    if (appTop is Map && out['application'] == null) {
      out['application'] = Map<String, dynamic>.from(appTop);
    }

    final link =
        envelope['actionUrl'] ??
        envelope['action_url'] ??
        envelope['deeplink'] ??
        envelope['url'];
    if (link is String && link.isNotEmpty) {
      _mergeIdsFromActionUrl(out, link);
    }

    if (out.isEmpty) {
      return null;
    }
    return out;
  }

  /// Fills [out] with `campaignId` / `applicationId` from deep links or web paths.
  static void _mergeIdsFromActionUrl(Map<String, dynamic> out, String raw) {
    try {
      final uri = Uri.parse(raw);
      for (final e in uri.queryParameters.entries) {
        final k = e.key.toLowerCase();
        if ((k == 'campaignid' || k == 'campaign_id') &&
            out['campaignId'] == null &&
            e.value.isNotEmpty) {
          out['campaignId'] = e.value;
        }
        if ((k == 'applicationid' ||
                k == 'application_id' ||
                k == 'creatorapplicationid') &&
            out['applicationId'] == null &&
            e.value.isNotEmpty) {
          out['applicationId'] = e.value;
        }
      }
      final segments = uri.pathSegments;
      for (var i = 0; i + 1 < segments.length; i++) {
        if (segments[i] == 'campaigns') {
          if (out['campaignId'] == null && segments[i + 1].isNotEmpty) {
            out['campaignId'] = segments[i + 1];
          }
        } else if (segments[i] == 'applications') {
          if (out['applicationId'] == null &&
              i + 1 < segments.length &&
              segments[i + 1].isNotEmpty) {
            out['applicationId'] = segments[i + 1];
          }
        }
      }
    } catch (_) {}
  }
}
