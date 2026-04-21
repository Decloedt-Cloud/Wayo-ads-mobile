import 'package:equatable/equatable.dart';

import '../../dashboard/domain/entities/campaign_platform.dart';
import '../../dashboard/domain/entities/campaign_status.dart';

/// Advertiser-facing campaign row from Wayo-ads `GET /api/campaigns` (read-only).
final class AdvertiserCampaign extends Equatable {
  const AdvertiserCampaign({
    required this.id,
    required this.name,
    required this.status,
    required this.platform,
    required this.totalBudgetCents,
    required this.remainingBudgetCents,
    required this.spentBudgetCents,
    required this.lockedBudgetCents,
    required this.cpcCents,
    required this.validViews,
    required this.approvedCreators,
    this.coverUrl,
    this.currency = 'EUR',
  });

  final String id;
  final String name;
  final CampaignStatus status;
  final CampaignPlatform platform;

  /// Total campaign budget (minor units).
  final int totalBudgetCents;
  final int remainingBudgetCents;
  final int spentBudgetCents;
  final int lockedBudgetCents;

  /// Cost per click in minor units (0 when campaign uses CPM/CPA only).
  final int cpcCents;

  /// Validated views / engagements from analytics (Wayo-ads naming).
  final int validViews;
  final int approvedCreators;
  final String? coverUrl;
  final String currency;

  bool get matchesActiveTab =>
      status == CampaignStatus.active ||
      status == CampaignStatus.draft ||
      status == CampaignStatus.unknown;

  bool get matchesPausedTab => status == CampaignStatus.paused;

  bool get matchesCompletedTab => status == CampaignStatus.completed;

  @override
  List<Object?> get props => [
        id,
        name,
        status,
        platform,
        totalBudgetCents,
        remainingBudgetCents,
        spentBudgetCents,
        lockedBudgetCents,
        cpcCents,
        validViews,
        approvedCreators,
        coverUrl,
        currency,
      ];
}
