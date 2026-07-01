import 'creator_business_profile.dart';
import 'creator_tax_rates.dart';

/// Tax breakdown shown in the withdraw sheet when VAT applies.
final class CreatorWithdrawalFeeEstimate {
  const CreatorWithdrawalFeeEstimate({
    required this.grossCents,
    required this.platformFeeCents,
    required this.taxCents,
    required this.netCents,
    required this.platformFeeRate,
    required this.taxRatePercent,
  });

  final int grossCents;
  final int platformFeeCents;
  final int taxCents;
  final int netCents;
  final double platformFeeRate;
  /// Display rate for VAT line (e.g. 20 for 20%).
  final double taxRatePercent;

  bool get hasTax => taxCents > 0;
}

CreatorWithdrawalFeeEstimate? estimateCreatorWithdrawalFees({
  required int? grossCents,
  CreatorBusinessProfile? profile,
}) {
  if (grossCents == null || grossCents <= 0) return null;

  // Platform fee is deducted when views/clicks are validated (earnings), not
  // again at withdrawal — available balance is already net of that fee.
  const platformFeeCents = 0;
  const platformFeeRate = 0.0;

  final isIndividual =
      profile?.businessType == CreatorBusinessType.personal ||
      profile == null;
  final taxCents = estimateCreatorWithdrawalTaxCents(
    grossCents: grossCents,
    countryCode: profile?.countryCode,
    isIndividual: isIndividual,
    stateOrSubdivision: profile?.state,
  );

  final taxRatePercent = taxCents > 0
      ? ((taxCents / grossCents) * 10000).round() / 100
      : 0.0;

  final netCents = grossCents - taxCents;
  if (netCents < 0) return null;

  return CreatorWithdrawalFeeEstimate(
    grossCents: grossCents,
    platformFeeCents: platformFeeCents,
    taxCents: taxCents,
    netCents: netCents,
    platformFeeRate: platformFeeRate,
    taxRatePercent: taxRatePercent,
  );
}
