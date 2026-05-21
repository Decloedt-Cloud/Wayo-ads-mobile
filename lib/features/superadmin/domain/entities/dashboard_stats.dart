import 'package:flutter/foundation.dart';

@immutable
class DashboardStats {
  const DashboardStats({
    required this.totalAmountCents,
    required this.totalTransactions,
    required this.byReason,
    required this.topCampaigns,
  });

  final int totalAmountCents;
  final int totalTransactions;
  final Map<String, ReasonSummary> byReason;
  final List<TopCampaign> topCampaigns;

  double get totalAmountUsd => totalAmountCents / 100;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final byReason = <String, ReasonSummary>{};
    final byReasonRaw = json['byReason'];
    if (byReasonRaw is List) {
      for (final item in byReasonRaw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final reason = m['reason']?.toString() ?? '';
        if (reason.isEmpty) continue;
        final sum = m['_sum'];
        final count = m['_count'];
        var totalCents = 0;
        var cnt = 0;
        if (sum is Map) {
          totalCents = _parseInt(sum['amountCents']);
        }
        if (count is Map) {
          cnt = _parseInt(count['id']);
        }
        byReason[reason] = ReasonSummary(count: cnt, totalCents: totalCents);
      }
    } else if (byReasonRaw is Map) {
      for (final entry in byReasonRaw.entries) {
        if (entry.value is Map) {
          byReason[entry.key.toString()] = ReasonSummary.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    final topCampaigns = <TopCampaign>[];
    final topCampaignsRaw = json['topCampaigns'];
    if (topCampaignsRaw is List) {
      for (final item in topCampaignsRaw) {
        if (item is Map) {
          topCampaigns.add(
            TopCampaign.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return DashboardStats(
      totalAmountCents: _parseInt(json['totalAmountCents']),
      totalTransactions: _parseInt(json['totalTransactions']),
      byReason: byReason,
      topCampaigns: topCampaigns,
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

@immutable
class ReasonSummary {
  const ReasonSummary({
    required this.count,
    required this.totalCents,
  });

  final int count;
  final int totalCents;

  double get totalUsd => totalCents / 100;

  factory ReasonSummary.fromJson(Map<String, dynamic> json) {
    return ReasonSummary(
      count: _parseInt(json['count']),
      totalCents: _parseInt(json['totalCents'] ?? json['total']),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

@immutable
class TopCampaign {
  const TopCampaign({
    required this.campaignId,
    required this.title,
    required this.totalCents,
    required this.count,
  });

  final String campaignId;
  final String title;
  final int totalCents;
  final int count;

  double get totalUsd => totalCents / 100;

  factory TopCampaign.fromJson(Map<String, dynamic> json) {
    final campaign = json['campaign'];
    final titleFromCampaign =
        campaign is Map ? (campaign['title'] ?? '').toString() : '';
    final sum = json['_sum'];
    final countObj = json['_count'];
    var totalCents = _parseInt(json['totalCents'] ?? json['total']);
    var count = _parseInt(json['count']);
    if (sum is Map) {
      totalCents = _parseInt(sum['amountCents']);
    }
    if (countObj is Map) {
      count = _parseInt(countObj['id']);
    }
    final title = titleFromCampaign.isNotEmpty
        ? titleFromCampaign
        : (json['title']?.toString() ?? json['name']?.toString() ?? '');
    return TopCampaign(
      campaignId: json['campaignId']?.toString() ?? json['id']?.toString() ?? '',
      title: title,
      totalCents: totalCents,
      count: count,
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

@immutable
class PayoutStats {
  const PayoutStats({
    required this.totalPending,
    required this.totalFrozen,
    required this.totalReleased,
    required this.totalCancelled,
    required this.eligibleNow,
  });

  final int totalPending;
  final int totalFrozen;
  final int totalReleased;
  final int totalCancelled;
  final int eligibleNow;

  factory PayoutStats.fromJson(Map<String, dynamic> json) {
    return PayoutStats(
      totalPending: _parseInt(json['totalPending']),
      totalFrozen: _parseInt(json['totalFrozen']),
      totalReleased: _parseInt(json['totalReleased']),
      totalCancelled: _parseInt(json['totalCancelled']),
      eligibleNow: _parseInt(json['eligibleNow']),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
