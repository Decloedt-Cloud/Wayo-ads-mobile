import 'package:flutter/foundation.dart';

enum WithdrawalStatus {
  pending,
  validated,
  paid,
  cancelled,
  unknown;

  static WithdrawalStatus fromString(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'PENDING':
        return WithdrawalStatus.pending;
      case 'VALIDATED':
      case 'APPROVED':
        return WithdrawalStatus.validated;
      case 'PAID':
        return WithdrawalStatus.paid;
      case 'CANCELLED':
      case 'CANCELED':
        return WithdrawalStatus.cancelled;
      default:
        return WithdrawalStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.validated:
        return 'Approved';
      case WithdrawalStatus.paid:
        return 'Paid';
      case WithdrawalStatus.cancelled:
        return 'Cancelled';
      case WithdrawalStatus.unknown:
        return 'Unknown';
    }
  }
}

@immutable
class Withdrawal {
  const Withdrawal({
    required this.id,
    required this.creatorId,
    required this.creatorEmail,
    this.creatorName,
    required this.amountCents,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  final String id;
  final String creatorId;
  final String creatorEmail;
  final String? creatorName;
  final int amountCents;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;

  double get amountUsd => amountCents / 100;

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    
    return Withdrawal(
      id: (json['id'] ?? '').toString(),
      creatorId: (creator?['id'] ?? json['creatorId'] ?? '').toString(),
      creatorEmail: (creator?['email'] ?? json['creatorEmail'] ?? '').toString(),
      creatorName: creator?['name']?.toString() ?? json['creatorName']?.toString(),
      amountCents: _parseInt(json['amountCents'] ?? json['amount']),
      status: WithdrawalStatus.fromString(json['status']?.toString()),
      createdAt: _parseDateTime(json['createdAt']),
      processedAt: json['processedAt'] != null 
          ? _parseDateTime(json['processedAt'])
          : null,
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
class WithdrawalsPage {
  const WithdrawalsPage({
    required this.withdrawals,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.summary,
  });

  final List<Withdrawal> withdrawals;
  final int total;
  final int totalPages;
  final int page;
  final WithdrawalsSummary summary;

  factory WithdrawalsPage.fromJson(Map<String, dynamic> json) {
    final withdrawalsRaw = json['withdrawals'];
    final withdrawals = <Withdrawal>[];
    if (withdrawalsRaw is List) {
      for (final item in withdrawalsRaw) {
        if (item is Map) {
          withdrawals.add(Withdrawal.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return WithdrawalsPage(
      withdrawals: withdrawals,
      total: _parseInt(json['total']),
      totalPages: _parseInt(json['totalPages'], fallback: 1),
      page: _parseInt(json['page'], fallback: 1),
      summary: WithdrawalsSummary.fromJson(
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
class WithdrawalsSummary {
  const WithdrawalsSummary({
    required this.pendingCount,
    required this.pendingAmountCents,
    required this.validatedCount,
    required this.validatedAmountCents,
    required this.paidCount,
    required this.paidAmountCents,
    required this.cancelledCount,
    required this.cancelledAmountCents,
  });

  final int pendingCount;
  final int pendingAmountCents;
  final int validatedCount;
  final int validatedAmountCents;
  final int paidCount;
  final int paidAmountCents;
  final int cancelledCount;
  final int cancelledAmountCents;

  factory WithdrawalsSummary.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('pendingCount') ||
        json.containsKey('pendingAmountCents')) {
      return WithdrawalsSummary(
        pendingCount: _parseInt(json['pendingCount']),
        pendingAmountCents: _parseInt(json['pendingAmountCents']),
        validatedCount: _parseInt(json['validatedCount']),
        validatedAmountCents: _parseInt(json['validatedAmountCents']),
        paidCount: _parseInt(json['paidCount']),
        paidAmountCents: _parseInt(json['paidAmountCents']),
        cancelledCount: _parseInt(json['cancelledCount']),
        cancelledAmountCents: _parseInt(json['cancelledAmountCents']),
      );
    }

    int statusCount(String status) {
      final v = json[status];
      if (v is Map<String, dynamic>) return _parseInt(v['count']);
      if (v is Map) return _parseInt(v['count']);
      return 0;
    }

    int statusAmount(String status) {
      final v = json[status];
      if (v is Map<String, dynamic>) return _parseInt(v['amountCents']);
      if (v is Map) return _parseInt(v['amountCents']);
      return 0;
    }

    return WithdrawalsSummary(
      pendingCount: statusCount('PENDING'),
      pendingAmountCents: statusAmount('PENDING'),
      validatedCount: statusCount('VALIDATED'),
      validatedAmountCents: statusAmount('VALIDATED'),
      paidCount: statusCount('PAID'),
      paidAmountCents: statusAmount('PAID'),
      cancelledCount: statusCount('CANCELLED'),
      cancelledAmountCents: statusAmount('CANCELLED'),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
