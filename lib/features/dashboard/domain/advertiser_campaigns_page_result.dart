import 'entities/campaign_summary.dart';

/// Server-side locked / spent totals for the advertiser dashboard (all campaigns),
/// independent of how many rows are returned for a page.
final class AdvertiserBudgetRollup {
  const AdvertiserBudgetRollup({
    required this.lockedCents,
    required this.spentCents,
  });

  final int lockedCents;
  final int spentCents;
}

/// Advertiser campaign list page from `GET /api/campaigns?advertiserOnly=true`.
final class AdvertiserCampaignsPageResult {
  const AdvertiserCampaignsPageResult({
    required this.campaigns,
    required this.total,
    required this.page,
    required this.totalPages,
    this.budgetRollup,
  });

  final List<CampaignSummary> campaigns;
  final int total;
  final int page;
  final int totalPages;
  final AdvertiserBudgetRollup? budgetRollup;
}
