import 'package:equatable/equatable.dart';

/// Status of a `SocialPost` as returned by
/// `GET /api/creator/campaigns/:id/submit-post` → `application.socialPosts[]`.
///
/// Mirrors the `SocialPostStatus` enum on Wayo-ads (Prisma).
enum CreatorSocialPostStatus {
  pending,
  approved,
  rejected,
  flagged,
  unknown;

  static CreatorSocialPostStatus fromApi(dynamic raw) {
    final s = (raw as String?)?.trim().toUpperCase() ?? '';
    return switch (s) {
      'PENDING' => CreatorSocialPostStatus.pending,
      'APPROVED' ||
      'VALIDATED' ||
      'ACTIVE' ||
      'PAUSED' ||
      'COMPLETED' =>
        CreatorSocialPostStatus.approved,
      'REJECTED' => CreatorSocialPostStatus.rejected,
      'FLAGGED' => CreatorSocialPostStatus.flagged,
      _ => CreatorSocialPostStatus.unknown,
    };
  }

  /// True when this post still occupies the single-submission slot.
  bool get blocksResubmission =>
      this != CreatorSocialPostStatus.rejected;
}

/// Creator-visible video submission. The advertiser reviews these in their
/// campaign detail screen, but the creator tracks status, validated views and
/// rejection reason (if any) for each post.
final class CreatorSocialPost extends Equatable {
  const CreatorSocialPost({
    required this.id,
    required this.platform,
    required this.status,
    required this.currentViews,
    required this.totalValidatedViews,
    this.pendingValidatedViews = 0,
    this.title,
    this.thumbnailUrl,
    this.videoUrl,
    this.submittedAt,
    this.rejectionReason,
    this.flagReason,
  });

  final String id;
  final String platform;
  final CreatorSocialPostStatus status;
  final int currentViews;
  final int totalValidatedViews;

  /// Views detected on YouTube but not yet settled (48h hold).
  final int pendingValidatedViews;
  final String? title;
  final String? thumbnailUrl;
  final String? videoUrl;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final String? flagReason;

  factory CreatorSocialPost.fromJson(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }

    return CreatorSocialPost(
      id: (m['id'] as String?) ?? '',
      platform: (m['platform'] as String?)?.toUpperCase() ?? 'YOUTUBE',
      status: CreatorSocialPostStatus.fromApi(m['status']),
      currentViews: (m['currentViews'] as num?)?.toInt() ?? 0,
      totalValidatedViews: (m['totalValidatedViews'] as num?)?.toInt() ?? 0,
      pendingValidatedViews:
          (m['pendingValidatedViews'] as num?)?.toInt() ?? 0,
      title: m['title'] as String?,
      thumbnailUrl: m['thumbnailUrl'] as String?,
      videoUrl: m['videoUrl'] as String?,
      submittedAt: parseDate(m['submittedAt'] ?? m['createdAt']),
      rejectionReason: m['rejectionReason'] as String?,
      flagReason: m['flagReason'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    platform,
    status,
    currentViews,
    totalValidatedViews,
    pendingValidatedViews,
    title,
    thumbnailUrl,
    videoUrl,
    submittedAt,
    rejectionReason,
    flagReason,
  ];
}
