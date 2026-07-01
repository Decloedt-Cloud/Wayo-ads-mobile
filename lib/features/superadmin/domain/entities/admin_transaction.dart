import 'package:flutter/foundation.dart';

@immutable
class AdminTransactionsPage {
  const AdminTransactionsPage({
    required this.transactions,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<AdminTransaction> transactions;
  final int page;
  final int totalPages;
  final int total;

  factory AdminTransactionsPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    final raw = json['transactions'];
    final list = <AdminTransaction>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(
            AdminTransaction.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return AdminTransactionsPage(
      transactions: list,
      page: _int(pagination['page'], fallback: 1),
      totalPages: _int(pagination['totalPages'], fallback: 1),
      total: _int(pagination['total']),
    );
  }

  static int _int(Object? v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }
}

@immutable
class AdminTransaction {
  const AdminTransaction({
    required this.id,
    required this.reason,
    required this.amountCents,
    required this.createdAt,
    this.campaignTitle,
    this.advertiserName,
    this.advertiserEmail,
    this.creatorName,
    this.creatorEmail,
  });

  final String id;
  final String reason;
  final int amountCents;
  final DateTime createdAt;
  final String? campaignTitle;
  final String? advertiserName;
  final String? advertiserEmail;
  final String? creatorName;
  final String? creatorEmail;

  double get amountUsd => amountCents / 100;

  factory AdminTransaction.fromJson(Map<String, dynamic> json) {
    final campaign = json['campaign'];
    String? campTitle;
    String? advName;
    String? advEmail;
    if (campaign is Map) {
      campTitle = campaign['title']?.toString();
      final adv = campaign['advertiser'];
      if (adv is Map) {
        advName = adv['name']?.toString();
        advEmail = adv['email']?.toString();
      }
    }
    final creator = json['creator'];
    String? crName;
    String? crEmail;
    if (creator is Map) {
      crName = creator['name']?.toString();
      crEmail = creator['email']?.toString();
    }
    return AdminTransaction(
      id: json['id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      amountCents: AdminTransactionsPage._int(json['amountCents']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      campaignTitle: campTitle,
      advertiserName: advName,
      advertiserEmail: advEmail,
      creatorName: crName,
      creatorEmail: crEmail,
    );
  }
}

@immutable
class TrafficQualitySummary {
  const TrafficQualitySummary({
    required this.flaggedCreators,
    required this.totalCreators,
    required this.creators,
  });

  final int flaggedCreators;
  final int totalCreators;
  final List<TrafficCreatorRisk> creators;

  factory TrafficQualitySummary.fromJson(Map<String, dynamic> json) {
    final raw = json['creators'];
    final list = <TrafficCreatorRisk>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(
            TrafficCreatorRisk.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return TrafficQualitySummary(
      flaggedCreators: AdminTransactionsPage._int(json['flaggedCreators']),
      totalCreators: AdminTransactionsPage._int(json['totalCreators']),
      creators: list,
    );
  }

  int get avgValidationRatePercent {
    if (creators.isEmpty) return 0;
    final sum = creators.fold<double>(
      0,
      (a, c) => a + (c.validationRate ?? 0),
    );
    return (sum / creators.length * 100).round();
  }

  int get maxAnomalyScore {
    if (creators.isEmpty) return 0;
    return creators
        .map((c) => c.anomalyScore ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
  }

  int get avgFraudScore {
    if (creators.isEmpty) return 0;
    final sum = creators.fold<double>(
      0,
      (a, c) => a + (c.avgFraudScore ?? 0),
    );
    return (sum / creators.length).round();
  }
}

@immutable
class TrafficCreatorRisk {
  const TrafficCreatorRisk({
    required this.creatorId,
    this.validationRate,
    this.anomalyScore,
    this.avgFraudScore,
    this.flagged = false,
  });

  final String creatorId;
  final double? validationRate;
  final int? anomalyScore;
  final double? avgFraudScore;
  final bool flagged;

  factory TrafficCreatorRisk.fromJson(Map<String, dynamic> json) {
    return TrafficCreatorRisk(
      creatorId: json['creatorId']?.toString() ?? '',
      validationRate: _dbl(json['validationRate']),
      anomalyScore: AdminTransactionsPage._int(json['anomalyScore']),
      avgFraudScore: _dbl(json['avgFraudScore']),
      flagged: json['flagged'] == true,
    );
  }

  static double? _dbl(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}
