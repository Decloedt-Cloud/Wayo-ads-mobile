import 'package:dio/dio.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../../../core/result.dart';
import '../domain/entities/admin_transaction.dart';
import '../domain/entities/admin_user.dart';
import '../domain/entities/ai_usage.dart';
import '../domain/entities/announcement.dart';
import '../domain/entities/banned_user.dart';
import '../domain/entities/dashboard_stats.dart';
import '../../creator_campaigns/domain/creator_browse_page_result.dart';
import '../domain/entities/country_tax_rate.dart';
import '../domain/entities/ledger_entry.dart';
import '../domain/entities/withdrawal.dart';
import 'superadmin_remote_datasource.dart';

abstract interface class ISuperadminRepository {
  // Dashboard
  Future<Result<DashboardStats>> getDashboardStats({
    int page = 1,
    int limit = 50,
    String? reason,
  });

  Future<Result<AdminTransactionsPage>> getAdminTransactionsPage({
    int page = 1,
    int limit = 20,
    String? reason,
  });

  Future<Result<TrafficQualitySummary>> getTrafficQualitySummary();
  
  Future<Result<PayoutStats>> getPayoutStats();

  // Users Management
  Future<Result<AdminUsersPage>> getUsers({
    String? search,
    RoleFilter? role,
    JoinedFilter? joined,
    bool? bannedOnly,
    int page = 1,
    int limit = kAdminUsersPageSize,
  });

  // Banned Users
  Future<Result<BannedUsersPage>> getBannedUsers({
    String? search,
    int limit = 50,
    int offset = 0,
  });

  Future<Result<List<SearchUser>>> searchUsers({
    required String search,
    String? role,
    int page = 1,
    int limit = 20,
  });

  Future<Result<void>> banUser({
    required String wayoUserId,
    String? reason,
  });

  Future<Result<void>> unbanUser(int authUserId);

  // Withdrawals
  Future<Result<WithdrawalsPage>> getWithdrawals({
    int limit = 50,
    int offset = 0,
    WithdrawalStatus? status,
  });

  Future<Result<Withdrawal>> approveWithdrawal(String withdrawalId);

  Future<Result<Withdrawal>> cancelWithdrawal(String withdrawalId);

  Future<Result<Withdrawal>> markWithdrawalPaid(String withdrawalId);

  // Announcements
  Future<Result<List<Announcement>>> getAnnouncements();

  Future<Result<Announcement>> createAnnouncement(Announcement announcement);

  Future<Result<Announcement>> updateAnnouncement(
    String id,
    Announcement announcement,
  );

  Future<Result<void>> deleteAnnouncement(String id);

  // AI Usage
  Future<Result<AiUsageStats>> getAiUsage({String period = '30d'});

