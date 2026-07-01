import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/campaigns/campaign_recency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/campaign_grid_hero_image.dart';
import '../../../../core/widgets/campaign_new_badge.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/domain/entities/campaign_platform.dart';
import '../../../dashboard/domain/entities/campaign_status.dart';
import '../../domain/advertiser_campaign.dart';
import '../theme/advertiser_campaigns_chrome.dart';

/// Grid tile layout metrics — fixed blocks keep rows aligned in the 2-column grid.
abstract final class _AdvertiserGridTileLayout {
  static const double titleFontSize = 13.5;
  static const double titleLineHeight = 1.2;
  static const int titleMaxLines = 2;
  static const double titleBlockHeight =
      titleFontSize * titleLineHeight * titleMaxLines;

  static const double platformRowHeight = 18;
  static const double budgetLabelHeight = 14;
  static const double budgetValueHeight = 22;
}

/// Minimal grid tile: hero image + title + status + budget (no dense stats rows).
class AdvertiserCampaignGridTile extends StatelessWidget {
  const AdvertiserCampaignGridTile({
    super.key,
    required this.campaign,
    required this.moneyLocale,
    required this.onTap,
    required this.gridIndex,
  });

  final AdvertiserCampaign campaign;
  final String moneyLocale;
  final VoidCallback onTap;
  final int gridIndex;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = campaign;

    Widget tile = _GridCampaignCardBody(
      campaign: c,
      t: t,
      moneyLocale: moneyLocale,
      onTap: onTap,
    );

    return tile
        .animate(key: ValueKey(c.id))
        .fadeIn(
          duration: 280.ms,
          delay: Duration(milliseconds: 60 * gridIndex),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          duration: 280.ms,
          delay: Duration(milliseconds: 60 * gridIndex),
          begin: 0.06,
          curve: Curves.easeOutCubic,
        );
  }
}

class _GridCampaignCardBody extends StatefulWidget {
  const _GridCampaignCardBody({
    required this.campaign,
    required this.t,
    required this.moneyLocale,
    required this.onTap,
  });

  final AdvertiserCampaign campaign;
  final Translations t;
  final String moneyLocale;
  final VoidCallback onTap;

  @override
  State<_GridCampaignCardBody> createState() => _GridCampaignCardBodyState();
}

class _GridCampaignCardBodyState extends State<_GridCampaignCardBody> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final t = widget.t;

    final budgetFmt = MoneyFormatter.format(
      c.totalBudgetCents / 100.0,
      currency: kWayoPublicCurrency,
      locale: widget.moneyLocale,
    );

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
            boxShadow: AdvertiserCampaignsChrome.cardElevation(context),
          ),
          child: Material(
          color: AdvertiserCampaignsChrome.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: AdvertiserCampaignsChrome.cardBorderSide(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            splashColor:
                AdvertiserCampaignsChrome.amber(context).withValues(alpha: 0.14),
            highlightColor:
                AdvertiserCampaignsChrome.amber(context).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scrimH = constraints.maxHeight *
                          AdvertiserCampaignsChrome.heroScrimHeightFactor(
                            context,
                          );
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          _GridHeroVisual(
                            coverUrl: normalizeWayoAdsMediaUrl(c.coverUrl),
                            brandLogoUrl:
                                resolveWayoAdsPublicUrl(c.brandLogoUrl),
                          ),
                          if (scrimH > 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: scrimH,
                              child: DecoratedBox(
                                decoration: AdvertiserCampaignsChrome
                                    .heroImageBottomFade(context),
                              ),
                            ),
                          PositionedDirectional(
                            top: 8,
                            end: 8,
                            child: _GridCompactStatus(status: c.status, t: t),
                          ),
                          if (isCampaignNew(c.createdAt))
                            PositionedDirectional(
                              top: 8,
                              start: 8,
                              child: CampaignNewBadge(
                                label: t.advertiser_campaigns.card.badge_new,
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
                          height: _AdvertiserGridTileLayout.titleBlockHeight,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              c.name,
                              maxLines: _AdvertiserGridTileLayout.titleMaxLines,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sora(
                                fontSize:
                                    _AdvertiserGridTileLayout.titleFontSize,
                                fontWeight: FontWeight.w800,
                                height:
                                    _AdvertiserGridTileLayout.titleLineHeight,
                                color: AdvertiserCampaignsChrome.value(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: _AdvertiserGridTileLayout.platformRowHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                _platformGlyph(c.platform),
                                size: 14,
                                color: AdvertiserCampaignsChrome.muted(context),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _platformLabel(widget.t, c.platform),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        AdvertiserCampaignsChrome.muted(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: _AdvertiserGridTileLayout.budgetLabelHeight,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              t.advertiser_campaigns.card.budget_total,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AdvertiserCampaignsChrome.muted(context)
                                    .withValues(alpha: 0.9),
                                letterSpacing: 0.2,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: _AdvertiserGridTileLayout.budgetValueHeight,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              budgetFmt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: AdvertiserCampaignsChrome.value(context),
                              ),
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

  IconData _platformGlyph(CampaignPlatform p) => switch (p) {
        CampaignPlatform.youtube => Icons.play_circle_filled_rounded,
        CampaignPlatform.tiktok => Icons.music_note_rounded,
        CampaignPlatform.instagram => Icons.photo_camera_rounded,
        CampaignPlatform.unknown => Icons.public_rounded,
      };

  String _platformLabel(Translations t, CampaignPlatform p) => switch (p) {
        CampaignPlatform.youtube => t.advertiser_campaigns.platform.youtube,
        CampaignPlatform.tiktok => t.advertiser_campaigns.platform.tiktok,
        CampaignPlatform.instagram => t.advertiser_campaigns.platform.instagram,
        CampaignPlatform.unknown => t.advertiser_campaigns.platform.other,
      };
}

class _GridHeroVisual extends StatelessWidget {
  const _GridHeroVisual({this.coverUrl, this.brandLogoUrl});

  final String? coverUrl;
  final String? brandLogoUrl;

  @override
  Widget build(BuildContext context) {
    return CampaignGridHeroImage(
      coverUrl: coverUrl,
      brandLogoUrl: brandLogoUrl,
      backdropColor: AdvertiserCampaignsChrome.card(context),
      fallback: ColoredBox(
        color: AppColors.surfaceElevatedOf(context),
        child: Icon(
          Icons.campaign_outlined,
          color: AdvertiserCampaignsChrome.amber(context).withValues(alpha: 0.85),
          size: 40,
        ),
      ),
    );
  }
}

class _GridCompactStatus extends StatelessWidget {
  const _GridCompactStatus({required this.status, required this.t});

  final CampaignStatus status;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      CampaignStatus.active => t.advertiser_campaigns.status.active,
      CampaignStatus.paused => t.advertiser_campaigns.status.paused,
      CampaignStatus.completed => t.advertiser_campaigns.status.completed,
      CampaignStatus.draft => t.advertiser_campaigns.status.draft,
      CampaignStatus.unknown => t.advertiser_campaigns.status.other,
    };

    final (bg, fg, borderClr) =
        AdvertiserCampaignsChrome.statusChip(context, status);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: borderClr != null
            ? Border.all(color: borderClr)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
