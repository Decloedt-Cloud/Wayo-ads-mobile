/// Draft / create payload aligned with Wayo-ads `createCampaignSchema`
/// and web `CampaignEditorForm.buildPayload`.
library;

import '../../dashboard/domain/entities/campaign_status.dart';

enum CampaignTypeApi {
  link,
  video,
  shorts;

  String get apiValue => switch (this) {
    link => 'LINK',
    video => 'VIDEO',
    shorts => 'SHORTS',
  };

  static CampaignTypeApi fromApi(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'VIDEO':
        return video;
      case 'SHORTS':
        return shorts;
      default:
        return link;
    }
  }
}

enum CampaignObjectiveApi {
  awareness,
  traffic;

  String get apiValue => switch (this) {
    awareness => 'AWARENESS',
    traffic => 'TRAFFIC',
  };

  static CampaignObjectiveApi? fromApi(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'AWARENESS':
        return awareness;
      case 'TRAFFIC':
        return traffic;
      default:
        return null;
    }
  }
}

/// Mutable wizard state — validated per step before POST/PATCH.
final class CampaignEditorDraft {
  CampaignEditorDraft({
    this.serverId,
    this.title = '',
    this.description,
    this.type = CampaignTypeApi.link,
    this.objective,
    this.niche,
    this.landingUrl,
    this.assetsUrl,
    this.brandLogoUrl,
    this.platforms = '',
    this.totalBudgetCents = 1000,
    this.cpmCents = 0,
    this.cpcCents = 0,
    this.notes,
    this.campaignEndDate,
    this.isGeoTargeted = false,
    this.targetCountryCode,
    this.targetCity,
    this.targetLatitude,
    this.targetLongitude,
    this.targetRadiusKm = 50,
    this.videoMinDurationMinutes = 1,
    this.allowMultiplePosts = true,
    this.shortsPlatform = 'YOUTUBE',
    this.shortsMaxDurationSeconds = 60,
    this.shortsRequireVertical = true,
    this.shortsRequireHashtag,
    this.shortsRequireLinkInBio = false,
    this.minPayoutCentsPerVideo,
    this.maxPayoutCentsPerVideo,
    this.submissionsCloseAtBudgetPercent,
    this.status = CampaignStatus.draft,
  });

  /// Set after first successful POST (draft on server).
  String? serverId;

  String title;
  String? description;
  CampaignTypeApi type;
  CampaignObjectiveApi? objective;
  String? niche;
  String? landingUrl;
  String? assetsUrl;
  String? brandLogoUrl;
  String platforms;
  int totalBudgetCents;
  int cpmCents;
  int? cpcCents;
  String? notes;

  /// `YYYY-MM-DD` required by API.
  String? campaignEndDate;

  bool isGeoTargeted;
  String? targetCountryCode;
  String? targetCity;
  double? targetLatitude;
  double? targetLongitude;
  int? targetRadiusKm;

  int? videoMinDurationMinutes;
  bool allowMultiplePosts;
  String? shortsPlatform;
  int? shortsMaxDurationSeconds;
  bool? shortsRequireVertical;
  String? shortsRequireHashtag;
  bool? shortsRequireLinkInBio;
  int? minPayoutCentsPerVideo;
  int? maxPayoutCentsPerVideo;
  int? submissionsCloseAtBudgetPercent;

  CampaignStatus status;

  /// Forced objective matching web form rules.
  CampaignObjectiveApi get effectiveObjective => type == CampaignTypeApi.link
      ? CampaignObjectiveApi.traffic
      : CampaignObjectiveApi.awareness;

  /// Derived platforms string matching web form.
  String get effectivePlatforms => switch (type) {
    CampaignTypeApi.video => 'YOUTUBE',
    CampaignTypeApi.shorts =>
      (shortsPlatform?.isNotEmpty == true) ? shortsPlatform! : 'YOUTUBE',
    CampaignTypeApi.link => '',
  };

