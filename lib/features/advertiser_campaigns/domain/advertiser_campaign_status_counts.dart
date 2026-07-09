/// Tab totals from `GET /api/campaigns?advertiserOnly=true` → `statusCounts`.
final class AdvertiserCampaignStatusCounts {
  const AdvertiserCampaignStatusCounts({
    this.active = 0,
    this.draft = 0,
    this.paused = 0,
    this.underReview = 0,
    this.completed = 0,
    this.cancelled = 0,
  });

  final int active;
  final int draft;
  final int paused;
  final int underReview;
  final int completed;
  final int cancelled;

  int countForApiStatus(String status) => switch (status.toUpperCase()) {
    'ACTIVE' => active,
    'DRAFT' => draft,
    'PAUSED' => paused,
    'UNDER_REVIEW' => underReview,
    'COMPLETED' => completed,
    'CANCELLED' => cancelled,
    _ => 0,
  };

  factory AdvertiserCampaignStatusCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AdvertiserCampaignStatusCounts();
    int read(String key) {
      final v = json[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return AdvertiserCampaignStatusCounts(
      active: read('ACTIVE'),
      draft: read('DRAFT'),
      paused: read('PAUSED'),
      underReview: read('UNDER_REVIEW'),
      completed: read('COMPLETED'),
      cancelled: read('CANCELLED'),
    );
  }
}
