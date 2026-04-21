/// Centralised HTTP paths for Auth_Wayo and Wayo-ads APIs.
///
/// Wayo-ads paths match `Wayo-ads/src/app/api/**` (App Router). Pass through
/// [AuthRuntimeConfig.wayoAdsRequestPath] for Dio [baseUrl] that already ends with `/api`.
abstract final class ApiEndpoints {
  /// Wayo-ads wallet (advertiser balance) — [GET /api/wallet](Wayo-ads).
  static const String wallet = 'api/wallet';

  /// Wayo-ads campaigns list — [GET /api/campaigns?advertiserOnly=true](Wayo-ads).
  static const String campaigns = 'api/campaigns';

  static String campaignDetail(String id) => 'api/campaigns/$id';

  /// Wayo-ads — notifications.
  static const String notifications = 'api/notifications';
  static const String notificationsUnread = 'api/notifications/unread-count';

  /// POST body: `{ "notificationId": "<id>" }` — [POST /api/notifications/read](Wayo-ads).
  static const String notificationsMarkRead = 'api/notifications/read';

  /// Laravel broadcasting auth for private Reverb/Pusher channels.
  // TODO(endpoint): confirm with Wayo-ads API (Next.js may proxy under `/api`).
  static const String broadcastingAuth = 'api/broadcasting/auth';

  /// Wayo-ads chat bootstrap — proxies to chat-service with server-only secret.
  /// [GET /api/chat/token](Wayo-ads) — Bearer (mobile) or session (web).
  static const String chatToken = 'api/chat/token';
}
