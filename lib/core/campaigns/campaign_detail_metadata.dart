import '../../features/creator_campaigns/domain/creator_browse_campaign.dart';
import '../../features/dashboard/domain/entities/campaign_platform.dart';
import '../../i18n/strings.g.dart';

/// Platform key from campaign JSON — mirrors Wayo-ads web detail parsing.
String campaignDetailPlatformKey(Map<String, dynamic> json) {
  final shorts = json['shortsPlatform'] as String?;
  if (shorts != null && shorts.trim().isNotEmpty) return shorts.trim();
  final platforms = json['platforms'] as String?;
  if (platforms != null && platforms.trim().isNotEmpty) {
    return platforms.split(',').first.trim();
  }
  final videoReq = json['videoRequirements'];
  if (videoReq is Map) {
    final required = videoReq['requiredPlatform'] as String?;
    if (required != null && required.trim().isNotEmpty) return required.trim();
  }
  final type = json['type'] as String?;
  if (type == 'VIDEO' || type == 'SHORTS') return 'youtube';
  return '';
}

String campaignDetailPlatformLabel(Translations t, CampaignPlatform platform) =>
    switch (platform) {
      CampaignPlatform.youtube => t.advertiser_campaigns.platform.youtube,
      CampaignPlatform.tiktok => t.advertiser_campaigns.platform.tiktok,
      CampaignPlatform.instagram => t.advertiser_campaigns.platform.instagram,
      CampaignPlatform.unknown => t.advertiser_campaigns.platform.other,
    };

String campaignDetailPlatformLabelFromJson(
  Map<String, dynamic> json,
  Translations t,
) =>
    campaignDetailPlatformLabel(
      t,
      CampaignPlatform.fromString(campaignDetailPlatformKey(json)),
    );

String campaignDetailObjectiveLabel(Translations t, String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'AWARENESS':
      return t.advertiser_campaigns.detail.objective_awareness;
    case 'TRAFFIC':
      return t.advertiser_campaigns.detail.objective_traffic;
    case 'CONVERSION':
      return t.advertiser_campaigns.detail.objective_conversion;
    default:
      return '—';
  }
}

String campaignDetailTypeLabel(Translations t, CreatorCampaignType type) =>
    switch (type) {
      CreatorCampaignType.link => t.creator.campaigns.type_link,
      CreatorCampaignType.video => t.creator.campaigns.type_video,
      CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
      CreatorCampaignType.unknown => '—',
    };
