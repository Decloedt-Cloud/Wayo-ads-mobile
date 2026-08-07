import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/creator_trust/domain/creator_trust_score.dart';

void main() {
  group('CreatorTrustScoreSnapshot.fromJson', () {
    test('parses breakdown and quality multiplier', () {
      final snap = CreatorTrustScoreSnapshot.fromJson({
        'trustScore': 82,
        'tier': 'Gold',
        'isVerified': true,
        'verificationLevel': 'full',
        'hasMetrics': true,
        'weeklyDelta': 3,
        'potentialCpmIncrease': '12%',
        'qualityMultiplier': 1.15,
        'breakdown': {
          'validationRatePoints': 40,
          'fraudScorePoints': 25,
          'anomalyScorePoints': 17,
        },
      });
      expect(snap.trustScore, 82);
      expect(snap.tier, 'Gold');
      expect(snap.qualityMultiplier, 1.15);
      expect(snap.breakdown?.validationRatePoints, 40);
      expect(snap.breakdown?.fraudScorePoints, 25);
      expect(snap.breakdown?.anomalyScorePoints, 17);
    });

    test('tolerates missing breakdown', () {
      final snap = CreatorTrustScoreSnapshot.fromJson({
        'trustScore': 10,
        'hasMetrics': false,
      });
      expect(snap.breakdown, isNull);
      expect(snap.isVerified, isFalse);
    });
  });
}
