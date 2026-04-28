import 'package:equatable/equatable.dart';

/// Summary KPI snapshot for the creator dashboard (`GET /api/creator/stats`).
final class CreatorStats extends Equatable {
  const CreatorStats({
    required this.totalEarningsCents,
    required this.pendingEarningsCents,
    required this.approvedApplications,
    required this.totalViews,
    required this.validatedViews,
    required this.currency,
  });

  /// Total paid + confirmed earnings, in cents.
  final int totalEarningsCents;

  /// Sum of [PayoutQueue] items with `status=PENDING`, in cents.
  final int pendingEarningsCents;

  /// Number of campaign applications with `status=APPROVED`.
  final int approvedApplications;

  /// Recorded views — all platforms, last 30 days.
  final int totalViews;

  /// Validated views — views that passed fraud filters, last 30 days.
  final int validatedViews;

  /// ISO 4217 currency code (e.g. `EUR`). Defaults to `EUR` when absent.
  final String currency;

  factory CreatorStats.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // Server shape (`GET /api/creator/stats`):
    //   totalViews            — validated views (aggregated over active posts)
    //   totalEarnings         — ledger credits (cents)
    //   activeCampaigns       — APPROVED applications count
    //   availableCents        — CreatorBalance.availableCents
    //   pendingCents          — CreatorBalance.pendingCents
    //   currency              — CreatorBalance.currency
    //
    // We also tolerate alternative key names for forward-compatibility.
    final validated = asInt(
      json['totalValidatedViews'] ??
          json['validatedViews'] ??
          json['totalViews'],
    );
    final total = asInt(
      json['totalRecordedViews'] ?? json['totalViews'] ?? validated,
    );
    return CreatorStats(
      totalEarningsCents: asInt(
        json['totalEarningsCents'] ?? json['totalEarnings'],
      ),
      pendingEarningsCents: asInt(
        json['pendingEarningsCents'] ??
            json['pendingCents'] ??
            json['pendingEarnings'],
      ),
      approvedApplications: asInt(
        json['approvedApplications'] ?? json['activeCampaigns'],
      ),
      totalViews: total,
      validatedViews: validated,
      currency: (json['currency'] as String?)?.trim().isNotEmpty == true
          ? (json['currency'] as String)
          : 'EUR',
    );
  }

  double get totalEarnings => totalEarningsCents / 100.0;
  double get pendingEarnings => pendingEarningsCents / 100.0;

  /// `0..1` ratio of validated over recorded views.
  double get validationRate {
    if (totalViews <= 0) return 0;
    return validatedViews / totalViews;
  }

  @override
  List<Object?> get props => [
    totalEarningsCents,
    pendingEarningsCents,
    approvedApplications,
    totalViews,
    validatedViews,
    currency,
  ];
}
