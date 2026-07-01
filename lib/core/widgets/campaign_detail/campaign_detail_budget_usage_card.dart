import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../format/campaign_finance_display.dart';
import '../../format/money_formatter.dart';
import '../../../features/dashboard/presentation/theme/campaign_detail_premium_palette.dart';
import '../../../i18n/strings.g.dart';

/// Budget progress bar with spent / remaining — shared creator + advertiser detail.
class CampaignDetailBudgetUsageCard extends StatelessWidget {
  const CampaignDetailBudgetUsageCard({
    super.key,
    required this.totalCents,
    required this.spentCents,
    required this.remainingCents,
    required this.moneyLocale,
    this.approvedCreators,
  });

  final int totalCents;
  final int spentCents;
  final int remainingCents;
  final String moneyLocale;
  final int? approvedCreators;

  String _money(int cents) => MoneyFormatter.format(
        cents / 100.0,
        currency: kWayoPublicCurrency,
        locale: moneyLocale,
      );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final total = totalCents <= 0 ? 1 : totalCents;
    final fraction = (spentCents / total).clamp(0.0, 1.0);
    final pctLabel = '${(fraction * 100).round()}%';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.advertiser_campaigns.detail.budget_usage_title,
                  style: CampaignDetailPremiumPalette.sectionTitle(context)
                      .copyWith(fontSize: 16),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: CampaignDetailPremiumPalette.accentGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pctLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  color: CampaignDetailPremiumPalette.divider(context)
                      .withValues(alpha: 0.7),
                ),
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: fraction == 0 ? 0.02 : fraction,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: CampaignDetailPremiumPalette.accentGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Legend(
                  label: t.advertiser_campaigns.detail.budget_usage_spent,
                  value: _money(spentCents),
                  dotColor: CampaignDetailPremiumPalette.deepOrange,
                  alignEnd: false,
                ),
              ),
              Expanded(
                child: _Legend(
                  label: t.advertiser_campaigns.detail.budget_usage_remaining,
                  value: _money(remainingCents < 0 ? 0 : remainingCents),
                  dotColor: CampaignDetailPremiumPalette.positive,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (approvedCreators != null) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: CampaignDetailPremiumPalette.rowSeparator(context),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 18,
                  color: CampaignDetailPremiumPalette.amber.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.advertiser_campaigns.detail.approved_creators,
                    style: CampaignDetailPremiumPalette.bodyLabel(context),
                  ),
                ),
                Text(
                  '$approvedCreators',
                  style: CampaignDetailPremiumPalette.monoSmall(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.label,
    required this.value,
    required this.dotColor,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final Color dotColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
            const SizedBox(width: 6),
            Text(label, style: CampaignDetailPremiumPalette.bodyLabel(context)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CampaignDetailPremiumPalette.monoSmall(context),
        ),
      ],
    );
  }
}
