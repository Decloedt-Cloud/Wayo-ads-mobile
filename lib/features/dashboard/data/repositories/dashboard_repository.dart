import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/request_deduplicator.dart';
import '../../../../core/network/rate_limiter.dart';
import '../../../../core/storage/secure_storage.dart';
import '../dashboard_hive_store.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../../domain/entities/advertiser_balance.dart';
import '../../domain/entities/campaign_platform.dart';
import '../../domain/entities/campaign_status.dart';
import '../../domain/entities/campaign_summary.dart';
import '../../domain/entities/user_profile.dart';

/// Cached + fresh dashboard payload with isolated section errors (no global crash).
final class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({
    required this.user,
    this.balance,
    this.campaigns = const [],
    this.unreadCount = 0,
    this.userError,
    this.balanceError,
    this.campaignsError,
    this.unreadError,
  });

  final UserProfile? user;
  final AdvertiserBalance? balance;
  final List<CampaignSummary> campaigns;
  final int unreadCount;
  final AuthException? userError;
  final AuthException? balanceError;
  final AuthException? campaignsError;
  final AuthException? unreadError;

  bool get hasUser => user != null;

  @override
  List<Object?> get props => [
        user,
        balance,
        campaigns,
        unreadCount,
        userError,
        balanceError,
        campaignsError,
        unreadError,
      ];
}

/// Loads dashboard data with SWR (Hive), deduplication, and per-endpoint rate limits.
abstract interface class DashboardRepository {
  Stream<DashboardSnapshot> watchDashboard();
}

