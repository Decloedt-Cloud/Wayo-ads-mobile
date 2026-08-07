/// Parsed `GET /api/creator/analytics` payload (amounts in cents).
final class CreatorAnalyticsSnapshot {
  const CreatorAnalyticsSnapshot({
    required this.period,
    required this.days,
    required this.currency,
    required this.data,
    required this.summary,
    required this.campaigns,
    required this.campaignBreakdown,
  });

  final String period;
  final int days;
  final String currency;
  final List<CreatorAnalyticsDay> data;
  final CreatorAnalyticsSummary summary;
  final List<CreatorAnalyticsCampaign> campaigns;
  final List<CreatorAnalyticsCampaignBreakdown> campaignBreakdown;

  factory CreatorAnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return CreatorAnalyticsSnapshot(
      period: (json['period'] as String?) ?? '30d',
      days: (json['days'] as num?)?.toInt() ?? 30,
      currency: (json['currency'] as String?) ?? 'USD',
      data: _days(json['data']),
      summary: CreatorAnalyticsSummary.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : const {},
      ),
      campaigns: _campaigns(json['campaigns']),
      campaignBreakdown: _breakdown(json['campaignBreakdown']),
    );
  }

  static List<CreatorAnalyticsDay> _days(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CreatorAnalyticsDay.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<CreatorAnalyticsCampaign> _campaigns(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) =>
              CreatorAnalyticsCampaign.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  static List<CreatorAnalyticsCampaignBreakdown> _breakdown(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) => CreatorAnalyticsCampaignBreakdown.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }
}

final class CreatorAnalyticsDay {
  const CreatorAnalyticsDay({
    required this.date,
    required this.recordedViews,
    required this.validatedViews,
    required this.recordedClicks,
    required this.validatedClicks,
  });

  final String date;
  final int recordedViews;
  final int validatedViews;
  final int recordedClicks;
  final int validatedClicks;

  factory CreatorAnalyticsDay.fromJson(Map<String, dynamic> json) {
    return CreatorAnalyticsDay(
      date: (json['date'] as String?) ?? '',
      recordedViews: (json['recordedViews'] as num?)?.toInt() ?? 0,
      validatedViews: (json['validatedViews'] as num?)?.toInt() ?? 0,
      recordedClicks: (json['recordedClicks'] as num?)?.toInt() ?? 0,
      validatedClicks: (json['validatedClicks'] as num?)?.toInt() ?? 0,
    );
  }
}

final class CreatorAnalyticsSummary {
  const CreatorAnalyticsSummary({
    required this.totalRecordedViews,
    required this.totalValidatedViews,
    required this.viewValidationRate,
    required this.totalRecordedClicks,
    required this.totalValidatedClicks,
    required this.clickValidationRate,
    required this.totalEarnings,
    required this.pendingAmount,
  });

  final int totalRecordedViews;
  final int totalValidatedViews;
  final double viewValidationRate;
  final int totalRecordedClicks;
  final int totalValidatedClicks;
  final double clickValidationRate;
  final int totalEarnings;
  final int pendingAmount;

  factory CreatorAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return CreatorAnalyticsSummary(
      totalRecordedViews: (json['totalRecordedViews'] as num?)?.toInt() ?? 0,
      totalValidatedViews: (json['totalValidatedViews'] as num?)?.toInt() ?? 0,
      viewValidationRate: (json['viewValidationRate'] as num?)?.toDouble() ?? 0,
      totalRecordedClicks: (json['totalRecordedClicks'] as num?)?.toInt() ?? 0,
      totalValidatedClicks:
          (json['totalValidatedClicks'] as num?)?.toInt() ?? 0,
      clickValidationRate:
          (json['clickValidationRate'] as num?)?.toDouble() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toInt() ?? 0,
      pendingAmount: (json['pendingAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

final class CreatorAnalyticsCampaign {
  const CreatorAnalyticsCampaign({
    required this.id,
    required this.title,
    required this.status,
    required this.type,
  });

  final String id;
  final String title;
  final String status;
  final String type;

  factory CreatorAnalyticsCampaign.fromJson(Map<String, dynamic> json) {
    return CreatorAnalyticsCampaign(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
    );
  }
}

final class CreatorAnalyticsCampaignBreakdown {
  const CreatorAnalyticsCampaignBreakdown({
    required this.campaignId,
    required this.campaignName,
    required this.campaignType,
    required this.validatedViews,
    required this.validatedClicks,
    required this.earnings,
  });

  final String campaignId;
  final String campaignName;
  final String campaignType;
  final int validatedViews;
  final int validatedClicks;
  final int earnings;

  factory CreatorAnalyticsCampaignBreakdown.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreatorAnalyticsCampaignBreakdown(
      campaignId: (json['campaignId'] as String?) ?? '',
      campaignName: (json['campaignName'] as String?) ?? '',
      campaignType: (json['campaignType'] as String?) ?? '',
      validatedViews: (json['validatedViews'] as num?)?.toInt() ?? 0,
      validatedClicks: (json['validatedClicks'] as num?)?.toInt() ?? 0,
      earnings: (json['earnings'] as num?)?.toInt() ?? 0,
    );
  }
}
