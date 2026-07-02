import 'stripe_connect_catalog.dart';

/// Mirrors `Wayo-ads/src/lib/data/major-billing-markets.ts`.
///
/// Used for advertiser global billing (invoices / wallet top-ups) — broader
/// country & currency lists than Stripe Connect payouts.
abstract final class MajorBillingCatalog {
  static const List<StripeConnectOption> _unsortedCountries = [
    StripeConnectOption(code: 'AE', name: 'United Arab Emirates'),
    StripeConnectOption(code: 'AR', name: 'Argentina'),
    StripeConnectOption(code: 'AT', name: 'Austria'),
    StripeConnectOption(code: 'AU', name: 'Australia'),
    StripeConnectOption(code: 'BE', name: 'Belgium'),
    StripeConnectOption(code: 'BH', name: 'Bahrain'),
    StripeConnectOption(code: 'BG', name: 'Bulgaria'),
    StripeConnectOption(code: 'BR', name: 'Brazil'),
    StripeConnectOption(code: 'CA', name: 'Canada'),
    StripeConnectOption(code: 'CH', name: 'Switzerland'),
    StripeConnectOption(code: 'CL', name: 'Chile'),
    StripeConnectOption(code: 'CO', name: 'Colombia'),
    StripeConnectOption(code: 'CY', name: 'Cyprus'),
    StripeConnectOption(code: 'CZ', name: 'Czech Republic'),
    StripeConnectOption(code: 'DE', name: 'Germany'),
    StripeConnectOption(code: 'DK', name: 'Denmark'),
    StripeConnectOption(code: 'EE', name: 'Estonia'),
    StripeConnectOption(code: 'EG', name: 'Egypt'),
    StripeConnectOption(code: 'ES', name: 'Spain'),
    StripeConnectOption(code: 'FI', name: 'Finland'),
    StripeConnectOption(code: 'FR', name: 'France'),
    StripeConnectOption(code: 'GB', name: 'United Kingdom'),
    StripeConnectOption(code: 'GR', name: 'Greece'),
    StripeConnectOption(code: 'HK', name: 'Hong Kong SAR'),
    StripeConnectOption(code: 'HR', name: 'Croatia'),
    StripeConnectOption(code: 'HU', name: 'Hungary'),
    StripeConnectOption(code: 'ID', name: 'Indonesia'),
    StripeConnectOption(code: 'IE', name: 'Ireland'),
    StripeConnectOption(code: 'IL', name: 'Israel'),
    StripeConnectOption(code: 'IS', name: 'Iceland'),
    StripeConnectOption(code: 'IT', name: 'Italy'),
    StripeConnectOption(code: 'JP', name: 'Japan'),
    StripeConnectOption(code: 'KE', name: 'Kenya'),
    StripeConnectOption(code: 'KR', name: 'South Korea'),
    StripeConnectOption(code: 'KW', name: 'Kuwait'),
    StripeConnectOption(code: 'LT', name: 'Lithuania'),
    StripeConnectOption(code: 'LU', name: 'Luxembourg'),
    StripeConnectOption(code: 'LV', name: 'Latvia'),
    StripeConnectOption(code: 'MA', name: 'Morocco'),
    StripeConnectOption(code: 'MC', name: 'Monaco'),
    StripeConnectOption(code: 'MX', name: 'Mexico'),
    StripeConnectOption(code: 'MY', name: 'Malaysia'),
    StripeConnectOption(code: 'MT', name: 'Malta'),
    StripeConnectOption(code: 'NL', name: 'Netherlands'),
    StripeConnectOption(code: 'NO', name: 'Norway'),
    StripeConnectOption(code: 'NZ', name: 'New Zealand'),
    StripeConnectOption(code: 'OM', name: 'Oman'),
    StripeConnectOption(code: 'PE', name: 'Peru'),
    StripeConnectOption(code: 'PL', name: 'Poland'),
    StripeConnectOption(code: 'PT', name: 'Portugal'),
    StripeConnectOption(code: 'QA', name: 'Qatar'),
    StripeConnectOption(code: 'RO', name: 'Romania'),
    StripeConnectOption(code: 'RU', name: 'Russia'),
    StripeConnectOption(code: 'SA', name: 'Saudi Arabia'),
    StripeConnectOption(code: 'SE', name: 'Sweden'),
    StripeConnectOption(code: 'SG', name: 'Singapore'),
    StripeConnectOption(code: 'SI', name: 'Slovenia'),
    StripeConnectOption(code: 'SK', name: 'Slovakia'),
    StripeConnectOption(code: 'TH', name: 'Thailand'),
    StripeConnectOption(code: 'TW', name: 'Taiwan'),
    StripeConnectOption(code: 'TR', name: 'Türkiye'),
    StripeConnectOption(code: 'US', name: 'United States'),
    StripeConnectOption(code: 'UA', name: 'Ukraine'),
    StripeConnectOption(code: 'UY', name: 'Uruguay'),
    StripeConnectOption(code: 'ZA', name: 'South Africa'),
  ];

