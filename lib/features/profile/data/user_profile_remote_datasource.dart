import 'package:dio/dio.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/wayo_ads_user_profile.dart';

class UserProfileUpdateException implements Exception {
  UserProfileUpdateException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class UserProfileRemoteDatasource {
  UserProfileRemoteDatasource(this._dio);

  final Dio _dio;

  String _path(String endpoint) =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(endpoint);

  Future<WayoAdsUserProfile> fetchProfile({bool bypassCache = false}) async {
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
      throw const FormatException('Empty profile response');
    }
    return WayoAdsUserProfile.fromResponseJson(data);
  }

  Future<WayoAdsUserProfile> updateProfile({
    String? name,
    String? image,
    bool removeImage = false,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (image != null) body['image'] = image;
    if (removeImage) body['removeImage'] = true;

    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        _path(ApiEndpoints.userProfile),
        data: body,
      );
      final data = res.data;
      if (data == null) {
        throw const FormatException('Empty profile response');
      }
      return WayoAdsUserProfile.fromResponseJson(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (data is Map) {
        final msg = (data['error'] ?? data['message'] ?? '').toString();
        var code = data['code']?.toString();
        if (code == null || code.isEmpty) {
          if (status == 409) {
            code = 'name_taken';
          } else if (status == 422) {
            final lower = msg.toLowerCase();
            if (lower.contains('already taken') || lower == 'name_taken') {
              code = 'name_taken';
            } else if (lower.contains('alphabet') || lower == 'name_invalid') {
              code = 'name_invalid';
            }
          }
        }
        if (msg.isNotEmpty) {
          throw UserProfileUpdateException(msg, code: code);
        }
      }
      rethrow;
    }
  }
}
