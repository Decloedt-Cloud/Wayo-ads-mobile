import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/advertiser_wallet_repository.dart';
import '../../domain/wallet_models.dart';

/// Full wallet payload for advertisers (GET /api/wallet + transactions).
final advertiserWalletPageProvider =
    FutureProvider.autoDispose<AdvertiserWalletPageData>((ref) async {
      return ref.read(advertiserWalletRepositoryProvider).fetchWalletPage();
    });

/// Cached PSP config (Stripe publishable key, etc.).
final walletPspConfigProvider = FutureProvider.autoDispose<WalletPspConfig>((
  ref,
) async {
  return ref.read(advertiserWalletRepositoryProvider).fetchPspConfig();
});
