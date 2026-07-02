import 'stripe_connect_catalog.dart';

/// US states + DC and Canadian provinces — mirrors web business profile forms.
abstract final class BusinessSubdivisions {
  static const Set<String> countriesWithDropdown = {'US', 'CA'};

  static bool countryUsesDropdown(String? countryCode) {
    if (countryCode == null) return false;
    return countriesWithDropdown.contains(countryCode.toUpperCase());
  }

  static const Map<String, String> usStates = {
    'AL': 'Alabama',
    'AK': 'Alaska',
    'AZ': 'Arizona',
    'AR': 'Arkansas',
    'CA': 'California',
    'CO': 'Colorado',
    'CT': 'Connecticut',
    'DE': 'Delaware',
    'DC': 'District of Columbia',
    'FL': 'Florida',
    'GA': 'Georgia',
    'HI': 'Hawaii',
    'ID': 'Idaho',
    'IL': 'Illinois',
    'IN': 'Indiana',
    'IA': 'Iowa',
    'KS': 'Kansas',
    'KY': 'Kentucky',
    'LA': 'Louisiana',
    'ME': 'Maine',
    'MD': 'Maryland',
    'MA': 'Massachusetts',
    'MI': 'Michigan',
    'MN': 'Minnesota',
    'MS': 'Mississippi',
    'MO': 'Missouri',
    'MT': 'Montana',
    'NE': 'Nebraska',
    'NV': 'Nevada',
    'NH': 'New Hampshire',
    'NJ': 'New Jersey',
    'NM': 'New Mexico',
    'NY': 'New York',
    'NC': 'North Carolina',
    'ND': 'North Dakota',
    'OH': 'Ohio',
    'OK': 'Oklahoma',
    'OR': 'Oregon',
    'PA': 'Pennsylvania',
    'RI': 'Rhode Island',
    'SC': 'South Carolina',
    'SD': 'South Dakota',
    'TN': 'Tennessee',
    'TX': 'Texas',
    'UT': 'Utah',
    'VT': 'Vermont',
    'VA': 'Virginia',
    'WA': 'Washington',
    'WV': 'West Virginia',
    'WI': 'Wisconsin',
    'WY': 'Wyoming',
  };

  static const Map<String, String> caProvinces = {
    'AB': 'Alberta',
    'BC': 'British Columbia',
    'MB': 'Manitoba',
    'NB': 'New Brunswick',
    'NL': 'Newfoundland and Labrador',
    'NS': 'Nova Scotia',
    'NT': 'Northwest Territories',
    'NU': 'Nunavut',
    'ON': 'Ontario',
    'PE': 'Prince Edward Island',
    'QC': 'Quebec',
    'SK': 'Saskatchewan',
    'YT': 'Yukon',
  };

  static Map<String, String>? optionsForCountry(String? countryCode) {
    final code = countryCode?.trim().toUpperCase();
    return switch (code) {
      'US' => usStates,
      'CA' => caProvinces,
      _ => null,
    };
  }

  static List<StripeConnectOption> pickerOptions(String? countryCode) {
    final map = optionsForCountry(countryCode);
    if (map == null) return const [];
    final entries = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return [
      for (final e in entries) StripeConnectOption(code: e.key, name: e.value),
    ];
  }

  static bool isValidCode(String? countryCode, String? subdivisionCode) {
    final map = optionsForCountry(countryCode);
    if (map == null) return true;
    final code = subdivisionCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) return false;
    return map.containsKey(code);
  }

  static String? normalizeStored(String? countryCode, String? raw) {
    final map = optionsForCountry(countryCode);
    if (map == null) {
      final t = raw?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }
    final code = raw?.trim().toUpperCase();
    if (code == null || code.isEmpty) return null;
    if (map.containsKey(code)) return code;
    for (final entry in map.entries) {
      if (entry.value.toLowerCase() == raw!.trim().toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }
}
