/// Safe subset of `GET /api/creator/trust-score` for mobile display.
final class CreatorTrustScoreSnapshot {
  const CreatorTrustScoreSnapshot({
    required this.trustScore,
    required this.tier,
    required this.isVerified,
    required this.verificationLevel,
    required this.hasMetrics,
    this.weeklyDelta,
    this.potentialCpmIncrease,
    this.qualityMultiplier,
    this.breakdown,
  });

  final int trustScore;
  final String? tier;
  final bool isVerified;
  final String? verificationLevel;
  final bool hasMetrics;
  final int? weeklyDelta;
  final String? potentialCpmIncrease;
  final double? qualityMultiplier;
  final CreatorTrustBreakdown? breakdown;

  factory CreatorTrustScoreSnapshot.fromJson(Map<String, dynamic> json) {
    CreatorTrustBreakdown? breakdown;
    final raw = json['breakdown'];
    if (raw is Map) {
      breakdown = CreatorTrustBreakdown.fromJson(Map<String, dynamic>.from(raw));
    }
    return CreatorTrustScoreSnapshot(
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 0,
      tier: json['tier'] as String?,
      isVerified: json['isVerified'] == true,
      verificationLevel: json['verificationLevel'] as String?,
      hasMetrics: json['hasMetrics'] == true,
      weeklyDelta: (json['weeklyDelta'] as num?)?.toInt(),
      potentialCpmIncrease: json['potentialCpmIncrease'] as String?,
      qualityMultiplier: (json['qualityMultiplier'] as num?)?.toDouble(),
      breakdown: breakdown,
    );
  }
}

final class CreatorTrustBreakdown {
  const CreatorTrustBreakdown({
    required this.validationRatePoints,
    required this.fraudScorePoints,
    required this.anomalyScorePoints,
  });

  final int validationRatePoints;
  final int fraudScorePoints;
  final int anomalyScorePoints;

  factory CreatorTrustBreakdown.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return CreatorTrustBreakdown(
      validationRatePoints: asInt(json['validationRatePoints']),
      fraudScorePoints: asInt(json['fraudScorePoints']),
      anomalyScorePoints: asInt(json['anomalyScorePoints']),
    );
  }
}
