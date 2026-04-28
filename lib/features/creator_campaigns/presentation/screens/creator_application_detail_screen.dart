import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../domain/creator_campaign_detail.dart';
import '../../domain/creator_social_post.dart';
import '../providers/creator_campaigns_providers.dart';
import '../widgets/creator_submit_post_sheet.dart';

/// Application detail screen (creator side).
///
/// Only accessible when the creator has an application on this campaign.
/// Shows:
/// - Campaign header + application status
/// - List of previously submitted videos with their review status
/// - Primary action bar:
///   - APPROVED + VIDEO/SHORTS → "Submit a post" + "Chat with advertiser"
///   - APPROVED + LINK → "Chat with advertiser" (no video submission)
///   - PENDING → disabled message
class CreatorApplicationDetailScreen extends ConsumerWidget {
  const CreatorApplicationDetailScreen({
    super.key,
    required this.campaignId,
    this.title,
  });

  final String campaignId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    ref.watch(localeProvider); // keep locale tracked for re-render
    final detailAsync = ref.watch(creatorCampaignDetailProvider(campaignId));
    final postsAsync = ref.watch(creatorMySubmissionsProvider(campaignId));

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? t.creator.campaigns.application_title),
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: CreatorColors.primaryOf(context),
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(creatorCampaignDetailProvider(campaignId));
          ref.invalidate(creatorMySubmissionsProvider(campaignId));
          await ref.read(creatorCampaignDetailProvider(campaignId).future);
          await ref.read(creatorMySubmissionsProvider(campaignId).future);
        },
        child: detailAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
                child: CircularProgressIndicator(
                  color: CreatorColors.primaryOf(context),
                ),
              ),
            ],
          ),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 40),
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 14),
              Text(
                t.creator.campaigns.load_error,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium(context),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(creatorCampaignDetailProvider(campaignId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(t.dashboard.errors.retry),
                ),
              ),
            ],
          ),
          data: (c) {
            // Prefer freshest submissions list coming from the dedicated
            // submissions provider (falls back to the ones embedded in the
            // detail payload while it's still loading).
            final posts = postsAsync.valueOrNull ?? c.myVideos;
            final merged = c.mergeSocialPosts(posts);
            return _Body(campaign: merged);
          },
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.campaign});

  final CreatorCampaignDetail campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final c = campaign;
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      children: [
        _CampaignCardHeader(campaign: c),
        const SizedBox(height: 16),
        _StatusBanner(status: c.myApplicationStatus),
        const SizedBox(height: 18),
        _SectionTitle(title: t.creator.campaigns.my_submissions_title),
        const SizedBox(height: 8),
        if (c.myVideos.isEmpty)
          _EmptySubmissions(canSubmit: c.isApproved)
        else
          ...c.myVideos.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SubmissionTile(post: p),
            ),
          ),
        const SizedBox(height: 20),
        _ActionBar(campaign: c),
      ],
    );
  }
}

class _CampaignCardHeader extends StatelessWidget {
  const _CampaignCardHeader({required this.campaign});

  final CreatorCampaignDetail campaign;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final url = c.coverUrl;
    final thumb = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            CreatorColors.primaryOf(context).withValues(alpha: 0.2),
            CreatorColors.primaryOf(context).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.campaign_outlined,
        color: CreatorColors.primaryOf(context),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surfaceElevatedOf(context),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          if (url != null && url.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                placeholder: (_, _) => thumb,
                errorWidget: (_, _, _) => thumb,
              ),
            )
          else
            thumb,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge(
                    context,
                  ).copyWith(fontSize: 15),
                ),
                if (c.advertiserName != null &&
                    c.advertiserName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    c.advertiserName!,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: AppColors.textSecondaryOf(context)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final CreatorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (color, icon, title, subtitle) = switch (status) {
      CreatorApplicationStatus.approved => (
        const Color(0xFF10B981),
        Icons.verified_rounded,
        t.creator.campaigns.status_banner_approved_title,
        t.creator.campaigns.status_banner_approved_subtitle,
      ),
      CreatorApplicationStatus.pending => (
        const Color(0xFFF59E0B),
        Icons.hourglass_top_rounded,
        t.creator.campaigns.status_banner_pending_title,
        t.creator.campaigns.status_banner_pending_subtitle,
      ),
      CreatorApplicationStatus.rejected => (
        Colors.red,
        Icons.block_rounded,
        t.creator.campaigns.status_banner_rejected_title,
        t.creator.campaigns.status_banner_rejected_subtitle,
      ),
      CreatorApplicationStatus.withdrawn => (
        AppColors.textSecondaryOf(context),
        Icons.remove_circle_outline,
        t.creator.applications.status_withdrawn,
        '',
      ),
      CreatorApplicationStatus.unknown => (
        AppColors.textSecondaryOf(context),
        Icons.help_outline,
        t.creator.applications.status_unknown,
        '',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge(
                    context,
                  ).copyWith(fontSize: 14, color: color),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: AppColors.textSecondaryOf(context)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.headlineMedium(context).copyWith(fontSize: 16),
    );
  }
}

