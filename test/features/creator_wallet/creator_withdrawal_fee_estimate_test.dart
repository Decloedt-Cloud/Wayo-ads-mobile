import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/creator_wallet/domain/creator_business_profile.dart';
import 'package:wayoadsgo/features/creator_wallet/domain/creator_withdrawal_fee_estimate.dart';

void main() {
  test('estimate applies VAT only (no withdrawal platform fee)', () {
    const profile = CreatorBusinessProfile(
      businessType: CreatorBusinessType.personal,
      businessInfoComplete: true,
      countryCode: 'FR',
    );

    final est = estimateCreatorWithdrawalFees(
      grossCents: 1000,
      profile: profile,
    );

    expect(est, isNotNull);
    expect(est!.grossCents, 1000);
    expect(est.platformFeeCents, 0);
    expect(est.taxCents, 200);
    expect(est.netCents, 800);
  });
}
