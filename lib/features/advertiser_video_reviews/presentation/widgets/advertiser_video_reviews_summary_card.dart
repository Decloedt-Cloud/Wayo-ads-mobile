import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/advertiser_submitted_video.dart';
import '../providers/advertiser_video_reviews_providers.dart';

/// Dashboard strip — title, subtitle, and four review status counts.
class AdvertiserVideoReviewsSummaryCard extends ConsumerWidget {
  const AdvertiserVideoReviewsSummaryCard({super.key});

  void _openReviews(
    BuildContext context,
    AdvertiserVideoReviewFilter filter,
  ) {
    HapticFeedback.lightImpact();
    context.push(
      '/advertiser/video-reviews?status=${filter.apiValue}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final vr = t.advertiser_video_reviews;
    final async = ref.watch(advertiserVideoReviewCountsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openReviews(
            context,
            AdvertiserVideoReviewFilter.pending,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vr.title,
                            style: AppTextStyles.headlineMedium(context)
                                .copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vr.subtitle,
                            style: AppTextStyles.caption(context).copyWith(
                              color: AppColors.textSecondaryOf(context),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                async.when(
                  data: (counts) => _CountsGrid(
                    counts: counts,
                    onTap: (filter) => _openReviews(context, filter),
                  ),
                  loading: () => Skeletonizer(
                    enabled: true,
                    child: _CountsGrid(
                      counts: const AdvertiserVideoStatusCounts(
                        pending: 0,
                        approved: 2,
                        rejected: 0,
                        flagged: 0,
                      ),
                      onTap: (_) {},
                    ),
                  ),
                  error: (_, __) => Text(
                    vr.load_error,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountsGrid extends StatelessWidget {
  const _CountsGrid({required this.counts, required this.onTap});

  final AdvertiserVideoStatusCounts counts;
  final void Function(AdvertiserVideoReviewFilter filter) onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t.advertiser_video_reviews;
    final items = <({AdvertiserVideoReviewFilter filter, String label, int value, Color color})>[
      (
        filter: AdvertiserVideoReviewFilter.pending,
        label: t.pending,
        value: counts.pending,
        color: const Color(0xFFF59E0B),
      ),
      (
        filter: AdvertiserVideoReviewFilter.approved,
        label: t.approved,
        value: counts.approved,
        color: const Color(0xFF10B981),
      ),
      (
        filter: AdvertiserVideoReviewFilter.rejected,
        label: t.rejected,
        value: counts.rejected,
        color: const Color(0xFFEF4444),
      ),
      (
        filter: AdvertiserVideoReviewFilter.flagged,
        label: t.flagged,
        value: counts.flagged,
        color: AppColors.primary,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _CountTile(
              label: items[i].label,
              value: items[i].value,
              accent: items[i].color,
              onTap: () => onTap(items[i].filter),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final int value;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              Text(
                '$value',
                style: AppTextStyles.headlineMedium(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
