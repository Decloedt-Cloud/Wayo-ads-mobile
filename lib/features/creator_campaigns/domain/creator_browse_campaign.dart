import 'package:equatable/equatable.dart';

import '../../../core/campaigns/campaign_recency.dart';
import '../../../core/network/wayo_ads_public_url.dart';
import '../../advertiser_campaigns/domain/campaign_niche_catalog.dart';

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
    this.currency = 'USD',
    this.approvedCreators = 0,
    this.validViews = 0,
    this.validClicks = 0,
    this.remainingBudgetCents = 0,
    this.spentBudgetCents = 0,
    this.requiredPlatform,
    this.niche,
    this.location,
    this.createdAt,
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

  /// Valid clicks for link-style campaigns when the API exposes them.
  final int validClicks;

  /// Remaining pool from list payload (`remainingBudgetCents` / finance).
  final int remainingBudgetCents;

  /// Spent amount when provided; used with [totalBudgetCents] for progress.
  final int spentBudgetCents;

  /// When set, campaign expects posts on this platform (`YOUTUBE`, …). May be null when list API omits it.
  final String? requiredPlatform;

  /// Wayo-ads `Campaign.niche` enum string (e.g. `FOOD_BEVERAGE`); optional on list payloads.
  final String? niche;

  /// Optional geo / location label when the API provides one (`targetLocation`, `location`, …).
  final String? location;

  /// Campaign creation timestamp (`createdAt`) — drives the "New" badge.
  final DateTime? createdAt;

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

    String? trimOrNull(dynamic v) {
      final s = v?.toString().trim();
      if (s == null || s.isEmpty) return null;
      return s;
    }

    final finance = m['finance'];
    final financeMap = finance is Map
        ? Map<String, dynamic>.from(finance)
        : const <String, dynamic>{};
    final total = parseCents(m['totalBudgetCents'] ?? m['totalBudget']);
    final hasRemKey =
        m.containsKey('remainingBudgetCents') ||
        m.containsKey('remainingBudget') ||
        financeMap.containsKey('remainingBudgetCents');
    final hasSpentKey =
        m.containsKey('spentBudget') ||
        m.containsKey('spentBudgetCents') ||
        financeMap.containsKey('spentBudgetCents') ||
        financeMap.containsKey('spentBudget');
    var remaining = parseCents(
      m['remainingBudgetCents'] ??
          m['remainingBudget'] ??
          financeMap['remainingBudgetCents'],
    );
    var spent = parseCents(
      m['spentBudget'] ??
          m['spentBudgetCents'] ??
          financeMap['spentBudgetCents'] ??
          financeMap['spentBudget'],
    );
    if (total > 0 && !hasRemKey && !hasSpentKey) {
      remaining = total;
      spent = 0;
    } else if (total > 0 && spent == 0 && hasRemKey) {
      spent = (total - remaining).clamp(0, total);
    } else if (total > 0 && remaining == 0 && hasSpentKey && spent > 0) {
      remaining = (total - spent).clamp(0, total);
    }

    return CreatorBrowseCampaign(
      id: (m['id'] as String?) ?? '${m['id']}',
      title: (m['title'] as String?) ?? (m['name'] as String?) ?? 'Campaign',
      type: CreatorCampaignType.fromApi(m['type']),
      totalBudgetCents: total,
      cpmCents: parseCents(m['cpmCents'] ?? financeMap['cpmCents']),
      cpcCents: parseCents(m['cpcCents'] ?? financeMap['cpcCents']),
      coverUrl: parseCampaignCoverUrlFromJson(m) ??
          (m['coverImageUrl'] as String?) ??
          (m['coverUrl'] as String?),
      brandLogoUrl: parseCampaignBrandLogoFromJson(m),
      advertiserName:
          (advertiserMap?['name'] as String?) ??
          (advertiserMap?['company'] as String?) ??
          (m['advertiserName'] as String?),
      description: m['description'] as String?,
      currency: (m['currency'] as String?)?.toUpperCase() ?? 'USD',
      approvedCreators: (m['approvedCreators'] as num?)?.toInt() ?? 0,
      validViews:
          (m['validViews'] as num?)?.toInt() ??
          (financeMap['validViews'] as num?)?.toInt() ??
          0,
      validClicks:
          (m['validClicks'] as num?)?.toInt() ??
          (financeMap['validClicks'] as num?)?.toInt() ??
          0,
      remainingBudgetCents: remaining,
      spentBudgetCents: spent,
      requiredPlatform:
          (m['requiredPlatform'] as String?)?.trim().toUpperCase(),
      niche: normalizeCampaignNicheApiValue(trimOrNull(m['niche'])),
      location: campaignLocationFromCampaignJson(
        m,
        debugSource: 'creatorBrowseList',
      ),
      createdAt: parseCampaignTimestamp(
        m['createdAt'] ?? m['created_at'] ?? m['createdat'],
      ),
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
    validClicks,
    remainingBudgetCents,
    spentBudgetCents,
    requiredPlatform,
    niche,
    location,
    createdAt,
  ];
}
