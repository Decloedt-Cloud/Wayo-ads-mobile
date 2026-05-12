import 'package:equatable/equatable.dart';

import 'invoice.dart';

/// Paginated `GET /api/{advertiser|creator}/invoices` response.
final class InvoicesPage extends Equatable {
  const InvoicesPage({
    required this.invoices,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<Invoice> invoices;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory InvoicesPage.empty() => const InvoicesPage(
    invoices: [],
    page: 1,
    pageSize: 10,
    totalCount: 0,
    totalPages: 1,
  );

  @override
  List<Object?> get props => [invoices, page, pageSize, totalCount, totalPages];
}
