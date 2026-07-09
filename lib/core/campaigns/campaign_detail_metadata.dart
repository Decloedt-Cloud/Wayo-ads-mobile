import 'package:flutter/material.dart';

import '../../features/creator_campaigns/domain/creator_browse_campaign.dart';
import '../../features/dashboard/domain/entities/campaign_platform.dart';
import '../../features/dashboard/domain/entities/campaign_status.dart';
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

String campaignStatusLabel(Translations t, CampaignStatus status) =>
    switch (status) {
      CampaignStatus.active => t.advertiser_campaigns.status.active,
      CampaignStatus.paused => t.advertiser_campaigns.status.paused,
      CampaignStatus.underReview => t.advertiser_campaigns.status.under_review,
      CampaignStatus.completed => t.advertiser_campaigns.status.completed,
      CampaignStatus.cancelled => t.advertiser_campaigns.status.cancelled,
      CampaignStatus.draft => t.advertiser_campaigns.status.draft,
      CampaignStatus.unknown => t.advertiser_campaigns.status.other,
    };

Color campaignStatusAccentColor(CampaignStatus status) => switch (status) {
  CampaignStatus.active => const Color(0xFF22C55E),
  CampaignStatus.paused => const Color(0xFFF59E0B),
  CampaignStatus.underReview => const Color(0xFF6366F1),
  CampaignStatus.completed => const Color(0xFF8B5CF6),
  CampaignStatus.cancelled => const Color(0xFFEF4444),
  CampaignStatus.draft => const Color(0xFF94A3B8),
  CampaignStatus.unknown => const Color(0xFF94A3B8),
};

IconData campaignStatusIcon(CampaignStatus status) => switch (status) {
  CampaignStatus.active => Icons.circle,
  CampaignStatus.paused => Icons.pause_circle_outline,
  CampaignStatus.underReview => Icons.hourglass_top_rounded,
  CampaignStatus.completed => Icons.check_circle_outline,
  CampaignStatus.cancelled => Icons.cancel_outlined,
  CampaignStatus.draft => Icons.edit_note_rounded,
  CampaignStatus.unknown => Icons.help_outline,
};