  // Ledger
  Future<Result<LedgerPage>> getLedger({
    int page = 1,
    int limit = 50,
    LedgerEntryType? type,
    String? creatorId,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Result<TaxRatesPage>> getTaxRates();

  Future<Result<void>> upsertTaxRate({
    required String countryCode,
    required double rate,
    String? label,
    String? subdivision,
  });

  Future<Result<void>> deleteTaxRateOverride(String id);

  Future<Result<CreatorBrowsePageResult>> getMarketplaceCampaignsPage({
    int page = 1,
    int limit = 10,
    String? search,
    String? type,
    String? niche,
    String? countryCode,
  });
}

final class SuperadminRepository implements ISuperadminRepository {
  SuperadminRepository(this._remote);

  final SuperadminRemote _remote;

  @override
  Future<Result<DashboardStats>> getDashboardStats({
    int page = 1,
    int limit = 50,
    String? reason,
  }) async {
    try {
      final stats = await _remote.fetchDashboardStats(
        page: page,
        limit: limit,
        reason: reason,
      );
      return Success(stats);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<AdminTransactionsPage>> getAdminTransactionsPage({
    int page = 1,
    int limit = 20,
    String? reason,
  }) async {
    try {
      final pageResult = await _remote.fetchAdminTransactionsPage(
        page: page,
        limit: limit,
        reason: reason,
      );
      return Success(pageResult);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<TrafficQualitySummary>> getTrafficQualitySummary() async {
    try {
      final summary = await _remote.fetchTrafficQualitySummary();
      return Success(summary);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<PayoutStats>> getPayoutStats() async {
    try {
      final stats = await _remote.fetchPayoutStats();
      return Success(stats);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<AdminUsersPage>> getUsers({
    String? search,
    RoleFilter? role,
    JoinedFilter? joined,
    bool? bannedOnly,
    int page = 1,
    int limit = kAdminUsersPageSize,
  }) async {
    try {
      final result = await _remote.fetchUsers(
        search: search,
        role: role,
        joined: joined,
        bannedOnly: bannedOnly,
        page: page,
        limit: limit,
      );
      return Success(result);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<BannedUsersPage>> getBannedUsers({
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final page = await _remote.fetchBannedUsers(
        search: search,
        limit: limit,
        offset: offset,
      );
      return Success(page);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<List<SearchUser>>> searchUsers({
    required String search,
    String? role,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final users = await _remote.searchUsers(
        search: search,
        role: role,
        page: page,
        limit: limit,
      );
      return Success(users);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<void>> banUser({
    required String wayoUserId,
    String? reason,
  }) async {
    try {
      await _remote.banUser(wayoUserId: wayoUserId, reason: reason);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<void>> unbanUser(int authUserId) async {
    try {
      await _remote.unbanUser(authUserId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<WithdrawalsPage>> getWithdrawals({
    int limit = 50,
    int offset = 0,
    WithdrawalStatus? status,
  }) async {
    try {
      final page = await _remote.fetchWithdrawals(
        limit: limit,
        offset: offset,
        status: status,
      );
      return Success(page);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<Withdrawal>> approveWithdrawal(String withdrawalId) async {
    try {
      final withdrawal = await _remote.approveWithdrawal(withdrawalId);
      return Success(withdrawal);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<Withdrawal>> cancelWithdrawal(String withdrawalId) async {
    try {
      final withdrawal = await _remote.cancelWithdrawal(withdrawalId);
      return Success(withdrawal);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<Withdrawal>> markWithdrawalPaid(String withdrawalId) async {
    try {
      final withdrawal = await _remote.markWithdrawalPaid(withdrawalId);
      return Success(withdrawal);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<List<Announcement>>> getAnnouncements() async {
    try {
      final announcements = await _remote.fetchAnnouncements();
      return Success(announcements);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<Announcement>> createAnnouncement(
    Announcement announcement,
  ) async {
    try {
      final created = await _remote.createAnnouncement(announcement);
      return Success(created);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<Announcement>> updateAnnouncement(
    String id,
    Announcement announcement,
  ) async {
    try {
      final updated = await _remote.updateAnnouncement(id, announcement);
      return Success(updated);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAnnouncement(String id) async {
    try {
      await _remote.deleteAnnouncement(id);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<AiUsageStats>> getAiUsage({String period = '30d'}) async {
    try {
      final stats = await _remote.fetchAiUsage(period: period);
      return Success(stats);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<LedgerPage>> getLedger({
    int page = 1,
    int limit = 50,
    LedgerEntryType? type,
    String? creatorId,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final ledger = await _remote.fetchLedger(
        page: page,
        limit: limit,
        type: type,
        creatorId: creatorId,
        campaignId: campaignId,
        startDate: startDate,
        endDate: endDate,
      );
      return Success(ledger);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<TaxRatesPage>> getTaxRates() async {
    try {
      final page = await _remote.fetchTaxRates();
      return Success(page);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<void>> upsertTaxRate({
    required String countryCode,
    required double rate,
    String? label,
    String? subdivision,
  }) async {
    try {
      await _remote.upsertTaxRate(
        countryCode: countryCode,
        rate: rate,
        label: label,
        subdivision: subdivision,
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTaxRateOverride(String id) async {
    try {
      await _remote.deleteTaxRateOverride(id);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  @override
  Future<Result<CreatorBrowsePageResult>> getMarketplaceCampaignsPage({
    int page = 1,
    int limit = 10,
    String? search,
    String? type,
    String? niche,
    String? countryCode,
  }) async {
    try {
      final pageResult = await _remote.fetchMarketplaceCampaignsPage(
        page: page,
        limit: limit,
        search: search,
        type: type,
        niche: niche,
        countryCode: countryCode,
      );
      return Success(pageResult);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(ServerException(e.toString()));
    }
  }

  AuthException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? message;
    if (data is Map) {
      message = data['message']?.toString() ?? data['error']?.toString();
    }

    if (status == 401) {
      return SessionInvalidException();
    }
    if (status == 403) {
      return ServerException(message ?? 'Access denied', status);
    }
    if (status == 404) {
      return ServerException(message ?? 'Not found', status);
    }
    if (status == 422) {
      return ServerException(message ?? 'Validation error', status);
    }
    if (status != null && status >= 500) {
      return ServerException(message ?? 'Server error', status);
    }

    return NetworkException(message ?? e.message ?? 'Network error');
  }
}
