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

  static const String _walletKey = 'creator_wallet';
  static const String _stripeKey = 'creator_wallet_stripe_status';
  static const String _businessKey = 'creator_wallet_business_profile';

  Future<CreatorWalletPage> fetchWalletPage({
    CreatorWalletPage? fallback,
  }) async {
    if (!_rate.canCall(_walletKey) && fallback != null) {
      return fallback;
    }
    _rate.mark(_walletKey);
    return _dedup.run<CreatorWalletPage>(
      _walletKey,
      () => _remote.fetchWalletPage(),
    );
  }

  Future<CreatorStripeStatus> fetchStripeStatus({
    CreatorStripeStatus? fallback,
  }) async {
    if (!_rate.canCall(_stripeKey) && fallback != null) {
      return fallback;
    }
    _rate.mark(_stripeKey);
    return _dedup.run<CreatorStripeStatus>(
      _stripeKey,
      _remote.fetchStripeStatus,
    );
  }

  Future<CreatorBusinessProfile> fetchBusinessProfile({
    CreatorBusinessProfile? fallback,
  }) async {
    if (!_rate.canCall(_businessKey) && fallback != null) {
      return fallback;
    }
    _rate.mark(_businessKey);
    return _dedup.run<CreatorBusinessProfile>(
      _businessKey,
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
