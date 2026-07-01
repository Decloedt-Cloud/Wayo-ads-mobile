import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';

import '../domain/account_deletion_anonymized.dart';

/// Wayo-ads `/api/user/profile` subset used for account deletion flow.
final class WayoAdsDeletionProfile {
  const WayoAdsDeletionProfile({
    required this.id,
    required this.email,
    required this.roles,
    this.name,
    this.status,
    this.deletionRequestedAt,
    this.deletionRequiresPassword = true,
  });

  final String id;
  final String email;
  final String roles;
  final String? name;
  final String? status;
  final DateTime? deletionRequestedAt;
  /// From Wayo-ads profile: false for Google/Apple-only accounts (no password in Auth_Wayo).
  final bool deletionRequiresPassword;

  bool get hasAdvertiserRole => roles.toUpperCase().contains('ADVERTISER');
  bool get hasCreatorRole => roles.toUpperCase().contains('CREATOR');

  bool get isAnonymized =>
      isAnonymizedWayoAdsAccount(status: status, email: email);

  /// Merge server-confirmed schedule time when GET /profile lags behind POST.
  WayoAdsDeletionProfile withDeletionScheduledAt(DateTime at) {
    return WayoAdsDeletionProfile(
      id: id,
      email: email,
      roles: roles,
      name: name,
      status: status,
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
    final rawDel =
        u['deletionRequestedAt'] ?? u['deletion_requested_at'];
    if (rawDel is String && rawDel.isNotEmpty) {
      del = DateTime.tryParse(rawDel);
    }
    final drp =
        u['deletionRequiresPassword'] ?? u['deletion_requires_password'];
    final requiresPw = _parseBoolField(drp, fallback: true);
    final statusRaw = u['status'];
    final status = statusRaw == null ? null : _stringField(statusRaw);
    final statusValue = (status == null || status.isEmpty) ? null : status;
    return WayoAdsDeletionProfile(
      id: _stringField(u['id']),
      email: _stringField(u['email']),
      roles: _stringField(u['roles']),
      name: u['name'] == null ? null : _stringField(u['name']),
      status: statusValue,
      deletionRequestedAt: del,
      deletionRequiresPassword: requiresPw,
    );
  }

  static bool _parseBoolField(dynamic v, {required bool fallback}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return fallback;
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

  /// Schedules account deletion.
  ///
  /// - Password users send [password].
  /// - Google/Apple-only users send a fresh OAuth [reauth] credential (the mobile
  ///   equivalent of the web "Re-authenticate to delete" step): the backend has no
  ///   NextAuth cookie for Bearer requests, so it verifies this credential via
  ///   Auth_Wayo before scheduling.
  Future<Map<String, dynamic>> scheduleDeletion({
    String? password,
    Map<String, dynamic>? reauth,
  }) async {
    final data = <String, dynamic>{};
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }
    if (reauth != null && reauth.isNotEmpty) {
      data['reauth'] = Map<String, dynamic>.from(reauth);
    }
    final res = await _dio.post<Map<String, dynamic>>(
      _path(ApiEndpoints.userDeleteAccount),
      data: data.isEmpty ? null : data,
    );
    final body = res.data ?? <String, dynamic>{};
    return _normalizeScheduleDeletionResponse(body);
  }

  /// Top-level or nested `user` shapes from Wayo-ads POST delete-account.
  static Map<String, dynamic> _normalizeScheduleDeletionResponse(
    Map<String, dynamic> body,
  ) {
    final out = Map<String, dynamic>.from(body);
    if (out['deletionRequestedAt'] == null &&
        out['deletion_requested_at'] != null) {
      out['deletionRequestedAt'] = out['deletion_requested_at'];
    }
    final user = out['user'];
    if (user is Map<String, dynamic>) {
      final nested =
          user['deletionRequestedAt'] ?? user['deletion_requested_at'];
      if (out['deletionRequestedAt'] == null && nested != null) {
        out['deletionRequestedAt'] = nested;
      }
    }
    return out;
  }

  Future<void> cancelScheduledDeletion() async {
    await _dio.delete<void>(_path(ApiEndpoints.userDeleteAccount));
  }
}
