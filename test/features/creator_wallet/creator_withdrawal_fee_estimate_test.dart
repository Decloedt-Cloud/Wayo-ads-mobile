import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/creator_wallet/domain/creator_business_profile.dart';
import 'package:wayoadsgo/features/creator_wallet/domain/creator_withdrawal_fee_estimate.dart';
import 'package:wayoadsgo/features/creator_wallet/domain/creator_wallet_models.dart';

void main() {
  test('estimate matches web breakdown for 10 USD FR personal', () {
    const limits = CreatorPlatformLimits(
      minimumWithdrawalCents: 1000,
      pendingHoldDays: 7,
      defaultCurrency: 'USD',
      platformFeeRate: 0.05,
    );
    const profile = CreatorBusinessProfile(
      businessType: CreatorBusinessType.personal,
      businessInfoComplete: true,
      countryCode: 'FR',
    );

    final est = estimateCreatorWithdrawalFees(
      grossCents: 1000,
      limits: limits,
      profile: profile,
    );

    expect(est, isNotNull);
    expect(est!.grossCents, 1000);
    expect(est.platformFeeCents, 50);
    expect(est.taxCents, 200);
    expect(est.netCents, 750);
  });
}
