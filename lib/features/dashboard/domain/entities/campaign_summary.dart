import 'package:equatable/equatable.dart';

import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import 'campaign_platform.dart';
import 'campaign_status.dart';

final class CampaignSummary extends Equatable {
  const CampaignSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.platform,
    required this.creatorsCount,
    this.coverUrl,
    this.brandLogoUrl,
    required this.campaignType,
    this.createdAt,
    this.lockedBudgetCents = 0,
    this.spentBudgetCents = 0,
  });

  final String id;
  final String name;
  final CampaignStatus status;
  final CampaignPlatform platform;
  final int creatorsCount;
  final String? coverUrl;

  /// Wayo-ads `brandLogoUrl` when the advertiser uploaded a logo.
  final String? brandLogoUrl;

  final CreatorCampaignType campaignType;

  final DateTime? createdAt;

  /// Locked campaign budget (cents), from Wayo-ads budget lock / list API.
  final int lockedBudgetCents;

  /// Spent campaign budget (cents), from Wayo-ads stats.
  final int spentBudgetCents;

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    platform,
    creatorsCount,
    coverUrl,
    brandLogoUrl,
    campaignType,
    createdAt,
    lockedBudgetCents,
    spentBudgetCents,
  ];
}