  /// Apply type switch side-effects (web parity).
  void applyType(CampaignTypeApi next) {
    type = next;
    objective = effectiveObjective;
    if (next == CampaignTypeApi.link) {
      assetsUrl = null;
      videoMinDurationMinutes = null;
      shortsPlatform = null;
      shortsMaxDurationSeconds = null;
      maxPayoutCentsPerVideo = null;
      cpmCents = 0;
      platforms = '';
    } else {
      landingUrl = null;
      cpcCents = 0;
      platforms = effectivePlatforms;
      if (next == CampaignTypeApi.video) {
        videoMinDurationMinutes ??= 1;
        shortsPlatform = null;
        shortsMaxDurationSeconds = null;
      } else {
        shortsPlatform ??= 'YOUTUBE';
        shortsMaxDurationSeconds ??= 60;
        shortsRequireVertical ??= true;
        shortsRequireLinkInBio ??= false;
        videoMinDurationMinutes = null;
      }
    }
  }

  /// JSON body for POST/PATCH — mirrors web `buildPayload`.
  Map<String, dynamic> toApiBody({required bool includeStatus}) {
    final usesCpm =
        type == CampaignTypeApi.video || type == CampaignTypeApi.shorts;
    final usesCpc = type == CampaignTypeApi.link;
    final body = <String, dynamic>{
      'title': title.trim(),
      'type': type.apiValue,
      'campaignObjective': effectiveObjective.apiValue,
      'totalBudgetCents': totalBudgetCents,
      'cpmCents': usesCpm ? cpmCents : 0,
      'cpcCents': usesCpc ? (cpcCents ?? 0) : 0,
      'platforms': effectivePlatforms,
      'isGeoTargeted': isGeoTargeted,
      'landingUrl': type == CampaignTypeApi.link
          ? (landingUrl?.trim().isNotEmpty == true ? landingUrl!.trim() : null)
          : null,
      'assetsUrl': usesCpm
          ? (assetsUrl?.trim().isNotEmpty == true ? assetsUrl!.trim() : null)
          : null,
    };

    void put(String key, Object? value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      body[key] = value is String ? value.trim() : value;
    }

    put('description', description);
    put('niche', niche);
    put('brandLogoUrl', brandLogoUrl);
    put('notes', notes);
    put('campaignEndDate', campaignEndDate);

    if (isGeoTargeted) {
      put('targetCountryCode', targetCountryCode);
      put('targetCity', targetCity);
      put('targetLatitude', targetLatitude);
      put('targetLongitude', targetLongitude);
      put('targetRadiusKm', targetRadiusKm ?? 50);
    } else {
      body['targetCountryCode'] = null;
      body['targetCity'] = null;
      body['targetLatitude'] = null;
      body['targetLongitude'] = null;
      body['targetRadiusKm'] = null;
    }

    if (type == CampaignTypeApi.video) {
      put('videoMinDurationMinutes', videoMinDurationMinutes ?? 1);
      body['videoRequirements'] = <String, dynamic>{
        'requiredPlatform': 'YOUTUBE',
        'allowMultiplePosts': allowMultiplePosts,
      };
      put('maxPayoutCentsPerVideo', maxPayoutCentsPerVideo);
    } else if (type == CampaignTypeApi.shorts) {
      put('shortsPlatform', shortsPlatform ?? 'YOUTUBE');
      put('shortsMaxDurationSeconds', shortsMaxDurationSeconds ?? 60);
      body['shortsRequireVertical'] = shortsRequireVertical ?? true;
      body['shortsRequireLinkInBio'] = shortsRequireLinkInBio ?? false;
      put('shortsRequireHashtag', shortsRequireHashtag);
      body['videoRequirements'] = <String, dynamic>{
        'allowMultiplePosts': allowMultiplePosts,
      };
      put('maxPayoutCentsPerVideo', maxPayoutCentsPerVideo);
    } else {
      body['videoRequirements'] = null;
      body['videoMinDurationMinutes'] = null;
      body['shortsPlatform'] = null;
      body['shortsMaxDurationSeconds'] = null;
      body['shortsRequireVertical'] = null;
      body['shortsRequireHashtag'] = null;
      body['shortsRequireLinkInBio'] = null;
      body['maxPayoutCentsPerVideo'] = null;
    }

    put('minPayoutCentsPerVideo', minPayoutCentsPerVideo);
    put('submissionsCloseAtBudgetPercent', submissionsCloseAtBudgetPercent);

    if (includeStatus && status != CampaignStatus.unknown) {
      body['status'] = status.apiValue;
    }

    return body;
  }

