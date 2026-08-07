import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../creator/presentation/providers/creator_session_gate.dart';
import '../../creator_wallet/domain/creator_business_profile.dart';
import '../../creator_wallet/presentation/providers/creator_wallet_providers.dart';
import '../domain/campaign_cost_estimate.dart';

final campaignCostRemoteProvider = Provider<CampaignCostRemote>((ref) {
  return CampaignCostRemote(ref.watch(wayoAdsDioProvider));
});

/// Fetches fee + tax from the same endpoints as web `useCampaignCostEstimate`.
final class CampaignCostRemote {
  CampaignCostRemote(this._dio);

  final Dio _dio;

  String _path(String endpoint) =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(endpoint);

  Future<PlatformFeesSnapshot> fetchPlatformFees() async {
    final res = await _dio.get<Object?>(_path(ApiEndpoints.platformFees));
    final data = res.data;
    if (data is Map) {
      return PlatformFeesSnapshot.fromJson(Map<String, dynamic>.from(data));
    }
    return const PlatformFeesSnapshot(platformFeePercentage: 5);
  }

  Future<TaxRateEstimate> fetchTaxRate({
    required String country,
    required int priceCents,
    required String profileType,
    String? subdivision,
  }) async {
    final res = await _dio.get<Object?>(
      _path(ApiEndpoints.tokensTaxRate),
      queryParameters: <String, dynamic>{
        'country': country,
        'priceCents': priceCents,
        'profileType': profileType,
        if (subdivision != null && subdivision.isNotEmpty)
          'subdivision': subdivision,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw const ServerException('Invalid tax-rate response');
    }
    return TaxRateEstimate.fromJson(Map<String, dynamic>.from(data));
  }
}

final platformFeesProvider =
    FutureProvider.autoDispose<PlatformFeesSnapshot>((ref) async {
  await awaitPostLoginBootstrap(ref);
  final remote = ref.watch(campaignCostRemoteProvider);
  return fetchWithSessionRetry(ref, remote.fetchPlatformFees);
});

/// Cost estimate for [budgetCents] — mirrors web assembly, server tax authority.
final campaignCostEstimateProvider = FutureProvider.autoDispose
    .family<CampaignCostEstimate?, int>((ref, budgetCents) async {
  final safe = budgetCents.clamp(0, 100000000);
  if (safe <= 0) return null;

  await awaitPostLoginBootstrap(ref);
  final fees = await ref.watch(platformFeesProvider.future);
  final feeCents = (safe * (fees.platformFeePercentage / 100)).round();

  CreatorBusinessProfile? profile;
  try {
    profile = await ref.watch(creatorBusinessProfileProvider.future);
  } catch (_) {
    profile = null;
  }

  final country = profile?.countryCode?.trim();
  if (country == null || country.isEmpty) {
    return CampaignCostEstimate.assemble(
      budgetCents: safe,
      platformFeePercentage: fees.platformFeePercentage,
      taxCents: 0,
      taxRate: 0,
      countryCode: null,
    );
  }

  final remote = ref.watch(campaignCostRemoteProvider);
  final profileType = profile!.businessType == CreatorBusinessType.personal
      ? 'INDIVIDUAL'
      : 'BUSINESS';
  final tax = await fetchWithSessionRetry(
    ref,
    () => remote.fetchTaxRate(
      country: country,
      priceCents: safe + feeCents,
      profileType: profileType,
      subdivision: profile?.state,
    ),
  );

  return CampaignCostEstimate.assemble(
    budgetCents: safe,
    platformFeePercentage: fees.platformFeePercentage,
    taxCents: tax.taxCents,
    taxRate: tax.effectiveRate,
    taxLabel: tax.taxLabel,
    countryCode: tax.countryCode ?? country,
  );
});
