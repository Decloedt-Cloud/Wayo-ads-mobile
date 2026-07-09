import 'package:equatable/equatable.dart';

/// Summary KPI snapshot for the creator dashboard (`GET /api/creator/stats`).
final class CreatorStats extends Equatable {
  const CreatorStats({
    required this.totalEarningsCents,
    required this.pendingEarningsCents,
    required this.approvedApplications,
    required this.validatedViews,
    required this.pendingViews,
    required this.estimatedViews,
    required this.totalValidClicks,
    required this.currency,
  });

  /// Total paid + confirmed earnings, in cents.
  final int totalEarningsCents;

  /// Sum of [PayoutQueue] items with `status=PENDING`, in cents.
  final int pendingEarningsCents;

  /// Number of campaign applications with `status=APPROVED`.
  final int approvedApplications;

  /// Settled / validated views (`totalViews` on Wayo-ads API).
  final int validatedViews;

  /// Views awaiting 48h YouTube settlement (`pendingViews` on API).
  final int pendingViews;

  /// Settled + pending (`estimatedViews` on API, or validated + pending).
  final int estimatedViews;

  /// Validated link clicks across campaigns (`totalValidClicks` on API).
  final int totalValidClicks;

  /// ISO 4217 currency code (e.g. `EUR`). Defaults to `EUR` when absent.
  final String currency;

  factory CreatorStats.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // Wayo-ads `GET /api/creator/stats` (Jul 2026 settlement):
    //   totalViews      — settled validated views
    //   pendingViews    — pendingValidatedViews sum (48h hold)
    //   estimatedViews  — totalViews + pendingViews
    //   totalValidClicks — validated VisitEvent count
    final validated = asInt(
      json['totalViews'] ??
          json['totalValidatedViews'] ??
          json['validatedViews'],
    );
    final pending = asInt(json['pendingViews']);
    var estimated = asInt(json['estimatedViews']);
    if (estimated <= 0 && (validated > 0 || pending > 0)) {
      estimated = validated + pending;
    }

    return CreatorStats(
      totalEarningsCents: asInt(
        json['totalEarningsCents'] ?? json['totalEarnings'],
      ),
      pendingEarningsCents: asInt(
        json['pendingEarningsCents'] ??
            json['pendingCents'] ??
            json['pendingBalance'] ??
            json['pendingEarnings'],
      ),
      approvedApplications: asInt(
        json['approvedApplications'] ?? json['activeCampaigns'],
      ),
      validatedViews: validated,
      pendingViews: pending,
      estimatedViews: estimated,
      totalValidClicks: asInt(json['totalValidClicks']),
      currency: (json['currency'] as String?)?.trim().isNotEmpty == true
          ? (json['currency'] as String)
          : 'EUR',
    );
  }

  double get totalEarnings => totalEarningsCents / 100.0;
  double get pendingEarnings => pendingEarningsCents / 100.0;

  /// Share of estimated views that are still in the 48h settlement hold.
  double get pendingViewsRatio {
    if (estimatedViews <= 0) return 0;
    return pendingViews / estimatedViews;
  }

  @override
  List<Object?> get props => [
    totalEarningsCents,
    pendingEarningsCents,
    approvedApplications,
    validatedViews,
    pendingViews,
    estimatedViews,
    totalValidClicks,
    currency,
  ];
}
