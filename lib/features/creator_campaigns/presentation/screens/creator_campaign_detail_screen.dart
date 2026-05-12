import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../domain/creator_browse_campaign.dart';
import '../../domain/creator_campaign_detail.dart';
import '../providers/creator_campaigns_providers.dart';
import '../widgets/creator_apply_sheet.dart';

/// Full campaign detail for the creator.
///
/// Shows:
/// - Cover banner (image, brand logo when no cover, or type placeholder)
/// - Rewards (CPM / payout per view) and budget state
/// - Campaign requirements (platform, min duration, assets link)
/// - Primary action bar that morphs based on the application status:
///   - no application yet → "Apply"
///   - PENDING → disabled "Application under review"
///   - APPROVED → "Submit a post" + "Chat with advertiser"
class CreatorCampaignDetailScreen extends ConsumerWidget {
  const CreatorCampaignDetailScreen({
    super.key,
    required this.id,
    this.coverUrl,
    this.brandLogoUrl,
    this.title,
  });

  final String id;
  final String? coverUrl;

  /// From list navigation extras; merged with fetched [CreatorCampaignDetail.brandLogoUrl].
  final String? brandLogoUrl;
  final String? title;

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
    final async = ref.watch(creatorCampaignDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? t.creator.campaigns.details_title),
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: CreatorColors.primaryOf(context),
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(creatorCampaignDetailProvider(id));
          await ref.read(creatorCampaignDetailProvider(id).future);
        },
        child: async.when(
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
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 40),
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                t.creator.campaigns.load_error,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium(context),
              ),
              const SizedBox(height: 6),
              Text(
                '$err',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(color: AppColors.textSecondaryOf(context)),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(creatorCampaignDetailProvider(id)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(t.dashboard.errors.retry),
                ),
              ),
            ],
          ),
          data: (c) => _Body(
            campaign: c,
            moneyLocale: moneyLocale,
            heroCoverUrl: coverUrl,
            heroBrandLogoUrl: brandLogoUrl,
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.campaign,
    required this.moneyLocale,
    required this.heroCoverUrl,
    required this.heroBrandLogoUrl,
  });

  final CreatorCampaignDetail campaign;
  final String moneyLocale;
  final String? heroCoverUrl;

  /// Carried from browse list [extra] until detail fetch completes (optional).
  final String? heroBrandLogoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final c = campaign;
    final coverRaw = heroCoverUrl ?? c.coverUrl;
    final cover = normalizeWayoAdsMediaUrl(coverRaw) ?? coverRaw?.trim();

    final logoRaw = heroBrandLogoUrl ?? c.brandLogoUrl;
    final resolvedLogo = resolveWayoAdsPublicUrl(logoRaw);
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
      children: [
        _Hero(coverUrl: cover, brandLogoUrl: resolvedLogo, type: c.type),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.advertiserName != null && c.advertiserName!.isNotEmpty)
                Text(
                  c.advertiserName!,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 4),
              Text(c.title, style: AppTextStyles.pageTitle(context)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    label: _typeLabel(t, c.type),
                    color: CreatorColors.primaryOf(context),
                    icon: _typeIcon(c.type),
                  ),
                  _ApplicationStatusPill(status: c.myApplicationStatus),
                ],
              ),
              const SizedBox(height: 18),
              _CampaignNicheLocationSummary(campaign: c, t: t),
              const SizedBox(height: 18),
              _RewardsBlock(campaign: c, moneyLocale: moneyLocale),
              const SizedBox(height: 18),
              if (c.description != null && c.description!.isNotEmpty) ...[
                _SectionTitle(title: t.creator.campaigns.description_title),
                const SizedBox(height: 6),
                Text(c.description!, style: AppTextStyles.bodyLarge(context)),
                const SizedBox(height: 18),
              ],
              if (c.type.requiresVideoSubmission) ...[
                _SectionTitle(title: t.creator.campaigns.requirements_title),
                const SizedBox(height: 8),
                _RequirementsBlock(campaign: c),
                const SizedBox(height: 18),
              ],
              if (c.assetsUrl != null && c.assetsUrl!.isNotEmpty) ...[
                _AssetsLink(url: c.assetsUrl!),
                const SizedBox(height: 18),
              ],
              _ActionBar(campaign: c),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  IconData _typeIcon(CreatorCampaignType t) => switch (t) {
    CreatorCampaignType.link => Icons.link_rounded,
    CreatorCampaignType.video => Icons.play_circle_fill_rounded,
    CreatorCampaignType.shorts => Icons.movie_filter_rounded,
    CreatorCampaignType.unknown => Icons.campaign_outlined,
  };

  String _typeLabel(Translations t, CreatorCampaignType type) => switch (type) {
    CreatorCampaignType.link => t.creator.campaigns.type_link,
    CreatorCampaignType.video => t.creator.campaigns.type_video,
    CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
    CreatorCampaignType.unknown => '—',
  };
}

