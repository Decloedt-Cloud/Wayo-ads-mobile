import 'package:equatable/equatable.dart';

/// One row of the campaign leaderboard returned by Wayo-ads
/// `GET /api/campaigns/:id` under `topCreators` (owner-only payload).
final class CampaignTopCreator extends Equatable {
  const CampaignTopCreator({
    required this.creatorId,
    required this.creatorName,
    this.creatorEmail,
    this.creatorImage,
    this.validViews = 0,
    this.paidViews = 0,
    this.netEarningsCents = 0,
    this.grossEarningsCents = 0,
  });

  final String creatorId;
  final String creatorName;
  final String? creatorEmail;
  final String? creatorImage;
  final int validViews;
  final int paidViews;

  /// Creator take-home for this campaign (cents).
  final int netEarningsCents;

  /// Gross before platform fees (cents).
  final int grossEarningsCents;

  factory CampaignTopCreator.fromJson(Map<String, dynamic> m) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final rawName = (m['creatorName'] as String?)?.trim();
    final rawEmail = (m['creatorEmail'] as String?)?.trim();
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (rawEmail != null && rawEmail.isNotEmpty)
            ? rawEmail.split('@').first
            : '—';

    return CampaignTopCreator(
      creatorId: '${m['creatorId'] ?? ''}',
      creatorName: name,
      creatorEmail: rawEmail,
      creatorImage: (m['creatorImage'] as String?)?.trim(),
      validViews: asInt(m['validViews']),
      paidViews: asInt(m['paidViews']),
      netEarningsCents: asInt(m['netEarnings']),
      grossEarningsCents: asInt(m['grossEarnings']),
    );
  }

  bool get hasActivity =>
      validViews > 0 || paidViews > 0 || netEarningsCents > 0;

  @override
  List<Object?> get props => [
        creatorId,
        creatorName,
        creatorEmail,
        creatorImage,
        validViews,
        paidViews,
        netEarningsCents,
        grossEarningsCents,
      ];
}

/// Parses `topCreators` embedded in `GET /api/campaigns/:id`.
///
/// Returns `null` when the key is absent (non-owner payload), or an ordered
/// list (already sorted by valid views server-side) otherwise.
List<CampaignTopCreator>? campaignTopCreatorsFromCampaignDetail(
  Map<String, dynamic> json,
) {
  if (!json.containsKey('topCreators')) return null;
  final list = json['topCreators'];
  if (list is! List) return const [];
  return list
      .whereType<Map>()
      .map((e) => CampaignTopCreator.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
