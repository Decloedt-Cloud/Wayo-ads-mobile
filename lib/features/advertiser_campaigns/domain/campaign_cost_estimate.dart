/// Display-only campaign cost estimate — mirrors web `useCampaignCostEstimate`.
///
/// Fee rate and tax cents come from backend APIs; this type only assembles the
/// breakdown for UI. Activation / lock remains server-authoritative.
library;

import 'package:flutter/foundation.dart';

@immutable
class CampaignCostEstimate {
  const CampaignCostEstimate({
    required this.budgetCents,
    required this.platformFeeCents,
    required this.platformFeeRate,
    required this.taxCents,
    required this.taxRate,
    required this.totalCents,
    this.taxLabel,
    this.countryCode,
  });

  final int budgetCents;
  final int platformFeeCents;

  /// Fraction e.g. `0.05` for 5%.
  final double platformFeeRate;
  final int taxCents;

  /// Percent e.g. `20` for 20% (API `effectiveRate`).
  final double taxRate;
  final int totalCents;
  final String? taxLabel;
  final String? countryCode;

  /// Assemble like web: fee = round(budget * rate), total = budget + fee + tax.
  factory CampaignCostEstimate.assemble({
    required int budgetCents,
    required double platformFeePercentage,
    required int taxCents,
    required double taxRate,
    String? taxLabel,
    String? countryCode,
  }) {
    final safeBudget = budgetCents.clamp(0, 100000000);
    final rate = (platformFeePercentage / 100).clamp(0.0, 1.0);
    final fee = (safeBudget * rate).round();
    final tax = taxCents < 0 ? 0 : taxCents;
    return CampaignCostEstimate(
      budgetCents: safeBudget,
      platformFeeCents: fee,
      platformFeeRate: rate,
      taxCents: tax,
      taxRate: taxRate,
      taxLabel: taxLabel,
      totalCents: safeBudget + fee + tax,
      countryCode: countryCode,
    );
  }
}

@immutable
class PlatformFeesSnapshot {
  const PlatformFeesSnapshot({
    required this.platformFeePercentage,
    this.platformFeeDescription,
  });

  /// e.g. `5` meaning 5%.
  final double platformFeePercentage;
  final String? platformFeeDescription;

  factory PlatformFeesSnapshot.fromJson(Map<String, dynamic> json) {
    final pct = json['platformFeePercentage'];
    double percentage;
    if (pct is num) {
      percentage = pct.toDouble();
    } else {
      final rate = json['platformFeeRate'];
      percentage = rate is num ? rate.toDouble() * 100 : 5;
    }
    return PlatformFeesSnapshot(
      platformFeePercentage: percentage,
      platformFeeDescription: json['platformFeeDescription']?.toString(),
    );
  }
}

@immutable
class TaxRateEstimate {
  const TaxRateEstimate({
    required this.taxCents,
    required this.effectiveRate,
    this.taxLabel,
    this.countryCode,
  });

  final int taxCents;
  final double effectiveRate;
  final String? taxLabel;
  final String? countryCode;

  factory TaxRateEstimate.fromJson(Map<String, dynamic> json) {
    return TaxRateEstimate(
      taxCents: _asInt(json['taxCents']),
      effectiveRate: _asDouble(json['effectiveRate']),
      taxLabel: json['taxLabel']?.toString(),
      countryCode: json['countryCode']?.toString(),
    );
  }
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _asDouble(Object? v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
