/// Advertiser wallet deposit charge — mirrors Wayo-ads web / API (1:1).
///
/// Stripe processing fees are deducted at settlement from the charged amount
/// (see `desiredNetAmountCents` / wallet history `stripeFeeCents`). They are
/// **not** added on top of the deposit amount at checkout.
final class AdvertiserDepositCharge {
  const AdvertiserDepositCharge({
    required this.walletAmountCents,
    required this.totalChargedCents,
  });

  /// Amount credited to Available after settlement (desired net).
  final int walletAmountCents;

  /// Amount charged on the PaymentIntent — same as [walletAmountCents] (1:1).
  final int totalChargedCents;
}

AdvertiserDepositCharge estimateAdvertiserDepositCharge({
  required int walletAmountCents,
}) {
  if (walletAmountCents <= 0) {
    return const AdvertiserDepositCharge(
      walletAmountCents: 0,
      totalChargedCents: 0,
    );
  }
  return AdvertiserDepositCharge(
    walletAmountCents: walletAmountCents,
    totalChargedCents: walletAmountCents,
  );
}
