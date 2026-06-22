import 'package:equatable/equatable.dart';

/// Type of the invoice as emitted by `Wayo-ads` finance service.
///
/// Values mirror the server (`DEPOSIT`, `BILLING`, `PAYOUT`, `EARNINGS`). Unknown server-side
/// values map to [InvoiceType.unknown] so the UI never crashes when the backend evolves.
enum InvoiceType {
  /// Advertiser wallet credit — issued after a successful Stripe deposit.
  deposit('DEPOSIT'),

  /// Advertiser campaign budget hold — issued when a campaign budget is locked.
  billing('BILLING'),

  /// Creator payout — issued when a withdrawal is completed.
  payout('PAYOUT'),

  /// Creator ad earnings — issued for each completed ad delivery batch.
  earnings('EARNINGS'),

  /// Creator token purchase receipt.
  tokenPurchase('TOKEN_PURCHASE'),
  unknown('UNKNOWN');

  const InvoiceType(this.api);

  /// String value used by `Wayo-ads` (`invoiceType` column).
  final String api;

  static InvoiceType fromApi(Object? v) {
    if (v is String) {
      final upper = v.trim().toUpperCase();
      for (final t in InvoiceType.values) {
        if (t.api == upper) return t;
      }
    }
    return InvoiceType.unknown;
  }
}

/// Owner role of the invoice.
enum InvoiceRoleType {
  advertiser('ADVERTISER'),
  creator('CREATOR'),
  unknown('UNKNOWN');

  const InvoiceRoleType(this.api);
  final String api;

  static InvoiceRoleType fromApi(Object? v) {
    if (v is String) {
      final upper = v.trim().toUpperCase();
      for (final t in InvoiceRoleType.values) {
        if (t.api == upper) return t;
      }
    }
    return InvoiceRoleType.unknown;
  }
}

/// Lifecycle status of the invoice (currently always [paid] in the live backend).
enum InvoiceStatus {
  paid('PAID'),
  /// Creator-side finance documents (net settle) — distinct from advertiser PAID.
  validated('VALIDATED'),
  pending('PENDING'),
  cancelled('CANCELLED'),
  unknown('UNKNOWN');

  const InvoiceStatus(this.api);
  final String api;

  static InvoiceStatus fromApi(Object? v) {
    if (v is String) {
      final upper = v.trim().toUpperCase();
      for (final s in InvoiceStatus.values) {
        if (s.api == upper) return s;
      }
    }
    return InvoiceStatus.unknown;
  }
}

/// Immutable invoice row.
///
/// Amounts are kept in **cents** to mirror Prisma `totalAmountCents`. UI is expected
/// to divide by 100 before formatting through `MoneyFormatter`.
final class Invoice extends Equatable {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.type,
    required this.roleType,
    required this.status,
    required this.totalAmountCents,
    required this.taxAmountCents,
    required this.currency,
    required this.referenceId,
    required this.createdAt,
    required this.paidAt,
  });

  final String id;
  final String invoiceNumber;
  final InvoiceType type;
  final InvoiceRoleType roleType;
  final InvoiceStatus status;
  final int totalAmountCents;
  final int taxAmountCents;
  final String currency;
  final String? referenceId;
  final DateTime createdAt;
  final DateTime? paidAt;

  double get totalMajor => totalAmountCents / 100.0;
  double get taxMajor => taxAmountCents / 100.0;
  double get netMajor => (totalAmountCents - taxAmountCents) / 100.0;

  /// Parses both the paginated **creator/advertiser** payloads and the legacy
  /// **`/api/invoices`** flat payload (which doesn't include `currency`).
  factory Invoice.fromJson(Map<String, dynamic> json, {String fallbackCurrency = 'EUR'}) {
    return Invoice(
      id: '${json['id'] ?? ''}',
      invoiceNumber: '${json['invoiceNumber'] ?? ''}',
      type: InvoiceType.fromApi(json['invoiceType']),
      roleType: InvoiceRoleType.fromApi(json['roleType']),
      status: InvoiceStatus.fromApi(json['status']),
      totalAmountCents: _parseInt(json['totalAmountCents'], 0),
      taxAmountCents: _parseInt(json['taxAmountCents'], 0),
      currency: (json['currency'] is String && (json['currency'] as String).isNotEmpty)
          ? (json['currency'] as String).trim().toUpperCase()
          : fallbackCurrency,
      referenceId: (json['referenceId'] is String && (json['referenceId'] as String).isNotEmpty)
          ? json['referenceId'] as String
          : null,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      paidAt: _parseDate(json['paidAt']),
    );
  }

  static int _parseInt(Object? v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse('$v')?.toUtc();
  }

  @override
  List<Object?> get props => [
    id,
    invoiceNumber,
    type,
    roleType,
    status,
    totalAmountCents,
    taxAmountCents,
    currency,
    referenceId,
    createdAt,
    paidAt,
  ];
}
