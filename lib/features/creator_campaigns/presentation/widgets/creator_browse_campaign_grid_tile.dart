import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/campaign_grid_hero_image.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../../dashboard/domain/entities/campaign_platform.dart';
import '../../../dashboard/presentation/theme/campaign_detail_premium_palette.dart';
import '../../domain/creator_browse_campaign.dart';
import '../theme/creator_campaigns_chrome.dart';

String? _gridRateCaption(
  CreatorBrowseCampaign c,
  Translations t,
  String moneyLocale,
) {
  final rate = resolveCampaignPayoutMetric(
    type: c.type,
    cpcCents: c.cpcCents,
    cpmCents: c.cpmCents,
    spentBudgetCents: c.spentBudgetCents,
    validViews: c.validViews,
  );
  if (!rate.hasValue) return null;
  return switch (rate.kind) {
    CampaignPayoutMetricKind.cpc => t.creator.campaigns.reward_per_click(
        amount: MoneyFormatter.format(
          rate.cents / 100.0,
          currency: kWayoPublicCurrency,
          locale: moneyLocale,
        ),
      ),
    CampaignPayoutMetricKind.cpm ||
    CampaignPayoutMetricKind.consumedCpm =>
      t.creator.campaigns.reward_per_view(
        amount: MoneyFormatter.format(
          rate.cents / 1000.0 / 100.0,
          currency: kWayoPublicCurrency,
          locale: moneyLocale,
        ),
      ),
  };
}

IconData _platformGlyph(CampaignPlatform p) => switch (p) {
      CampaignPlatform.youtube => Icons.play_circle_filled_rounded,
      CampaignPlatform.tiktok => Icons.music_note_rounded,
      CampaignPlatform.instagram => Icons.photo_camera_rounded,
      CampaignPlatform.unknown => Icons.public_rounded,
    };

/// Grid tile layout — fixed blocks align rows in the 2-column browse grid.
abstract final class _CreatorGridTileLayout {
  static const double titleFontSize = 13.5;
  static const double titleLineHeight = 1.2;
  static const int titleMaxLines = 2;
  static const double titleBlockHeight =
      titleFontSize * titleLineHeight * titleMaxLines;

  static const double advertiserFontSize = 11;
  static const double advertiserLineHeight = 1.2;
  static const double advertiserBlockHeight =
      advertiserFontSize * advertiserLineHeight;

  static const double metaRowHeight = 22;
  static const double budgetLabelHeight = 14;
  static const double budgetValueHeight = 22;
  static const double progressHeight = 3;
  static const double progressTopGap = 6;
}

/// Compact 2‑column browse tile — minimal footer (creator).
class CreatorBrowseCampaignGridTile extends StatelessWidget {
  const CreatorBrowseCampaignGridTile({
    super.key,
    required this.campaign,
    required this.moneyLocale,
    required this.onTap,
    required this.gridIndex,
    this.applicationStatus,
  });

  final CreatorBrowseCampaign campaign;
  final String moneyLocale;
  final VoidCallback onTap;
  final int gridIndex;
  final CreatorApplicationStatus? applicationStatus;

  @override
  Widget build(BuildContext context) {
    final tile = _GridTileBody(
      campaign: campaign,
      moneyLocale: moneyLocale,
      onTap: onTap,
      applicationStatus: applicationStatus,
    );

    return tile
        .animate(key: ValueKey(campaign.id))
        .fadeIn(
          duration: 280.ms,
          delay: Duration(milliseconds: 55 * gridIndex),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          duration: 280.ms,
          delay: Duration(milliseconds: 55 * gridIndex),
          begin: 0.06,
          curve: Curves.easeOutCubic,
        );
  }
}

class _GridTileBody extends StatefulWidget {
  const _GridTileBody({
    required this.campaign,
    required this.moneyLocale,
    required this.onTap,
    this.applicationStatus,
  });

  final CreatorBrowseCampaign campaign;
  final String moneyLocale;
  final VoidCallback onTap;
  final CreatorApplicationStatus? applicationStatus;

  @override
  State<_GridTileBody> createState() => _GridTileBodyState();
}