class _Hero extends StatelessWidget {
  const _Hero({required this.coverUrl, required this.type, this.brandLogoUrl});

  final String? coverUrl;
  final CreatorCampaignType type;

  /// Already resolved absolute URL ([resolveWayoAdsPublicUrl]).
  final String? brandLogoUrl;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.trim().isNotEmpty;
    final hasBrand = brandLogoUrl != null && brandLogoUrl!.trim().isNotEmpty;

    final placeholder = Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CreatorColors.primaryOf(context).withValues(alpha: 0.4),
            CreatorColors.primaryOf(context).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          switch (type) {
            CreatorCampaignType.link => Icons.link_rounded,
            CreatorCampaignType.video => Icons.play_circle_fill_rounded,
            CreatorCampaignType.shorts => Icons.movie_filter_rounded,
            CreatorCampaignType.unknown => Icons.campaign_outlined,
          },
          size: 64,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );

    if (!hasBrand) {
      if (!hasCover) {
        return SizedBox(height: 200, child: placeholder);
      }
      return SizedBox(
        height: 200,
        child: CachedNetworkImage(
          imageUrl: coverUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          memCacheWidth: 800,
          memCacheHeight: 400,
          placeholder: (_, _) => placeholder,
          errorWidget: (_, _, _) => placeholder,
        ),
      );
    }

    if (!hasCover) {
      return SizedBox(
        height: 200,
        child: ColoredBox(
          color: AppColors.surfaceElevatedOf(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: CachedNetworkImage(
              imageUrl: brandLogoUrl!,
              fit: BoxFit.contain,
              memCacheWidth: 320,
              memCacheHeight: 320,
              errorWidget: (_, _, _) => placeholder,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: coverUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              memCacheHeight: 400,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
          ),
          Positioned(
            left: 18,
            bottom: 14,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOf(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: brandLogoUrl!,
                    fit: BoxFit.contain,
                    memCacheWidth: 160,
                    memCacheHeight: 160,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignNicheLocationSummary extends StatelessWidget {
  const _CampaignNicheLocationSummary({
    required this.campaign,
    required this.t,
  });

  final CreatorCampaignDetail campaign;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final nicheLabel =
        (campaign.niche != null && campaign.niche!.trim().isNotEmpty)
            ? campaignNicheFallbackLabel(campaign.niche!)
            : '—';
    final locationLabel =
        (campaign.location != null && campaign.location!.trim().isNotEmpty)
            ? campaign.location!
            : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: 18,
              color: AppColors.textSecondaryOf(context),
            ),
            const SizedBox(width: 8),
            Text(
              t.advertiser_campaigns.detail.niche_label,
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.textMutedOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nicheLabel,
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 18,
              color: AppColors.textSecondaryOf(context),
            ),
            const SizedBox(width: 8),
            Text(
              t.advertiser_campaigns.detail.location_label,
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.textMutedOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locationLabel,
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
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

class _RewardsBlock extends StatelessWidget {
  const _RewardsBlock({required this.campaign, required this.moneyLocale});

  final CreatorCampaignDetail campaign;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = campaign;
    final items = <Widget>[];
    if (c.type.requiresVideoSubmission && c.cpmCents > 0) {
      items.add(
        _RewardTile(
          label: t.creator.campaigns.reward_cpm_label,
          value: MoneyFormatter.format(
            c.cpmCents / 100.0,
            currency: c.currency,
            locale: moneyLocale,
          ),
          icon: Icons.visibility_rounded,
          accent: CreatorColors.primaryOf(context),
        ),
      );
      items.add(
        _RewardTile(
          label: t.creator.campaigns.reward_per_view_label,
          value: MoneyFormatter.format(
            c.payoutPerViewCents / 100.0,
            currency: c.currency,
            locale: moneyLocale,
          ),
          icon: Icons.paid_rounded,
          accent: const Color(0xFF10B981),
        ),
      );
    } else if (c.type == CreatorCampaignType.link && c.cpcCents > 0) {
      items.add(
        _RewardTile(
          label: t.creator.campaigns.reward_cpc_label,
          value: MoneyFormatter.format(
            c.cpcCents / 100.0,
            currency: c.currency,
            locale: moneyLocale,
          ),
          icon: Icons.ads_click_rounded,
          accent: const Color(0xFF10B981),
        ),
      );
    }
    items.add(
      _RewardTile(
        label: t.creator.campaigns.budget_remaining_label,
        value: MoneyFormatter.format(
          c.remainingBudgetCents / 100.0,
          currency: c.currency,
          locale: moneyLocale,
        ),
        icon: Icons.account_balance_wallet_outlined,
        accent: const Color(0xFF8B5CF6),
      ),
    );
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          items[i],
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: AppColors.textSecondaryOf(context)),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.headlineMedium(context).copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _RequirementsBlock extends StatelessWidget {
  const _RequirementsBlock({required this.campaign});

  final CreatorCampaignDetail campaign;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rows = <Widget>[];
    if (campaign.requiredPlatform != null) {
      rows.add(
        _RequirementRow(
          icon: Icons.videocam_outlined,
          label: t.creator.campaigns.requirement_platform(
            platform: campaign.requiredPlatform!,
          ),
        ),
      );
    }
    if (campaign.videoMinDurationMinutes != null &&
        campaign.videoMinDurationMinutes! > 0) {
      rows.add(
        _RequirementRow(
          icon: Icons.timer_outlined,
          label: t.creator.campaigns.requirement_min_duration(
            minutes: campaign.videoMinDurationMinutes!,
          ),
        ),
      );
    }
    if (campaign.type == CreatorCampaignType.shorts &&
        campaign.shortsMaxDurationSeconds != null) {
      rows.add(
        _RequirementRow(
          icon: Icons.short_text_rounded,
          label: t.creator.campaigns.requirement_shorts_max(
            seconds: campaign.shortsMaxDurationSeconds!,
          ),
        ),
      );
    }
    if (campaign.shortsRequireVertical == true) {
      rows.add(
        _RequirementRow(
          icon: Icons.crop_portrait_rounded,
          label: t.creator.campaigns.requirement_vertical,
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(
        _RequirementRow(
          icon: Icons.check_circle_outline,
          label: t.creator.campaigns.requirement_none,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows) ...[r, const SizedBox(height: 6)],
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: CreatorColors.primaryOf(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _AssetsLink extends StatelessWidget {
  const _AssetsLink({required this.url});

  final String url;

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          _open();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: CreatorColors.primaryOf(context).withValues(alpha: 0.08),
            border: Border.all(
              color: CreatorColors.primaryOf(context).withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.folder_open_rounded,
                color: CreatorColors.primaryOf(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.creator.campaigns.assets_title,
                      style: AppTextStyles.labelLarge(
                        context,
                      ).copyWith(fontSize: 14),
                    ),
                    Text(
                      t.creator.campaigns.assets_subtitle,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                color: CreatorColors.primaryOf(context),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationStatusPill extends StatelessWidget {
  const _ApplicationStatusPill({required this.status});

  final CreatorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (status == CreatorApplicationStatus.unknown) {
      return const SizedBox.shrink();
    }
    final label = switch (status) {
      CreatorApplicationStatus.approved =>
        t.creator.applications.status_approved,
      CreatorApplicationStatus.pending => t.creator.applications.status_pending,
      CreatorApplicationStatus.rejected =>
        t.creator.applications.status_rejected,
      CreatorApplicationStatus.withdrawn =>
        t.creator.applications.status_withdrawn,
      CreatorApplicationStatus.unknown => '',
    };
    final color = switch (status) {
      CreatorApplicationStatus.approved => const Color(0xFF10B981),
      CreatorApplicationStatus.pending => const Color(0xFFF59E0B),
      CreatorApplicationStatus.rejected => Colors.red,
      CreatorApplicationStatus.withdrawn => AppColors.textSecondaryOf(context),
      CreatorApplicationStatus.unknown => AppColors.textSecondaryOf(context),
    };
    final icon = switch (status) {
      CreatorApplicationStatus.approved => Icons.verified_rounded,
      CreatorApplicationStatus.pending => Icons.timelapse_rounded,
      CreatorApplicationStatus.rejected => Icons.block_rounded,
      CreatorApplicationStatus.withdrawn => Icons.remove_circle_outline,
      CreatorApplicationStatus.unknown => Icons.help_outline,
    };
    return _Pill(label: label, color: color, icon: icon);
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.campaign});

  final CreatorCampaignDetail campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final c = campaign;

    if (c.canApply) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () async {
            final ok = await showCreatorApplySheet(
              context,
              campaignId: c.id,
              campaignTitle: c.title,
            );
            if (ok == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.creator.campaigns.apply_success),
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
          icon: const Icon(Icons.send_rounded),
          label: Text(
            t.creator.campaigns.apply_cta,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
    }

    if (c.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.creator.campaigns.apply_pending_title,
                    style: AppTextStyles.labelLarge(
                      context,
                    ).copyWith(fontSize: 14),
                  ),
                  Text(
                    t.creator.campaigns.apply_pending_subtitle,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: AppColors.textSecondaryOf(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (c.isApproved) {
      return Column(
        children: [
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                context.pushReplacement(
                  '/creator/campaigns/${c.id}/application',
                  extra: <String, Object?>{'title': c.title},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CreatorColors.primaryOf(context),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.upload_rounded),
              label: Text(
                c.type.requiresVideoSubmission
                    ? t.creator.campaigns.submit_cta
                    : t.creator.campaigns.open_application_cta,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
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
                  color: CreatorColors.primaryOf(
                    context,
                  ).withValues(alpha: 0.5),
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

    // REJECTED / WITHDRAWN / UNKNOWN — read-only state, no primary CTA.
    return const SizedBox.shrink();
  }
}
