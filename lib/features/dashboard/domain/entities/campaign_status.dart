enum CampaignStatus {
  draft,
  active,
  completed,
  paused,
  unknown;

  static CampaignStatus fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'draft':
        return draft;
      case 'active':
        return active;
      case 'completed':
        return completed;
      case 'paused':
        return paused;
      case 'under_review':
        return paused;
      case 'cancelled':
        return completed;
      default:
        return unknown;
    }
  }
}
