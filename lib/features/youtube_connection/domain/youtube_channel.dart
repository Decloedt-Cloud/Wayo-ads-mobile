import 'package:equatable/equatable.dart';

/// OAuth connection status for YouTube channel.
enum YouTubeOAuthStatus {
  notLinked,
  active,
  reconnectRequired,
  unknown;

  static YouTubeOAuthStatus fromApi(String? raw) {
    return switch (raw?.trim()) {
      'not_linked' => YouTubeOAuthStatus.notLinked,
      'active' => YouTubeOAuthStatus.active,
      'reconnect_required' => YouTubeOAuthStatus.reconnectRequired,
      _ => YouTubeOAuthStatus.unknown,
    };
  }
}

/// Connected YouTube channel info.
class YouTubeChannel extends Equatable {
  const YouTubeChannel({
    required this.channelId,
    required this.channelName,
    this.channelHandle,
    this.channelAvatar,
    this.subscriberCount,
    this.videoCount,
    required this.oauthStatus,
  });

  final String channelId;
  final String channelName;
  final String? channelHandle;
  final String? channelAvatar;
  final int? subscriberCount;
  final int? videoCount;
  final YouTubeOAuthStatus oauthStatus;

  factory YouTubeChannel.fromJson(Map<String, dynamic> json) {
    int? parseCount(dynamic v) => v is int
        ? v
        : v is num
        ? v.toInt()
        : int.tryParse('$v');

    return YouTubeChannel(
      channelId:
          (json['youtubeChannelId'] ?? json['channelId']) as String? ?? '',
      channelName: json['channelName'] as String? ?? '',
      channelHandle: json['channelHandle'] as String?,
      channelAvatar:
          (json['channelAvatarUrl'] ?? json['channelAvatar']) as String?,
      subscriberCount: parseCount(json['subscriberCount']),
      videoCount: parseCount(json['videoCount']),
      oauthStatus: YouTubeOAuthStatus.fromApi(json['oauthStatus'] as String?),
    );
  }

  bool get isConnected => oauthStatus == YouTubeOAuthStatus.active;
  bool get needsReconnect =>
      oauthStatus == YouTubeOAuthStatus.reconnectRequired;

  @override
  List<Object?> get props => [
    channelId,
    channelName,
    channelHandle,
    channelAvatar,
    subscriberCount,
    videoCount,
    oauthStatus,
  ];
}

/// Response from `/api/creator/youtube/channel`.
class YouTubeChannelResponse extends Equatable {
  const YouTubeChannelResponse({required this.oauthStatus, this.channel});

  final YouTubeOAuthStatus oauthStatus;
  final YouTubeChannel? channel;

  factory YouTubeChannelResponse.fromJson(Map<String, dynamic> json) {
    final status = YouTubeOAuthStatus.fromApi(json['oauthStatus'] as String?);
    final channelData = json['channel'] as Map<String, dynamic>?;

    YouTubeChannel? channel;
    if (channelData != null) {
      channel = YouTubeChannel.fromJson({
        ...channelData,
        'oauthStatus': json['oauthStatus'],
      });
    }

    return YouTubeChannelResponse(oauthStatus: status, channel: channel);
  }

  bool get isConnected => oauthStatus == YouTubeOAuthStatus.active;
  bool get needsReconnect =>
      oauthStatus == YouTubeOAuthStatus.reconnectRequired;

  @override
  List<Object?> get props => [oauthStatus, channel];
}

class YouTubeConnectInit extends Equatable {
  const YouTubeConnectInit({required this.authUrl, required this.codeVerifier});

  final String authUrl;
  final String codeVerifier;

  factory YouTubeConnectInit.fromJson(Map<String, dynamic> json) {
    return YouTubeConnectInit(
      authUrl: json['authUrl'] as String? ?? '',
      codeVerifier: json['codeVerifier'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [authUrl, codeVerifier];
}

class YouTubeConnectResult extends Equatable {
  const YouTubeConnectResult({
    required this.channelName,
    this.isReconnect = false,
  });

  final String channelName;
  final bool isReconnect;

  factory YouTubeConnectResult.fromJson(Map<String, dynamic> json) {
    return YouTubeConnectResult(
      channelName: json['channelName'] as String? ?? '',
      isReconnect: json['isReconnect'] == true,
    );
  }

  @override
  List<Object?> get props => [channelName, isReconnect];
}
