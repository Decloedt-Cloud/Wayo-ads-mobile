import 'package:flutter/foundation.dart';

@immutable
class AiUsageStats {
  const AiUsageStats({
    required this.period,
    required this.summary,
    required this.byFeature,
    required this.byProvider,
    required this.byModel,
    required this.topCreators,
    required this.dailyCosts,
  });

  final String period;
  final AiUsageSummary summary;
  final List<AiUsageByCategory> byFeature;
  final List<AiUsageByCategory> byProvider;
  final List<AiUsageByCategory> byModel;
  final List<AiTopCreator> topCreators;
  final List<AiDailyCost> dailyCosts;

  factory AiUsageStats.fromJson(Map<String, dynamic> json) {
    return AiUsageStats(
      period: (json['period'] ?? '30d').toString(),
      summary: AiUsageSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      byFeature: _parseCategories(json['byFeature']),
      byProvider: _parseCategories(json['byProvider']),
      byModel: _parseCategories(json['byModel']),
      topCreators: _parseTopCreators(json['topCreators']),
      dailyCosts: _parseDailyCosts(json['dailyCosts']),
    );
  }

  static List<AiUsageByCategory> _parseCategories(Object? data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => AiUsageByCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<AiTopCreator> _parseTopCreators(Object? data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => AiTopCreator.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<AiDailyCost> _parseDailyCosts(Object? data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => AiDailyCost.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

@immutable
class AiUsageSummary {
  const AiUsageSummary({
    required this.totalRequests,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCostUsd,
    required this.avgCostPerRequest,
    this.activeCreators = 0,
    this.tokensCharged = 0,
  });

  final int totalRequests;
  final int totalInputTokens;
  final int totalOutputTokens;
  final double totalCostUsd;
  final double avgCostPerRequest;
  /// Distinct creators with LLM usage in the period (when API provides it).
  final int activeCreators;
  /// Platform token charges / billing events (when API provides it).
  final int tokensCharged;

  int get totalTokens => totalInputTokens + totalOutputTokens;

  factory AiUsageSummary.fromJson(Map<String, dynamic> json) {
    return AiUsageSummary(
      totalRequests: _parseInt(json['totalRequests']),
      totalInputTokens: _parseInt(json['totalInputTokens']),
      totalOutputTokens: _parseInt(json['totalOutputTokens']),
      totalCostUsd: _parseDouble(json['totalCostUsd'] ?? json['totalCost']),
      avgCostPerRequest: _parseDouble(json['avgCostPerRequest']),
      activeCreators: _parseInt(json['activeCreators']),
      tokensCharged: _parseInt(
        json['tokensCharged'] ?? json['totalTokensCharged'],
      ),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static double _parseDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}

@immutable
class AiUsageByCategory {
  const AiUsageByCategory({
    required this.name,
    required this.requests,
    required this.tokens,
    required this.costUsd,
  });

  final String name;
  final int requests;
  final int tokens;
  final double costUsd;

  factory AiUsageByCategory.fromJson(Map<String, dynamic> json) {
    return AiUsageByCategory(
      name: (json['name'] ?? json['feature'] ?? json['provider'] ?? json['model'] ?? '').toString(),
      requests: _parseInt(json['requests'] ?? json['count']),
      tokens: _parseInt(json['tokens'] ?? json['totalTokens']),
      costUsd: _parseDouble(json['costUsd'] ?? json['cost']),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static double _parseDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}

@immutable
class AiTopCreator {
  const AiTopCreator({
    required this.creatorId,
    required this.email,
    this.name,
    required this.requests,
    required this.tokens,
    required this.costUsd,
  });

  final String creatorId;
  final String email;
  final String? name;
  final int requests;
  final int tokens;
  final double costUsd;

  factory AiTopCreator.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    
    return AiTopCreator(
      creatorId: (creator?['id'] ?? json['creatorId'] ?? '').toString(),
      email: (creator?['email'] ?? json['email'] ?? '').toString(),
      name: creator?['name']?.toString() ?? json['name']?.toString(),
      requests: _parseInt(json['requests'] ?? json['count']),
      tokens: _parseInt(json['tokens'] ?? json['totalTokens']),
      costUsd: _parseDouble(json['costUsd'] ?? json['cost']),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static double _parseDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}

@immutable
class AiDailyCost {
  const AiDailyCost({
    required this.date,
    required this.costUsd,
    required this.requests,
  });

  final DateTime date;
  final double costUsd;
  final int requests;

  factory AiDailyCost.fromJson(Map<String, dynamic> json) {
    return AiDailyCost(
      date: _parseDate(json['date']),
      costUsd: _parseDouble(json['costUsd'] ?? json['cost']),
      requests: _parseInt(json['requests'] ?? json['count']),
    );
  }

  static DateTime _parseDate(Object? v) {
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static double _parseDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}
