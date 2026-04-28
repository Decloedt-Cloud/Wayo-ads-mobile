import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/campaign_application.dart';
import '../providers/advertiser_campaigns_providers.dart';

class CampaignApplicationsSection extends ConsumerWidget {
  const CampaignApplicationsSection({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final async = ref.watch(campaignApplicationsProvider(campaignId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      data: (list) {
        final pending = list.where(
          (a) => a.status == CampaignApplicationStatus.pending,
        );
        final pendingCount = pending.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: t.advertiser_campaigns.applications.title,
              pendingCount: pendingCount,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            Text(
              t.advertiser_campaigns.applications.subtitle,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: AppColors.textMutedOf(context), fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              _EmptyState(t: t, isDark: isDark)
            else
              _ApplicationsList(
                campaignId: campaignId,
                applications: list,
                isDark: isDark,
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => _ErrorState(
        message: t.advertiser_campaigns.applications.load_error,
        onRetry: () => ref.invalidate(campaignApplicationsProvider(campaignId)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.pendingCount,
    required this.isDark,
  });

  final String title;
  final int pendingCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.labelLarge(context).copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: AppColors.textMutedOf(context),
          ),
        ),
        if (pendingCount > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              t.advertiser_campaigns.applications.pending_badge(
                count: pendingCount,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t, required this.isDark});

  final Translations t;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surfaceElevatedOf(context),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 40,
            color: AppColors.textMutedOf(context),
          ),
          const SizedBox(height: 12),
          Text(
            t.advertiser_campaigns.applications.empty_title,
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            t.advertiser_campaigns.applications.empty_subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.textMutedOf(context), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 36, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.t.dashboard.errors.retry),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsList extends StatelessWidget {
  const _ApplicationsList({
    required this.campaignId,
    required this.applications,
    required this.isDark,
  });

  final String campaignId;
  final List<CampaignApplication> applications;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceElevatedOf(
          context,
        ).withValues(alpha: isDark ? 0.92 : 0.98),
        border: Border.all(
          color: AppColors.borderOf(
            context,
          ).withValues(alpha: isDark ? 0.5 : 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: applications.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.borderOf(
              context,
            ).withValues(alpha: isDark ? 0.4 : 0.7),
          ),
        ),
        itemBuilder: (context, index) => _ApplicationTile(
          campaignId: campaignId,
          app: applications[index],
          isDark: isDark,
        ),
      ),
    );
  }
}

class _ApplicationTile extends ConsumerStatefulWidget {
  const _ApplicationTile({
    required this.campaignId,
    required this.app,
    required this.isDark,
  });

  final String campaignId;
  final CampaignApplication app;
  final bool isDark;

  @override
  ConsumerState<_ApplicationTile> createState() => _ApplicationTileState();
}

class _ApplicationTileState extends ConsumerState<_ApplicationTile> {
  bool _busy = false;

  Future<void> _onApprove() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      final repo = ref.read(advertiserCampaignsRepositoryProvider);
      await repo.approveApplication(widget.campaignId, widget.app.id);
      ref.invalidate(campaignApplicationsProvider(widget.campaignId));
      ref.invalidate(advertiserCampaignDetailProvider(widget.campaignId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t.dashboard.application_approved),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t.dashboard.application_action_failed),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onReject() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      final repo = ref.read(advertiserCampaignsRepositoryProvider);
      await repo.rejectApplication(widget.campaignId, widget.app.id);
      ref.invalidate(campaignApplicationsProvider(widget.campaignId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t.dashboard.application_rejected),
            backgroundColor: Colors.orange.shade600,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t.dashboard.application_action_failed),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final app = widget.app;
    final isPending = app.status == CampaignApplicationStatus.pending;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(name: app.creatorName, avatarUrl: app.creatorAvatar),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.creatorName,
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (app.trustScore != null)
                      Text(
                        t.advertiser_campaigns.applications.trust_score(
                          score: app.trustScore!,
                        ),
                        style: AppTextStyles.caption(context).copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (app.trustLevel != null)
                      _TrustBadge(level: app.trustLevel!),
                  ],
                ),
                if (app.message != null && app.message!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    app.message!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textMutedOf(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isPending && !_busy)
            _ActionButtons(onReject: _onReject, onApprove: _onApprove, t: t)
          else if (isPending && _busy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            _StatusPill(status: app.status, t: t),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          avatarUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) =>
              _Placeholder(letter: letter, isDark: isDark),
        ),
      );
    }
    return _Placeholder(letter: letter, isDark: isDark);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.letter, required this.isDark});

  final String letter;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (level.toUpperCase()) {
      'BRONZE' => (Colors.brown.shade400, 'BRONZE'),
      'SILVER' => (Colors.grey.shade400, 'SILVER'),
      'GOLD' => (Colors.amber.shade600, 'GOLD'),
      'PLATINUM' => (Colors.blueGrey.shade300, 'PLATINUM'),
      _ => (AppColors.textMutedOf(context), level.toUpperCase()),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onReject,
    required this.onApprove,
    required this.t,
  });

  final VoidCallback onReject;
  final VoidCallback onApprove;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          child: OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              side: BorderSide(color: AppColors.borderOf(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 4),
                Text(
                  t.advertiser_campaigns.applications.reject_button,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: FilledButton(
            onPressed: onApprove,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  t.advertiser_campaigns.applications.approve_button,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.t});

  final CampaignApplicationStatus status;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      CampaignApplicationStatus.approved => (
        Colors.green,
        t.advertiser_campaigns.applications.approved_status,
      ),
      CampaignApplicationStatus.rejected => (
        Colors.red,
        t.advertiser_campaigns.applications.rejected_status,
      ),
      _ => (Colors.grey, '—'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
