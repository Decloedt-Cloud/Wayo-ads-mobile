/// Country-level tax rate (merged hardcoded + DB override) from GET /api/admin/tax-rates.
class CountryTaxRate {
  const CountryTaxRate({
    required this.code,
    required this.name,
    required this.rate,
    required this.defaultRate,
    required this.overridden,
    this.overrideId,
    this.hasSubdivisions = false,
  });

  final String code;
  final String name;
  final double rate;
  final double defaultRate;
  final bool overridden;
  final String? overrideId;
  final bool hasSubdivisions;

  factory CountryTaxRate.fromJson(Map<String, dynamic> json) {
    return CountryTaxRate(
      code: (json['code'] as String? ?? '').toUpperCase(),
      name: json['name'] as String? ?? json['code'] as String? ?? '',
      rate: _parseRate(json['rate']),
      defaultRate: _parseRate(json['defaultRate'] ?? json['rate']),
      overridden: json['overridden'] as bool? ?? false,
      overrideId: json['overrideId'] as String?,
      hasSubdivisions: json['hasSubdivisions'] as bool? ?? false,
    );
  }
}

/// US state / CA province rate from GET /api/admin/tax-rates `subdivisions`.
class TaxSubdivisionRate {
  const TaxSubdivisionRate({
    required this.code,
    required this.subdivision,
    required this.name,
    required this.rate,
    required this.defaultRate,
    required this.overridden,
    this.overrideId,
    this.label,
  });

  final String code;
  final String subdivision;
  final String name;
  final double rate;
  final double defaultRate;
  final bool overridden;
  final String? overrideId;
  final String? label;

  String get countryCode {
    final i = code.indexOf('-');
    if (i <= 0) return code;
    return code.substring(0, i);
  }

  factory TaxSubdivisionRate.fromJson(Map<String, dynamic> json) {
    return TaxSubdivisionRate(
      code: json['code'] as String? ?? '',
      subdivision: json['subdivision'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rate: _parseRate(json['rate']),
      defaultRate: _parseRate(json['defaultRate'] ?? json['rate']),
      overridden: json['overridden'] as bool? ?? false,
      overrideId: json['overrideId'] as String?,
      label: json['label'] as String?,
    );
  }
}

class TaxRatesPage {
  const TaxRatesPage({
    required this.rates,
    required this.subdivisions,
  });

  final List<CountryTaxRate> rates;
  final List<TaxSubdivisionRate> subdivisions;

  factory TaxRatesPage.fromJson(Map<String, dynamic> json) {
    final ratesRaw = json['rates'];
    final subRaw = json['subdivisions'];
    return TaxRatesPage(
      rates: ratesRaw is List
          ? ratesRaw
              .whereType<Map>()
              .map((e) => CountryTaxRate.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      subdivisions: subRaw is List
          ? subRaw
              .whereType<Map>()
              .map((e) => TaxSubdivisionRate.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }

  List<TaxSubdivisionRate> subdivisionsForCountry(String countryCode) {
    final cc = countryCode.toUpperCase();
    return subdivisions
        .where((s) => s.countryCode.toUpperCase() == cc)
        .toList();
  }
}

double _parseRate(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String formatTaxRatePercent(double rate) {
  if (rate == rate.roundToDouble()) {
    return '${rate.toInt()}%';
  }
  return '${rate.toStringAsFixed(1)}%';
}