final class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required DashboardRemote remote,
    required RequestDeduplicator deduplicator,
    required RateLimiter rateLimiter,
    required SecureStorageService secureStorage,
  })  : _remote = remote,
        _deduplicator = deduplicator,
        _rate = rateLimiter,
        _storage = secureStorage;

  final DashboardRemote _remote;
  final RequestDeduplicator _deduplicator;
  final RateLimiter _rate;
  final SecureStorageService _storage;

  /// One cache entry per logged-in user so account switches never reuse another user's Hive row.
  static String _hiveKeyForUserId(int? userId) =>
      userId != null ? 'overview_v2_u$userId' : 'overview_v2_anon';

  Future<String> _hiveCacheKey() async {
    final j = await _storage.getUserJson();
    if (j == null || j.isEmpty) {
      return _hiveKeyForUserId(null);
    }
    try {
      final m = jsonDecode(j) as Map<String, dynamic>;
      final idVal = m['id'];
      final id = idVal is int
          ? idVal
          : idVal is num
              ? idVal.toInt()
              : int.tryParse('$idVal');
      return _hiveKeyForUserId(id);
    } catch (_) {
      return _hiveKeyForUserId(null);
    }
  }

  @override
  Stream<DashboardSnapshot> watchDashboard() async* {
    try {
      final cacheKey = await _hiveCacheKey();
      final cached = _readCache(cacheKey);
      if (cached != null) {
        yield cached;
      }
      yield await _loadSnapshot(seed: cached, cacheKey: cacheKey);
    } catch (e) {
      // Never tear down the stream on an unexpected failure: show recoverable state.
      yield DashboardSnapshot(user: null, userError: _map(e));
    }
  }

  Future<DashboardSnapshot> _loadSnapshot({
    DashboardSnapshot? seed,
    required String cacheKey,
  }) async {
    UserProfile? user = seed?.user;
    AuthException? userErr;

    try {
      user = await _deduplicator.run('dashboard_user', () => _remote.fetchUser());
      userErr = null;
    } catch (e) {
      userErr = _map(e);
      if (user == null) {
        return DashboardSnapshot(user: null, userError: userErr);
      }
    }

    AuthException? balanceErr;
    AdvertiserBalance? balance = seed?.balance;
    if (_rate.canCall(DashboardRateLimiterKeys.balance)) {
      try {
        balance = await _deduplicator.run(
          'dashboard_balance',
          () => _remote.fetchBalance(),
        );
        _rate.mark(DashboardRateLimiterKeys.balance);
      } catch (e) {
        balanceErr = _map(e);
      }
    } else if (balance == null) {
      balanceErr = const ServerException('Rate limited');
    }

    AuthException? campaignsErr;
    var campaigns = seed?.campaigns ?? const <CampaignSummary>[];
    if (_rate.canCall(DashboardRateLimiterKeys.campaigns)) {
      try {
        campaigns = await _deduplicator.run(
          'dashboard_campaigns',
          () => _remote.fetchCampaigns(),
        );
        _rate.mark(DashboardRateLimiterKeys.campaigns);
      } catch (e) {
        campaignsErr = _map(e);
      }
    } else if (campaigns.isEmpty) {
      campaignsErr = const ServerException('Rate limited');
    }

    if (balance != null && campaignsErr == null) {
      balance = _mergeAdvertiserBalanceFromCampaigns(balance, campaigns);
    }

    AuthException? unreadErr;
    var unread = seed?.unreadCount ?? 0;
    if (_rate.canCall(DashboardRateLimiterKeys.unread)) {
      try {
        unread = await _deduplicator.run(
          'dashboard_unread',
          () => _remote.fetchUnreadCount(),
        );
        _rate.mark(DashboardRateLimiterKeys.unread);
      } catch (e) {
        unreadErr = _map(e);
      }
    }

    // After login, Auth + Wayo-ads requests can race secure storage / JWT; one short
    // delayed retry avoids forcing the user to tap Retry.
    if (user != null &&
        (balanceErr != null ||
            campaignsErr != null ||
            unreadErr != null)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (balanceErr != null) {
        try {
          balance = await _deduplicator.run(
            'dashboard_balance',
            () => _remote.fetchBalance(),
          );
          balanceErr = null;
          _rate.mark(DashboardRateLimiterKeys.balance);
        } catch (e) {
          balanceErr = _map(e);
        }
      }
      if (campaignsErr != null) {
        try {
          campaigns = await _deduplicator.run(
            'dashboard_campaigns',
            () => _remote.fetchCampaigns(),
          );
          campaignsErr = null;
          _rate.mark(DashboardRateLimiterKeys.campaigns);
        } catch (e) {
          campaignsErr = _map(e);
        }
      }
      if (balance != null && campaignsErr == null) {
        balance = _mergeAdvertiserBalanceFromCampaigns(balance, campaigns);
      }
      if (unreadErr != null) {
        try {
          unread = await _deduplicator.run(
            'dashboard_unread',
            () => _remote.fetchUnreadCount(),
          );
          unreadErr = null;
          _rate.mark(DashboardRateLimiterKeys.unread);
        } catch (e) {
          unreadErr = _map(e);
        }
      }
    }

    final snap = DashboardSnapshot(
      user: user,
      balance: balance,
      campaigns: campaigns,
      unreadCount: unread,
      userError: userErr,
      balanceError: balanceErr,
      campaignsError: campaignsErr,
      unreadError: unreadErr,
    );

    await _writeCache(snap, cacheKey);
    return snap;
  }

  DashboardSnapshot? _readCache(String key) {
    final raw = DashboardHiveStore.readFresh(key);
    if (raw == null) {
      return null;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return _snapshotFromJson(m);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(DashboardSnapshot s, String key) async {
    try {
      await DashboardHiveStore.write(key, jsonEncode(_snapshotToJson(s)));
    } catch (_) {}
  }

  DashboardSnapshot _snapshotFromJson(Map<String, dynamic> m) {
    UserProfile? user;
    final u = m['user'];
    if (u is Map<String, dynamic>) {
      user = UserProfile(
        id: (u['id'] as num).toInt(),
        email: u['email'] as String? ?? '',
        firstName: u['firstName'] as String?,
        name: u['name'] as String?,
        avatarUrl: u['avatarUrl'] as String?,
      );
    }
    AdvertiserBalance? balance;
    final b = m['balance'];
    if (b is Map<String, dynamic>) {
      balance = AdvertiserBalance(
        available: (b['available'] as num).toDouble(),
        locked: (b['locked'] as num).toDouble(),
        spent: (b['spent'] as num).toDouble(),
        currency: b['currency'] as String? ?? 'EUR',
      );
    }
    final list = (m['campaigns'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return DashboardSnapshot(
      user: user,
      balance: balance,
      campaigns: list.map(_campaignFromJson).toList(),
      unreadCount: (m['unread'] as num?)?.toInt() ?? 0,
    );
  }

  CampaignSummary _campaignFromJson(Map<String, dynamic> c) {
    return CampaignSummary(
      id: c['id'] as String,
      name: c['name'] as String,
      status: CampaignStatus.fromString(c['status'] as String?),
      platform: CampaignPlatform.fromString(c['platform'] as String?),
      creatorsCount: (c['creatorsCount'] as num).toInt(),
      coverUrl: c['coverUrl'] as String?,
      createdAt:
          c['createdAt'] == null ? null : DateTime.tryParse(c['createdAt'] as String),
      lockedBudgetCents: (c['lockedBudgetCents'] as num?)?.toInt() ??
          (c['lockedBudget'] as num?)?.toInt() ??
          0,
      spentBudgetCents: (c['spentBudgetCents'] as num?)?.toInt() ??
          (c['spentBudget'] as num?)?.toInt() ??
          0,
    );
  }

  /// Dashboard rules: locked = sum of campaign locks for running campaigns;
  /// spent = sum of spent amounts for completed campaigns. [wallet.available] stays from API.
  AdvertiserBalance _mergeAdvertiserBalanceFromCampaigns(
    AdvertiserBalance wallet,
    List<CampaignSummary> campaigns,
  ) {
    var lockedCents = 0;
    var spentCents = 0;
    for (final c in campaigns) {
      switch (c.status) {
        case CampaignStatus.active:
        case CampaignStatus.paused:
          lockedCents += c.lockedBudgetCents;
          break;
        case CampaignStatus.completed:
          spentCents += c.spentBudgetCents;
          break;
        case CampaignStatus.draft:
        case CampaignStatus.unknown:
          break;
      }
    }
    return AdvertiserBalance(
      available: wallet.available,
      locked: lockedCents / 100.0,
      spent: spentCents / 100.0,
      currency: wallet.currency,
    );
  }

  Map<String, dynamic> _snapshotToJson(DashboardSnapshot o) {
    return {
      if (o.user != null)
        'user': {
          'id': o.user!.id,
          'email': o.user!.email,
          'firstName': o.user!.firstName,
          'name': o.user!.name,
          'avatarUrl': o.user!.avatarUrl,
        },
      if (o.balance != null)
        'balance': {
          'available': o.balance!.available,
          'locked': o.balance!.locked,
          'spent': o.balance!.spent,
          'currency': o.balance!.currency,
        },
      'campaigns': o.campaigns
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'status': c.status.name,
              'platform': c.platform.name,
              'creatorsCount': c.creatorsCount,
              'coverUrl': c.coverUrl,
              'createdAt': c.createdAt?.toIso8601String(),
              'lockedBudgetCents': c.lockedBudgetCents,
              'spentBudgetCents': c.spentBudgetCents,
            },
          )
          .toList(),
      'unread': o.unreadCount,
    };
  }

  AuthException _map(Object e) {
    if (e is AuthException) {
      return e;
    }
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const NetworkException();
      }
      return ServerException(e.message ?? 'Request failed');
    }
    return ServerException('$e');
  }
}

/// Rate-limiter keys for dashboard sections.
abstract final class DashboardRateLimiterKeys {
  static const balance = 'balance';
  static const campaigns = 'campaigns';
  static const unread = 'unread_count';
}
