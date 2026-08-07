/// Parsed `GET /api/advertiser/campaigns/:id/financial-summary` (amounts in cents).
final class CampaignFinancialSummary {
  const CampaignFinancialSummary({
    required this.campaignId,
    required this.campaignTitle,
    required this.campaignStatus,
    required this.totalBudget,
    required this.lockedBudget,
    required this.spentBillable,
    required this.paidToCreators,
    required this.pendingPayouts,
    required this.reservedAmount,
    required this.underReviewAmount,
    required this.remainingBudget,
    required this.effectiveCpm,
    required this.validationRate,
    required this.fraudBlockRate,
    required this.confidenceScore,
    required this.confidenceBadge,
    required this.totalViews,
    required this.validatedViews,
    required this.billableViews,
    required this.totalClicks,
    required this.validatedClicks,
    required this.billableClicks,
    required this.dailySpend,
  });

  final String campaignId;
  final String campaignTitle;
  final String campaignStatus;
  final int totalBudget;
  final int lockedBudget;
  final int spentBillable;
  final int paidToCreators;
  final int pendingPayouts;
  final int reservedAmount;
  final int underReviewAmount;
  final int remainingBudget;
  final double effectiveCpm;
  final double validationRate;
  final double fraudBlockRate;
  final int confidenceScore;
  final String confidenceBadge;
  final int totalViews;
  final int validatedViews;
  final int billableViews;
  final int totalClicks;
  final int validatedClicks;
  final int billableClicks;
  final List<CampaignDailySpend> dailySpend;

  factory CampaignFinancialSummary.fromJson(Map<String, dynamic> json) {
    final daily = <CampaignDailySpend>[];
    final rawDaily = json['dailySpend'];
    if (rawDaily is List) {
      for (final e in rawDaily) {
        if (e is Map) {
          daily.add(CampaignDailySpend.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return CampaignFinancialSummary(
      campaignId: (json['campaignId'] as String?) ?? '',
      campaignTitle: (json['campaignTitle'] as String?) ?? '',
      campaignStatus: (json['campaignStatus'] as String?) ?? '',
      totalBudget: (json['totalBudget'] as num?)?.toInt() ?? 0,
      lockedBudget: (json['lockedBudget'] as num?)?.toInt() ?? 0,
      spentBillable: (json['spentBillable'] as num?)?.toInt() ?? 0,
      paidToCreators: (json['paidToCreators'] as num?)?.toInt() ?? 0,
      pendingPayouts: (json['pendingPayouts'] as num?)?.toInt() ?? 0,
      reservedAmount: (json['reservedAmount'] as num?)?.toInt() ?? 0,
      underReviewAmount: (json['underReviewAmount'] as num?)?.toInt() ?? 0,
      remainingBudget: (json['remainingBudget'] as num?)?.toInt() ?? 0,
      effectiveCpm: (json['effectiveCPM'] as num?)?.toDouble() ?? 0,
      validationRate: (json['validationRate'] as num?)?.toDouble() ?? 0,
      fraudBlockRate: (json['fraudBlockRate'] as num?)?.toDouble() ?? 0,
      confidenceScore: (json['confidenceScore'] as num?)?.toInt() ?? 0,
      confidenceBadge: (json['confidenceBadge'] as String?) ?? 'MONITOR',
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      validatedViews: (json['validatedViews'] as num?)?.toInt() ?? 0,
      billableViews: (json['billableViews'] as num?)?.toInt() ?? 0,
      totalClicks: (json['totalClicks'] as num?)?.toInt() ?? 0,
      validatedClicks: (json['validatedClicks'] as num?)?.toInt() ?? 0,
      billableClicks: (json['billableClicks'] as num?)?.toInt() ?? 0,
      dailySpend: daily,
    );
  }
}

final class CampaignDailySpend {
  const CampaignDailySpend({
    required this.date,
    required this.spend,
    required this.views,
    required this.clicks,
  });

  final String date;
  final int spend;
  final int views;
  final int clicks;

  factory CampaignDailySpend.fromJson(Map<String, dynamic> json) {
    return CampaignDailySpend(
      date: (json['date'] as String?) ?? '',
      spend: (json['spend'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      clicks: (json['clicks'] as num?)?.toInt() ?? 0,
    );
  }
}
