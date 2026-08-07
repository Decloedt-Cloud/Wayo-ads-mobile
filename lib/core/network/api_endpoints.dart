/// Centralised HTTP paths for Auth_Wayo and Wayo-ads APIs.
///
/// Wayo-ads paths match `Wayo-ads/src/app/api/**` (App Router). Pass through
/// [AuthRuntimeConfig.wayoAdsRequestPath] for Dio [baseUrl] that already ends with `/api`.
abstract final class ApiEndpoints {
  /// Wayo-ads wallet (advertiser balance) — [GET /api/wallet](Wayo-ads).
  static const String wallet = 'api/wallet';

  /// Stripe / PSP settings for mobile — [GET /api/wallet/config](Wayo-ads).
  static const String walletConfig = 'api/wallet/config';

  /// [POST /api/wallet/deposit-intent](Wayo-ads) — body `{ amountCents, currency? }`.
  static const String walletDepositIntent = 'api/wallet/deposit-intent';

  /// [POST /api/wallet/confirm-deposit](Wayo-ads) — body `{ intentId }`.
  static const String walletConfirmDeposit = 'api/wallet/confirm-deposit';

  /// Dev/mock only — [POST /api/webhooks/psp/simulate](Wayo-ads) — body `{ intentId }`.
  static const String webhooksPspSimulate = 'api/webhooks/psp/simulate';

  /// Manual settle for one stuck PENDING deposit —
  /// [POST /api/wallet/deposits/:intentId/reconcile](Wayo-ads).
  static String walletDepositReconcile(String intentId) =>
      'api/wallet/deposits/${Uri.encodeComponent(intentId)}/reconcile';

  /// DB projection of saved Stripe cards —
  /// [GET|DELETE /api/wallet/saved-cards](Wayo-ads).
  static const String walletSavedCards = 'api/wallet/saved-cards';

  /// Live Stripe → DB sync —
  /// [POST /api/wallet/saved-cards/refresh](Wayo-ads).
  static const String walletSavedCardsRefresh = 'api/wallet/saved-cards/refresh';

  /// Wayo-ads campaigns list — [GET /api/campaigns?advertiserOnly=true](Wayo-ads).
  static const String campaigns = 'api/campaigns';

  static String campaignDetail(String id) => 'api/campaigns/$id';

  /// Brand logo upload — [POST /api/campaigns/upload-logo](Wayo-ads) body `{ data: dataUrl }`.
  static const String campaignUploadLogo = 'api/campaigns/upload-logo';

  /// Public platform fee % — [GET /api/platform/fees](Wayo-ads).
  static const String platformFees = 'api/platform/fees';

  /// Tax estimate — [GET /api/tokens/tax-rate](Wayo-ads).
  static const String tokensTaxRate = 'api/tokens/tax-rate';

  /// Campaign traffic/submissions analytics — [GET /api/campaigns/:id/analytics](Wayo-ads).
  static String campaignAnalytics(String id) => 'api/campaigns/$id/analytics';

  /// Owner financial health — [GET /api/advertiser/campaigns/:id/financial-summary](Wayo-ads).
  static String campaignFinancialSummary(String id) =>
      'api/advertiser/campaigns/$id/financial-summary';

  static String campaignCreatorAiMatchScore(String campaignId, String creatorId) =>
      'api/campaigns/$campaignId/creators/$creatorId/ai-match-score';

  static String campaignCreatorAiMatchScoreRefresh(
    String campaignId,
    String creatorId,
  ) => 'api/campaigns/$campaignId/creators/$creatorId/ai-match-score/refresh';

  static String campaignCreatorInsights(String campaignId, String creatorId) =>
      'api/campaigns/$campaignId/creators/$creatorId/insights';

  static String campaignCreatorInsightsRefresh(
    String campaignId,
    String creatorId,
  ) => 'api/campaigns/$campaignId/creators/$creatorId/insights/refresh';

  /// List applications for a campaign (advertiser) — [GET /api/campaigns/:id/applications](Wayo-ads).
  static String campaignApplications(String campaignId) =>
      'api/campaigns/$campaignId/applications';

  /// Approve a pending creator application (advertiser) — [POST /api/campaigns/:id/applications/:applicationId/approve](Wayo-ads).
  static String campaignApplicationApprove(
    String campaignId,
    String applicationId,
  ) => 'api/campaigns/$campaignId/applications/$applicationId/approve';

  /// Reject a pending application — [POST /api/campaigns/:id/applications/:applicationId/reject](Wayo-ads).
  static String campaignApplicationReject(
    String campaignId,
    String applicationId,
  ) => 'api/campaigns/$campaignId/applications/$applicationId/reject';

