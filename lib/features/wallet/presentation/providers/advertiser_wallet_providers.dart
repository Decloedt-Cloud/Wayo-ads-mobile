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

/// Abandoned Stripe deposit checkout + ACH-processing/wire-awaiting deposits —
/// [GET /api/wallet/deposit-intent].
final advertiserPendingDepositsSnapshotProvider =
    FutureProvider.autoDispose<AdvertiserPendingDepositsSnapshot>((ref) async {
      return ref.read(advertiserWalletRepositoryProvider).fetchPendingDeposit();
    });

/// Convenience accessor for just the single in-progress card/ACH checkout.
final advertiserPendingDepositProvider =
    FutureProvider.autoDispose<AdvertiserPendingDeposit?>((ref) async {
      final snapshot = await ref.watch(advertiserPendingDepositsSnapshotProvider.future);
      return snapshot.pending;
    });

/// Saved Stripe cards — only fetch when [enabled] (payment step visible),
/// mirroring the web `useSavedCards('wallet', enabled)` behavior.
final advertiserSavedCardsProvider =
    FutureProvider.autoDispose.family<SavedCardsResult, bool>((ref, enabled) async {
      if (!enabled) return SavedCardsResult.empty;
      final repo = ref.read(advertiserWalletRepositoryProvider);
      final result = await repo.fetchSavedCards();
      if (!result.projectionInitialized) {
        try {
          return await repo.refreshSavedCards();
        } catch (_) {
          return result;
        }
      }
      return result;
    });
