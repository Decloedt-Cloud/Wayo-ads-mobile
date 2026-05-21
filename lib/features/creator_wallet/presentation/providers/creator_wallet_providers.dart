import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/rate_limiter.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
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

/// Drops cached wallet / Stripe / business reads (login, logout, account switch).
void invalidateCreatorWalletProviders(Ref ref) {
  ref.read(creatorWalletRateLimiterProvider).reset();
  ref.invalidate(creatorWalletPageProvider);
  ref.invalidate(creatorStripeStatusProvider);
  ref.invalidate(creatorBusinessProfileProvider);
}

int? _creatorWalletSessionUserId(Ref ref) {
  return ref.watch(currentAppUserProvider)?.id;
}

/// Balance + platform limits + withdrawal history (`GET /api/creator/withdrawal`).
final creatorWalletPageProvider = FutureProvider<CreatorWalletPage>((
  ref,
) async {
  final userId = _creatorWalletSessionUserId(ref);
  if (userId == null) {
    throw StateError('Creator wallet requires an authenticated user');
  }
  ref.keepAlive();
  return ref
      .watch(creatorWalletRepositoryProvider)
      .fetchWalletPage(sessionUserId: userId);
});

/// Stripe Connect onboarding flags.
final creatorStripeStatusProvider = FutureProvider<CreatorStripeStatus>((
  ref,
) async {
  final userId = _creatorWalletSessionUserId(ref);
  if (userId == null) {
    throw StateError('Creator Stripe status requires an authenticated user');
  }
  ref.keepAlive();
  return ref
      .watch(creatorWalletRepositoryProvider)
      .fetchStripeStatus(sessionUserId: userId);
});

/// Creator business profile — gates Stripe onboarding (see
/// `Wayo-ads/src/app/api/creator/stripe-connect/onboard/route.ts`).
final creatorBusinessProfileProvider = FutureProvider<CreatorBusinessProfile>((
  ref,
) async {
  final userId = _creatorWalletSessionUserId(ref);
  if (userId == null) {
    throw StateError('Creator business profile requires an authenticated user');
  }
  ref.keepAlive();
  return ref
      .watch(creatorWalletRepositoryProvider)
      .fetchBusinessProfile(sessionUserId: userId);
});
