import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/presentation/theme/campaign_detail_premium_palette.dart';
import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/campaign_application.dart';
import '../providers/advertiser_campaigns_providers.dart';

/// Creator applications strip for advertiser campaign detail (`GET …/applications`).
class CampaignApplicationsSection extends ConsumerWidget {
  const CampaignApplicationsSection({
    super.key,
    required this.campaignId,
    this.premiumChrome = false,
  });

  final String campaignId;

  /// Campaign detail overhaul: stacked cards + bottom sheet + shimmer load.
  final bool premiumChrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final async = ref.watch(campaignApplicationsProvider(campaignId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      data: (list) => premiumChrome
          ? _PremiumDataBody(campaignId: campaignId, list: list)
          : _ClassicDataBody(
              campaignId: campaignId,
              list: list,
              isDark: isDark,
              t: t,
            ),
      loading: () =>
          premiumChrome ? const _PremiumLoading() : const _ClassicLoading(),
      error: (Object? e, StackTrace? s) => premiumChrome
          ? _PremiumError(
              onRetry: () => ref.invalidate(campaignApplicationsProvider(campaignId)),
            )
          : _ErrorState(
              message: t.advertiser_campaigns.applications.load_error,
              onRetry: () =>
                  ref.invalidate(campaignApplicationsProvider(campaignId)),
            ),
    );
  }
}

class _ClassicDataBody extends StatelessWidget {
  const _ClassicDataBody({
    required this.campaignId,
    required this.list,
    required this.isDark,
    required this.t,
  });

  final String campaignId;
  final List<CampaignApplication> list;
  final bool isDark;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        list.where((a) => a.status == CampaignApplicationStatus.pending).length;

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
          style: AppTextStyles.caption(context).copyWith(
            color: AppColors.textMutedOf(context),
            fontSize: 14,
          ),
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
  }
}

class _PremiumDataBody extends StatelessWidget {
  const _PremiumDataBody({required this.campaignId, required this.list});

  final String campaignId;
  final List<CampaignApplication> list;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pendingCount =
        list.where((a) => a.status == CampaignApplicationStatus.pending).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.advertiser_campaigns.applications.title,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CampaignDetailPremiumPalette.value(context),
                ),
              ),
            ),
            if (pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: CampaignDetailPremiumPalette.accentGradient,
                  boxShadow: CampaignDetailPremiumPalette.cardShadow(
                    context,
                    0.12,
                  ),
                ),
                child: Text(
                  t.advertiser_campaigns.applications.pending_badge(
                    count: pendingCount,
                  ),
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          t.advertiser_campaigns.applications.subtitle,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.35,
            color: CampaignDetailPremiumPalette.muted(context),
          ),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          _PremiumEmpty(t: t)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: list.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) => _PremiumApplicationCard(
              campaignId: campaignId,
              app: list[index],
            ),
          ),
      ],
    );
  }
}

