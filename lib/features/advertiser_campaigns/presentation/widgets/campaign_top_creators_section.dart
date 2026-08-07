import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/format/campaign_finance_display.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/presentation/theme/campaign_detail_premium_palette.dart';
import '../../domain/campaign_top_creator.dart';

/// Campaign leaderboard for the advertiser — ranked creators by validated views.
///
/// Data comes embedded in `GET /api/campaigns/:id` (`topCreators`, owner-only).
class CampaignTopCreatorsSection extends StatelessWidget {
  const CampaignTopCreatorsSection({
    super.key,
    required this.creators,
    required this.moneyLocale,
  });

  final List<CampaignTopCreator> creators;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final ranked = creators.where((c) => c.hasActivity).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (rect) => CampaignDetailPremiumPalette
                  .accentGradient
                  .createShader(rect),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.advertiser_campaigns.detail.top_creators_title,
                style: CampaignDetailPremiumPalette.sectionTitle(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          t.advertiser_campaigns.detail.top_creators_subtitle,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.35,
            color: CampaignDetailPremiumPalette.muted(context),
          ),
        ),
        const SizedBox(height: 14),
        if (ranked.isEmpty)
          _TopCreatorsEmpty(t: t)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: ranked.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final maxViews = ranked.first.validViews;
              return _TopCreatorTile(
                    rank: index + 1,
                    creator: ranked[index],
                    maxViews: maxViews,
                    moneyLocale: moneyLocale,
                  )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn(duration: 360.ms, curve: Curves.easeOutCubic)
                  .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
            },
          ),
      ],
    );
  }
}

class _TopCreatorTile extends StatelessWidget {
  const _TopCreatorTile({
    required this.rank,
    required this.creator,
    required this.maxViews,
    required this.moneyLocale,
  });

  final int rank;
  final CampaignTopCreator creator;
  final int maxViews;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFC53D),
      2 => const Color(0xFFB8C2CC),
      3 => const Color(0xFFCD7F32),
      _ => CampaignDetailPremiumPalette.muted(context),
    };
    final isPodium = rank <= 3;
    final viewsRatio = maxViews > 0
        ? (creator.validViews / maxViews).clamp(0.04, 1.0)
        : 0.0;
    final earnings = MoneyFormatter.format(
      creator.netEarningsCents / 100.0,
      currency: kWayoPublicCurrency,
      locale: moneyLocale,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CampaignDetailPremiumPalette.surface1(context),
        borderRadius: BorderRadius.circular(
          CampaignDetailPremiumPalette.kCardRadius,
        ),
        border: Border.all(
          color: isPodium
              ? rankColor.withValues(alpha: 0.45)
              : CampaignDetailPremiumPalette.divider(context),
        ),
        boxShadow: CampaignDetailPremiumPalette.cardShadow(context, 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RankBadge(rank: rank, color: rankColor, isPodium: isPodium),
              const SizedBox(width: 12),
              _CreatorAvatar(creator: creator),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.creatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CampaignDetailPremiumPalette.bodyValue(
                        context,
                      ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.advertiser_campaigns.detail.top_creators_views(
                        count: creator.validViews,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CampaignDetailPremiumPalette.bodyLabel(
                        context,
                      ).copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    earnings,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CampaignDetailPremiumPalette.positive,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.advertiser_campaigns.detail.top_creators_earned,
                    style: CampaignDetailPremiumPalette.bodyLabel(
                      context,
                    ).copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: viewsRatio,
              minHeight: 5,
              backgroundColor: CampaignDetailPremiumPalette.divider(
                context,
              ).withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(rankColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.color,
    required this.isPodium,
  });

  final int rank;
  final Color color;
  final bool isPodium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPodium
            ? color.withValues(alpha: 0.18)
            : CampaignDetailPremiumPalette.surfaceGlass(context),
        border: Border.all(
          color: isPodium
              ? color.withValues(alpha: 0.6)
              : CampaignDetailPremiumPalette.divider(context),
        ),
      ),
      child: isPodium
          ? Icon(Icons.emoji_events_rounded, size: 16, color: color)
          : Text(
              '$rank',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: CampaignDetailPremiumPalette.muted(context),
              ),
            ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.creator});

  final CampaignTopCreator creator;

  static const double _size = 42;

  @override
  Widget build(BuildContext context) {
    final url = creator.creatorImage;
    final letter = creator.creatorName.isNotEmpty
        ? creator.creatorName[0].toUpperCase()
        : '?';
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _AvatarPlaceholder(letter: letter),
        ),
      );
    }
    return _AvatarPlaceholder(letter: letter);
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _CreatorAvatar._size,
      height: _CreatorAvatar._size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: CampaignDetailPremiumPalette.accentGradient,
      ),
      child: Text(
        letter,
        style: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  final String letter;
}

class _TopCreatorsEmpty extends StatelessWidget {
  const _TopCreatorsEmpty({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: CampaignDetailPremiumPalette.surface1(context),
        border: Border.all(
          color: CampaignDetailPremiumPalette.divider(context),
        ),
        boxShadow: CampaignDetailPremiumPalette.cardShadow(context, 0.08),
      ),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 38,
            color: CampaignDetailPremiumPalette.amber.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 12),
          Text(
            t.advertiser_campaigns.detail.top_creators_empty_title,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CampaignDetailPremiumPalette.value(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.advertiser_campaigns.detail.top_creators_empty_subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.35,
              color: CampaignDetailPremiumPalette.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}
