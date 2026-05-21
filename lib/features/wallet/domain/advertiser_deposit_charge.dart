/// Bank fee on wallet top-ups — mirrors `WALLET_DEPOSIT_BANK_FEE_BPS` in Wayo-ads.
const int kAdvertiserWalletDepositBankFeeBps = 369;

/// Breakdown for advertiser wallet deposit (wallet credit + bank fee only; no tax at deposit).
final class AdvertiserDepositCharge {
  const AdvertiserDepositCharge({
    required this.walletAmountCents,
    required this.bankFeeCents,
    required this.totalChargedCents,
  });

  final int walletAmountCents;
  final int bankFeeCents;
  final int totalChargedCents;
}

int advertiserWalletDepositBankFeeCents(int walletAmountCents) {
  if (walletAmountCents <= 0) {
    return 0;
  }
  return ((walletAmountCents * kAdvertiserWalletDepositBankFeeBps) / 10000)
      .round();
}

AdvertiserDepositCharge estimateAdvertiserDepositCharge({
  required int walletAmountCents,
}) {
  if (walletAmountCents <= 0) {
    return const AdvertiserDepositCharge(
      walletAmountCents: 0,
      bankFeeCents: 0,
      totalChargedCents: 0,
    );
  }
  final bankFeeCents = advertiserWalletDepositBankFeeCents(walletAmountCents);
  return AdvertiserDepositCharge(
    walletAmountCents: walletAmountCents,
    bankFeeCents: bankFeeCents,
    totalChargedCents: walletAmountCents + bankFeeCents,
  );
}
