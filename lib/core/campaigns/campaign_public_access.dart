/// Mirrors Wayo-ads web `/campaigns/[id]` access rules (WADS-235, WADS-242):
/// non-owners cannot browse campaigns that are not publicly active.
bool isCampaignRestrictedForPublicBrowse(String status) {
  final s = status.toUpperCase();
  return s == 'CANCELLED' ||
      s == 'COMPLETED' ||
      s == 'DRAFT' ||
      s == 'PAUSED';
}

/// Whether a non-owner should see the "not available" screen instead of detail.
bool shouldBlockCampaignPublicDetail({
  required String status,
  required bool isOwner,
}) {
  return !isOwner && isCampaignRestrictedForPublicBrowse(status);
}
