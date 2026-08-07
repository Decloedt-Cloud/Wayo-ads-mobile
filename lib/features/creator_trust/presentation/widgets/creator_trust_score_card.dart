import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/creator_trust_remote.dart';
import '../../domain/creator_trust_score.dart';

/// Compact safe trust-score card for the creator dashboard.
class CreatorTrustScoreCard extends ConsumerWidget {
  const CreatorTrustScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.creator.trust;
    final async = ref.watch(creatorTrustScoreProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (score) => _TrustBody(score: score, t: t),
    );
  }
}

class _TrustBody extends StatelessWidget {
  const _TrustBody({required this.score, required this.t});

  final CreatorTrustScoreSnapshot score;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    final accent = CreatorColors.primaryOf(context);
    final delta = score.weeklyDelta;

    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/creator/analytics'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${score.trustScore}',
                  style: AppTextStyles.headlineMedium(
                    context,
                  ).copyWith(color: accent, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: AppTextStyles.labelLarge(context)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (score.tier != null && score.tier!.isNotEmpty)
                          t.tier(name: score.tier!),
                        if (score.isVerified) t.verified,
                        if (delta != null)
                          delta >= 0
                              ? t.delta_up(value: delta)
                              : t.delta_down(value: delta.abs()),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: AppTextStyles.caption(context),
                    ),
                    if (score.potentialCpmIncrease != null &&
                        score.potentialCpmIncrease!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        t.cpm_hint(value: score.potentialCpmIncrease!),
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: accent),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
