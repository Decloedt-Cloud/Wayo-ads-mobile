import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/rate_limiter.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../data/creator_wallet_remote_datasource.dart';
import '../../data/creator_wallet_repository.dart';
import '../../domain/creator_business_profile.dart';
import '../../domain/creator_wallet_models.dart';

/// 2 s limiter — mirrors the dashboard cadence to avoid backend hammering.
final creatorWalletRateLimiterProvider = Provider<RateLimiter>((ref) {
  ref.keepAlive();
  return RateLimiter(minInterval: const Duration(seconds: 2));
});

final creatorWalletRemoteProvider = Provider<CreatorWalletRemoteDatasource>((
  ref,
) {
  return CreatorWalletRemoteDatasource(ref.watch(wayoAdsDioProvider));
});

final creatorWalletRepositoryProvider = Provider<CreatorWalletRepository>((
  ref,
) {
  ref.keepAlive();
  return CreatorWalletRepository(
    remote: ref.watch(creatorWalletRemoteProvider),
    deduplicator: ref.watch(requestDeduplicatorProvider),
    rateLimiter: ref.watch(creatorWalletRateLimiterProvider),
  );
});

/// Balance + platform limits + withdrawal history (`GET /api/creator/withdrawal`).
final creatorWalletPageProvider = FutureProvider<CreatorWalletPage>((
  ref,
) async {
  ref.keepAlive();
  return ref.watch(creatorWalletRepositoryProvider).fetchWalletPage();
});

/// Stripe Connect onboarding flags.
final creatorStripeStatusProvider = FutureProvider<CreatorStripeStatus>((
  ref,
) async {
  ref.keepAlive();
  return ref.watch(creatorWalletRepositoryProvider).fetchStripeStatus();
});

/// Creator business profile — gates Stripe onboarding (see
/// `Wayo-ads/src/app/api/creator/stripe-connect/onboard/route.ts`).
final creatorBusinessProfileProvider = FutureProvider<CreatorBusinessProfile>((
  ref,
) async {
  ref.keepAlive();
  return ref.watch(creatorWalletRepositoryProvider).fetchBusinessProfile();
});
