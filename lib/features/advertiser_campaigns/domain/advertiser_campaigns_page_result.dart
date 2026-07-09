import '../../../core/campaigns/campaign_marketplace_facets.dart';
import 'advertiser_campaign.dart';
import 'advertiser_campaign_status_counts.dart';

/// One page from `GET /api/campaigns?advertiserOnly=true&status=…&page=…&limit=…`.
final class AdvertiserCampaignsPageResult {
  const AdvertiserCampaignsPageResult({
    required this.campaigns,
    required this.total,
    required this.page,
    required this.totalPages,
    this.statusCounts,
    this.facets = const CampaignMarketplaceFacets(),
  });

  final List<AdvertiserCampaign> campaigns;
  final int total;
  final int page;
  final int totalPages;

  /// Present on advertiser-only list responses (`statusCounts` rollup).
  final AdvertiserCampaignStatusCounts? statusCounts;
  final CampaignMarketplaceFacets facets;
}
