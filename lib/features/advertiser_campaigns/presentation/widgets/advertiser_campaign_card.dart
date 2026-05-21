import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../dashboard/domain/entities/campaign_platform.dart';
import '../../../dashboard/domain/entities/campaign_status.dart';
import '../../domain/advertiser_campaign.dart';
import '../theme/advertiser_campaigns_chrome.dart';

class AdvertiserCampaignCard extends StatefulWidget {
  const AdvertiserCampaignCard({
    super.key,
    required this.campaign,
    required this.moneyLocale,
    required this.onTap,
    required this.listIndex,
  });

  final AdvertiserCampaign campaign;
  final String moneyLocale;
  final VoidCallback onTap;

  /// Stagger entrance animation offset.
  final int listIndex;

  @override
  State<AdvertiserCampaignCard> createState() => _AdvertiserCampaignCardState();
}

class _AdvertiserCampaignCardState extends State<AdvertiserCampaignCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = widget.campaign;

    Widget card = Listener(
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
                AdvertiserCampaignsChrome.amber(context).withValues(alpha: 0.12),
            highlightColor:
                AdvertiserCampaignsChrome.amber(context).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ListThumbGradient(
                        coverUrl: normalizeWayoAdsMediaUrl(c.coverUrl),
                        brandLogoUrl: resolveWayoAdsPublicUrl(c.brandLogoUrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: AdvertiserCampaignsChrome.value(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _ListStatusChip(status: c.status, t: t),
                                _ListTypeChip(type: c.campaignType, t: t),
                                _ListPlatformChip(platform: c.platform, t: t),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AdvertiserCampaignsChrome.divider(context),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                          label: t.advertiser_campaigns.card.budget_total,
                          value: MoneyFormatter.format(
                            c.totalBudgetCents / 100.0,
                            currency: c.currency,
                            locale: widget.moneyLocale,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _StatColumn(
                          label: _remainingOrSpentLabel(context, c),
                          value: _remainingOrSpentValue(context, c),
                        ),
                      ),
                      Expanded(
                        child: _StatColumn(
                          label: t.advertiser_campaigns.card.cpc,
                          value: c.cpcCents > 0
                              ? MoneyFormatter.format(
                                  c.cpcCents / 100.0,
                                  currency: c.currency,
                                  locale: widget.moneyLocale,
                                )
                              : '—',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AdvertiserCampaignsChrome.divider(context),
                  ),
                  const SizedBox(height: 10),
                  _EngagementFooter(campaign: c, t: t),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );

    return card
        .animate(key: ValueKey(c.id))
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 80 * widget.listIndex),
          curve: Curves.easeOutCubic,
        )
        .slideX(
          duration: 300.ms,
          delay: Duration(milliseconds: 80 * widget.listIndex),
          begin: 0.05,
          curve: Curves.easeOutCubic,
        );
  }

  String _remainingOrSpentLabel(BuildContext context, AdvertiserCampaign c) {
    final t = context.t;
    if (c.status == CampaignStatus.completed) {
      return t.advertiser_campaigns.card.spent;
    }
    return t.advertiser_campaigns.card.remaining;
  }

  String _remainingOrSpentValue(BuildContext context, AdvertiserCampaign c) {
    final cents =
        c.status == CampaignStatus.completed ? c.spentBudgetCents : c.remainingBudgetCents;
    return MoneyFormatter.format(
      cents / 100.0,
      currency: c.currency,
      locale: widget.moneyLocale,
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AdvertiserCampaignsChrome.muted(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AdvertiserCampaignsChrome.value(context),
          ),
        ),
      ],
    );
  }
}

class _EngagementFooter extends StatelessWidget {
  const _EngagementFooter({required this.campaign, required this.t});

