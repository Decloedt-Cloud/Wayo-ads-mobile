import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';

/// Trusted device row from `GET /api/user/devices` (Wayo-ads).
final class KnownDevice {
  const KnownDevice({
    required this.id,
    required this.deviceLabel,
    required this.platform,
    required this.lastIpAddress,
    required this.trusted,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.current,
  });

  final String id;
  final String? deviceLabel;
  final String? platform;
  final String? lastIpAddress;
  final bool trusted;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final bool current;

  factory KnownDevice.fromJson(Map<String, dynamic> json) {
    return KnownDevice(
      id: json['id'] as String? ?? '',
      deviceLabel: json['deviceLabel'] as String?,
      platform: json['platform'] as String?,
      lastIpAddress: json['lastIpAddress'] as String?,
      trusted: json['trusted'] == true,
      firstSeenAt: DateTime.tryParse(json['firstSeenAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      current: json['current'] == true,
    );
  }
}

/// Lists and revokes trusted known devices — same contract as web settings.
final class KnownDevicesRemote {
  KnownDevicesRemote(this._dio);

  final Dio _dio;

  String get _path =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.userDevices);

  Future<List<KnownDevice>> fetchDevices() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _path,
      options: Options(headers: {'Cache-Control': 'no-store'}),
    );
    final raw = res.data?['devices'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => KnownDevice.fromJson(Map<String, dynamic>.from(e)))
        .where((d) => d.id.isNotEmpty)
        .toList(growable: false);
  }

  /// Forget (revoke) a trusted device by its [deviceId].
  Future<void> revokeDevice(String deviceId) async {
    await _dio.post<void>(
      _path,
      data: {'deviceId': deviceId, 'action': 'revoke'},
    );
  }
}