  static final List<StripeConnectOption> countries = List.unmodifiable(
    [..._unsortedCountries]..sort((a, b) => a.name.compareTo(b.name)),
  );

  static final Set<String> countryCodes = {
    for (final c in countries) c.code,
  };

  static const List<StripeConnectOption> _unsortedCurrencies = [
    StripeConnectOption(code: 'AED', name: 'UAE Dirham (AED)'),
    StripeConnectOption(code: 'ARS', name: 'Argentine Peso (ARS)'),
    StripeConnectOption(code: 'AUD', name: 'Australian Dollar (AUD)'),
    StripeConnectOption(code: 'BHD', name: 'Bahraini Dinar (BHD)'),
    StripeConnectOption(code: 'BRL', name: 'Brazilian Real (BRL)'),
    StripeConnectOption(code: 'CAD', name: 'Canadian Dollar (CAD)'),
    StripeConnectOption(code: 'CHF', name: 'Swiss Franc (CHF)'),
    StripeConnectOption(code: 'CLP', name: 'Chilean Peso (CLP)'),
    StripeConnectOption(code: 'COP', name: 'Colombian Peso (COP)'),
    StripeConnectOption(code: 'CZK', name: 'Czech Koruna (CZK)'),
    StripeConnectOption(code: 'DKK', name: 'Danish Krone (DKK)'),
    StripeConnectOption(code: 'EGP', name: 'Egyptian Pound (EGP)'),
    StripeConnectOption(code: 'EUR', name: 'Euro (EUR)'),
    StripeConnectOption(code: 'GBP', name: 'British Pound (GBP)'),
    StripeConnectOption(code: 'HKD', name: 'Hong Kong Dollar (HKD)'),
    StripeConnectOption(code: 'HUF', name: 'Hungarian Forint (HUF)'),
    StripeConnectOption(code: 'IDR', name: 'Indonesian Rupiah (IDR)'),
    StripeConnectOption(code: 'ILS', name: 'Israeli New Shekel (ILS)'),
    StripeConnectOption(code: 'JPY', name: 'Japanese Yen (JPY)'),
    StripeConnectOption(code: 'KES', name: 'Kenyan Shilling (KES)'),
    StripeConnectOption(code: 'KRW', name: 'South Korean Won (KRW)'),
    StripeConnectOption(code: 'KWD', name: 'Kuwaiti Dinar (KWD)'),
    StripeConnectOption(code: 'MXN', name: 'Mexican Peso (MXN)'),
    StripeConnectOption(code: 'MAD', name: 'Moroccan Dirham (MAD)'),
    StripeConnectOption(code: 'MYR', name: 'Malaysian Ringgit (MYR)'),
    StripeConnectOption(code: 'NOK', name: 'Norwegian Krone (NOK)'),
    StripeConnectOption(code: 'NZD', name: 'New Zealand Dollar (NZD)'),
    StripeConnectOption(code: 'OMR', name: 'Omani Rial (OMR)'),
    StripeConnectOption(code: 'PEN', name: 'Peruvian Sol (PEN)'),
    StripeConnectOption(code: 'PLN', name: 'Polish Zloty (PLN)'),
    StripeConnectOption(code: 'QAR', name: 'Qatari Riyal (QAR)'),
    StripeConnectOption(code: 'RON', name: 'Romanian Leu (RON)'),
    StripeConnectOption(code: 'RUB', name: 'Russian Ruble (RUB)'),
    StripeConnectOption(code: 'SAR', name: 'Saudi Riyal (SAR)'),
    StripeConnectOption(code: 'SEK', name: 'Swedish Krona (SEK)'),
    StripeConnectOption(code: 'SGD', name: 'Singapore Dollar (SGD)'),
    StripeConnectOption(code: 'THB', name: 'Thai Baht (THB)'),
    StripeConnectOption(code: 'TRY', name: 'Turkish Lira (TRY)'),
    StripeConnectOption(code: 'TWD', name: 'New Taiwan Dollar (TWD)'),
    StripeConnectOption(code: 'USD', name: 'US Dollar (USD)'),
    StripeConnectOption(code: 'UYU', name: 'Uruguayan Peso (UYU)'),
    StripeConnectOption(code: 'ZAR', name: 'South African Rand (ZAR)'),
  ];

  static final List<StripeConnectOption> currencies = List.unmodifiable(
    [..._unsortedCurrencies]..sort((a, b) => a.code.compareTo(b.code)),
  );

  static final Set<String> currencyCodes = {
    for (final c in currencies) c.code,
  };

  static bool isCountryCode(String code) =>
      countryCodes.contains(code.trim().toUpperCase());

  static bool isCurrencyCode(String code) =>
      currencyCodes.contains(code.trim().toUpperCase());
}
