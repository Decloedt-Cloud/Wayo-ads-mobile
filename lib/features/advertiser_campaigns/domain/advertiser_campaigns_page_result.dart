import 'advertiser_campaign.dart';

/// One page from `GET /api/campaigns?advertiserOnly=true&status=…&page=…&limit=…`.
final class AdvertiserCampaignsPageResult {
  const AdvertiserCampaignsPageResult({
    required this.campaigns,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<AdvertiserCampaign> campaigns;
  final int total;
  final int page;
  final int totalPages;
}
