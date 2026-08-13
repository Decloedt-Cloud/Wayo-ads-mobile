import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_oauth_extras.dart';
import '../../../core/network/request_flags.dart';
import '../data/models/auth_response.dart';
import 'passkey_exceptions.dart';
import 'passkey_models.dart';

final passkeyApiProvider = Provider<PasskeyApi>((ref) {
  return PasskeyApi(ref.watch(dioProvider));
});

class PasskeyApi {
  PasskeyApi(this._dio);

  final Dio _dio;

  Map<String, dynamic> _data(Map<String, dynamic>? body) {
    if (body == null) throw const PasskeyNetworkError('Empty response');
    if (body['success'] == false) {
      final errors = body['errors'];
      final code = errors is Map ? errors['code'] as String? : null;
      final msg = body['message'] as String? ?? 'Request failed';
      if (code == 'passkey_expired_challenge') {
        throw const PasskeyExpiredChallenge();
      }
      if (code == 'passkey_limit_reached') {
        throw PasskeyLimitReached(msg);
      }
      if (code == 'passkey_last_credential') {
        throw PasskeyLastCredential(msg);
      }
      throw PasskeyServerRejected(msg);
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const PasskeyServerRejected('Malformed response');
  }

  Future<({bool loginEnabled, bool registrationEnabled, String? rpId})>
      fetchServerFlags() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        AuthRuntimeConfig.instance.authHttpPath('passkeys/available'),
        options: Options(extra: {kSkipAuthInjection: true}),
      );
      final data = _data(res.data);
      return (
        loginEnabled: data['login_enabled'] as bool? ?? true,
        registrationEnabled: data['registration_enabled'] as bool? ?? true,
        rpId: data['rp_id'] as String?,
      );
    } on PasskeyException {
      rethrow;
    } on DioException catch (e) {
      throw PasskeyNetworkError(e.message);
    }
  }

  Future<PasskeyAuthOptions> authenticateOptions() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        AuthRuntimeConfig.instance.authHttpPath('passkeys/authenticate/options'),
        options: Options(extra: {kSkipAuthInjection: true})
          ..disableRetry = true,
      );
      return PasskeyAuthOptions.fromData(_data(res.data));
    } on PasskeyException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<AuthResponse> authenticateVerify({
    required String challengeId,
    required Map<String, dynamic> credential,
  }) async {
    try {
      final cfg = AuthRuntimeConfig.instance;
      final res = await _dio.post<Map<String, dynamic>>(
        cfg.authHttpPath('passkeys/authenticate/verify'),
        data: mergeWayoAuthPayload({
          'challenge_id': challengeId,
          'credential': credential,
          if (cfg.authAppName.isNotEmpty) 'app': cfg.authAppName,
          if (cfg.wayoAdsAppKey.isNotEmpty) 'app_key': cfg.wayoAdsAppKey,
        }),
        options: Options(extra: {kSkipAuthInjection: true})
          ..disableRetry = true,
      );
      final body = res.data;
      if (body == null) throw const PasskeyNetworkError('Empty response');
      if (body['success'] == false) {
        final errors = body['errors'];
        final code = errors is Map ? errors['code'] as String? : null;
        if (code == 'passkey_expired_challenge') {
          throw const PasskeyExpiredChallenge();
        }
        if (code == 'passkey_not_found') {
          throw const PasskeyNotFound();
        }
        throw PasskeyServerRejected(
          body['message'] as String? ?? 'Passkey sign-in failed',
        );
      }
      return AuthResponse.fromJson(body);
    } on PasskeyException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<PasskeyAuthOptions> registerOptions() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        AuthRuntimeConfig.instance.authHttpPath('passkeys/register/options'),
      );
      return PasskeyAuthOptions.fromData(_data(res.data));
    } on PasskeyException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<PasskeyInfo> registerVerify({
    required String challengeId,
    required String name,
    required Map<String, dynamic> credential,
    String? provider,
    String? platform,
    String? deviceName,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        AuthRuntimeConfig.instance.authHttpPath('passkeys/register/verify'),
        data: {
          'challenge_id': challengeId,
          'name': name,
          'credential': credential,
          if (provider != null) 'provider': provider,
          if (platform != null) 'platform': platform,
          if (deviceName != null) 'device_name': deviceName,
        },
      );
      final data = _data(res.data);
      return PasskeyInfo.fromJson(data['passkey'] as Map<String, dynamic>);
    } on PasskeyException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<List<PasskeyInfo>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        AuthRuntimeConfig.instance.authHttpPath('passkeys'),
      );
      final data = _data(res.data);
      final list = data['passkeys'] as List<dynamic>? ?? const [];
      return list
          .map((e) => PasskeyInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PasskeyException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<void> rename(int id, String name) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        AuthRuntimeConfig.instance.authHttpPath('passkeys/$id'),
        data: {'name': name},
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<void> revoke(int id) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        AuthRuntimeConfig.instance.authHttpPath('passkeys/$id'),
      );
      final body = res.data;
      if (body != null && body['success'] == false) {
        final errors = body['errors'];
        final code = errors is Map ? errors['code'] as String? : null;
        final msg = body['message'] as String? ?? 'Unable to remove passkey';
        if (code == 'passkey_last_credential') {
          throw PasskeyLastCredential(msg);
        }
        throw PasskeyServerRejected(msg);
      }
    } on PasskeyException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  PasskeyException _mapDio(DioException e) {
    final data = e.response?.data;
    final msg = data is Map ? data['message'] as String? : e.message;
    final errors = data is Map ? data['errors'] : null;
    final code = errors is Map ? errors['code'] as String? : null;
    if (code == 'passkey_expired_challenge') {
      return const PasskeyExpiredChallenge();
    }
    if (code == 'passkey_not_found') {
      return const PasskeyNotFound();
    }
    if (code == 'passkey_last_credential') {
      return PasskeyLastCredential(msg);
    }
    if (code == 'passkey_limit_reached') {
      return PasskeyLimitReached(msg);
    }
    if (code == 'passkey_registration_rejected') {
      return PasskeyServerRejected(msg);
    }
    if (code == 'passkey_server_rejected' || e.response?.statusCode == 401) {
      return PasskeyServerRejected(msg);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return PasskeyNetworkError(msg);
    }
    return PasskeyServerRejected(msg);
  }
}
