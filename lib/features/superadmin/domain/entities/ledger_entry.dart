import 'package:flutter/foundation.dart';

/// Matches Prisma `LedgerEntryType` in Wayo-ads:
/// VIEW_PAYOUT, CONVERSION_PAYOUT, PLATFORM_FEE, REVERSAL
enum LedgerEntryType {
  viewPayout,
  conversionPayout,
  platformFee,
  reversal,
  unknown;

  static LedgerEntryType fromString(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'VIEW_PAYOUT':
        return LedgerEntryType.viewPayout;
      case 'CONVERSION_PAYOUT':
      case 'CONVERSION_FEE':
        return LedgerEntryType.conversionPayout;
      case 'PLATFORM_FEE':
        return LedgerEntryType.platformFee;
      case 'REVERSAL':
        return LedgerEntryType.reversal;
      default:
        return LedgerEntryType.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case LedgerEntryType.viewPayout:
        return 'View payout';
      case LedgerEntryType.conversionPayout:
        return 'Conversion payout';
      case LedgerEntryType.platformFee:
        return 'Platform fee';
      case LedgerEntryType.reversal:
        return 'Reversal';
      case LedgerEntryType.unknown:
        return 'Unknown';
    }
  }

  /// Query `type=` value for `/api/admin/ledger`
  String get apiValue {
    switch (this) {
      case LedgerEntryType.viewPayout:
        return 'VIEW_PAYOUT';
      case LedgerEntryType.conversionPayout:
        return 'CONVERSION_PAYOUT';
      case LedgerEntryType.platformFee:
        return 'PLATFORM_FEE';
      case LedgerEntryType.reversal:
        return 'REVERSAL';
      case LedgerEntryType.unknown:
        return '';
    }
  }
}

@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.description,
    this.campaignId,
    this.campaignTitle,
    this.creatorId,
    this.creatorEmail,
    this.creatorName,
    this.advertiserId,
    this.advertiserEmail,
    required this.createdAt,
  });

  final String id;
  final LedgerEntryType type;
  final int amountCents;
  final String description;
  final String? campaignId;
  final String? campaignTitle;
  final String? creatorId;
  final String? creatorEmail;
  final String? creatorName;
  final String? advertiserId;
  final String? advertiserEmail;
  final DateTime createdAt;

  double get amountUsd => amountCents / 100;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    final campaign = json['campaign'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    final advertiser = campaign?['advertiser'] as Map<String, dynamic>?;

    return LedgerEntry(
      id: (json['id'] ?? '').toString(),
      type: LedgerEntryType.fromString(json['type']?.toString()),
      amountCents: _parseInt(json['amountCents'] ?? json['amount']),
      description: (json['description'] ?? json['reason'] ?? '').toString(),
      campaignId: campaign?['id']?.toString() ?? json['campaignId']?.toString(),
      campaignTitle: campaign?['title']?.toString() ?? json['campaignTitle']?.toString(),
      creatorId: creator?['id']?.toString() ?? json['creatorId']?.toString(),
      creatorEmail: creator?['email']?.toString() ?? json['creatorEmail']?.toString(),
      creatorName: creator?['name']?.toString() ?? json['creatorName']?.toString(),
      advertiserId: advertiser?['id']?.toString() ?? json['advertiserId']?.toString(),
      advertiserEmail: advertiser?['email']?.toString() ?? json['advertiserEmail']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static DateTime _parseDateTime(Object? v) {
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

@immutable
class LedgerPage {
  const LedgerPage({
    required this.entries,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.summary,
  });

  final List<LedgerEntry> entries;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final LedgerSummary summary;

  factory LedgerPage.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'];
    final entries = <LedgerEntry>[];
    if (entriesRaw is List) {
      for (final item in entriesRaw) {
        if (item is Map) {
          entries.add(LedgerEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final pagination = json['pagination'] as Map<String, dynamic>? ?? json;

    return LedgerPage(
      entries: entries,
      page: _parseInt(pagination['page'], fallback: 1),
      limit: _parseInt(pagination['limit'], fallback: 50),
      total: _parseInt(pagination['total']),
      totalPages: _parseInt(pagination['totalPages'], fallback: 1),
      summary: LedgerSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  static int _parseInt(Object? v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }
}

@immutable
class LedgerSummary {
  const LedgerSummary({
    required this.totalAmountCents,
    required this.byType,
  });

  final int totalAmountCents;
  final List<LedgerTypeSummary> byType;

  double get totalAmountUsd => totalAmountCents / 100;

  factory LedgerSummary.fromJson(Map<String, dynamic> json) {
    final byTypeRaw = json['byType'];
    final byType = <LedgerTypeSummary>[];
    if (byTypeRaw is List) {
      for (final item in byTypeRaw) {
        if (item is Map) {
          byType.add(LedgerTypeSummary.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return LedgerSummary(
      totalAmountCents: _parseInt(json['totalAmount'] ?? json['totalAmountCents']),
      byType: byType,
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

@immutable
class LedgerTypeSummary {
  const LedgerTypeSummary({
    required this.type,
    required this.amountCents,
    required this.count,
  });

  final LedgerEntryType type;
  final int amountCents;
  final int count;

  double get amountUsd => amountCents / 100;

  factory LedgerTypeSummary.fromJson(Map<String, dynamic> json) {
    return LedgerTypeSummary(
      type: LedgerEntryType.fromString(json['type']?.toString()),
      amountCents: _parseInt(json['amountCents']),
      count: _parseInt(json['count']),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
