import 'campaign_niche_catalog.dart';

/// Build JSON for Wayo-ads `POST /api/campaigns` (same shape as
/// `createCampaignSchema` in `Wayo-ads/src/app/api/campaigns/route.ts`).
///
/// Monetary fields are **minor units** (EUR cents ×100 from major input on the UI).
abstract final class AdvertiserCampaignCreatePayload {
  /// Default multi-platform string used by Wayo-ads when creating campaigns.
  static const String defaultPlatforms = 'YOUTUBE,INSTAGRAM,TIKTOK,FACEBOOK';

  static Map<String, dynamic> draft({
    required String title,
    String? description,
    required String type, // LINK | VIDEO | SHORTS
    String? niche,
    String? campaignObjective, // AWARENESS | TRAFFIC | CONVERSION
    String? landingUrl,
    String? assetsUrl,
    String platforms = defaultPlatforms,
    required int totalBudgetCents,
    required int cpmCents,
    int? cpcCents,
    int? videoMinDurationMinutes,
    Map<String, dynamic>? videoRequirements,
    String? shortsPlatform,
    int? shortsMaxDurationSeconds,
    bool? shortsRequireVertical,
    String? shortsRequireHashtag,
    bool? shortsRequireLinkInBio,
  }) {
    final body = <String, dynamic>{
      'title': title.trim(),
      'type': type.trim().toUpperCase(),
      'platforms': platforms,
      'totalBudgetCents': totalBudgetCents,
      'cpmCents': cpmCents,
      'status': 'DRAFT',
    };

    final d = description?.trim();
    if (d != null && d.isNotEmpty) {
      body['description'] = d;
    }

    final n = niche?.trim();
    if (n != null && n.isNotEmpty && kCampaignNicheApiValues.contains(n)) {
      body['niche'] = n;
    }

    final obj = campaignObjective?.trim().toUpperCase();
    if (obj != null &&
        obj.isNotEmpty &&
        (obj == 'AWARENESS' || obj == 'TRAFFIC' || obj == 'CONVERSION')) {
      body['campaignObjective'] = obj;
    }

    final land = landingUrl?.trim();
    if (land != null && land.isNotEmpty) {
      body['landingUrl'] = land;
    }

    final assets = assetsUrl?.trim();
    if (assets != null && assets.isNotEmpty) {
      body['assetsUrl'] = assets;
    }

    if (cpcCents != null) {
      body['cpcCents'] = cpcCents;
    }

    if (videoMinDurationMinutes != null) {
      body['videoMinDurationMinutes'] = videoMinDurationMinutes;
    }
    if (videoRequirements != null) {
      body['videoRequirements'] = videoRequirements;
    }

    final sp = shortsPlatform?.trim().toUpperCase();
    if (sp != null &&
        (sp == 'YOUTUBE' || sp == 'TIKTOK' || sp == 'INSTAGRAM')) {
      body['shortsPlatform'] = sp;
    }
    if (shortsMaxDurationSeconds != null) {
      body['shortsMaxDurationSeconds'] = shortsMaxDurationSeconds;
    }
    if (shortsRequireVertical != null) {
      body['shortsRequireVertical'] = shortsRequireVertical;
    }
    final hashtag = shortsRequireHashtag?.trim();
    if (hashtag != null && hashtag.isNotEmpty) {
      body['shortsRequireHashtag'] = hashtag;
    }
    if (shortsRequireLinkInBio != null) {
      body['shortsRequireLinkInBio'] = shortsRequireLinkInBio;
    }

    return body;
  }
}

/// Same rules as Wayo-ads `createCampaignSchema` refine on `assetsUrl`.
bool isCampaignAssetsSharingUrlValid(String raw) {
  final url = raw.trim();
  if (url.isEmpty) {
    return false;
  }
  if (!url.startsWith('https://')) {
    return false;
  }
  const allowed = [
    'drive.google.com',
    'docs.google.com',
    'onedrive.live.com',
    'sharepoint.com',
  ];
  for (final domain in allowed) {
    if (url.contains(domain)) {
      return true;
    }
  }
  return false;
}