class _GridTileBodyState extends State<_GridTileBody> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = widget.campaign;
    final plat = CampaignPlatform.fromString(
      (c.requiredPlatform ?? '').toLowerCase(),
    );
    final platLabel = switch (plat) {
      CampaignPlatform.youtube => t.advertiser_campaigns.platform.youtube,
      CampaignPlatform.tiktok => t.advertiser_campaigns.platform.tiktok,
      CampaignPlatform.instagram =>
        t.advertiser_campaigns.platform.instagram,
      CampaignPlatform.unknown => t.advertiser_campaigns.platform.other,
    };
    final typeLabel = switch (c.type) {
      CreatorCampaignType.link => t.creator.campaigns.type_link,
      CreatorCampaignType.video => t.creator.campaigns.type_video,
      CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
      CreatorCampaignType.unknown => '—',
    };
    final rateCaption = _gridRateCaption(c, t, widget.moneyLocale);
    final spentFrac = c.totalBudgetCents > 0
        ? (c.spentBudgetCents / c.totalBudgetCents).clamp(0.0, 1.0)
        : 0.0;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: CreatorCampaignsChrome.cardElevation(context),
          ),
          child: Material(
            color: CreatorCampaignsChrome.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: CreatorCampaignsChrome.cardBorderSide(context),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap();
              },
              splashColor:
                  CreatorCampaignsChrome.amber(context).withValues(alpha: 0.14),
              highlightColor:
                  CreatorCampaignsChrome.amber(context).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final scrimH = constraints.maxHeight *
                            CreatorCampaignsChrome.heroScrimHeightFactor(
                              context,
                            );
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _HeroVisual(
                              coverUrl: normalizeWayoAdsMediaUrl(c.coverUrl),
                              brandLogoUrl:
                                  resolveWayoAdsPublicUrl(c.brandLogoUrl),
                              type: c.type,
                            ),
                            if (scrimH > 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: scrimH,
                                child: DecoratedBox(
                                  decoration: CreatorCampaignsChrome
                                      .heroImageBottomFade(context),
                                ),
                              ),
                            if (rateCaption != null)
                              PositionedDirectional(
                                start: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: CreatorCampaignsChrome.green
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                  child: Text(
                                    rateCaption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: CreatorCampaignsChrome.green,
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.applicationStatus != null)
                              PositionedDirectional(
                                top: 8,
                                end: 8,
                                child: _StatusDotBadge(
                                  status: widget.applicationStatus!,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: _CreatorGridTileLayout.titleBlockHeight,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                c.title,
                                maxLines: _CreatorGridTileLayout.titleMaxLines,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.sora(
                                  fontSize:
                                      _CreatorGridTileLayout.titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  height:
                                      _CreatorGridTileLayout.titleLineHeight,
                                  color: CampaignDetailPremiumPalette.value(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height:
                                _CreatorGridTileLayout.advertiserBlockHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                c.advertiserName ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize:
                                      _CreatorGridTileLayout.advertiserFontSize,
                                  fontWeight: FontWeight.w600,
                                  height: _CreatorGridTileLayout
                                      .advertiserLineHeight,
                                  color: CreatorCampaignsChrome.muted(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: _CreatorGridTileLayout.metaRowHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        CreatorCampaignsChrome.typeBg(context),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: CreatorCampaignsChrome.amber(
                                        context,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    typeLabel,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: CreatorCampaignsChrome.amber(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _platformGlyph(plat),
                                  size: 14,
                                  color: CreatorCampaignsChrome.muted(context),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    platLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          CreatorCampaignsChrome.muted(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: _CreatorGridTileLayout.budgetLabelHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                t.creator.campaigns.budget_remaining_label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  color: CreatorCampaignsChrome.label(context),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: _CreatorGridTileLayout.budgetValueHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                MoneyFormatter.format(
                                  c.remainingBudgetCents / 100.0,
                                  currency: c.currency,
                                  locale: widget.moneyLocale,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  color: CreatorCampaignsChrome.amber(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: _CreatorGridTileLayout.progressTopGap,
                          ),
                          SizedBox(
                            height: _CreatorGridTileLayout.progressHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                minHeight: _CreatorGridTileLayout.progressHeight,
                                value: spentFrac,
                                backgroundColor:
                                    CreatorCampaignsChrome.divider(context),
                                color: CreatorCampaignsChrome.amber(context)
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({
    required this.coverUrl,
    required this.brandLogoUrl,
    required this.type,
  });

  final String? coverUrl;
  final String? brandLogoUrl;
  final CreatorCampaignType type;

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceElevatedOf(context),
      child: Icon(
        switch (type) {
          CreatorCampaignType.link => Icons.link_rounded,
          CreatorCampaignType.video => Icons.play_circle_fill_rounded,
          CreatorCampaignType.shorts => Icons.movie_filter_rounded,
          CreatorCampaignType.unknown => Icons.campaign_outlined,
        },
        color: CreatorCampaignsChrome.amber(context).withValues(alpha: 0.85),
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CampaignGridHeroImage(
      coverUrl: coverUrl,
      brandLogoUrl: brandLogoUrl,
      backdropColor: CreatorCampaignsChrome.card(context),
      fallback: _fallback(context),
    );
  }
}

class _StatusDotBadge extends StatelessWidget {
  const _StatusDotBadge({required this.status});

  final CreatorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final fg = switch (status) {
      CreatorApplicationStatus.approved => CreatorCampaignsChrome.green,
      CreatorApplicationStatus.pending =>
          CreatorCampaignsChrome.amber(context),
      CreatorApplicationStatus.rejected => Colors.redAccent,
      _ => CreatorCampaignsChrome.muted(context),
    };
    final icon = switch (status) {
      CreatorApplicationStatus.approved => Icons.verified_rounded,
      CreatorApplicationStatus.pending => Icons.schedule_rounded,
      CreatorApplicationStatus.rejected => Icons.block_rounded,
      _ => Icons.info_outline_rounded,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }
}
