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

/// Change password — Auth Bearer first, Wayo-ads proxy fallback on 404.
final class ChangePasswordRemote {
  ChangePasswordRemote(this._authDio, this._wayoAdsDio);

  final Dio _authDio;
  final Dio _wayoAdsDio;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final authPath =
        AuthRuntimeConfig.instance.authHttpPath('change-password');
    try {
      await _authDio.patch<void>(
        authPath,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmation,
        },
      );
      return;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        throw _fromDio(e);
      }
    }

    // Auth route not deployed yet — fall back to Wayo-ads (web contract).
    try {
      await _wayoAdsDio.patch<void>(
        AuthRuntimeConfig.instance.wayoAdsRequestPath(ApiEndpoints.userPassword),
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'newPasswordConfirmation': confirmation,
        },
      );
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  ChangePasswordException _fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    var msg = '';
    if (data is Map) {
      msg = (data['message'] ?? data['error'] ?? '').toString();
    }
    if (msg.isEmpty) {
      msg = e.message ?? 'Failed to change password';
    }
    return ChangePasswordException(msg, statusCode: status);
  }
}
