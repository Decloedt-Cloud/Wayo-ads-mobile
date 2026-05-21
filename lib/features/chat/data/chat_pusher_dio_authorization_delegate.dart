import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/interceptors/certificate_pinning.dart';

/// Same TLS stack as Wayo Chat HTTP (certificate pinning via [CertificatePinning]).
///
/// The default [EndpointAuthorizableChannelTokenAuthorizationDelegate] uses
/// `package:http`, which **does not** use Dio pinning. In release, that mismatch
/// can make `/broadcasting/auth` fail while JSON APIs succeed — presence never
/// subscribes and online indicators stay stale on mobile.
///
/// **Presence `channel_data`:** do not mutate the JSON returned by Laravel here:
/// signing binds `auth` to the exact serialized payload. The chat-service should
/// include `user_id` in presence payloads if required (dart_pusher_channels PresenceChannel
/// expects the key **`user_id`** in decoded `channel_data`; many Laravel apps only expose `id`).
final class ChatPusherPrivateDioAuthDelegate
    implements
        EndpointAuthorizableChannelAuthorizationDelegate<
            PrivateChannelAuthorizationData> {
  ChatPusherPrivateDioAuthDelegate({
    required this.authorizationEndpoint,
    required Map<String, String> headers,
    this.onAuthFailed,
  }) : _headers = Map<String, String>.from(headers);

  final Uri authorizationEndpoint;
  final Map<String, String> _headers;

  @override
  final EndpointAuthFailedCallback? onAuthFailed;

  @override
  Future<PrivateChannelAuthorizationData> authorizationData(
    String socketId,
    String channelName,
  ) async {
    final dio = _buildAuthDio();
    try {
      final res = await dio.post<dynamic>(
        authorizationEndpoint.toString(),
        data: <String, dynamic>{
          'socket_id': socketId,
          'channel_name': channelName,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: _headers,
          responseType: ResponseType.plain,
        ),
      );

      final code = res.statusCode ?? 0;
      final decoded = _decodeBroadcastingAuthJson(res.data);
      if (code != 200) {
        throw StateError(
          'broadcasting/private auth HTTP $code: $decoded',
        );
      }
      final raw = decoded;
      final authKey = raw['auth'];
      if (authKey is! String || authKey.isEmpty) {
        throw StateError('broadcasting/private missing auth: $decoded');
      }
      return PrivateChannelAuthorizationData(authKey: authKey);
    } finally {
      dio.close(force: true);
    }
  }
}

final class ChatPusherPresenceDioAuthDelegate
    implements
        EndpointAuthorizableChannelAuthorizationDelegate<
            PresenceChannelAuthorizationData> {
  ChatPusherPresenceDioAuthDelegate({
    required this.authorizationEndpoint,
    required Map<String, String> headers,
    this.onAuthFailed,
  }) : _headers = Map<String, String>.from(headers);

  final Uri authorizationEndpoint;
  final Map<String, String> _headers;

  @override
  final EndpointAuthFailedCallback? onAuthFailed;

  @override
  Future<PresenceChannelAuthorizationData> authorizationData(
    String socketId,
    String channelName,
  ) async {
    final dio = _buildAuthDio();
    try {
      final res = await dio.post<dynamic>(
        authorizationEndpoint.toString(),
        data: <String, dynamic>{
          'socket_id': socketId,
          'channel_name': channelName,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: _headers,
          responseType: ResponseType.plain,
        ),
      );

      final code = res.statusCode ?? 0;
      final decoded = _decodeBroadcastingAuthJson(res.data);
      if (code != 200) {
        throw StateError(
          'broadcasting/presence auth HTTP $code ($channelName): $decoded',
        );
      }

      final authKey = decoded['auth'];
      if (authKey is! String || authKey.isEmpty) {
        throw StateError('broadcasting/presence missing auth: $decoded');
      }

      final channelDataNormalized = _channelDataEncodedForPusher(decoded['channel_data']);

      return PresenceChannelAuthorizationData(
        authKey: authKey,
        channelDataEncoded: channelDataNormalized,
      );
    } finally {
      dio.close(force: true);
    }
  }
}

Dio _buildAuthDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 25),
      validateStatus: (c) => c != null && c < 600,
    ),
  );
  CertificatePinning.attach(
    dio,
    pinnedSha256Base64: AuthRuntimeConfig.instance.mergedPinnedSha256Base64,
  );
  return dio;
}

Map<String, dynamic> _decodeBroadcastingAuthJson(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  final raw = '${data ?? ''}'.trim();
  if (raw.isEmpty) {
    throw const FormatException('empty broadcasting auth response');
  }
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  throw FormatException('broadcasting auth is not JSON object: ${decoded.runtimeType}');
}

String _channelDataEncodedForPusher(dynamic channelData) {
  if (channelData is String) {
    final t = channelData.trim();
    if (t.isEmpty) {
      throw StateError('channel_data JSON string empty');
    }
    return t;
  }
  if (channelData is Map) {
    try {
      return jsonEncode(channelData);
    } catch (_) {
      throw StateError('channel_data map encode failed');
    }
  }
  throw StateError(
    'channel_data expected String or Map, got ${channelData.runtimeType}',
  );
}