class _EmptySubmissions extends StatelessWidget {
  const _EmptySubmissions({required this.canSubmit});

  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surfaceElevatedOf(context),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.upload_file_outlined,
            color: CreatorColors.primaryOf(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              canSubmit
                  ? t.creator.campaigns.my_submissions_empty_approved
                  : t.creator.campaigns.my_submissions_empty_pending,
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(color: AppColors.textSecondaryOf(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.post});

  final CreatorSocialPost post;

  Color _statusColor(BuildContext context) => switch (post.status) {
    CreatorSocialPostStatus.approved => const Color(0xFF10B981),
    CreatorSocialPostStatus.pending => const Color(0xFFF59E0B),
    CreatorSocialPostStatus.rejected => Colors.red,
    CreatorSocialPostStatus.flagged => const Color(0xFF8B5CF6),
    CreatorSocialPostStatus.unknown => AppColors.textSecondaryOf(context),
  };

  String _statusLabel(BuildContext context) {
    final t = context.t;
    return switch (post.status) {
      CreatorSocialPostStatus.approved =>
        t.creator.campaigns.submission_status_approved,
      CreatorSocialPostStatus.pending =>
        t.creator.campaigns.submission_status_pending,
      CreatorSocialPostStatus.rejected =>
        t.creator.campaigns.submission_status_rejected,
      CreatorSocialPostStatus.flagged =>
        t.creator.campaigns.submission_status_flagged,
      CreatorSocialPostStatus.unknown => t.creator.applications.status_unknown,
    };
  }

  Future<void> _openVideo() async {
    final url = post.videoUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = _statusColor(context);
    final thumb = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: CreatorColors.primaryOf(context).withValues(alpha: 0.12),
      ),
      child: Icon(
        Icons.ondemand_video_rounded,
        color: CreatorColors.primaryOf(context),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: (post.videoUrl?.isNotEmpty ?? false) ? _openVideo : null,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surfaceElevatedOf(context),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: post.thumbnailUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => thumb,
                    errorWidget: (_, _, _) => thumb,
                  ),
                )
              else
                thumb,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title ?? post.videoUrl ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge(
                        context,
                      ).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            _statusLabel(context),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Text(
                          t.creator.campaigns.submission_views(
                            views: post.totalValidatedViews,
                          ),
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondaryOf(context)),
                        ),
                      ],
                    ),
                    if (post.rejectionReason != null &&
                        post.rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.rejectionReason!,
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              if (post.videoUrl?.isNotEmpty ?? false)
                Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.textSecondaryOf(context),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.campaign});

  final CreatorCampaignDetail campaign;

  bool get _canSubmitMore {
    if (!campaign.isApproved) return false;
    if (!campaign.type.requiresVideoSubmission) return false;
    if (campaign.allowMultiplePosts == true) return true;
    // If multiple posts aren't allowed, only permit a new submission when the
    // previous one was rejected (same rule the backend enforces).
    final hasActive = campaign.myVideos.any(
      (p) =>
          p.status == CreatorSocialPostStatus.pending ||
          p.status == CreatorSocialPostStatus.approved ||
          p.status == CreatorSocialPostStatus.flagged,
    );
    return !hasActive;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final c = campaign;

    if (!c.isApproved) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_canSubmitMore)
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await showCreatorSubmitPostSheet(
                  context,
                  campaign: c,
                );
                if (ok == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.creator.campaigns.submit_success),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CreatorColors.primaryOf(context),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text(
                t.creator.campaigns.submit_cta,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          )
        else if (c.type.requiresVideoSubmission)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surfaceElevatedOf(context),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.creator.campaigns.submit_blocked_limit,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              context.go('/chat');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: CreatorColors.primaryOf(context),
              side: BorderSide(
                color: CreatorColors.primaryOf(context).withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: Text(
              t.creator.campaigns.chat_with_advertiser,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
