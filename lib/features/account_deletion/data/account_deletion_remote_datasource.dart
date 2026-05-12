import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';

/// Wayo-ads `/api/user/profile` subset used for account deletion flow.
final class WayoAdsDeletionProfile {
  const WayoAdsDeletionProfile({
    required this.id,
    required this.email,
    required this.roles,
    this.name,
    this.deletionRequestedAt,
    this.deletionRequiresPassword = true,
  });

  final String id;
  final String email;
  final String roles;
  final String? name;
  final DateTime? deletionRequestedAt;
  /// From Wayo-ads profile: false for Google/Apple-only accounts (no password in Auth_Wayo).
  final bool deletionRequiresPassword;

  bool get hasAdvertiserRole => roles.toUpperCase().contains('ADVERTISER');
  bool get hasCreatorRole => roles.toUpperCase().contains('CREATOR');

  /// Merge server-confirmed schedule time when GET /profile lags behind POST.
  WayoAdsDeletionProfile withDeletionScheduledAt(DateTime at) {
    return WayoAdsDeletionProfile(
      id: id,
      email: email,
      roles: roles,
      name: name,
      deletionRequestedAt: at,
      deletionRequiresPassword: deletionRequiresPassword,
    );
  }

  static WayoAdsDeletionProfile fromResponseJson(Map<String, dynamic> json) {
    final u = json['user'];
    if (u is! Map<String, dynamic>) {
      throw const FormatException('Expected user object');
    }
    DateTime? del;
    final raw = u['deletionRequestedAt'];
    if (raw is String && raw.isNotEmpty) {
      del = DateTime.tryParse(raw);
    }
    final drp = u['deletionRequiresPassword'];
    final requiresPw = drp is bool ? drp : true;
    return WayoAdsDeletionProfile(
      id: _stringField(u['id']),
      email: _stringField(u['email']),
      roles: _stringField(u['roles']),
      name: u['name'] == null ? null : _stringField(u['name']),
      deletionRequestedAt: del,
      deletionRequiresPassword: requiresPw,
    );
  }

  static String _stringField(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}

class AccountDeletionRemoteDatasource {
  AccountDeletionRemoteDatasource(this._dio);

  final Dio _dio;

  String _path(String endpoint) =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(endpoint);

  Future<WayoAdsDeletionProfile> fetchProfile({bool bypassCache = false}) async {
    var path = _path(ApiEndpoints.userProfile);
    if (bypassCache) {
      final sep = path.contains('?') ? '&' : '?';
      path = '$path${sep}_=${DateTime.now().microsecondsSinceEpoch}';
    }
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      options: bypassCache
          ? Options(
              headers: const {
                'Cache-Control': 'no-cache',
                'Pragma': 'no-cache',
              },
            )
          : null,
    );
    final data = res.data;
    if (data == null) {
      throw DioException(requestOptions: res.requestOptions, message: 'Empty body');
    }
    return WayoAdsDeletionProfile.fromResponseJson(data);
  }

  Future<Map<String, dynamic>> scheduleDeletion({String? password}) async {
    final data = <String, dynamic>{};
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }
    final res = await _dio.post<Map<String, dynamic>>(
      _path(ApiEndpoints.userDeleteAccount),
      data: data,
    );
    return res.data ?? <String, dynamic>{};
  }

  Future<void> cancelScheduledDeletion() async {
    await _dio.delete<void>(_path(ApiEndpoints.userDeleteAccount));
  }
}
