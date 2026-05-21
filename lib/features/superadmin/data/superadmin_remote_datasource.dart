import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/admin_api_endpoints.dart';
import '../domain/entities/admin_user.dart';
import '../domain/entities/ai_usage.dart';
import '../domain/entities/announcement.dart';
import '../domain/entities/banned_user.dart';
import '../domain/entities/dashboard_stats.dart';
import '../domain/entities/ledger_entry.dart';
import '../domain/entities/withdrawal.dart';

abstract interface class SuperadminRemote {
  // Dashboard
  Future<DashboardStats> fetchDashboardStats({
    int page = 1,
    int limit = 50,
    String? reason,
  });
  
  Future<PayoutStats> fetchPayoutStats();

  // Users Management
  Future<AdminUsersPage> fetchUsers({
    String? search,
    RoleFilter? role,
    JoinedFilter? joined,
    bool? bannedOnly,
    int page = 1,
    int limit = kAdminUsersPageSize,
  });

  // Banned Users
  Future<BannedUsersPage> fetchBannedUsers({
    String? search,
    int limit = 50,
    int offset = 0,
  });

  Future<List<SearchUser>> searchUsers({
    required String search,
    String? role,
    int page = 1,
    int limit = 20,
  });

  Future<void> banUser({
    required String wayoUserId,
    String? reason,
  });

  Future<void> unbanUser(int authUserId);

  // Withdrawals
  Future<WithdrawalsPage> fetchWithdrawals({
    int limit = 50,
    int offset = 0,
    WithdrawalStatus? status,
  });

  Future<Withdrawal> approveWithdrawal(String withdrawalId);

  Future<Withdrawal> cancelWithdrawal(String withdrawalId);

  Future<Withdrawal> markWithdrawalPaid(String withdrawalId);

  // Announcements
  Future<List<Announcement>> fetchAnnouncements();

  Future<Announcement> createAnnouncement(Announcement announcement);

  Future<Announcement> updateAnnouncement(String id, Announcement announcement);

  Future<void> deleteAnnouncement(String id);

  // AI Usage
  Future<AiUsageStats> fetchAiUsage({String period = '30d'});

