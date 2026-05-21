/// Normalizes web [actionUrl] paths from Wayo-ads into Flutter go_router paths.
String? normalizeMobilePushRoute(String? actionUrl) {
  final u = (actionUrl ?? '').trim();
  if (u.isEmpty) return null;
  if (!u.startsWith('/')) return null;

  final lower = u.toLowerCase();
  if (lower.contains('/dashboard/creator')) {
    if (lower.contains('withdraw') || lower.contains('earning')) {
      return '/wallet';
    }
    return '/dashboard';
  }
  if (lower.contains('/dashboard/advertiser')) {
    return '/dashboard';
  }

  final campaignMatch = RegExp(r'/campaigns/([^/?#]+)').firstMatch(u);
  final campaignId = campaignMatch?.group(1);
  if (campaignId != null && campaignId.isNotEmpty) {
    if (lower.contains('/links') || lower.contains('/application')) {
      return '/creator/campaigns/$campaignId/application';
    }
    if (lower.startsWith('/creator/')) {
      return '/creator/campaigns/$campaignId';
    }
    return '/campaigns/$campaignId';
  }

  if (lower.contains('withdraw') || lower.contains('payout')) {
    return '/superadmin/withdrawals';
  }

  return u;
}
