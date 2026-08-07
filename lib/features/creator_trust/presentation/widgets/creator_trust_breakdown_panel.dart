import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/creator_trust_remote.dart';

/// Detailed trust breakdown on analytics (web parity fields).
class CreatorTrustBreakdownPanel extends ConsumerWidget {
  const CreatorTrustBreakdownPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.creator.trust;
    final async = ref.watch(creatorTrustScoreProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (score) {
        final b = score.breakdown;
        if (b == null) return const SizedBox.shrink();
        return Material(
          color: AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.breakdown_title, style: AppTextStyles.labelLarge(context)),
                const SizedBox(height: 10),
                _Row(label: t.validation_points, value: b.validationRatePoints),
                _Row(label: t.fraud_points, value: b.fraudScorePoints),
                _Row(label: t.anomaly_points, value: b.anomalyScorePoints),
                if (score.qualityMultiplier != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'QM ×${score.qualityMultiplier!.toStringAsFixed(2)}',
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge(context))),
          Text('$value', style: AppTextStyles.labelLarge(context)),
        ],
      ),
    );
  }
}
