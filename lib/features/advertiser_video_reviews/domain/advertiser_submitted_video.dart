import 'package:equatable/equatable.dart';

/// UI filter tabs — matches `GET /api/advertiser/videos?status=…`.
enum AdvertiserVideoReviewFilter {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  flagged('FLAGGED');

  const AdvertiserVideoReviewFilter(this.apiValue);
  final String apiValue;

  static AdvertiserVideoReviewFilter? fromQuery(String? raw) {
    final s = (raw ?? '').trim().toUpperCase();
    for (final f in AdvertiserVideoReviewFilter.values) {
      if (f.apiValue == s) return f;
    }
    return null;
  }
}

enum AdvertiserSubmittedVideoPostStatus {
  pending,
  active,
  paused,
  flagged,
  rejected,
  completed,
  unknown;

  static AdvertiserSubmittedVideoPostStatus fromApi(dynamic raw) {
    return switch ((raw as String?)?.trim().toUpperCase() ?? '') {
      'PENDING' => AdvertiserSubmittedVideoPostStatus.pending,
      'ACTIVE' => AdvertiserSubmittedVideoPostStatus.active,
      'PAUSED' => AdvertiserSubmittedVideoPostStatus.paused,
      'FLAGGED' => AdvertiserSubmittedVideoPostStatus.flagged,
      'REJECTED' => AdvertiserSubmittedVideoPostStatus.rejected,
      'COMPLETED' => AdvertiserSubmittedVideoPostStatus.completed,
      _ => AdvertiserSubmittedVideoPostStatus.unknown,
    };
  }
}

