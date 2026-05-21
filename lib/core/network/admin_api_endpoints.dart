/// Superadmin API endpoints for Wayo-ads.
abstract final class AdminApiEndpoints {
  // Dashboard / Stats
  static const String transactions = 'api/admin/transactions';
  static const String payouts = 'api/admin/payouts';
  static const String debugTracking = 'api/admin/debug/tracking';
  
  // Users Management
  static const String users = 'api/admin/users';
  /// Full list + global [stats] (same as web admin).
  static const String usersAll = 'api/admin/users/all';
  static const String usersSearch = 'api/admin/users/search';
  
  // Banned Users
  static const String appBans = 'api/admin/app-bans';
  static String appBanDelete(int authUserId) => 'api/admin/app-bans/$authUserId';
  
  // Withdrawals
  static const String withdrawals = 'api/admin/withdrawals';
  
  // Announcements
  static const String announcements = 'api/admin/announcements';
  static String announcementById(String id) => 'api/admin/announcements/$id';
  
  // AI Usage
  static const String aiUsage = 'api/admin/ai/usage';
  
  // Ledger
  static const String ledger = 'api/admin/ledger';
}
