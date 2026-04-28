import 'package:equatable/equatable.dart';

/// Creator application as seen by the advertiser (from `GET /api/campaigns/:id/applications`).
final class CampaignApplication extends Equatable {
  const CampaignApplication({
    required this.id,
    required this.creatorName,
    required this.status,
    this.creatorAvatar,
    this.message,
    this.trustScore,
    this.trustLevel,
    this.createdAt,
  });

  final String id;
  final String creatorName;
  final CampaignApplicationStatus status;
  final String? creatorAvatar;
  final String? message;
  final int? trustScore;
  final String? trustLevel;
  final DateTime? createdAt;

  factory CampaignApplication.fromJson(Map<String, dynamic> m) {
    final creator = m['creator'] ?? m['user'];
    String name = '';
    String? avatar;
    int? trust;
    String? level;
    if (creator is Map<String, dynamic>) {
      name =
          creator['name'] as String? ??
          creator['displayName'] as String? ??
          creator['username'] as String? ??
          '';
      avatar =
          creator['image'] as String? ??
          creator['avatar'] as String? ??
          creator['avatarUrl'] as String?;
      trust =
          (creator['trustScore'] as num?)?.toInt() ??
          (creator['trust_score'] as num?)?.toInt();
      level =
          creator['tier'] as String? ??
          creator['trustLevel'] as String? ??
          creator['trust_level'] as String?;
    }
    if (name.isEmpty) {
      name = m['creatorName'] as String? ?? m['creator_name'] as String? ?? '—';
    }
    avatar ??= m['creatorAvatar'] as String? ?? m['creator_avatar'] as String?;
    trust ??= (m['trustScore'] as num?)?.toInt();
    level ??= m['trustLevel'] as String?;

    DateTime? created;
    final raw = m['createdAt'] ?? m['created_at'];
    if (raw is String) {
      created = DateTime.tryParse(raw);
    }

    return CampaignApplication(
      id: '${m['id'] ?? ''}',
      creatorName: name,
      status: CampaignApplicationStatus.fromApi(m['status']),
      creatorAvatar: avatar,
      message: m['message'] as String? ?? m['pitch'] as String?,
      trustScore: trust,
      trustLevel: level,
      createdAt: created,
    );
  }

  @override
  List<Object?> get props => [
    id,
    creatorName,
    status,
    creatorAvatar,
    message,
    trustScore,
    trustLevel,
    createdAt,
  ];
}

enum CampaignApplicationStatus {
  pending,
  approved,
  rejected,
  withdrawn,
  unknown;

  static CampaignApplicationStatus fromApi(dynamic v) {
    final s = (v?.toString().toUpperCase() ?? '').trim();
    return switch (s) {
      'PENDING' => CampaignApplicationStatus.pending,
      'APPROVED' => CampaignApplicationStatus.approved,
      'REJECTED' => CampaignApplicationStatus.rejected,
      'WITHDRAWN' => CampaignApplicationStatus.withdrawn,
      _ => CampaignApplicationStatus.unknown,
    };
  }
}