  /// Wayo-ads — notifications.
  static const String notifications = 'api/notifications';
  static const String notificationsUnread = 'api/notifications/unread-count';

  /// POST body: `{ "notificationId": "<id>" }` — [POST /api/notifications/read](Wayo-ads).
  static const String notificationsMarkRead = 'api/notifications/read';

  /// POST (no body) — [POST /api/notifications/mark-all-read](Wayo-ads).
  static const String notificationsMarkAllRead =
      'api/notifications/mark-all-read';

  /// POST body: `{ "notificationId": "<id>" }` — [POST /api/notifications/dismiss](Wayo-ads).
  static const String notificationsDismiss = 'api/notifications/dismiss';

  /// POST body: `{ "notificationId": "<id>" }` — [POST /api/notifications/archive](Wayo-ads).
  static const String notificationsArchive = 'api/notifications/archive';

  /// Channel + category prefs — [GET|PATCH /api/notifications/preferences](Wayo-ads).
  static const String notificationsPreferences = 'api/notifications/preferences';

  /// GDPR-style JSON export — [GET /api/user/export-data](Wayo-ads).
  static const String userExportData = 'api/user/export-data';

  /// Passkeys SSO handoff (JSON `{ url }` with Bearer) —
  /// [GET /api/settings/passkeys-handoff](Wayo-ads).
  static const String passkeysHandoff = 'api/settings/passkeys-handoff';

  /// Connected accounts SSO handoff (JSON `{ url }` with Bearer) —
  /// [GET /api/settings/connected-accounts-handoff](Wayo-ads).
  static const String connectedAccountsHandoff =
      'api/settings/connected-accounts-handoff';

  /// Laravel broadcasting auth for private Reverb/Pusher channels.
  // TODO(endpoint): confirm with Wayo-ads API (Next.js may proxy under `/api`).
  static const String broadcastingAuth = 'api/broadcasting/auth';

  /// Wayo-ads chat bootstrap — proxies to chat-service with server-only secret.
  /// [GET /api/chat/token](Wayo-ads) — Bearer (mobile) or session (web).
  static const String chatToken = 'api/chat/token';

  /// Marketing profile lookup for missing chat avatars.
  static const String chatUserProfiles = 'api/chat/user-profiles';

  /// Marketing roles by email — [GET /api/chat/user-roles?emails=…](Wayo-ads).
  static const String chatUserRoles = 'api/chat/user-roles';

  /// [GET /api/user/profile](Wayo-ads) — Bearer (mobile) or session (web).
  static const String userProfile = 'api/user/profile';

  /// [PATCH /api/user/password](Wayo-ads) — change password while signed in (web).
  static const String userPassword = 'api/user/password';

  /// [PATCH /api/auth/change-password](Auth_Wayo) — mobile Bearer change password.
  static const String authChangePassword = 'api/auth/change-password';

  /// [GET/POST /api/user/sessions](Wayo-ads) — active browser sessions (mobile).
  static const String userSessions = 'api/user/sessions';

  /// [POST /api/user/sessions/register](Wayo-ads) — register this phone session.
  static const String userSessionsRegister = 'api/user/sessions/register';

  /// [GET/POST /api/user/devices](Wayo-ads) — trusted known devices.
  static const String userDevices = 'api/user/devices';

  /// [POST /api/user/delete-account](Wayo-ads), body `{ password }`.
  static const String userDeleteAccount = 'api/user/delete-account';

  /// [POST /api/user/push-device](Wayo-ads) — body `{ fcmToken, platform? }`.
  /// [DELETE /api/user/push-device?fcmToken=…](Wayo-ads) — unregister on logout.
  static const String userPushDevice = 'api/user/push-device';

  /// All invoices visible to the signed-in user — [GET /api/invoices](Wayo-ads).
  /// (No `success` field; used as a **fallback** when role-specific paginated routes
  /// fail with 404/403 on older deployments.)
  static const String invoicesAll = 'api/invoices';

  /// Paginated invoices list for ADVERTISER (`?page=N`, default page size 15) —
  /// [GET /api/advertiser/invoices](Wayo-ads).
  static const String advertiserInvoices = 'api/advertiser/invoices';

  /// Bulk advertiser invoice PDFs as ZIP —
  /// [POST /api/advertiser/invoices/zip](Wayo-ads), body `{ ids, locale? }`.
  static const String advertiserInvoicesZip = 'api/advertiser/invoices/zip';

  /// Creator earnings statements — [GET /api/creator/payouts](Wayo-ads).
  static const String creatorPayouts = 'api/creator/payouts';