  // Ledger
  Future<LedgerPage> fetchLedger({
    int page = 1,
    int limit = 50,
    LedgerEntryType? type,
    String? creatorId,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

final class SuperadminRemoteDatasource implements SuperadminRemote {
  SuperadminRemoteDatasource(this._dio);

  final Dio _dio;

  String _path(String endpoint) =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(endpoint);

  @override
  Future<DashboardStats> fetchDashboardStats({
    int page = 1,
    int limit = 50,
    String? reason,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.transactions),
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        if (reason != null) 'reason': reason,
      },
    );
    final data = _extractMap(res.data);
    final summary = data['summary'] as Map<String, dynamic>? ?? data;
    return DashboardStats.fromJson(summary);
  }

  @override
  Future<PayoutStats> fetchPayoutStats() async {
    final res = await _dio.get<Object?>(_path(AdminApiEndpoints.payouts));
    final data = _extractMap(res.data);
    final stats = data['stats'] as Map<String, dynamic>? ?? data;
    return PayoutStats.fromJson(stats);
  }

  @override
  Future<AdminUsersPage> fetchUsers({
    String? search,
    RoleFilter? role,
    JoinedFilter? joined,
    bool? bannedOnly,
    int page = 1,
    int limit = kAdminUsersPageSize,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.usersAll),
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null && role.apiValue != null) 'role': role.apiValue,
        if (joined != null && joined.dateFromIso != null)
          'dateFrom': joined.dateFromIso,
      },
    );
    return AdminUsersPage.fromJson(_extractMap(res.data));
  }

  @override
  Future<BannedUsersPage> fetchBannedUsers({
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.appBans),
      queryParameters: <String, dynamic>{
        'limit': limit.clamp(1, 100),
        'offset': offset,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return BannedUsersPage.fromJson(_extractMap(res.data));
  }

  @override
  Future<List<SearchUser>> searchUsers({
    required String search,
    String? role,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.usersSearch),
      queryParameters: <String, dynamic>{
        'search': search,
        'page': page,
        'limit': limit.clamp(1, 50),
        if (role != null) 'role': role,
      },
    );
    final data = _extractMap(res.data);
    final usersRaw = data['users'];
    if (usersRaw is! List) return [];
    return usersRaw
        .whereType<Map>()
        .map((e) => SearchUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> banUser({
    required String wayoUserId,
    String? reason,
  }) async {
    await _dio.post<Object?>(
      _path(AdminApiEndpoints.appBans),
      data: <String, dynamic>{
        'wayoUserId': wayoUserId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  @override
  Future<void> unbanUser(int authUserId) async {
    await _dio.delete<Object?>(
      _path(AdminApiEndpoints.appBanDelete(authUserId)),
    );
  }

  @override
  Future<WithdrawalsPage> fetchWithdrawals({
    int limit = 50,
    int offset = 0,
    WithdrawalStatus? status,
  }) async {
    String? statusParam;
    if (status != null && status != WithdrawalStatus.unknown) {
      statusParam = status.name.toUpperCase();
      if (status == WithdrawalStatus.paid) {
        statusParam = 'VALIDATED';
      }
    }

    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.withdrawals),
      queryParameters: <String, dynamic>{
        'limit': limit.clamp(1, 100),
        'offset': offset,
        if (statusParam != null) 'status': statusParam,
      },
    );
    return WithdrawalsPage.fromJson(_extractMap(res.data));
  }

  @override
  Future<Withdrawal> approveWithdrawal(String withdrawalId) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.withdrawals),
      data: <String, dynamic>{
        'withdrawalId': withdrawalId,
        'action': 'approve',
      },
    );
    final data = _extractMap(res.data);
    final withdrawal = data['withdrawal'] as Map<String, dynamic>?;
    if (withdrawal == null) {
      throw const FormatException('Invalid withdrawal response');
    }
    return Withdrawal.fromJson(withdrawal);
  }

  @override
  Future<Withdrawal> cancelWithdrawal(String withdrawalId) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.withdrawals),
      data: <String, dynamic>{
        'withdrawalId': withdrawalId,
        'action': 'cancel',
      },
    );
    final data = _extractMap(res.data);
    final withdrawal = data['withdrawal'] as Map<String, dynamic>?;
    if (withdrawal == null) {
      throw const FormatException('Invalid withdrawal response');
    }
    return Withdrawal.fromJson(withdrawal);
  }

  @override
  Future<Withdrawal> markWithdrawalPaid(String withdrawalId) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.withdrawals),
      data: <String, dynamic>{
        'withdrawalId': withdrawalId,
        'action': 'mark_paid',
      },
    );
    final data = _extractMap(res.data);
    final withdrawal = data['withdrawal'] as Map<String, dynamic>?;
    if (withdrawal == null) {
      throw const FormatException('Invalid withdrawal response');
    }
    return Withdrawal.fromJson(withdrawal);
  }

  @override
  Future<List<Announcement>> fetchAnnouncements() async {
    final res = await _dio.get<Object?>(_path(AdminApiEndpoints.announcements));
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Announcement.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final map = _extractMap(data);
    final announcements = map['announcements'] ?? map['data'];
    if (announcements is List) {
      return announcements
          .whereType<Map>()
          .map((e) => Announcement.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  @override
  Future<Announcement> createAnnouncement(Announcement announcement) async {
    final res = await _dio.post<Object?>(
      _path(AdminApiEndpoints.announcements),
      data: announcement.toCreateJson(),
    );
    return Announcement.fromJson(_extractMap(res.data));
  }

  @override
  Future<Announcement> updateAnnouncement(
    String id,
    Announcement announcement,
  ) async {
    final res = await _dio.put<Object?>(
      _path(AdminApiEndpoints.announcementById(id)),
      data: announcement.toUpdateJson(),
    );
    return Announcement.fromJson(_extractMap(res.data));
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    await _dio.delete<Object?>(_path(AdminApiEndpoints.announcementById(id)));
  }

  @override
  Future<AiUsageStats> fetchAiUsage({String period = '30d'}) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.aiUsage),
      queryParameters: <String, dynamic>{'period': period},
    );
    return AiUsageStats.fromJson(_extractMap(res.data));
  }

  @override
  Future<LedgerPage> fetchLedger({
    int page = 1,
    int limit = 50,
    LedgerEntryType? type,
    String? creatorId,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await _dio.get<Object?>(
      _path(AdminApiEndpoints.ledger),
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit.clamp(1, 100),
        if (type != null && type != LedgerEntryType.unknown)
          'type': type.apiValue,
        if (creatorId != null) 'creatorId': creatorId,
        if (campaignId != null) 'campaignId': campaignId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );
    return LedgerPage.fromJson(_extractMap(res.data));
  }

  Map<String, dynamic> _extractMap(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }
}
