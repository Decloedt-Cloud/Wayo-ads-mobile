import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';

class ChangePasswordException implements Exception {
  ChangePasswordException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// [PATCH /api/user/password](Wayo-ads) — same contract as web settings.
final class ChangePasswordRemote {
  ChangePasswordRemote(this._dio);

  final Dio _dio;

  String get _path =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.userPassword);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      await _dio.patch<void>(
        _path,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'newPasswordConfirmation': confirmation,
        },
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      var msg = '';
      if (data is Map) {
        msg = (data['error'] ?? data['message'] ?? '').toString();
      }
      if (msg.isEmpty) {
        msg = e.message ?? 'Failed to change password';
      }
      throw ChangePasswordException(msg, statusCode: status);
    }
  }
}