final class AdvertiserSubmittedVideoCampaign extends Equatable {
  const AdvertiserSubmittedVideoCampaign({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final String status;

  factory AdvertiserSubmittedVideoCampaign.fromJson(Map<String, dynamic>? m) {
    return AdvertiserSubmittedVideoCampaign(
      id: (m?['id'] as String?) ?? '',
      title: (m?['title'] as String?) ?? '',
      status: (m?['status'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [id, title, status];
}

final class AdvertiserSubmittedVideoCreator extends Equatable {
  const AdvertiserSubmittedVideoCreator({
    required this.id,
    this.name,
    this.image,
    this.email,
  });

  final String id;
  final String? name;
  final String? image;
  final String? email;

  factory AdvertiserSubmittedVideoCreator.fromJson(Map<String, dynamic>? m) {
    return AdvertiserSubmittedVideoCreator(
      id: (m?['id'] as String?) ?? '',
      name: m?['name'] as String?,
      image: m?['image'] as String?,
      email: m?['email'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, image, email];
}

/// Advertiser-facing creator video submission (`SocialPost`).
final class AdvertiserSubmittedVideo extends Equatable {
  const AdvertiserSubmittedVideo({
    required this.id,
    required this.videoId,
    required this.videoType,
    required this.titleSnapshot,
    required this.postStatus,
    required this.uiStatus,
    required this.currentViews,
    required this.totalValidatedViews,
    required this.cpmCents,
    required this.campaign,
    required this.creator,
    this.thumbnailUrl,
    this.videoUrl,
    this.youtubePrivacyStatus,
    this.rejectionReason,
    this.flagReason,
    this.submittedAt,
  });

  final String id;
  final String videoId;
  final String videoType;
  final String titleSnapshot;
  final AdvertiserSubmittedVideoPostStatus postStatus;
  final String uiStatus;
  final int currentViews;
  final int totalValidatedViews;
  final int cpmCents;
  final AdvertiserSubmittedVideoCampaign campaign;
  final AdvertiserSubmittedVideoCreator creator;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? youtubePrivacyStatus;
  final String? rejectionReason;
  final String? flagReason;
  final DateTime? submittedAt;

  bool get isPending =>
      postStatus == AdvertiserSubmittedVideoPostStatus.pending;

  bool get isShort => videoType.toUpperCase() == 'SHORT';

  String get resolvedThumbnailUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return thumbnailUrl!;
    }
    if (videoId.isNotEmpty) {
      return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    }
    return '';
  }

  factory AdvertiserSubmittedVideo.fromJson(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v)?.toLocal();
      }
      return null;
    }

    final campaignRaw = m['campaign'];
    final creatorRaw = m['creator'];

    return AdvertiserSubmittedVideo(
      id: (m['id'] as String?) ?? '',
      videoId: (m['videoId'] as String?) ?? '',
      videoType: (m['videoType'] as String?) ?? 'VIDEO',
      titleSnapshot: (m['titleSnapshot'] as String?) ?? 'YouTube Video',
      postStatus: AdvertiserSubmittedVideoPostStatus.fromApi(m['postStatus']),
      uiStatus: (m['status'] as String?) ?? '',
      currentViews: (m['currentViews'] as num?)?.toInt() ?? 0,
      totalValidatedViews: (m['totalValidatedViews'] as num?)?.toInt() ?? 0,
      cpmCents: (m['cpmCents'] as num?)?.toInt() ?? 0,
      thumbnailUrl: m['thumbnailUrl'] as String?,
      videoUrl: m['videoUrl'] as String?,
      youtubePrivacyStatus: m['youtubePrivacyStatus'] as String?,
      rejectionReason: m['rejectionReason'] as String?,
      flagReason: m['flagReason'] as String?,
      campaign: AdvertiserSubmittedVideoCampaign.fromJson(
        campaignRaw is Map<String, dynamic> ? campaignRaw : null,
      ),
      creator: AdvertiserSubmittedVideoCreator.fromJson(
        creatorRaw is Map<String, dynamic> ? creatorRaw : null,
      ),
      submittedAt: parseDate(m['submittedAt'] ?? m['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    videoId,
    videoType,
    titleSnapshot,
    postStatus,
    uiStatus,
    currentViews,
    totalValidatedViews,
    cpmCents,
    campaign,
    creator,
    thumbnailUrl,
    videoUrl,
    youtubePrivacyStatus,
    rejectionReason,
    flagReason,
    submittedAt,
  ];
}

final class AdvertiserVideoStatusCounts extends Equatable {
  const AdvertiserVideoStatusCounts({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.flagged,
  });

  final int pending;
  final int approved;
  final int rejected;
  final int flagged;

  static const empty = AdvertiserVideoStatusCounts(
    pending: 0,
    approved: 0,
    rejected: 0,
    flagged: 0,
  );

  factory AdvertiserVideoStatusCounts.fromJson(Map<String, dynamic>? raw) {
    if (raw == null) return empty;
    int read(String key) => (raw[key] as num?)?.toInt() ?? 0;
    return AdvertiserVideoStatusCounts(
      pending: read('PENDING'),
      approved: read('APPROVED'),
      rejected: read('REJECTED'),
      flagged: read('FLAGGED'),
    );
  }

  int countFor(AdvertiserVideoReviewFilter filter) => switch (filter) {
    AdvertiserVideoReviewFilter.pending => pending,
    AdvertiserVideoReviewFilter.approved => approved,
    AdvertiserVideoReviewFilter.rejected => rejected,
    AdvertiserVideoReviewFilter.flagged => flagged,
  };

  @override
  List<Object?> get props => [pending, approved, rejected, flagged];
}

final class AdvertiserVideosPageResult extends Equatable {
  const AdvertiserVideosPageResult({
    required this.videos,
    required this.totalCount,
    required this.page,
    required this.totalPages,
    required this.countsByStatus,
  });

  final List<AdvertiserSubmittedVideo> videos;
  final int totalCount;
  final int page;
  final int totalPages;
  final AdvertiserVideoStatusCounts countsByStatus;

  factory AdvertiserVideosPageResult.fromJson(Map<String, dynamic> json) {
    final videosRaw = json['videos'];
    final videos = videosRaw is List
        ? videosRaw
              .whereType<Map>()
              .map(
                (e) => AdvertiserSubmittedVideo.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <AdvertiserSubmittedVideo>[];

    final countsRaw = json['countsByStatus'];
    final counts = countsRaw is Map<String, dynamic>
        ? AdvertiserVideoStatusCounts.fromJson(countsRaw)
        : countsRaw is Map
        ? AdvertiserVideoStatusCounts.fromJson(
            Map<String, dynamic>.from(countsRaw),
          )
        : AdvertiserVideoStatusCounts.empty;

    return AdvertiserVideosPageResult(
      videos: videos,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? videos.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      countsByStatus: counts,
    );
  }

  @override
  List<Object?> get props => [
    videos,
    totalCount,
    page,
    totalPages,
    countsByStatus,
  ];
}
