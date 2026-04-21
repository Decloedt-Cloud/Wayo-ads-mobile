/// Bootstrap payload from Wayo-ads `GET /api/chat/token` (same contract as web).
final class ChatCredentials {
  const ChatCredentials({
    required this.token,
    required this.chatUserId,
    required this.appId,
    required this.apiBaseUrl,
    required this.realtime,
  });

  final String token;
  final int chatUserId;
  final String appId;

  /// Chat-service root (e.g. `https://wayochat.wayo.ac`), no trailing slash.
  final String apiBaseUrl;
  final ChatRealtimeConfig realtime;
}

final class ChatRealtimeConfig {
  const ChatRealtimeConfig({
    required this.key,
    required this.wsHost,
    required this.wsPort,
    required this.wssPort,
    required this.forceTLS,
    required this.authEndpoint,
  });

  final String key;
  final String wsHost;
  final int wsPort;
  final int wssPort;
  final bool forceTLS;

  /// Full URL to Laravel broadcasting auth (chat-service).
  final String authEndpoint;
}
