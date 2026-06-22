import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';

/// Browser or mobile session row from `GET /api/user/sessions` (Wayo-ads).
final class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.deviceLabel,
    required this.ipAddress,
    required this.lastSeenAt,
    required this.current,
    this.platform,
  });

  final String id;
  final String? deviceLabel;
  final String? ipAddress;
  final DateTime lastSeenAt;
  final bool current;
  final String? platform;

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      id: json['id'] as String? ?? '',
      deviceLabel: json['deviceLabel'] as String?,
      ipAddress: json['ipAddress'] as String?,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      current: json['current'] == true,
      platform: json['platform'] as String?,
    );
  }
}

/// Lists and revokes browser sessions — same contract as web settings.
final class ActiveSessionsRemote {
  ActiveSessionsRemote(this._dio);

  final Dio _dio;

  String get _path =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.userSessions);

  Future<List<ActiveSession>> fetchSessions() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _path,
      options: Options(headers: {'Cache-Control': 'no-store'}),
    );
    final raw = res.data?['sessions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ActiveSession.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> revokeSession(String sessionId) async {
    await _dio.post<void>(
      _path,
      data: {'sessionId': sessionId},
    );
  }

  Future<void> revokeOtherSessions() async {
    await _dio.post<void>(
      _path,
      data: {'scope': 'others'},
    );
  }
}
