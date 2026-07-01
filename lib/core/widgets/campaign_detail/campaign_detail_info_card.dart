import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/dashboard/presentation/theme/campaign_detail_premium_palette.dart';
import '../../../i18n/strings.g.dart';

/// Shared metadata rows: platform, niche, location, objective, campaign type.
class CampaignDetailInfoCard extends StatelessWidget {
  const CampaignDetailInfoCard({
    super.key,
    required this.platformLabel,
    required this.nicheLabel,
    required this.locationLabel,
    required this.objectiveLabel,
    required this.campaignTypeLabel,
  });

  final String platformLabel;
  final String nicheLabel;
  final String locationLabel;
  final String objectiveLabel;
  final String campaignTypeLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rows = [
      (Icons.public_outlined, t.advertiser_campaigns.detail.platform_label, platformLabel),
      (Icons.category_outlined, t.advertiser_campaigns.detail.niche_label, nicheLabel),
      (Icons.place_outlined, t.advertiser_campaigns.detail.location_label, locationLabel),
      (Icons.flag_outlined, t.advertiser_campaigns.detail.objective_label, objectiveLabel),
      (
        Icons.interests_outlined,
        t.advertiser_campaigns.detail.campaign_type_label,
        campaignTypeLabel,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CampaignDetailPremiumPalette.kCardPadding),
      decoration: BoxDecoration(
        color: CampaignDetailPremiumPalette.surface1(context),
        borderRadius:
            BorderRadius.circular(CampaignDetailPremiumPalette.kCardRadius),
        border: Border.all(
          color: CampaignDetailPremiumPalette.divider(context)
              .withValues(alpha: 0.9),
        ),
        boxShadow: CampaignDetailPremiumPalette.cardShadow(context, 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: CampaignDetailPremiumPalette.rowSeparator(context),
              ),
            Padding(
              padding: EdgeInsets.only(top: i > 0 ? 10 : 0, bottom: 10),
              child: _InfoRow(
                icon: rows[i].$1,
                label: rows[i].$2,
                value: rows[i].$3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: CampaignDetailPremiumPalette.label(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CampaignDetailPremiumPalette.value(context),
            ),
          ),
        ),
      ],
    );
  }
}