class _PremiumLoading extends StatelessWidget {
  const _PremiumLoading();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CampaignDetailPremiumPalette.surface1(context),
      highlightColor:
          CampaignDetailPremiumPalette.surfaceGlass(context).withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            width: 200,
            decoration: BoxDecoration(
              color: CampaignDetailPremiumPalette.surfaceGlass(context),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: CampaignDetailPremiumPalette.surfaceGlass(context),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            4,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i == 3 ? 0 : 12),
              child: Container(
                height: 92,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CampaignDetailPremiumPalette.surfaceGlass(context),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumError extends StatelessWidget {
  const _PremiumError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: CampaignDetailPremiumPalette.surface1(context),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 36),
          const SizedBox(height: 8),
          Text(
            t.advertiser_campaigns.applications.load_error,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: CampaignDetailPremiumPalette.label(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon:
                const Icon(Icons.refresh, color: CampaignDetailPremiumPalette.amber),
            label: Text(
              t.dashboard.errors.retry,
              style: GoogleFonts.dmSans(
                color: CampaignDetailPremiumPalette.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumEmpty extends StatelessWidget {
  const _PremiumEmpty({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: CampaignDetailPremiumPalette.surface1(context),
        border: Border.all(color: CampaignDetailPremiumPalette.divider(context)),
        boxShadow: CampaignDetailPremiumPalette.cardShadow(
          context,
          0.1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add_alt_1_outlined,
            size: 40,
            color: CampaignDetailPremiumPalette.amber.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 12),
          Text(
            t.advertiser_campaigns.applications.empty_title,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CampaignDetailPremiumPalette.value(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.advertiser_campaigns.applications.empty_subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: CampaignDetailPremiumPalette.muted(context),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumApplicationCard extends ConsumerWidget {
  const _PremiumApplicationCard({
    required this.campaignId,
    required this.app,
  });

  final String campaignId;
  final CampaignApplication app;

  void _openSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ApplicationDetailSheet(campaignId: campaignId, app: app),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final handle = _creatorHandle(app.creatorName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(CampaignDetailPremiumPalette.kCardRadius),
        onTap: () => _openSheet(context),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(CampaignDetailPremiumPalette.kCardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CampaignDetailPremiumPalette.kCardRadius),
            color: CampaignDetailPremiumPalette.surface1(context),
            border: Border.all(color: CampaignDetailPremiumPalette.divider(context)),
            boxShadow: CampaignDetailPremiumPalette.cardShadow(
              context,
              0.08,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PremiumAvatar(name: app.creatorName, avatarUrl: app.creatorAvatar),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.creatorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CampaignDetailPremiumPalette.bodyValue(context)
                                    .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                handle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CampaignDetailPremiumPalette.bodyLabel(context)
                                    .copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _PremiumStatusChip(status: app.status, t: t),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                thickness: 1,
                color: CampaignDetailPremiumPalette.rowSeparator(context),
              ),
              const SizedBox(height: 12),
              Text(
                _premiumApplicationStatLine(context, t, app),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CampaignDetailPremiumPalette.bodyLabel(context).copyWith(
                  fontSize: 13,
                  color: CampaignDetailPremiumPalette.muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _premiumApplicationStatLine(
  BuildContext context,
  Translations t,
  CampaignApplication app,
) {
  final loc = Localizations.localeOf(context);
  const plat = '—';
  var mid = '—';
  if (app.trustLevel != null && app.trustLevel!.trim().isNotEmpty) {
    mid = app.trustLevel!.trim().toUpperCase();
  } else if (app.trustScore != null) {
    mid = t.advertiser_campaigns.applications.trust_score(score: app.trustScore!);
  }
  final ds = app.createdAt;
  final dateStr =
      ds != null ? DateFormat.yMMMd(loc.toLanguageTag()).format(ds.toLocal()) : '—';
  return '$plat · $mid · $dateStr';
}

String _creatorHandle(String name) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (slug.isEmpty) return '@creator';
  return '@$slug';
}

class _PremiumAvatar extends StatelessWidget {
  const _PremiumAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _PremiumAvatarPlaceholder(letter: letter),
        ),
      );
    }
    return _PremiumAvatarPlaceholder(letter: letter);
  }
}

class _PremiumAvatarPlaceholder extends StatelessWidget {
  const _PremiumAvatarPlaceholder({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: CampaignDetailPremiumPalette.accentGradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PremiumStatusChip extends StatelessWidget {
  const _PremiumStatusChip({required this.status, required this.t});

  final CampaignApplicationStatus status;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final ct = context.t;
    final (Color bg, Color fg, Color borderColor, String label) = switch (status) {
      CampaignApplicationStatus.approved => (
        const Color(0xFF1A3A2A),
        const Color(0xFF4ADE80),
        const Color(0xFF4ADE80),
        t.advertiser_campaigns.applications.approved_status,
      ),
      CampaignApplicationStatus.pending => (
        const Color(0xFF2A2000),
        const Color(0xFFF59E0B),
        const Color(0xFFF59E0B),
        ct.creator.applications.status_pending,
      ),
      CampaignApplicationStatus.rejected => (
        const Color(0xFF2A1A1A),
        const Color(0xFFF87171),
        const Color(0xFFF87171),
        t.advertiser_campaigns.applications.rejected_status,
      ),
      CampaignApplicationStatus.withdrawn => (
        CampaignDetailPremiumPalette.surfaceGlass(context),
        CampaignDetailPremiumPalette.label(context),
        CampaignDetailPremiumPalette.divider(context),
        ct.creator.applications.status_withdrawn,
      ),
      _ => (
        CampaignDetailPremiumPalette.divider(context).withValues(alpha: 0.4),
        CampaignDetailPremiumPalette.label(context),
        CampaignDetailPremiumPalette.divider(context),
        ct.creator.applications.status_unknown,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ApplicationDetailSheet extends ConsumerStatefulWidget {
  const _ApplicationDetailSheet({required this.campaignId, required this.app});

  final String campaignId;
  final CampaignApplication app;

  @override
  ConsumerState<_ApplicationDetailSheet> createState() =>
      _ApplicationDetailSheetState();
}

class _ApplicationDetailSheetState extends ConsumerState<_ApplicationDetailSheet> {
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
        Navigator.pop(context);
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
        Navigator.pop(context);
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
    final handle = _creatorHandle(app.creatorName);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CampaignDetailPremiumPalette.surface1(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0x66000000)
                  : const Color(0x22000000),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CampaignDetailPremiumPalette.divider(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                _PremiumAvatar(name: app.creatorName, avatarUrl: app.creatorAvatar),
                const SizedBox(height: 12),
                Text(
                  app.creatorName,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: CampaignDetailPremiumPalette.value(context),
                  ),
                ),
                Text(
                  handle,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: CampaignDetailPremiumPalette.muted(context),
                  ),
                ),
                const SizedBox(height: 12),
                _PremiumStatusChip(status: app.status, t: t),
                if (app.trustScore != null || app.trustLevel != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (app.trustScore != null)
                        Text(
                          t.advertiser_campaigns.applications.trust_score(
                            score: app.trustScore!,
                          ),
                          style: GoogleFonts.dmSans(
                            color: CampaignDetailPremiumPalette.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (app.trustLevel != null) _TrustBadge(level: app.trustLevel!),
                    ],
                  ),
                ],
                if (app.message != null && app.message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      app.message!,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        height: 1.45,
                        color: CampaignDetailPremiumPalette.value(context),
                      ),
                    ),
                  ),
                ],
                if (isPending) ...[
                  const SizedBox(height: 22),
                  if (_busy)
                    const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade300,
                              side:
                                  BorderSide(color: Colors.red.withValues(alpha: 0.45)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              t.advertiser_campaigns.applications.reject_button,
                              style:
                                  GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _onApprove,
                            style: FilledButton.styleFrom(
                              backgroundColor: CampaignDetailPremiumPalette.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              t.advertiser_campaigns.applications.approve_button,
                              style:
                                  GoogleFonts.dmSans(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassicLoading extends StatelessWidget {
  const _ClassicLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
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
            style: AppTextStyles.bodyLarge(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.advertiser_campaigns.applications.empty_subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textMutedOf(context),
              fontSize: 14,
            ),
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
        color: AppColors.surfaceElevatedOf(context)
            .withValues(alpha: isDark ? 0.92 : 0.98),
        border: Border.all(
          color: AppColors.borderOf(context)
              .withValues(alpha: isDark ? 0.5 : 0.65),
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
            color: AppColors.borderOf(context).withValues(
              alpha: isDark ? 0.4 : 0.7,
            ),
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
                  style:
                      AppTextStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.w700),
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
                    if (app.trustLevel != null) _TrustBadge(level: app.trustLevel!),
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
            _ClassicStatusPill(status: app.status, t: t),
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

class _ClassicStatusPill extends StatelessWidget {
  const _ClassicStatusPill({required this.status, required this.t});

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
