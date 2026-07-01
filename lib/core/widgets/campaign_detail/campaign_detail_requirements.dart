import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/creator_campaigns/domain/creator_browse_campaign.dart';
import '../../../features/dashboard/presentation/theme/campaign_detail_premium_palette.dart';
import '../../../i18n/strings.g.dart';

/// Video / Shorts submission requirements — shared creator + advertiser detail.
class CampaignDetailRequirements extends StatelessWidget {
  const CampaignDetailRequirements({
    super.key,
    required this.type,
    this.requiredPlatform,
    this.videoMinDurationMinutes,
    this.shortsMaxDurationSeconds,
    this.shortsRequireVertical,
  });

  final CreatorCampaignType type;
  final String? requiredPlatform;
  final int? videoMinDurationMinutes;
  final int? shortsMaxDurationSeconds;
  final bool? shortsRequireVertical;

  @override
  Widget build(BuildContext context) {
    if (!type.requiresVideoSubmission) return const SizedBox.shrink();

    final t = context.t;
    final rows = <Widget>[];

    if (requiredPlatform != null && requiredPlatform!.trim().isNotEmpty) {
      rows.add(
        _Row(
          icon: Icons.videocam_outlined,
          label: t.creator.campaigns.requirement_platform(
            platform: requiredPlatform!,
          ),
        ),
      );
    }
    if (videoMinDurationMinutes != null && videoMinDurationMinutes! > 0) {
      rows.add(
        _Row(
          icon: Icons.timer_outlined,
          label: t.creator.campaigns.requirement_min_duration(
            minutes: videoMinDurationMinutes!,
          ),
        ),
      );
    }
    if (type == CreatorCampaignType.shorts &&
        shortsMaxDurationSeconds != null) {
      rows.add(
        _Row(
          icon: Icons.short_text_rounded,
          label: t.creator.campaigns.requirement_shorts_max(
            seconds: shortsMaxDurationSeconds!,
          ),
        ),
      );
    }
    if (type == CreatorCampaignType.shorts && shortsRequireVertical == true) {
      rows.add(
        _Row(
          icon: Icons.crop_portrait_rounded,
          label: t.creator.campaigns.requirement_vertical,
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(
        _Row(
          icon: Icons.check_circle_outline,
          label: t.creator.campaigns.requirement_none,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.creator.campaigns.requirements_title,
          style: CampaignDetailPremiumPalette.sectionTitle(context),
        ),
        const SizedBox(height: 10),
        for (final r in rows) ...[r, const SizedBox(height: 6)],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: CampaignDetailPremiumPalette.amber.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.35,
              color: CampaignDetailPremiumPalette.value(context)
                  .withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}
