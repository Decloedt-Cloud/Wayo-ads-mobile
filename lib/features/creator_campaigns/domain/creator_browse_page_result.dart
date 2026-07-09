import 'creator_browse_campaign.dart';
import '../../../core/campaigns/campaign_marketplace_facets.dart';

/// Paginated browse payload from `GET /api/campaigns?creatorOnly=true`.
final class CreatorBrowsePageResult {
  const CreatorBrowsePageResult({
    required this.campaigns,
    required this.total,
    required this.page,
    required this.totalPages,
    this.facets = const CampaignMarketplaceFacets(),
  });

  final List<CreatorBrowseCampaign> campaigns;
  final int total;
  final int page;
  final int totalPages;
  final CampaignMarketplaceFacets facets;
}
