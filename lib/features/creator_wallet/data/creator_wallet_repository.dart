import '../../../core/network/rate_limiter.dart';
import '../../../core/network/request_deduplicator.dart';
import '../domain/creator_business_profile.dart';
import '../domain/creator_wallet_models.dart';
import 'creator_wallet_remote_datasource.dart';

/// Repository for the creator wallet — deduplicated reads, pass-through writes.
///
/// Mutations (withdraw, cancel, stripe URLs) intentionally bypass the rate
/// limiter: those are user-initiated one-shots that must reach the backend.
class CreatorWalletRepository {
  CreatorWalletRepository({
    required CreatorWalletRemoteDatasource remote,
    required RequestDeduplicator deduplicator,
    required RateLimiter rateLimiter,
  }) : _remote = remote,
       _dedup = deduplicator,
       _rate = rateLimiter;

  final CreatorWalletRemoteDatasource _remote;
  final RequestDeduplicator _dedup;
  final RateLimiter _rate;

  static String _walletKeyFor(int sessionUserId) =>
      'creator_wallet_$sessionUserId';

  static String _stripeKeyFor(int sessionUserId) =>
      'creator_wallet_stripe_$sessionUserId';

  static String _businessKeyFor(int sessionUserId) =>
      'creator_wallet_business_$sessionUserId';

  Future<CreatorWalletPage> fetchWalletPage({
    required int sessionUserId,
    CreatorWalletPage? fallback,
  }) async {
    final key = _walletKeyFor(sessionUserId);
    if (!_rate.canCall(key) && fallback != null) {
      return fallback;
    }
    _rate.mark(key);
    return _dedup.run<CreatorWalletPage>(
      key,
      () => _remote.fetchWalletPage(),
    );
  }

  Future<CreatorStripeStatus> fetchStripeStatus({
    required int sessionUserId,
    CreatorStripeStatus? fallback,
  }) async {
    final key = _stripeKeyFor(sessionUserId);
    if (!_rate.canCall(key) && fallback != null) {
      return fallback;
    }
    _rate.mark(key);
    return _dedup.run<CreatorStripeStatus>(
      key,
      _remote.fetchStripeStatus,
    );
  }

  Future<CreatorBusinessProfile> fetchBusinessProfile({
    required int sessionUserId,
    CreatorBusinessProfile? fallback,
  }) async {
    final key = _businessKeyFor(sessionUserId);
    if (!_rate.canCall(key) && fallback != null) {
      return fallback;
    }
    _rate.mark(key);
    return _dedup.run<CreatorBusinessProfile>(
      key,
      _remote.fetchBusinessProfile,
    );
  }

  Future<CreatorBusinessProfile> updateBusinessProfile(
    CreatorBusinessProfileInput input,
  ) => _remote.updateBusinessProfile(input);

  Future<CreatorWithdrawal> requestWithdrawal({required int amountCents}) =>
      _remote.requestWithdrawal(amountCents: amountCents);

  Future<void> cancelWithdrawal(String id) => _remote.cancelWithdrawal(id);

  Future<String> createStripeOnboardingUrl() => _remote.createOnboardingUrl();

  Future<String> createStripeLoginUrl() => _remote.createLoginUrl();
}
