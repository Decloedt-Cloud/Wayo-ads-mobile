import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_dashboard/domain/creator_application.dart';
import '../../../dashboard/presentation/theme/campaign_detail_premium_palette.dart';
import '../../domain/creator_browse_campaign.dart';
import '../theme/creator_campaigns_chrome.dart';

/// Premium list card — browse campaigns (creator).
class CreatorBrowseCampaignCard extends StatefulWidget {
  const CreatorBrowseCampaignCard({
    super.key,
    required this.campaign,
    required this.moneyLocale,
    required this.onTap,
    required this.listIndex,
    this.applicationStatus,
  });

  final CreatorBrowseCampaign campaign;
  final String moneyLocale;
  final VoidCallback onTap;
  final int listIndex;
  final CreatorApplicationStatus? applicationStatus;

  @override
  State<CreatorBrowseCampaignCard> createState() =>
      _CreatorBrowseCampaignCardState();
}

class _CreatorBrowseCampaignCardState extends State<CreatorBrowseCampaignCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = widget.campaign;
    final payoutPerView = c.cpmCents / 1000.0;
    final payoutLabel = c.type == CreatorCampaignType.link
        ? t.creator.campaigns.reward_per_click(
            amount: MoneyFormatter.format(
              c.cpcCents / 100.0,
              currency: c.currency,
              locale: widget.moneyLocale,
            ),
          )
        : t.creator.campaigns.reward_per_view(
            amount: MoneyFormatter.format(
              payoutPerView / 100.0,
              currency: c.currency,
              locale: widget.moneyLocale,
            ),
          );

    Widget card = Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Material(
          color: CreatorCampaignsChrome.card(context),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            splashColor:
                CreatorCampaignsChrome.amber(context).withValues(alpha: 0.12),
            highlightColor:
                CreatorCampaignsChrome.amber(context).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ListThumbGradient(
                        url: normalizeWayoAdsMediaUrl(c.coverUrl),
                        brandLogoUrl: resolveWayoAdsPublicUrl(c.brandLogoUrl),
                        type: c.type,
                      ),
                      if (widget.applicationStatus != null) ...[
                        const SizedBox(height: 6),
                        _AppStatusMini(status: widget.applicationStatus!),
                      ],
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CreatorCampaignsChrome.cardTitle(context),
                        ),
                        if (c.advertiserName != null &&
                            c.advertiserName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            c.advertiserName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CreatorCampaignsChrome.bodyDm(context),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _TypeChip(type: c.type, t: t),
                            _RewardChip(label: payoutLabel),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
          delay: Duration(milliseconds: 70 * widget.listIndex),
          curve: Curves.easeOutCubic,
        )
        .slideX(
          duration: 300.ms,
          delay: Duration(milliseconds: 70 * widget.listIndex),
          begin: 0.05,
          curve: Curves.easeOutCubic,
        );
  }
}

class _ListThumbGradient extends StatelessWidget {
  const _ListThumbGradient({
    required this.url,
    required this.type,
    this.brandLogoUrl,
  });

  final String? url;
  final String? brandLogoUrl;
  final CreatorCampaignType type;

  static const double _sz = 72;

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
        color: CreatorCampaignsChrome.amber(context).withValues(alpha: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = _fallback(context);

    Widget withGradient(Widget child) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: _sz,
            height: _sz,
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _sz * 0.48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.58),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    final logo = brandLogoUrl;
    if (logo != null && logo.isNotEmpty) {
      return withGradient(
        CachedNetworkImage(
          imageUrl: logo,
          fit: BoxFit.contain,
          memCacheWidth: 160,
          memCacheHeight: 160,
          placeholder: (context, _) => placeholder,
          errorWidget: (context, errorUrl, _) {
            final fallbackCover = url;
            return fallbackCover != null && fallbackCover.trim().isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: fallbackCover,
                    fit: BoxFit.cover,
                    memCacheWidth: 160,
                    memCacheHeight: 160,
                    placeholder: (context, _) => placeholder,
                    errorWidget: (context, w, stack) => placeholder,
                  )
                : placeholder;
          },
        ),
      );
    }

    if (url != null && url!.trim().isNotEmpty) {
      return withGradient(
        CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          memCacheWidth: 160,
          memCacheHeight: 160,
          placeholder: (context, _) => placeholder,
          errorWidget: (context, w, _) => placeholder,
        ),
      );
    }

    return withGradient(placeholder);
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, required this.t});

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
        color: CreatorCampaignsChrome.typeBg(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CreatorCampaignsChrome.amber(context)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: CreatorCampaignsChrome.amber(context),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CreatorCampaignsChrome.greenBg(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: CreatorCampaignsChrome.green,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AppStatusMini extends StatelessWidget {
  const _AppStatusMini({required this.status});

  final CreatorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final label = switch (status) {
      CreatorApplicationStatus.approved =>
        t.creator.applications.status_approved,
      CreatorApplicationStatus.pending => t.creator.applications.status_pending,
      CreatorApplicationStatus.rejected =>
        t.creator.applications.status_rejected,
      CreatorApplicationStatus.withdrawn =>
        t.creator.applications.status_withdrawn,
      CreatorApplicationStatus.unknown =>
        t.creator.applications.status_unknown,
    };
    final bg = switch (status) {
      CreatorApplicationStatus.approved =>
        CreatorCampaignsChrome.greenBg(context),
      CreatorApplicationStatus.pending =>
        CreatorCampaignsChrome.typeBg(context),
      CreatorApplicationStatus.rejected =>
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF3F1F1F)
            : const Color(0xFFFEF2F2),
      _ => Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A35)
          : CampaignDetailPremiumPalette.surfaceGlass(context),
    };
    final fg = switch (status) {
      CreatorApplicationStatus.approved => CreatorCampaignsChrome.green,
      CreatorApplicationStatus.pending =>
          CreatorCampaignsChrome.amber(context),
      CreatorApplicationStatus.rejected => const Color(0xFFF87171),
      _ => CreatorCampaignsChrome.muted(context),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 92),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: status == CreatorApplicationStatus.pending
              ? Border.all(
                  color: CreatorCampaignsChrome.amber(context),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
    );
  }
}
