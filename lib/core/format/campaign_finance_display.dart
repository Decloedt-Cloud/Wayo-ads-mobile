import '../../features/creator_campaigns/domain/creator_browse_campaign.dart';
import '../../i18n/strings.g.dart';

/// Platform display currency for public campaign amounts (matches Wayo-ads default).
const String kWayoPublicCurrency = 'USD';

/// Locale used when formatting [kWayoPublicCurrency] (USD always uses en-US, like web).
String wayoPublicMoneyLocale(AppLocale appLocale) {
  return 'en_US';
}

/// Effective / consumed CPM in minor units: `(spent / views) * 1000`.
int computeConsumedCpmCents({
  required int spentBudgetCents,
  required int validViews,
}) {
  if (validViews <= 0 || spentBudgetCents <= 0) return 0;
  return ((spentBudgetCents * 1000) / validViews).round();
}

enum CampaignPayoutMetricKind { cpc, cpm, consumedCpm }

final class CampaignPayoutMetric {
  const CampaignPayoutMetric(this.kind, this.cents);

  final CampaignPayoutMetricKind kind;
  final int cents;

  bool get hasValue => cents > 0;
}

/// Resolves the primary payout rate shown on cards and detail headers.
///
/// Mirrors Wayo-ads list behaviour (CPC for LINK, CPM for VIDEO/SHORTS) with a
/// fallback to consumed CPM when the configured rate is missing.
CampaignPayoutMetric resolveCampaignPayoutMetric({
  required CreatorCampaignType type,
  required int cpcCents,
  required int cpmCents,
  required int spentBudgetCents,
  required int validViews,
}) {
  final consumed = computeConsumedCpmCents(
    spentBudgetCents: spentBudgetCents,
    validViews: validViews,
  );

  final isVideo =
      type == CreatorCampaignType.video || type == CreatorCampaignType.shorts;

  if (isVideo) {
    if (cpmCents > 0) {
      return CampaignPayoutMetric(CampaignPayoutMetricKind.cpm, cpmCents);
    }
    if (consumed > 0) {
      return CampaignPayoutMetric(
        CampaignPayoutMetricKind.consumedCpm,
        consumed,
      );
    }
    return const CampaignPayoutMetric(CampaignPayoutMetricKind.cpm, 0);
  }

  if (cpcCents > 0) {
    return CampaignPayoutMetric(CampaignPayoutMetricKind.cpc, cpcCents);
  }
  if (consumed > 0) {
    return CampaignPayoutMetric(
      CampaignPayoutMetricKind.consumedCpm,
      consumed,
    );
  }
  return const CampaignPayoutMetric(CampaignPayoutMetricKind.cpc, 0);
}

String campaignPayoutMetricLabel(Translations t, CampaignPayoutMetricKind kind) {
  return switch (kind) {
    CampaignPayoutMetricKind.cpc => t.advertiser_campaigns.card.cpc,
    CampaignPayoutMetricKind.cpm => t.advertiser_campaigns.card.cpm,
    CampaignPayoutMetricKind.consumedCpm =>
      t.advertiser_campaigns.detail.cpm_consumed,
  };
}
