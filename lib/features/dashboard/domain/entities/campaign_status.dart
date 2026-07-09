enum CampaignStatus {
  draft,
  active,
  paused,
  underReview,
  completed,
  cancelled,
  unknown;

  static CampaignStatus fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'draft':
        return draft;
      case 'active':
        return active;
      case 'paused':
        return paused;
      case 'under_review':
        return underReview;
      case 'completed':
        return completed;
      case 'cancelled':
        return cancelled;
      default:
        return unknown;
    }
  }

  String get apiValue => switch (this) {
    draft => 'DRAFT',
    active => 'ACTIVE',
    paused => 'PAUSED',
    underReview => 'UNDER_REVIEW',
    completed => 'COMPLETED',
    cancelled => 'CANCELLED',
    unknown => '',
  };
}
