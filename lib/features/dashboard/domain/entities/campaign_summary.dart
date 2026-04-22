import 'package:equatable/equatable.dart';

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
    createdAt,
    lockedBudgetCents,
    spentBudgetCents,
  ];
}
