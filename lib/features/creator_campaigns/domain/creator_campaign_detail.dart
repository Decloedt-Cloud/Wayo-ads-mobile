import 'package:equatable/equatable.dart';

import '../../../core/campaigns/campaign_detail_metadata.dart';
import '../../../core/network/wayo_ads_public_url.dart';
import '../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../creator_dashboard/domain/creator_application.dart';
import '../../dashboard/domain/entities/campaign_platform.dart';
import 'creator_browse_campaign.dart';
import 'creator_social_post.dart';
import 'creator_tracking_link.dart';

/// Snapshot of a campaign as seen by a creator (`GET /api/campaigns/:id` +
/// `GET /api/creator/campaigns/:id/submit-post` merged client-side when the
/// creator is APPROVED).
///
/// Not every field is available on every call — for example
/// [videoRequirements] only comes through when the campaign is VIDEO/SHORTS,
/// and [myVideos]/[earningsCents] are gated behind an APPROVED application.
final class CreatorCampaignDetail extends Equatable {
  const CreatorCampaignDetail({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.totalBudgetCents,
    required this.spentBudgetCents,
    required this.remainingBudgetCents,
    required this.cpmCents,
    required this.cpcCents,
    required this.payoutPerViewCents,
    required this.validViews,
    required this.validClicks,
    required this.approvedCreators,
    required this.platform,
    this.campaignObjective,
    this.lockedBudgetCents = 0,
    required this.myApplicationStatus,
    required this.myVideos,
    this.trackingLinks = const [],
    this.myApplicationId,
    this.coverUrl,
    this.brandLogoUrl,
    this.description,
    this.notes,
    this.assetsUrl,
    this.landingUrl,
    this.advertiserName,
    this.advertiserId,
    this.requiredPlatform,
    this.niche,
    this.location,
    this.videoMinDurationMinutes,
    this.allowMultiplePosts,
    this.shortsMaxDurationSeconds,
    this.shortsRequireVertical,
    this.currency = 'USD',
    this.earningsCents = 0,
    this.netEarningsCents = 0,
    this.availableBalanceCents = 0,
    this.paidViews = 0,
    this.validatedClicks = 0,
    this.recordedClicks = 0,
  });

  final String id;
  final String title;
  final CreatorCampaignType type;

  /// Raw `status` from backend (e.g. `ACTIVE`, `PAUSED`). We keep it as a
  /// string because only `ACTIVE` really matters for the creator (only active
  /// campaigns accept applications / submissions).
  final String status;
  final int totalBudgetCents;
  final int spentBudgetCents;
  final int remainingBudgetCents;
  final int cpmCents;
  final int cpcCents;

  /// Payout per 1 valid view, minor units. Useful for "you'll earn X / view".
  final int payoutPerViewCents;
  final int validViews;
  final int validClicks;
  final int approvedCreators;
  final CampaignPlatform platform;
  final String? campaignObjective;
  final int lockedBudgetCents;

  final CreatorApplicationStatus myApplicationStatus;
  final List<CreatorSocialPost> myVideos;
  final List<CreatorTrackingLink> trackingLinks;
  final String? myApplicationId;

  final String? coverUrl;

  /// Uploaded in Wayo-ads campaign editor (`brandLogoUrl`).
  final String? brandLogoUrl;

  final String? description;
  final String? notes;
  final String? assetsUrl;
  final String? landingUrl;
  final String? advertiserName;
  final String? advertiserId;

  /// Only set when [type] is [CreatorCampaignType.video] or
  /// [CreatorCampaignType.shorts]. `null` means "no platform restriction".
  final String? requiredPlatform;

  /// Target niche (API enum) when present — same sources as list payloads.
  final String? niche;

  /// Geo / location label when the API provides one (`targetLocation`, …).
  final String? location;

  final int? videoMinDurationMinutes;
  final bool? allowMultiplePosts;
  final int? shortsMaxDurationSeconds;
  final bool? shortsRequireVertical;

  final String currency;
  final int earningsCents;
  final int netEarningsCents;
  final int availableBalanceCents;
  final int paidViews;
  final int validatedClicks;
  final int recordedClicks;

  int get earningsViews =>
      myVideos.fold<int>(0, (sum, v) => sum + v.totalValidatedViews);

  int get platformViews =>
      myVideos.fold<int>(0, (sum, v) => sum + v.currentViews);

  bool get isApproved =>
      myApplicationStatus == CreatorApplicationStatus.approved;
  bool get isPending => myApplicationStatus == CreatorApplicationStatus.pending;
  bool get canApply =>
      status == 'ACTIVE' &&
      myApplicationStatus == CreatorApplicationStatus.unknown;