  /// Bulk creator payout statement PDFs as ZIP —
  /// [POST /api/creator/payouts/zip](Wayo-ads), body `{ ids, locale? }`
  /// (`ids` = withdrawal request IDs).
  static const String creatorPayoutsZip = 'api/creator/payouts/zip';

  /// Creator payout / token-purchase PDF —
  /// [GET /payouts/:statementId?locale=](Wayo-ads).
  static String payoutPdf(String statementId) =>
      'payouts/${Uri.encodeComponent(statementId)}';

  /// Paginated invoices list for CREATOR (`?page=N`, page size 10) —
  /// [GET /api/creator/invoices](Wayo-ads).
  static const String creatorInvoices = 'api/creator/invoices';

  /// Bulk creator invoice PDFs as ZIP —
  /// [POST /api/creator/invoices/zip](Wayo-ads), body `{ ids, locale? }`.
  static const String creatorInvoicesZip = 'api/creator/invoices/zip';
  /// Creator dashboard KPIs + balance — [GET /api/creator/stats](Wayo-ads).
  static const String creatorStats = 'api/creator/stats';

  /// Creator campaign applications — [GET /api/creator/applications](Wayo-ads).
  static const String creatorApplications = 'api/creator/applications';

  /// Creator wallet / withdrawals —
  /// [GET|POST|DELETE /api/creator/withdrawal](Wayo-ads).
  static const String creatorWithdrawal = 'api/creator/withdrawal';

  /// [GET /api/creator/stripe-connect/status](Wayo-ads).
  static const String creatorStripeConnectStatus =
      'api/creator/stripe-connect/status';

  /// [POST /api/creator/stripe-connect/onboard](Wayo-ads).
  static const String creatorStripeConnectOnboard =
      'api/creator/stripe-connect/onboard';

  /// [POST /api/creator/stripe-connect/login](Wayo-ads).
  static const String creatorStripeConnectLogin =
      'api/creator/stripe-connect/login';

  /// [GET|PUT /api/creator/business-profile](Wayo-ads).
  static const String creatorBusinessProfile = 'api/creator/business-profile';

  /// [GET /api/creator/youtube/channel](Wayo-ads) — OAuth link status for submit gate.
  static const String creatorYoutubeChannel = 'api/creator/youtube/channel';

  /// [GET /api/creator/youtube/connect?mobile=1](Wayo-ads) — PKCE OAuth init.
  static const String creatorYoutubeConnect = 'api/creator/youtube/connect';

  /// [POST /api/creator/youtube/mobile-complete](Wayo-ads) — exchange code + state.
  static const String creatorYoutubeMobileComplete =
      'api/creator/youtube/mobile-complete';

  /// [DELETE /api/creator/youtube/disconnect](Wayo-ads).
  static const String creatorYoutubeDisconnect =
      'api/creator/youtube/disconnect';

  /// [POST /api/creator/youtube/refresh](Wayo-ads).
  static const String creatorYoutubeRefresh = 'api/creator/youtube/refresh';

  /// Creator trust score — [GET /api/creator/trust-score](Wayo-ads).
  static const String creatorTrustScore = 'api/creator/trust-score';

  /// [GET|POST /api/creator/campaigns/:id/submit-post](Wayo-ads).
  static String creatorCampaignSubmitPost(String campaignId) =>
      'api/creator/campaigns/$campaignId/submit-post';

  /// Creator tracking links for a LINK campaign —
  /// [GET|POST /api/campaigns/:id/links](Wayo-ads).
  static String campaignTrackingLinks(String campaignId) =>
      'api/campaigns/$campaignId/links';

  /// Creator applies to a campaign — [POST /api/campaigns/:id/apply](Wayo-ads).
  static String campaignApply(String campaignId) =>
      'api/campaigns/$campaignId/apply';

  /// Streams a generated `application/pdf` (Bearer or session) —
  /// [GET /api/invoices/:id/pdf](Wayo-ads).
  static String invoicePdf(String id) => 'api/invoices/$id/pdf';

  /// Advertiser video submissions — [GET /api/advertiser/videos](Wayo-ads).
  static const String advertiserVideos = 'api/advertiser/videos';

  /// Browse creators on advertiser campaigns — [GET /api/advertiser/creators](Wayo-ads).
  static const String advertiserCreators = 'api/advertiser/creators';

  /// Creator performance analytics — [GET /api/creator/analytics](Wayo-ads).
  static const String creatorAnalytics = 'api/creator/analytics';

  /// Approve or reject a pending submission —
  /// [PATCH /api/advertiser/videos/:id](Wayo-ads).
  static String advertiserVideoReview(String videoId) =>
      'api/advertiser/videos/$videoId';
}
