import 'package:equatable/equatable.dart';

import '../../../core/network/wayo_ads_public_url.dart';

/// Campaign type — maps the `type` column of `Campaign` on Wayo-ads
/// (`LINK` | `VIDEO` | `SHORTS`). `unknown` guards against new values the
/// backend may add later without crashing the mobile client.
enum CreatorCampaignType {
  link,
  video,
  shorts,
  unknown;

  static CreatorCampaignType fromApi(dynamic raw) {
    final s = (raw as String?)?.trim().toUpperCase() ?? '';
    return switch (s) {
      'LINK' => CreatorCampaignType.link,
      'VIDEO' => CreatorCampaignType.video,
      'SHORTS' => CreatorCampaignType.shorts,
      _ => CreatorCampaignType.unknown,
    };
  }

  /// Persisted/cache enum name (`link`, `video`, …) from [CampaignSummary] JSON.
  static CreatorCampaignType fromStoredName(String? raw) {
    final s = raw?.trim().toLowerCase() ?? '';
    return switch (s) {
      'link' => CreatorCampaignType.link,
      'video' => CreatorCampaignType.video,
      'shorts' => CreatorCampaignType.shorts,
      'unknown' => CreatorCampaignType.unknown,
      _ => CreatorCampaignType.unknown,
    };
  }

  /// True when the creator must submit a YouTube/TikTok video for this
  /// campaign (i.e. not a plain landing-link referral).
  bool get requiresVideoSubmission =>
      this == CreatorCampaignType.video || this == CreatorCampaignType.shorts;
}

/// Row returned by `GET /api/campaigns?creatorOnly=true&status=ACTIVE`.
///
/// Trimmed down to only the fields a creator needs to decide whether to open
/// the details screen — the full payload is fetched lazily on detail.
final class CreatorBrowseCampaign extends Equatable {
  const CreatorBrowseCampaign({
    required this.id,
    required this.title,
    required this.type,
    required this.totalBudgetCents,
    required this.cpmCents,
    required this.cpcCents,
    this.coverUrl,

    /// Brand logo from campaign creation (`brandLogoUrl` on Wayo-ads API).
    this.brandLogoUrl,
    this.advertiserName,
    this.description,
    this.currency = 'EUR',
    this.approvedCreators = 0,
    this.validViews = 0,
  });

  final String id;
  final String title;
  final CreatorCampaignType type;
  final int totalBudgetCents;
  final int cpmCents;
  final int cpcCents;
  final String? coverUrl;

  /// Same as Wayo-ads `Campaign.brandLogoUrl` (uploaded in campaign editor).
  final String? brandLogoUrl;

  final String? advertiserName;
  final String? description;
  final String currency;
  final int approvedCreators;
  final int validViews;

  factory CreatorBrowseCampaign.fromJson(Map<String, dynamic> m) {
    final advertiser = m['advertiser'];
    final advertiserMap = advertiser is Map
        ? Map<String, dynamic>.from(advertiser)
        : null;

    int parseCents(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return CreatorBrowseCampaign(
      id: (m['id'] as String?) ?? '${m['id']}',
      title: (m['title'] as String?) ?? (m['name'] as String?) ?? 'Campaign',
      type: CreatorCampaignType.fromApi(m['type']),
      totalBudgetCents: parseCents(m['totalBudgetCents'] ?? m['totalBudget']),
      cpmCents: parseCents(m['cpmCents']),
      cpcCents: parseCents(m['cpcCents']),
      coverUrl: (m['coverImageUrl'] as String?) ?? (m['coverUrl'] as String?),
      brandLogoUrl: parseCampaignBrandLogoFromJson(m),
      advertiserName:
          (advertiserMap?['name'] as String?) ??
          (advertiserMap?['company'] as String?) ??
          (m['advertiserName'] as String?),
      description: m['description'] as String?,
      currency: (m['currency'] as String?)?.toUpperCase() ?? 'EUR',
      approvedCreators: (m['approvedCreators'] as num?)?.toInt() ?? 0,
      validViews: (m['validViews'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    totalBudgetCents,
    cpmCents,
    cpcCents,
    coverUrl,
    brandLogoUrl,
    advertiserName,
    description,
    currency,
    approvedCreators,
    validViews,
  ];
}
