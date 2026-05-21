/// Hardcoded VAT/GST rates — mirrors `Wayo-ads/src/server/tokens/taxRates.ts` (display estimates).
const Map<String, double> kCreatorTaxRatesByCountry = {
  'AT': 20,
  'BE': 21,
  'BG': 20,
  'HR': 25,
  'CY': 19,
  'CZ': 21,
  'DK': 25,
  'EE': 22,
  'FI': 25.5,
  'FR': 20,
  'DE': 19,
  'GR': 24,
  'HU': 27,
  'IE': 23,
  'IT': 22,
  'LV': 21,
  'LT': 21,
  'LU': 17,
  'MT': 18,
  'NL': 21,
  'PL': 23,
  'PT': 23,
  'RO': 19,
  'SK': 23,
  'SI': 22,
  'ES': 21,
  'SE': 25,
  'GB': 20,
  'CH': 8.1,
  'NO': 25,
  'IS': 24,
  'LI': 8.1,
  'TR': 20,
  'RU': 20,
  'UA': 20,
  'CA': 5,
  'US': 0,
  'MX': 16,
  'BR': 20,
  'AR': 21,
  'CL': 19,
  'CO': 19,
  'AU': 10,
  'NZ': 15,
  'JP': 10,
  'KR': 10,
  'SG': 9,
  'MY': 8,
  'TH': 7,
  'ID': 11,
  'TW': 5,
  'HK': 0,
  'AE': 5,
  'SA': 15,
  'QA': 10,
  'KW': 0,
  'OM': 5,
  'BH': 10,
  'IL': 17,
  'ZA': 15,
  'KE': 16,
  'EG': 14,
  'MA': 20,
  'TN': 19,
};

const Map<String, double> kUsStateTaxRates = {
  'AL': 9.25,
  'AK': 1.76,
  'AZ': 8.40,
  'AR': 9.50,
  'CA': 8.85,
  'CO': 8.31,
  'CT': 6.35,
  'DE': 0,
  'FL': 7.00,
  'GA': 8.00,
  'HI': 4.44,
  'ID': 6.00,
  'IL': 8.82,
  'IN': 7.00,
  'IA': 6.94,
  'KS': 8.70,
  'KY': 6.00,
  'LA': 9.55,
  'ME': 5.50,
  'MD': 6.00,
  'MA': 6.25,
  'MI': 6.00,
  'MN': 7.50,
  'MS': 7.00,
  'MO': 8.38,
  'MT': 0,
  'NE': 7.00,
  'NV': 8.25,
  'NH': 0,
  'NJ': 6.63,
  'NM': 7.50,
  'NY': 8.52,
  'NC': 6.98,
  'ND': 6.50,
  'OH': 7.25,
  'OK': 8.95,
  'OR': 0,
  'PA': 6.00,
  'RI': 7.00,
  'SC': 7.46,
  'SD': 6.00,
  'TN': 9.55,
  'TX': 8.25,
  'UT': 7.19,
  'VT': 6.00,
  'VA': 5.75,
  'WA': 9.30,
  'WV': 6.50,
  'WI': 5.50,
  'WY': 5.50,
  'DC': 6.00,
};

const Set<String> kB2bTaxCountries = {'GB'};

double creatorTaxRateForCountry(String countryCode) {
  return kCreatorTaxRatesByCountry[countryCode.toUpperCase()] ?? 0;
}

double? creatorSubdivisionTaxRate(String countryCode, String subdivision) {
  final code = countryCode.toUpperCase();
  if (code == 'US') {
    return kUsStateTaxRates[subdivision.toUpperCase()];
  }
  return null;
}

/// Mirrors `calculateTaxCents` in Wayo-ads `taxRates.ts` (client estimate).
int estimateCreatorWithdrawalTaxCents({
  required int grossCents,
  required String? countryCode,
  required bool isIndividual,
  String? stateOrSubdivision,
}) {
  if (countryCode == null || countryCode.trim().isEmpty) return 0;
  final code = countryCode.toUpperCase();
  if (!isIndividual && !kB2bTaxCountries.contains(code)) return 0;

  final sub = stateOrSubdivision?.trim();
  if (sub != null && sub.isNotEmpty) {
    final subRate = creatorSubdivisionTaxRate(code, sub);
    if (subRate != null && subRate > 0) {
      return (grossCents * subRate / 100).round();
    }
  }

  final rate = creatorTaxRateForCountry(code);
  if (rate <= 0) return 0;
  return (grossCents * rate / 100).round();
}
