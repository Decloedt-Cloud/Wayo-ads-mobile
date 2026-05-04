import 'package:equatable/equatable.dart';

import '../../../core/network/wayo_ads_public_url.dart';

/// One row from `GET /api/creator/applications`.
final class CreatorApplication extends Equatable {
  const CreatorApplication({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.status,
    this.submittedAt,
    this.coverUrl,
    this.advertiserName,
  });

  final String id;
  final String campaignId;
  final String campaignTitle;
  final CreatorApplicationStatus status;
  final DateTime? submittedAt;
  final String? coverUrl;
  final String? advertiserName;

  factory CreatorApplication.fromJson(Map<String, dynamic> json) {
    final campaign = json['campaign'];
    final campaignMap = campaign is Map
        ? Map<String, dynamic>.from(campaign)
        : null;
    final advertiser = campaignMap?['advertiser'];
    final advertiserMap = advertiser is Map
        ? Map<String, dynamic>.from(advertiser)
        : null;

    DateTime? parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }

    return CreatorApplication(
      id: (json['id'] as String?) ?? '',
      campaignId:
          (json['campaignId'] as String?) ??
          (campaignMap?['id'] as String?) ??
          '',
      campaignTitle:
          (campaignMap?['title'] as String?) ??
          (json['campaignTitle'] as String?) ??
          'Campaign',
      status: CreatorApplicationStatus.fromApi(json['status']),
      submittedAt: parseDate(json['submittedAt'] ?? json['createdAt']),
      coverUrl: campaignMap != null
          ? (parseCampaignCoverUrlFromJson(campaignMap) ??
              (campaignMap['coverImageUrl'] as String?) ??
              (campaignMap['coverUrl'] as String?))
          : (json['coverUrl'] as String?),
      advertiserName:
          (advertiserMap?['name'] as String?) ??
          (advertiserMap?['company'] as String?),
    );
  }

  @override
  List<Object?> get props => [
    id,
    campaignId,
    campaignTitle,
    status,
    submittedAt,
    coverUrl,
    advertiserName,
  ];
}

enum CreatorApplicationStatus {
  pending,
  approved,
  rejected,
  withdrawn,
  unknown;

  static CreatorApplicationStatus fromApi(dynamic raw) {
    final s = (raw as String?)?.trim().toUpperCase() ?? '';
    return switch (s) {
      'PENDING' => CreatorApplicationStatus.pending,
      'APPROVED' => CreatorApplicationStatus.approved,
      'REJECTED' => CreatorApplicationStatus.rejected,
      'WITHDRAWN' || 'CANCELLED' => CreatorApplicationStatus.withdrawn,
      _ => CreatorApplicationStatus.unknown,
    };
  }
}
