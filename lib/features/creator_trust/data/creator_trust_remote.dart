import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/wayo_ads_account_role.dart';
import '../../auth/presentation/providers/current_account_providers.dart';
import '../../creator/presentation/providers/creator_session_gate.dart';
import '../domain/creator_trust_score.dart';

final creatorTrustRemoteProvider = Provider<CreatorTrustRemote>((ref) {
  return CreatorTrustRemote(ref.watch(wayoAdsDioProvider));
});

class CreatorTrustRemote {
  CreatorTrustRemote(this._dio);

  final Dio _dio;

  Future<CreatorTrustScoreSnapshot> fetch() async {
    try {
      final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
        ApiEndpoints.creatorTrustScore,
      );
      final res = await _dio.get<Map<String, dynamic>>(path);
      final data = res.data;
      if (data == null) throw const ServerException('Empty response');
      if (data['error'] is String) {
        throw ServerException(data['error'] as String);
      }
      return CreatorTrustScoreSnapshot.fromJson(data);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['error'] is String) {
        throw ServerException(body['error'] as String, e.response?.statusCode);
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(
        e.message ?? 'Request failed',
        e.response?.statusCode,
      );
    }
  }
}

/// Fetches trust score only after auth + access token are ready.
///
/// Anonymous / non-creator sessions never hit the API. At most one retry after
/// session bootstrap (via [fetchWithSessionRetry]); 401 is not maintenance.
final creatorTrustScoreProvider =
    FutureProvider.autoDispose<CreatorTrustScoreSnapshot>((ref) async {
      final auth = await ref.watch(authNotifierProvider.future);
      if (auth is! AuthAuthenticated) {
        throw StateError('Trust score requires an authenticated session');
      }
      if (auth.user.wayoAdsRole != WayoAdsAccountRole.creator) {
        throw StateError('Trust score is creator-only');
      }

      await awaitPostLoginBootstrap(ref);

      final storage = ref.read(secureStorageProvider);
      var token = await storage.getAccessToken();
      if (token == null || token.isEmpty) {
        // Single short wait for secure-storage hydration — no retry loop.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        token = await storage.getAccessToken();
      }
      if (token == null || token.isEmpty) {
        throw StateError('Trust score requires an access token');
      }

      // Ensure currentAppUser is hydrated (role gate already checked auth.user).
      ref.read(currentAppUserProvider);

      return fetchWithSessionRetry(
        ref,
        () => ref.read(creatorTrustRemoteProvider).fetch(),
        attempts: 2,
      );
    });
