import 'package:equatable/equatable.dart';

import '../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../dashboard/domain/entities/campaign_platform.dart';
import '../../dashboard/domain/entities/campaign_status.dart';

/// Advertiser-facing campaign row from Wayo-ads `GET /api/campaigns` (read-only).
final class AdvertiserCampaign extends Equatable {
  const AdvertiserCampaign({
    required this.id,
    required this.name,
    required this.status,
    required this.platform,
    required this.campaignType,
    required this.totalBudgetCents,
    required this.remainingBudgetCents,
    required this.spentBudgetCents,
    required this.lockedBudgetCents,
    required this.cpcCents,
    this.cpmCents = 0,
    required this.validViews,
    this.validClicks = 0,
    required this.approvedCreators,
    this.coverUrl,
    this.brandLogoUrl,
    this.currency = 'USD',
    this.niche,
    this.location,
  });

  final String id;
  final String name;
  final CampaignStatus status;
  final CampaignPlatform platform;

  /// `LINK` | `VIDEO` | `SHORTS` from Wayo-ads `Campaign.type`.
  final CreatorCampaignType campaignType;

  /// Total campaign budget (minor units).
  final int totalBudgetCents;
  final int remainingBudgetCents;
  final int spentBudgetCents;
  final int lockedBudgetCents;

  /// Cost per click in minor units (0 when campaign uses CPM/CPA only).
  final int cpcCents;

  /// Cost per mille (1000 impressions / views) in minor units, when applicable.
  final int cpmCents;

  /// Validated views / engagements from analytics (Wayo-ads naming).
  final int validViews;

  /// Valid link clicks when tracked (`validClicks` on API).
  final int validClicks;
  final int approvedCreators;
  final String? coverUrl;

  /// Campaign brand logo from editor (`brandLogoUrl` on API).
  final String? brandLogoUrl;
  final String currency;

  /// Optional niche / location when present on list payloads (same as web cards).
  final String? niche;
  final String? location;

  /// Only live campaigns (not draft). Drafts are under [matchesDraftTab].
  bool get matchesActiveTab => status == CampaignStatus.active;

  /// Drafts and unknown/unmapped API statuses (kept out of "Active" per product spec).
  bool get matchesDraftTab =>
      status == CampaignStatus.draft || status == CampaignStatus.unknown;

  bool get matchesPausedTab => status == CampaignStatus.paused;

  bool get matchesCompletedTab => status == CampaignStatus.completed;

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    platform,
    campaignType,
    totalBudgetCents,
    remainingBudgetCents,
    spentBudgetCents,
    lockedBudgetCents,
    cpcCents,
    cpmCents,
    validViews,
    validClicks,
    approvedCreators,
    coverUrl,
    brandLogoUrl,
    currency,
    niche,
    location,
  ];
}