  /// Non-sensitive local resume snapshot (no auth tokens / secrets).
  Map<String, dynamic> toLocalJson() => {
    'serverId': serverId,
    'allowMultiplePosts': allowMultiplePosts,
    ...toApiBody(includeStatus: true),
  };

  factory CampaignEditorDraft.fromLocalJson(Map<String, dynamic> json) {
    final draft = CampaignEditorDraft(
      serverId: json['serverId'] as String?,
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      type: CampaignTypeApi.fromApi(json['type'] as String?),
      objective: CampaignObjectiveApi.fromApi(
        json['campaignObjective'] as String?,
      ),
      niche: json['niche'] as String?,
      landingUrl: json['landingUrl'] as String?,
      assetsUrl: json['assetsUrl'] as String?,
      brandLogoUrl: json['brandLogoUrl'] as String?,
      platforms: (json['platforms'] as String?) ?? '',
      totalBudgetCents: (json['totalBudgetCents'] as num?)?.toInt() ?? 1000,
      cpmCents: (json['cpmCents'] as num?)?.toInt() ?? 0,
      cpcCents: (json['cpcCents'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      campaignEndDate: json['campaignEndDate'] as String?,
      isGeoTargeted: json['isGeoTargeted'] as bool? ?? false,
      targetCountryCode: json['targetCountryCode'] as String?,
      targetCity: json['targetCity'] as String?,
      targetLatitude: (json['targetLatitude'] as num?)?.toDouble(),
      targetLongitude: (json['targetLongitude'] as num?)?.toDouble(),
      targetRadiusKm: (json['targetRadiusKm'] as num?)?.toInt() ?? 50,
      videoMinDurationMinutes: (json['videoMinDurationMinutes'] as num?)
          ?.toInt(),
      allowMultiplePosts: json['allowMultiplePosts'] as bool? ?? true,
      shortsPlatform: json['shortsPlatform'] as String?,
      shortsMaxDurationSeconds: (json['shortsMaxDurationSeconds'] as num?)
          ?.toInt(),
      shortsRequireVertical: json['shortsRequireVertical'] as bool?,
      shortsRequireHashtag: json['shortsRequireHashtag'] as String?,
      shortsRequireLinkInBio: json['shortsRequireLinkInBio'] as bool?,
      minPayoutCentsPerVideo: (json['minPayoutCentsPerVideo'] as num?)?.toInt(),
      maxPayoutCentsPerVideo: (json['maxPayoutCentsPerVideo'] as num?)?.toInt(),
      submissionsCloseAtBudgetPercent:
          (json['submissionsCloseAtBudgetPercent'] as num?)?.toInt(),
      status: CampaignStatus.fromString(json['status'] as String?),
    );
    final vr = json['videoRequirements'];
    if (vr is Map && vr['allowMultiplePosts'] is bool) {
      draft.allowMultiplePosts = vr['allowMultiplePosts'] as bool;
    }
    return draft;
  }

  factory CampaignEditorDraft.fromServerJson(Map<String, dynamic> json) {
    final c = json['campaign'] is Map
        ? Map<String, dynamic>.from(json['campaign'] as Map)
        : json;
    String? dateOnly(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.length >= 10) return s.substring(0, 10);
      return s;
    }

    final draft = CampaignEditorDraft.fromLocalJson({
      ...c,
      'serverId': c['id'],
      'campaignEndDate': dateOnly(c['campaignEndDate']),
    });
    return draft;
  }
}
