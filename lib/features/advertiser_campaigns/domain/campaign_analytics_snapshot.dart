/// Parsed `GET /api/campaigns/:id/analytics` payload.
final class CampaignAnalyticsSnapshot {
  const CampaignAnalyticsSnapshot({
    required this.campaignType,
    required this.activeSince,
    required this.trafficTotal,
    required this.submissionsTotal,
    required this.dailyTraffic,
    required this.dailySubmissions,
  });

  final String campaignType;
  final DateTime? activeSince;
  final int trafficTotal;
  final int submissionsTotal;
  final List<CampaignDailyPoint> dailyTraffic;
  final List<CampaignDailyPoint> dailySubmissions;

  factory CampaignAnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return CampaignAnalyticsSnapshot(
      campaignType: (json['campaignType'] as String?) ?? 'LINK',
      activeSince: _parseDate(json['activeSince']),
      trafficTotal: (json['trafficTotal'] as num?)?.toInt() ?? 0,
      submissionsTotal: (json['submissionsTotal'] as num?)?.toInt() ?? 0,
      dailyTraffic: _points(json['dailyTraffic']),
      dailySubmissions: _points(json['dailySubmissions']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static List<CampaignDailyPoint> _points(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CampaignDailyPoint.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

final class CampaignDailyPoint {
  const CampaignDailyPoint({required this.dayKey, required this.value});

  final String dayKey;
  final int value;

  factory CampaignDailyPoint.fromJson(Map<String, dynamic> json) {
    return CampaignDailyPoint(
      dayKey: (json['dayKey'] as String?) ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }
}
