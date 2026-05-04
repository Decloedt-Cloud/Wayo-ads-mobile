/// Same values as Wayo-ads `src/lib/campaign-niches.ts` / Prisma `CampaignNiche`.
///
/// Keep synced when the web catalog changes.
const List<String> kCampaignNicheApiValues = [
  'FASHION_APPAREL',
  'BEAUTY_PERSONAL_CARE',
  'TECH_SOFTWARE_ELECTRONICS',
  'FOOD_BEVERAGE',
  'HEALTH_WELLNESS',
  'FITNESS_SPORTS',
  'HOME_LIVING',
  'TRAVEL_HOSPITALITY',
  'FINANCE_INSURANCE',
  'EDUCATION_LEARNING',
  'ENTERTAINMENT_MEDIA',
  'GAMING_ESPORTS',
  'AUTOMOTIVE',
  'PETS_ANIMALS',
  'BABY_FAMILY',
  'B2B_PROFESSIONAL',
  'ECOMMERCE_RETAIL',
  'NONPROFIT_CAUSE',
  'REAL_ESTATE',
  'CRYPTO_WEB3',
  'ART_DESIGN_PHOTOGRAPHY',
  'MUSIC_AUDIO',
  'LIFESTYLE_VLOGS',
  'DIY_CRAFTS',
  'ENVIRONMENT_SUSTAINABILITY',
  'OTHER',
];

/// Fallback label when no dedicated i18n exists (readable English-style title).
String campaignNicheFallbackLabel(String apiValue) {
  final t = apiValue.trim();
  if (t.isEmpty) return '—';
  return t
      .split('_')
      .where((s) => s.isNotEmpty)
      .map(
        (w) =>
            w.length == 1 ? w.toUpperCase() : '${w[0]}${w.substring(1).toLowerCase()}',
      )
      .join(' ');
}
