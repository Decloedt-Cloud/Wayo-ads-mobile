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

  /// Wayo-ads campaigns list — [GET /api/campaigns?advertiserOnly=true](Wayo-ads).
  static const String campaigns = 'api/campaigns';

  static String campaignDetail(String id) => 'api/campaigns/$id';

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

  /// Laravel broadcasting auth for private Reverb/Pusher channels.
  // TODO(endpoint): confirm with Wayo-ads API (Next.js may proxy under `/api`).
  static const String broadcastingAuth = 'api/broadcasting/auth';

  /// Wayo-ads chat bootstrap — proxies to chat-service with server-only secret.
  /// [GET /api/chat/token](Wayo-ads) — Bearer (mobile) or session (web).
  static const String chatToken = 'api/chat/token';
}
