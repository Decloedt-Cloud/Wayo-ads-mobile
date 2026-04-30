import 'package:flutter/foundation.dart';

/// Single entry in a picker (country or currency).
@immutable
final class StripeConnectOption {
  const StripeConnectOption({required this.code, required this.name});

  /// ISO 2-letter country code (e.g. `FR`) or ISO 4217 currency code (`EUR`).
  final String code;

  /// Human-friendly label.
  final String name;
}

/// Mirrors `src/lib/stripe-connect.ts` on Wayo-ads.
///
/// Using a static list keeps parity with the backend zod `refine()` check —
/// a country/currency absent from this list would be rejected server-side.
abstract final class StripeConnectCatalog {
  static const List<StripeConnectOption> countries = [
    StripeConnectOption(code: 'AU', name: 'Australia'),
    StripeConnectOption(code: 'AT', name: 'Austria'),
    StripeConnectOption(code: 'BE', name: 'Belgium'),
    StripeConnectOption(code: 'BR', name: 'Brazil'),
    StripeConnectOption(code: 'BG', name: 'Bulgaria'),
    StripeConnectOption(code: 'CA', name: 'Canada'),
    StripeConnectOption(code: 'HR', name: 'Croatia'),
    StripeConnectOption(code: 'CY', name: 'Cyprus'),
    StripeConnectOption(code: 'CZ', name: 'Czech Republic'),
    StripeConnectOption(code: 'DK', name: 'Denmark'),
    StripeConnectOption(code: 'EE', name: 'Estonia'),
    StripeConnectOption(code: 'FI', name: 'Finland'),
    StripeConnectOption(code: 'FR', name: 'France'),
    StripeConnectOption(code: 'DE', name: 'Germany'),
    StripeConnectOption(code: 'GR', name: 'Greece'),
    StripeConnectOption(code: 'HK', name: 'Hong Kong'),
    StripeConnectOption(code: 'HU', name: 'Hungary'),
    StripeConnectOption(code: 'IE', name: 'Ireland'),
    StripeConnectOption(code: 'IT', name: 'Italy'),
    StripeConnectOption(code: 'JP', name: 'Japan'),
    StripeConnectOption(code: 'LV', name: 'Latvia'),
    StripeConnectOption(code: 'LT', name: 'Lithuania'),
    StripeConnectOption(code: 'LU', name: 'Luxembourg'),
    StripeConnectOption(code: 'MT', name: 'Malta'),
    StripeConnectOption(code: 'MX', name: 'Mexico'),
    StripeConnectOption(code: 'NL', name: 'Netherlands'),
    StripeConnectOption(code: 'NZ', name: 'New Zealand'),
    StripeConnectOption(code: 'NO', name: 'Norway'),
    StripeConnectOption(code: 'PL', name: 'Poland'),
    StripeConnectOption(code: 'PT', name: 'Portugal'),
    StripeConnectOption(code: 'RO', name: 'Romania'),
    StripeConnectOption(code: 'SG', name: 'Singapore'),
    StripeConnectOption(code: 'SK', name: 'Slovakia'),
    StripeConnectOption(code: 'SI', name: 'Slovenia'),
    StripeConnectOption(code: 'ES', name: 'Spain'),
    StripeConnectOption(code: 'SE', name: 'Sweden'),
    StripeConnectOption(code: 'CH', name: 'Switzerland'),
    StripeConnectOption(code: 'TH', name: 'Thailand'),
    StripeConnectOption(code: 'GB', name: 'United Kingdom'),
    StripeConnectOption(code: 'US', name: 'United States'),
    StripeConnectOption(code: 'AE', name: 'United Arab Emirates'),
    StripeConnectOption(code: 'MY', name: 'Malaysia'),
    StripeConnectOption(code: 'LI', name: 'Liechtenstein'),
    StripeConnectOption(code: 'GI', name: 'Gibraltar'),
  ];

  static const List<StripeConnectOption> currencies = [
    StripeConnectOption(code: 'USD', name: 'US Dollar (USD)'),
    StripeConnectOption(code: 'EUR', name: 'Euro (EUR)'),
    StripeConnectOption(code: 'GBP', name: 'British Pound (GBP)'),
    StripeConnectOption(code: 'CHF', name: 'Swiss Franc (CHF)'),
    StripeConnectOption(code: 'AUD', name: 'Australian Dollar (AUD)'),
    StripeConnectOption(code: 'CAD', name: 'Canadian Dollar (CAD)'),
    StripeConnectOption(code: 'SGD', name: 'Singapore Dollar (SGD)'),
    StripeConnectOption(code: 'HKD', name: 'Hong Kong Dollar (HKD)'),
    StripeConnectOption(code: 'DKK', name: 'Danish Krone (DKK)'),
    StripeConnectOption(code: 'NOK', name: 'Norwegian Krone (NOK)'),
    StripeConnectOption(code: 'SEK', name: 'Swedish Krona (SEK)'),
    StripeConnectOption(code: 'PLN', name: 'Polish Złoty (PLN)'),
    StripeConnectOption(code: 'RON', name: 'Romanian Leu (RON)'),
    StripeConnectOption(code: 'CZK', name: 'Czech Koruna (CZK)'),
    StripeConnectOption(code: 'HUF', name: 'Hungarian Forint (HUF)'),
    StripeConnectOption(code: 'MXN', name: 'Mexican Peso (MXN)'),
    StripeConnectOption(code: 'BRL', name: 'Brazilian Real (BRL)'),
    StripeConnectOption(code: 'JPY', name: 'Japanese Yen (JPY)'),
    StripeConnectOption(code: 'THB', name: 'Thai Baht (THB)'),
    StripeConnectOption(code: 'AED', name: 'UAE Dirham (AED)'),
    StripeConnectOption(code: 'MYR', name: 'Malaysian Ringgit (MYR)'),
  ];

  static String? countryName(String? code) {
    if (code == null) return null;
    for (final c in countries) {
      if (c.code == code) return c.name;
    }
    return null;
  }
}
