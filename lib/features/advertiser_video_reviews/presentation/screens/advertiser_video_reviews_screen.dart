import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/advertiser_video_reviews_repository.dart';
import '../../domain/advertiser_submitted_video.dart';
import '../providers/advertiser_video_reviews_providers.dart';

/// Foreground refresh while this screen is visible (Reverb is the fast path).
const Duration _kVideoReviewsFocusRefreshInterval = Duration(seconds: 8);

/// Full-screen advertiser video review queue — filters, list, approve/reject.
class AdvertiserVideoReviewsScreen extends ConsumerStatefulWidget {
  const AdvertiserVideoReviewsScreen({
    super.key,
    this.initialFilter,
  });

  final AdvertiserVideoReviewFilter? initialFilter;

  @override
  ConsumerState<AdvertiserVideoReviewsScreen> createState() =>
      _AdvertiserVideoReviewsScreenState();
}

class _AdvertiserVideoReviewsScreenState
    extends ConsumerState<AdvertiserVideoReviewsScreen>
    with WidgetsBindingObserver {
  String? _processingVideoId;
  Timer? _focusPollTimer;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final filter = widget.initialFilter;
      if (filter != null) {
        ref.read(advertiserVideoReviewFilterProvider.notifier).state = filter;
        ref.read(advertiserVideoReviewsPageProvider.notifier).state = 1;
      }
      _startFocusPolling();
    });
  }

  @override
  void dispose() {
    _focusPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      invalidateAdvertiserVideoReviews(ref);
      _startFocusPolling();
    } else {
      _focusPollTimer?.cancel();
      _focusPollTimer = null;
    }
  }

  void _startFocusPolling() {
    _focusPollTimer?.cancel();
    _focusPollTimer = Timer.periodic(_kVideoReviewsFocusRefreshInterval, (_) {
      if (!mounted) return;
      if (_lifecycle != AppLifecycleState.resumed) return;
      invalidateAdvertiserVideoReviews(ref);
    });
  }

  Future<void> _refresh() async {
    invalidateAdvertiserVideoReviews(ref);
    HapticFeedback.lightImpact();
  }

  Future<void> _approve(AdvertiserSubmittedVideo video) async {
    if (_processingVideoId != null) return;
    setState(() => _processingVideoId = video.id);
    final t = context.t.advertiser_video_reviews;
    try {
      await ref
          .read(advertiserVideoReviewsRepositoryProvider)
          .approveVideo(video.id);
      if (!mounted) return;
      invalidateAdvertiserVideoReviews(ref);
      WayoToast.success(context, t.approve_success);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ServerException && e.message.isNotEmpty
          ? e.message
          : t.action_failed;
      WayoToast.error(context, msg);
    } finally {
      if (mounted) setState(() => _processingVideoId = null);
    }
  }

  Future<void> _reject(AdvertiserSubmittedVideo video) async {
    final t = context.t.advertiser_video_reviews;
    final reason = await showWayoDialog<String>(
      context: context,
      builder: (ctx) => _RejectReasonDialog(videoTitle: video.titleSnapshot),
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    setState(() => _processingVideoId = video.id);
    try {
      await ref
          .read(advertiserVideoReviewsRepositoryProvider)
          .rejectVideo(video.id, reason: reason.trim());
      if (!mounted) return;
      invalidateAdvertiserVideoReviews(ref);
      WayoToast.success(context, t.reject_success);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ServerException && e.message.isNotEmpty
          ? e.message
          : t.action_failed;
      WayoToast.error(context, msg);
    } finally {
      if (mounted) setState(() => _processingVideoId = null);
    }
  }

  Future<void> _openVideo(AdvertiserSubmittedVideo video) async {
    final raw = video.videoUrl?.trim();
    final url = (raw != null && raw.isNotEmpty)
        ? raw
        : video.videoId.isNotEmpty
        ? 'https://www.youtube.com/watch?v=${video.videoId}'
        : null;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final vr = t.advertiser_video_reviews;
    final filter = ref.watch(advertiserVideoReviewFilterProvider);
    final page = ref.watch(advertiserVideoReviewsPageProvider);
    final query = (filter: filter, page: page);
    final async = ref.watch(advertiserVideoReviewsProvider(query));

    return Scaffold(
      bottomNavigationBar: const WayoBlackBottomBar(),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          vr.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headlineMedium(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  vr.subtitle,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: async.maybeWhen(
                data: (result) => _FilterRow(
                  counts: result.countsByStatus,
                  selected: filter,
                  onSelected: (next) {
                    ref.read(advertiserVideoReviewFilterProvider.notifier).state =
                        next;
                    ref.read(advertiserVideoReviewsPageProvider.notifier).state =
                        1;
                  },
                ),
                orElse: () => _FilterRow(
                  counts: AdvertiserVideoStatusCounts.empty,
                  selected: filter,
                  onSelected: (next) {
                    ref.read(advertiserVideoReviewFilterProvider.notifier).state =
                        next;
                    ref.read(advertiserVideoReviewsPageProvider.notifier).state =
                        1;
                  },
                ),
              ),
            ),
            async.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Skeletonizer(
                      enabled: true,
                      child: const _VideoCardSkeleton(),
                    ),
                    childCount: 3,
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vr.load_error,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge(context),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _refresh,
                          child: Text(t.dashboard.errors.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (result) {
                if (result.videos.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam_off_outlined,
                              size: 48,
                              color: AppColors.textSecondaryOf(context),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              vr.empty,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: result.videos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final video = result.videos[index];
                      return _VideoReviewCard(
                        video: video,
                        busy: _processingVideoId == video.id,
                        onApprove: () => _approve(video),
                        onReject: () => _reject(video),
                        onOpenVideo: () => _openVideo(video),
                        onOpenCampaign: () => context.push(
                          '/campaigns/${video.campaign.id}',
                          extra: {'title': video.campaign.title},
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            async.maybeWhen(
              data: (result) {
                if (result.totalPages <= 1) {
                  return const SliverToBoxAdapter(child: SizedBox(height: 24));
                }
                return SliverToBoxAdapter(
                  child: _PaginationBar(
                    page: result.page,
                    totalPages: result.totalPages,
                    totalCount: result.totalCount,
                    onPrevious: result.page > 1
                        ? () => ref
                              .read(advertiserVideoReviewsPageProvider.notifier)
                              .state = result.page - 1
                        : null,
                    onNext: result.page < result.totalPages
                        ? () => ref
                              .read(advertiserVideoReviewsPageProvider.notifier)
                              .state = result.page + 1
                        : null,
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: WayoBlackBottomBar.totalHeight(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final AdvertiserVideoStatusCounts counts;
  final AdvertiserVideoReviewFilter selected;
  final ValueChanged<AdvertiserVideoReviewFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.t.advertiser_video_reviews;
    final items = <({AdvertiserVideoReviewFilter filter, String label})>[
      (filter: AdvertiserVideoReviewFilter.pending, label: t.pending),
      (filter: AdvertiserVideoReviewFilter.approved, label: t.approved),
      (filter: AdvertiserVideoReviewFilter.rejected, label: t.rejected),
      (filter: AdvertiserVideoReviewFilter.flagged, label: t.flagged),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            FilterChip(
              label: Text('${item.label} (${counts.countFor(item.filter)})'),
              selected: selected == item.filter,
              onSelected: (_) => onSelected(item.filter),
              selectedColor: AppColors.primary.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primary,
            ),
        ],
      ),
    );
  }
}

class _VideoReviewCard extends StatelessWidget {
  const _VideoReviewCard({
    required this.video,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onOpenVideo,
    required this.onOpenCampaign,
  });

  final AdvertiserSubmittedVideo video;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onOpenVideo;
  final VoidCallback onOpenCampaign;

  @override
  Widget build(BuildContext context) {
    final t = context.t.advertiser_video_reviews;
    final thumb = video.resolvedThumbnailUrl;
    final submitted = video.submittedAt != null
        ? DateFormat.yMMMd().add_Hm().format(video.submittedAt!)
        : null;
    final creatorName = (video.creator.name?.trim().isNotEmpty ?? false)
        ? video.creator.name!.trim()
        : 'Creator';

    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpenVideo,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumb.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        child: const Icon(Icons.play_circle_outline, size: 48),
                      ),
                    )
                  else
                    ColoredBox(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      child: const Center(
                        child: Icon(Icons.play_circle_outline, size: 48),
                      ),
                    ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.titleSnapshot,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMedium(context)
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onOpenCampaign,
                  child: Text(
                    video.campaign.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (video.isShort)
                      _Badge(label: t.shorts_badge, color: const Color(0xFF8B5CF6)),
                    _Badge(
                      label: _statusLabel(t, video),
                      color: _statusColor(video),
                    ),
                  ],
                ),
                if (submitted != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${t.submitted_at}: $submitted',
                    style: AppTextStyles.caption(context),
                  ),
                ],
                if (video.rejectionReason != null &&
                    video.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${t.rejection_reason}: ${video.rejectionReason}',
                    style: AppTextStyles.caption(context).copyWith(
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
                if (video.flagReason != null && video.flagReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${t.flag_reason}: ${video.flagReason}',
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: video.creator.image != null
                          ? NetworkImage(video.creator.image!)
                          : null,
                      child: video.creator.image == null
                          ? Text(creatorName.characters.first.toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        creatorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context),
                      ),
                    ),
                  ],
                ),
                if (video.isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: busy ? null : onApprove,
                          icon: busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(t.approve_button),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : onReject,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: Text(t.reject_button),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(TranslationsAdvertiserVideoReviewsEn t, AdvertiserSubmittedVideo video) {
    return switch (video.postStatus) {
      AdvertiserSubmittedVideoPostStatus.pending => t.status_pending,
      AdvertiserSubmittedVideoPostStatus.rejected => t.status_rejected,
      AdvertiserSubmittedVideoPostStatus.flagged => t.status_flagged,
      _ => t.status_approved,
    };
  }

  Color _statusColor(AdvertiserSubmittedVideo video) {
    return switch (video.postStatus) {
      AdvertiserSubmittedVideoPostStatus.pending => const Color(0xFFF59E0B),
      AdvertiserSubmittedVideoPostStatus.rejected => const Color(0xFFEF4444),
      AdvertiserSubmittedVideoPostStatus.flagged => AppColors.primary,
      _ => const Color(0xFF10B981),
    };
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _VideoCardSkeleton extends StatelessWidget {
  const _VideoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox(height: 260),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              '$page / $totalPages ($totalCount)',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(context),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog({required this.videoTitle});

  final String videoTitle;

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.advertiser_video_reviews;
    return WayoAlertDialog(
      title: Text(t.reject_dialog_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.videoTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: t.reject_reason_hint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.chat.delete_confirm_cancel),
        ),
        FilledButton(
          onPressed: () {
            final reason = _ctrl.text.trim();
            if (reason.isEmpty) {
              WayoToast.warning(context, t.reject_reason_required);
              return;
            }
            Navigator.of(context).pop(reason);
          },
          child: Text(t.reject_button),
        ),
      ],
    );
  }
}
