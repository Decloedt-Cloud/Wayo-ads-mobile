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
  static String userById(String id) => 'api/admin/users/$id';
  
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

  // Tax rates (VAT/GST overrides)
  static const String taxRates = 'api/admin/tax-rates';

  // Finance / security ops (P0 mobile parity)
  static const String paymentAudits = 'api/admin/payment-audits';
  static String paymentAuditReconcile(String id) =>
      'api/admin/payment-audits/${Uri.encodeComponent(id)}/reconcile';
  static const String advertiserDeposits = 'api/admin/advertiser-deposits';
  static const String auditLog = 'api/admin/audit-log';
  static const String health = 'api/admin/health';
  static const String healthServices = 'api/admin/health/services';

  // Ops panels (P1 mobile parity — read)
  static const String tokenPurchases = 'api/admin/token-purchases';
  static const String clickPipeline = 'api/admin/click-pipeline';
  static const String creatorVelocity = 'api/admin/creator-velocity';
  static const String emailLogs = 'api/admin/emails/logs';
  static const String emailTemplates = 'api/admin/emails/templates';
  static String emailTemplatePreview(String name) =>
      'api/admin/emails/preview/${Uri.encodeComponent(name)}';
  static const String recentActivity = 'api/admin/recent-activity';

  // Financial documents (admin browse)
  static const String invoices = 'api/admin/invoices';
  static const String paymentStatements = 'api/admin/payment-statements';
  static const String invoicesZip = 'api/admin/invoices/zip';
  static const String paymentStatementsZip = 'api/admin/payment-statements/zip';

  // Jobs / YT / settings (P2)
  static const String youtubeCheckPostViews = 'api/admin/jobs/check-post-views';
  static const String youtubeRefreshStatus = 'api/admin/jobs/refresh-youtube-status';
  static const String jobAggregateMetrics = 'api/admin/jobs/aggregate-creator-metrics';
  static const String jobTrustScores = 'api/admin/jobs/compute-trust-scores';
  static const String jobCampaignFinancials = 'api/admin/jobs/compute-campaign-financials';
  static const String jobReleasePayouts = 'api/admin/jobs/release-payouts';
  static const String tokenPackages = 'api/admin/token-packages';
  static const String platformSettings = 'api/admin/platform-settings';
  static const String stripeSettings = 'api/admin/stripe-settings';
  static const String stripeSettingsReveal = 'api/admin/stripe-settings/reveal';
  static const String stripeSettingsTestConnection =
      'api/admin/stripe-settings/test-connection';
  static const String stripeSettingsActiveMode =
      'api/admin/stripe-settings/active-mode';
  static const String notificationsBroadcast = 'api/admin/notifications/broadcast';

  /// Sync one token package to Stripe catalog —
  /// [POST /api/admin/token-packages/sync-stripe](Wayo-ads) body `{ slug }`.
  static const String tokenPackagesSyncStripe =
      'api/admin/token-packages/sync-stripe';

  // Email settings (superadmin, sensitive ops)
  static const String emailSettings = 'api/admin/email-settings';
  static const String emailSettingsTest = 'api/admin/email-settings/test-email';
  static const String emailsSendTest = 'api/admin/emails/send-test';
}
