import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../../creator/presentation/providers/creator_session_gate.dart';
import '../domain/notification_preferences.dart';

final notificationPrefsRemoteProvider = Provider<NotificationPrefsRemote>((
  ref,
) {
  return NotificationPrefsRemote(ref.watch(wayoAdsDioProvider));
});

final class NotificationPrefsRemote {
  NotificationPrefsRemote(this._dio);

  final Dio _dio;

  String _path(String endpoint) =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(endpoint);

  Future<NotificationPreferencesSnapshot> fetch() async {
    try {
      final res = await _dio.get<Object?>(
        _path(ApiEndpoints.notificationsPreferences),
      );
      final data = res.data;
      if (data is! Map) {
        throw const ServerException('Invalid preferences response');
      }
      return NotificationPreferencesSnapshot.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<NotificationPreferencesSnapshot> patchChannel({
    required String key,
    required bool value,
  }) async {
    try {
      final res = await _dio.patch<Object?>(
        _path(ApiEndpoints.notificationsPreferences),
        data: <String, dynamic>{key: value},
      );
      final data = res.data;
      if (data is! Map) {
        throw const ServerException('Invalid preferences response');
      }
      return NotificationPreferencesSnapshot.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<NotificationPreferencesSnapshot> patchCategory({
    required NotificationPrefCategory category,
    required String channel,
    required bool enabled,
  }) async {
    try {
      final res = await _dio.patch<Object?>(
        _path(ApiEndpoints.notificationsPreferences),
        data: <String, dynamic>{
          'category': category.name,
          'channel': channel,
          'enabled': enabled,
        },
      );
      final data = res.data;
      if (data is! Map) {
        throw const ServerException('Invalid preferences response');
      }
      return NotificationPreferencesSnapshot.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  AuthException _mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    final code = e.response?.statusCode;
    if (code == 401) return const SessionInvalidException();
    final data = e.response?.data;
    var message = e.message ?? 'Request failed';
    if (data is Map) {
      final err = data['error'] ?? data['message'];
      if (err != null && '$err'.isNotEmpty) message = '$err';
    }
    return ServerException(message, code);
  }
}

final notificationPreferencesProvider =
    FutureProvider.autoDispose<NotificationPreferencesSnapshot>((ref) async {
      await awaitPostLoginBootstrap(ref);
      return fetchWithSessionRetry(
        ref,
        () => ref.read(notificationPrefsRemoteProvider).fetch(),
      );
    });
