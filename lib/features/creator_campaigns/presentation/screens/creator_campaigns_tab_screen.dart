import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../../creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../providers/creator_campaigns_providers.dart';
import '../widgets/creator_browse_campaign_card.dart';

/// Creator **campaigns** tab — browse active campaigns and see the state
/// of applications you've already submitted.
///
/// Pull-to-refresh invalidates both [creatorBrowseCampaignsProvider] and
/// [creatorApplicationsProvider] so the "applied" / "approved" pills stay
/// in sync with the list on the left.
class CreatorCampaignsTabScreen extends ConsumerWidget {
  const CreatorCampaignsTabScreen({super.key});

  String _moneyLocale(AppLocale l) => switch (l) {
    AppLocale.en => 'en_US',
    AppLocale.fr => 'fr_FR',
    AppLocale.ar => 'ar_SA',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final browseAsync = ref.watch(creatorBrowseCampaignsProvider);
    final appsAsync = ref.watch(creatorApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.nav.campaigns), elevation: 0),
      body: RefreshIndicator(
        color: CreatorColors.primaryOf(context),
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(creatorBrowseCampaignsProvider);
          ref.invalidate(creatorApplicationsProvider);
          await ref.read(creatorBrowseCampaignsProvider.future);
        },
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _SectionHeader(
              title: t.creator.campaigns.browse_title,
              subtitle: t.creator.campaigns.browse_subtitle,
            ),
            const SizedBox(height: 12),
            browseAsync.when(
              loading: () => const _LoadingBlock(),
              error: (err, _) => _ErrorBlock(
                message: t.creator.campaigns.load_error,
                onRetry: () => ref.invalidate(creatorBrowseCampaignsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyBrowseBlock(
                    title: t.creator.campaigns.empty_title,
                    subtitle: t.creator.campaigns.empty_subtitle,
                  );
                }
                final statusByCampaign = <String, CreatorApplicationStatus>{};
                for (final a
                    in appsAsync.valueOrNull ?? const <CreatorApplication>[]) {
                  final existing = statusByCampaign[a.campaignId];
                  if (existing == null ||
                      _statusPriority(a.status) > _statusPriority(existing)) {
                    statusByCampaign[a.campaignId] = a.status;
                  }
                }
                return Column(
                  children: [
                    for (final c in list) ...[
                      CreatorBrowseCampaignCard(
                        campaign: c,
                        moneyLocale: moneyLocale,
                        applicationStatus: statusByCampaign[c.id],
                        onTap: () {
                          context.push(
                            '/creator/campaigns/${c.id}',
                            extra: <String, Object?>{
                              'coverUrl': c.coverUrl,
                              'brandLogoUrl': c.brandLogoUrl,
                              'title': c.title,
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: t.creator.campaigns.applications_title,
              subtitle: t.creator.campaigns.applications_subtitle,
            ),
            const SizedBox(height: 12),
            appsAsync.when(
              loading: () => const _LoadingBlock(),
              error: (_, _) => _ErrorBlock(
                message: t.creator.applications.load_error,
                onRetry: () => ref.invalidate(creatorApplicationsProvider),
              ),
              data: (apps) {
                final active = apps
                    .where(
                      (a) =>
                          a.status == CreatorApplicationStatus.pending ||
                          a.status == CreatorApplicationStatus.approved,
                    )
                    .toList();
                if (active.isEmpty) {
                  return _EmptyBrowseBlock(
                    title: t.creator.applications.empty_title,
                    subtitle: t.creator.applications.empty_subtitle,
                  );
                }
                return Column(
                  children: [
                    for (final a in active) ...[
                      _ApplicationTile(
                        application: a,
                        onTap: () {
                          context.push(
                            '/creator/campaigns/${a.campaignId}/application',
                            extra: <String, Object?>{'title': a.campaignTitle},
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineMedium(context).copyWith(fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTextStyles.caption(
            context,
          ).copyWith(color: AppColors.textSecondaryOf(context)),
        ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(
          color: CreatorColors.primaryOf(context),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppTextStyles.bodyLarge(context)),
          ),
          TextButton(onPressed: onRetry, child: Text(t.dashboard.errors.retry)),
        ],
      ),
    );
  }
}

class _EmptyBrowseBlock extends StatelessWidget {
  const _EmptyBrowseBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surfaceElevatedOf(context),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.explore_outlined,
            color: CreatorColors.primaryOf(context),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.headlineMedium(context).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }
}

/// When a creator has multiple applications for the same campaign (re-apply
/// flow), prefer showing the most meaningful status on the browse card.
int _statusPriority(CreatorApplicationStatus s) {
  return switch (s) {
    CreatorApplicationStatus.approved => 5,
    CreatorApplicationStatus.pending => 4,
    CreatorApplicationStatus.rejected => 3,
    CreatorApplicationStatus.withdrawn => 2,
    CreatorApplicationStatus.unknown => 1,
  };
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.application, required this.onTap});

  final CreatorApplication application;
  final VoidCallback onTap;

  Color _statusColor(BuildContext context, CreatorApplicationStatus s) {
    return switch (s) {
      CreatorApplicationStatus.approved => const Color(0xFF10B981),
      CreatorApplicationStatus.pending => const Color(0xFFF59E0B),
      CreatorApplicationStatus.rejected => Colors.red,
      CreatorApplicationStatus.withdrawn => AppColors.textSecondaryOf(context),
      CreatorApplicationStatus.unknown => AppColors.textSecondaryOf(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = application;
    final statusLabel = switch (a.status) {
      CreatorApplicationStatus.approved =>
        t.creator.applications.status_approved,
      CreatorApplicationStatus.pending => t.creator.applications.status_pending,
      CreatorApplicationStatus.rejected =>
        t.creator.applications.status_rejected,
      CreatorApplicationStatus.withdrawn =>
        t.creator.applications.status_withdrawn,
      CreatorApplicationStatus.unknown => t.creator.applications.status_unknown,
    };
    final color = _statusColor(context, a.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.surfaceElevatedOf(context),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    a.status == CreatorApplicationStatus.approved
                        ? Icons.verified_rounded
                        : Icons.timelapse_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.campaignTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLarge(
                          context,
                        ).copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      if (a.advertiserName != null &&
                          a.advertiserName!.isNotEmpty)
                        Text(
                          a.advertiserName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondaryOf(context)),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondaryOf(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