  final AdvertiserCampaign campaign;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    String viewsTxt() => t.advertiser_campaigns.card.list_row_views
        .replaceAll('{count}', '${campaign.validViews}');
    String clicksTxt() => t.advertiser_campaigns.card.list_row_clicks
        .replaceAll('{count}', '${campaign.validClicks}');
    String creatorsTxt() => t.advertiser_campaigns.card.list_row_creators
        .replaceAll('{count}', '${campaign.approvedCreators}');

    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: t.advertiser_campaigns.detail.valid_views,
            child: _FooterCell(icon: Icons.visibility_outlined, text: viewsTxt()),
          ),
        ),
        SizedBox(
          height: 20,
          child: VerticalDivider(
            width: 1,
            thickness: 1,
            color: AdvertiserCampaignsChrome.divider(context),
          ),
        ),
        Expanded(
          child: Tooltip(
            message: t.advertiser_campaigns.detail.valid_clicks,
            child: _FooterCell(icon: Icons.ads_click_rounded, text: clicksTxt()),
          ),
        ),
        SizedBox(
          height: 20,
          child: VerticalDivider(
            width: 1,
            thickness: 1,
            color: AdvertiserCampaignsChrome.divider(context),
          ),
        ),
        Expanded(
          child: Tooltip(
            message: t.advertiser_campaigns.detail.approved_creators,
            child:
                _FooterCell(icon: Icons.groups_2_outlined, text: creatorsTxt()),
          ),
        ),
      ],
    );
  }
}

class _FooterCell extends StatelessWidget {
  const _FooterCell({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AdvertiserCampaignsChrome.amber(context).withValues(alpha: 0.9),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AdvertiserCampaignsChrome.value(context)
                  .withValues(alpha: 0.92),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListThumbGradient extends StatelessWidget {
  const _ListThumbGradient({this.coverUrl, this.brandLogoUrl});

  final String? coverUrl;

  /// Absolute URL for brand mark (optional).
  final String? brandLogoUrl;

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    Widget tile(String? url) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              url != null && url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      memCacheWidth: 160,
                      memCacheHeight: 160,
                      errorWidget: (context, url, error) => _placeholder(context),
                    )
                  : _placeholder(context),
              if (Theme.of(context).brightness == Brightness.dark)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _size *
                      AdvertiserCampaignsChrome.heroScrimHeightFactor(context),
                  child: DecoratedBox(
                    decoration: AdvertiserCampaignsChrome.heroImageBottomFade(
                      context,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final logo = brandLogoUrl;
    if (logo != null && logo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: logo,
                fit: BoxFit.contain,
                memCacheWidth: 160,
                memCacheHeight: 160,
                errorWidget: (context, url, error) => tile(coverUrl),
              ),
              if (Theme.of(context).brightness == Brightness.dark)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _size * 0.45,
                  child: DecoratedBox(
                    decoration: AdvertiserCampaignsChrome.heroImageBottomFade(
                      context,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return tile(coverUrl);
  }

  Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceElevatedOf(context),
      child: Icon(
        Icons.campaign_outlined,
        color: AdvertiserCampaignsChrome.amber(context).withValues(alpha: 0.85),
      ),
    );
  }
}

class _ListStatusChip extends StatelessWidget {
  const _ListStatusChip({required this.status, required this.t});

  final CampaignStatus status;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final String label = switch (status) {
      CampaignStatus.active => t.advertiser_campaigns.status.active,
      CampaignStatus.paused => t.advertiser_campaigns.status.paused,
      CampaignStatus.completed => t.advertiser_campaigns.status.completed,
      CampaignStatus.draft => t.advertiser_campaigns.status.draft,
      CampaignStatus.unknown => t.advertiser_campaigns.status.other,
    };

    final (bg, fg, borderClr) =
        AdvertiserCampaignsChrome.statusChip(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: borderClr != null
            ? Border.all(color: borderClr, width: 1)
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ListTypeChip extends StatelessWidget {
  const _ListTypeChip({required this.type, required this.t});

  final CreatorCampaignType type;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      CreatorCampaignType.link => t.creator.campaigns.type_link,
      CreatorCampaignType.video => t.creator.campaigns.type_video,
      CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
      CreatorCampaignType.unknown => '—',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AdvertiserCampaignsChrome.typeBg(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AdvertiserCampaignsChrome.amber(context),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: AdvertiserCampaignsChrome.amber(context),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ListPlatformChip extends StatelessWidget {
  const _ListPlatformChip({required this.platform, required this.t});

  final CampaignPlatform platform;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final label = switch (platform) {
      CampaignPlatform.youtube => t.advertiser_campaigns.platform.youtube,
      CampaignPlatform.tiktok => t.advertiser_campaigns.platform.tiktok,
      CampaignPlatform.instagram => t.advertiser_campaigns.platform.instagram,
      CampaignPlatform.unknown => t.advertiser_campaigns.platform.other,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: AdvertiserCampaignsChrome.muted(context),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
