import 'creator_browse_campaign.dart';

/// Paginated browse payload from `GET /api/campaigns?creatorOnly=true`.
final class CreatorBrowsePageResult {
  const CreatorBrowsePageResult({
    required this.campaigns,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<CreatorBrowseCampaign> campaigns;
  final int total;
  final int page;
  final int totalPages;
}
