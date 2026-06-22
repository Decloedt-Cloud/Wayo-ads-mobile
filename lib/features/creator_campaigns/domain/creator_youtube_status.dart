/// YouTube OAuth link state from `GET /api/creator/youtube/channel`.
enum CreatorYoutubeOAuthStatus {
  notLinked,
  active,
  reconnectRequired,
  unknown;

  static CreatorYoutubeOAuthStatus fromApi(String? raw) {
    return switch (raw?.trim()) {
      'not_linked' => CreatorYoutubeOAuthStatus.notLinked,
      'active' => CreatorYoutubeOAuthStatus.active,
      'reconnect_required' => CreatorYoutubeOAuthStatus.reconnectRequired,
      _ => CreatorYoutubeOAuthStatus.unknown,
    };
  }

  /// Token is valid — video/short submission can proceed.
  bool get isReadyForSubmit => this == CreatorYoutubeOAuthStatus.active;
}

final class CreatorYoutubeChannelStatus {
  const CreatorYoutubeChannelStatus({required this.oauthStatus, this.channelName});

  final CreatorYoutubeOAuthStatus oauthStatus;
  final String? channelName;

  bool get isReadyForSubmit => oauthStatus.isReadyForSubmit;

  factory CreatorYoutubeChannelStatus.fromJson(Map<String, dynamic> json) {
    return CreatorYoutubeChannelStatus(
      oauthStatus: CreatorYoutubeOAuthStatus.fromApi(
        json['oauthStatus'] as String?,
      ),
      channelName: (json['channel'] is Map
          ? (json['channel'] as Map)['channelName']
          : null) as String?,
    );
  }

  static const disconnected = CreatorYoutubeChannelStatus(
    oauthStatus: CreatorYoutubeOAuthStatus.notLinked,
  );
}
