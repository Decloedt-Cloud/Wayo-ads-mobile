import 'package:equatable/equatable.dart';

import 'invoice.dart';

/// KPI block returned by [GET /api/advertiser/invoices] (`stats` — net amounts in cents).
final class AdvertiserInvoicesStats extends Equatable {
  const AdvertiserInvoicesStats({
    required this.totalPaidCents,
    required this.totalThisMonthCents,
  });

  final int totalPaidCents;
  final int totalThisMonthCents;

  factory AdvertiserInvoicesStats.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const AdvertiserInvoicesStats(totalPaidCents: 0, totalThisMonthCents: 0);
    }
    int p(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return AdvertiserInvoicesStats(
      totalPaidCents: p(
        json['totalPaid'] ??
            json['totalPaidCents'] ??
            json['totalValidated'],
      ),
      totalThisMonthCents: p(json['totalThisMonth'] ?? json['totalThisMonthCents']),
    );
  }

  @override
  List<Object?> get props => [totalPaidCents, totalThisMonthCents];
}

/// Paginated `GET /api/{advertiser|creator}/invoices` response.
final class InvoicesPage extends Equatable {
  const InvoicesPage({
    required this.invoices,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    this.currency,
    this.advertiserStats,
  });

  final List<Invoice> invoices;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  /// Present on advertiser list when the API returns account-wide stats.
  final String? currency;
  final AdvertiserInvoicesStats? advertiserStats;

  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory InvoicesPage.empty() => const InvoicesPage(
    invoices: [],
    page: 1,
    pageSize: 15,
    totalCount: 0,
    totalPages: 1,
  );

  @override
  List<Object?> get props => [
    invoices,
    page,
    pageSize,
    totalCount,
    totalPages,
    currency,
    advertiserStats,
  ];
}