  /// Whether the creator may submit a new video/short for this campaign.
  /// Mirrors the backend rule: one active post unless [allowMultiplePosts].
  bool get canSubmitVideoPost {
    if (!isApproved) return false;
    if (!type.requiresVideoSubmission) return false;
    if (allowMultiplePosts == true) return true;
    if (myVideos.isEmpty) return true;
    // Any non-rejected submission blocks a new upload (PENDING, ACTIVE, …).
    return myVideos.every(
      (p) => p.status == CreatorSocialPostStatus.rejected,
    );
  }

  /// Info banner under the action bar — only while a submission awaits review.
  bool get shouldShowSubmitPendingNotice {
    if (canSubmitVideoPost || !type.requiresVideoSubmission) return false;
    return myVideos.any(
      (p) =>
          p.status == CreatorSocialPostStatus.pending ||
          p.status == CreatorSocialPostStatus.flagged,
    );
  }

  factory CreatorCampaignDetail.fromJson(Map<String, dynamic> m) {
    int parseCents(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final finance = m['finance'];
    final financeMap = finance is Map
        ? Map<String, dynamic>.from(finance)
        : const {};

    final advertiser = m['advertiser'];
    final advertiserMap = advertiser is Map
        ? Map<String, dynamic>.from(advertiser)
        : null;

    final myApp = m['userApplication'];
    final myAppMap = myApp is Map ? Map<String, dynamic>.from(myApp) : null;

    final videoReq = m['videoRequirements'];
    final videoReqMap = videoReq is Map
        ? Map<String, dynamic>.from(videoReq)
        : null;

    final myVideosRaw = m['myVideos'];
    final myVideos = myVideosRaw is List
        ? myVideosRaw
              .whereType<Map>()
              .map(
                (e) => CreatorSocialPost.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const <CreatorSocialPost>[];

    final trackingLinksRaw = m['trackingLinks'];
    final trackingLinks = trackingLinksRaw is List
        ? trackingLinksRaw
              .whereType<Map>()
              .map(
                (e) => CreatorTrackingLink.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(growable: false)
        : const <CreatorTrackingLink>[];

    final earnings = m['myEarnings'];
    final earningsMap = earnings is Map
        ? Map<String, dynamic>.from(earnings)
        : null;

    String? trimOrNull(dynamic v) {
      final s = v?.toString().trim();
      if (s == null || s.isEmpty) return null;
      return s;
    }

    final earningsCampaign = earningsMap?['campaign'] is Map
        ? Map<String, dynamic>.from(earningsMap!['campaign'] as Map)
        : null;
    final totalBalance = earningsMap?['totalBalance'] is Map
        ? Map<String, dynamic>.from(earningsMap!['totalBalance'] as Map)
        : null;

    return CreatorCampaignDetail(
      id: (m['id'] as String?) ?? '${m['id']}',
      title: (m['title'] as String?) ?? 'Campaign',
      type: CreatorCampaignType.fromApi(m['type']),
      status: (m['status'] as String?) ?? 'UNKNOWN',
      totalBudgetCents: parseCents(
        financeMap['totalBudgetCents'] ?? m['totalBudgetCents'],
      ),
      spentBudgetCents: parseCents(
        financeMap['spentBudgetCents'] ?? m['spentBudget'],
      ),
      remainingBudgetCents: parseCents(
        financeMap['remainingBudgetCents'] ?? m['remainingBudget'],
      ),
      cpmCents: parseCents(financeMap['cpmCents'] ?? m['cpmCents']),
      cpcCents: parseCents(financeMap['cpcCents'] ?? m['cpcCents']),
      payoutPerViewCents: parseCents(financeMap['payoutPerViewCents']),
      validViews:
          (financeMap['validViews'] as num?)?.toInt() ??
          (m['validViews'] as num?)?.toInt() ??
          0,
      validClicks:
          (financeMap['validClicks'] as num?)?.toInt() ??
          (m['validClicks'] as num?)?.toInt() ??
          0,
      approvedCreators: (m['approvedCreators'] as num?)?.toInt() ?? 0,
      platform: CampaignPlatform.fromString(campaignDetailPlatformKey(m)),
      campaignObjective: trimOrNull(m['campaignObjective']),
      lockedBudgetCents: parseCents(
        financeMap['lockedBudgetCents'] ?? m['lockedBudgetCents'],
      ),
      myApplicationStatus: CreatorApplicationStatus.fromApi(
        myAppMap?['status'] ?? (m['isApproved'] == true ? 'APPROVED' : null),
      ),
      myApplicationId: myAppMap?['id'] as String?,
      myVideos: myVideos,
      trackingLinks: trackingLinks,
      coverUrl: parseCampaignCoverUrlFromJson(m) ??
          (m['coverImageUrl'] as String?) ??
          (m['coverUrl'] as String?),
      brandLogoUrl: parseCampaignBrandLogoFromJson(m),
      description: m['description'] as String?,
      notes: m['notes'] as String?,
      assetsUrl: m['assetsUrl'] as String?,
      landingUrl: m['landingUrl'] as String?,
      advertiserName: advertiserMap?['name'] as String?,
      advertiserId:
          advertiserMap?['id'] as String? ?? m['advertiserId'] as String?,
      requiredPlatform: videoReqMap?['requiredPlatform'] as String?,
      niche: normalizeCampaignNicheApiValue(trimOrNull(m['niche'])),
      location: campaignLocationFromCampaignJson(
        m,
        debugSource: 'creatorCampaignDetail',
      ),
      videoMinDurationMinutes: (m['videoMinDurationMinutes'] as num?)?.toInt(),
      allowMultiplePosts: videoReqMap?['allowMultiplePosts'] as bool?,
      shortsMaxDurationSeconds: (m['shortsMaxDurationSeconds'] as num?)
          ?.toInt(),
      shortsRequireVertical: m['shortsRequireVertical'] as bool?,
      currency: (m['currency'] as String?)?.toUpperCase() ?? 'USD',
      earningsCents: parseCents(
        earningsCampaign?['netEarnings'] ??
            earningsCampaign?['totalEarningsCents'] ??
            totalBalance?['totalEarnedCents'],
      ),
      netEarningsCents: parseCents(earningsCampaign?['netEarnings']),
      availableBalanceCents: parseCents(totalBalance?['availableCents']),
      paidViews: (earningsCampaign?['paidViews'] as num?)?.toInt() ?? 0,
      validatedClicks:
          (earningsCampaign?['validatedClicks'] as num?)?.toInt() ?? 0,
      recordedClicks:
          (earningsCampaign?['recordedClicks'] as num?)?.toInt() ?? 0,
    );
  }

  CreatorCampaignDetail mergeSocialPosts(List<CreatorSocialPost> posts) {
    if (posts.isEmpty) return this;
    return CreatorCampaignDetail(
      id: id,
      title: title,
      type: type,
      status: status,
      totalBudgetCents: totalBudgetCents,
      spentBudgetCents: spentBudgetCents,
      remainingBudgetCents: remainingBudgetCents,
      cpmCents: cpmCents,
      cpcCents: cpcCents,
      payoutPerViewCents: payoutPerViewCents,
      validViews: validViews,
      validClicks: validClicks,
      approvedCreators: approvedCreators,
      platform: platform,
      campaignObjective: campaignObjective,
      lockedBudgetCents: lockedBudgetCents,
      myApplicationStatus: myApplicationStatus,
      myApplicationId: myApplicationId,
      myVideos: posts,
      trackingLinks: trackingLinks,
      coverUrl: coverUrl,
      brandLogoUrl: brandLogoUrl,
      description: description,
      notes: notes,
      assetsUrl: assetsUrl,
      landingUrl: landingUrl,
      advertiserName: advertiserName,
      advertiserId: advertiserId,
      requiredPlatform: requiredPlatform,
      niche: niche,
      location: location,
      videoMinDurationMinutes: videoMinDurationMinutes,
      allowMultiplePosts: allowMultiplePosts,
      shortsMaxDurationSeconds: shortsMaxDurationSeconds,
      shortsRequireVertical: shortsRequireVertical,
      currency: currency,
      earningsCents: earningsCents,
      netEarningsCents: netEarningsCents,
      availableBalanceCents: availableBalanceCents,
      paidViews: paidViews,
      validatedClicks: validatedClicks,
      recordedClicks: recordedClicks,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    status,
    totalBudgetCents,
    spentBudgetCents,
    remainingBudgetCents,
    cpmCents,
    cpcCents,
    payoutPerViewCents,
    validViews,
    validClicks,
    approvedCreators,
    platform,
    campaignObjective,
    lockedBudgetCents,
    myApplicationStatus,
    myApplicationId,
    myVideos,
    trackingLinks,
    coverUrl,
    brandLogoUrl,
    description,
    notes,
    assetsUrl,
    landingUrl,
    advertiserName,
    advertiserId,
    requiredPlatform,
    niche,
    location,
    videoMinDurationMinutes,
    allowMultiplePosts,
    shortsMaxDurationSeconds,
    shortsRequireVertical,
    currency,
    earningsCents,
    netEarningsCents,
    availableBalanceCents,
    paidViews,
    validatedClicks,
    recordedClicks,
  ];
}
