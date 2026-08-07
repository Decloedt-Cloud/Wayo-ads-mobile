import 'package:flutter/foundation.dart';

/// One bank/wire routing address block — mirrors
/// `BankTransferFundingInstructions.addresses` (Wayo-ads `lib/finance/types.ts`).
@immutable
class AdminFundingAddress {
  const AdminFundingAddress({
    required this.network,
    this.accountHolderName,
    this.bankName,
    this.accountNumber,
    this.routingNumber,
    this.sortCode,
    this.swiftCode,
    this.iban,
    this.bic,
    this.country,
  });

  final String network;
  final String? accountHolderName;
  final String? bankName;
  final String? accountNumber;
  final String? routingNumber;
  final String? sortCode;
  final String? swiftCode;
  final String? iban;
  final String? bic;
  final String? country;

  factory AdminFundingAddress.fromJson(Map<String, dynamic> json) {
    return AdminFundingAddress(
      network: '${json['network'] ?? ''}',
      accountHolderName: json['accountHolderName']?.toString(),
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      routingNumber: json['routingNumber']?.toString(),
      sortCode: json['sortCode']?.toString(),
      swiftCode: json['swiftCode']?.toString(),
      iban: json['iban']?.toString(),
      bic: json['bic']?.toString(),
      country: json['country']?.toString(),
    );
  }
}

/// Normalized bank-transfer / wire instructions snapshot — mirrors
/// `BankTransferFundingInstructions` (Wayo-ads `lib/finance/types.ts`).
@immutable
class AdminFundingInstructions {
  const AdminFundingInstructions({
    required this.amountRemainingCents,
    required this.currency,
    required this.addresses,
    this.reference,
    this.hostedInstructionsUrl,
    this.transferType,
  });

  final int amountRemainingCents;
  final String currency;
  final String? reference;
  final String? hostedInstructionsUrl;
  final String? transferType;
  final List<AdminFundingAddress> addresses;

  static AdminFundingInstructions? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final amountRemainingCents = json['amountRemainingCents'];
    final currency = json['currency'];
    if (amountRemainingCents == null || currency == null) return null;
    final addressesRaw = json['addresses'];
    final addresses = addressesRaw is List
        ? addressesRaw
            .whereType<Map>()
            .map((e) => AdminFundingAddress.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AdminFundingAddress>[];
    return AdminFundingInstructions(
      amountRemainingCents: _asInt(amountRemainingCents),
      currency: '$currency'.toUpperCase(),
      reference: json['reference']?.toString(),
      hostedInstructionsUrl: json['hostedInstructionsUrl']?.toString(),
      transferType: json['transferType']?.toString(),
      addresses: addresses,
    );
  }
}

@immutable
class PaymentAuditRecord {
  const PaymentAuditRecord({
    required this.id,
    required this.stripePaymentIntentId,
    required this.advertiserId,
    required this.amountCents,
    required this.currency,
    required this.reconciliationStatus,
    required this.createdAt,
    this.actualProcessingFeeCents = 0,
    this.internationalFeeCents = 0,
    this.additionalStripeFeeCents = 0,
    this.advertiserEmail,
    this.advertiserName,
    this.depositMethod,
    this.wireReference,
    this.fundingInstructions,
  });

  final String id;
  final String stripePaymentIntentId;
  final String advertiserId;
  final int amountCents;
  final String currency;
  final String reconciliationStatus;
  final DateTime createdAt;
  final int actualProcessingFeeCents;
  final int internationalFeeCents;
  final int additionalStripeFeeCents;
  final String? advertiserEmail;
  final String? advertiserName;
  final String? depositMethod;
  final String? wireReference;
  final AdminFundingInstructions? fundingInstructions;

  int get totalFeeCents =>
      actualProcessingFeeCents + internationalFeeCents + additionalStripeFeeCents;

  factory PaymentAuditRecord.fromJson(Map<String, dynamic> json) {
    final adv = json['advertiser'];
    Map<String, dynamic>? advMap;
    if (adv is Map) {
      advMap = Map<String, dynamic>.from(adv);
    }
    return PaymentAuditRecord(
      id: '${json['id'] ?? ''}',
      stripePaymentIntentId: '${json['stripePaymentIntentId'] ?? ''}',
      advertiserId: '${json['advertiserId'] ?? advMap?['id'] ?? ''}',
      amountCents: _asInt(json['amountCents']),
      currency: '${json['currency'] ?? 'EUR'}'.toUpperCase(),
      reconciliationStatus: '${json['reconciliationStatus'] ?? 'UNKNOWN'}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      actualProcessingFeeCents: _asInt(json['actualProcessingFeeCents']),
      internationalFeeCents: _asInt(json['internationalFeeCents']),
      additionalStripeFeeCents: _asInt(json['additionalStripeFeeCents']),
      advertiserEmail: advMap?['email']?.toString(),
      advertiserName: advMap?['name']?.toString(),
      depositMethod: json['depositMethod']?.toString(),
      wireReference: json['wireReference']?.toString(),
      fundingInstructions: AdminFundingInstructions.tryParse(json['fundingInstructions']),
    );
  }
}

/// One reconciled row from [GET /api/admin/payment-audits/{id}/reconcile].
@immutable
class PaymentAuditReconcileResult {
  const PaymentAuditReconcileResult({
    required this.auditId,
    required this.reconciliationStatus,
    this.additionalStripeFeeCents,
    this.processingFeeSettled,
  });

  final String auditId;
  final String reconciliationStatus;
  final int? additionalStripeFeeCents;
  final bool? processingFeeSettled;

  factory PaymentAuditReconcileResult.fromJson(Map<String, dynamic> json) {
    return PaymentAuditReconcileResult(
      auditId: '${json['auditId'] ?? ''}',
      reconciliationStatus: '${json['reconciliationStatus'] ?? 'UNKNOWN'}',
      additionalStripeFeeCents: json['additionalStripeFeeCents'] == null
          ? null
          : _asInt(json['additionalStripeFeeCents']),
      processingFeeSettled: json['processingFeeSettled'] is bool
          ? json['processingFeeSettled'] as bool
          : null,
    );
  }
}

/// One row from [GET /api/admin/advertiser-deposits] — per-advertiser totals.
@immutable
class AdvertiserDepositTotalRow {
  const AdvertiserDepositTotalRow({
    required this.advertiserId,
    required this.advertiserEmail,
    required this.currency,
    required this.depositCount,
    required this.totalChargedCents,
    required this.totalStripeFeeCents,
    required this.totalInternationalFeeCents,
    required this.totalAdditionalStripeFeeCents,
    required this.totalNetCents,
    this.advertiserName,
    this.walletAvailableCents,
    this.lastDepositAt,
  });

  final String advertiserId;
  final String advertiserEmail;
  final String? advertiserName;
  final String currency;
  final int depositCount;
  final int totalChargedCents;
  final int totalStripeFeeCents;
  final int totalInternationalFeeCents;
  final int totalAdditionalStripeFeeCents;
  final int totalNetCents;
  final int? walletAvailableCents;
  final DateTime? lastDepositAt;

  factory AdvertiserDepositTotalRow.fromJson(Map<String, dynamic> json) {
    return AdvertiserDepositTotalRow(
      advertiserId: '${json['advertiserId'] ?? ''}',
      advertiserEmail: '${json['advertiserEmail'] ?? ''}',
      advertiserName: json['advertiserName']?.toString(),
      currency: '${json['currency'] ?? 'EUR'}'.toUpperCase(),
      depositCount: _asInt(json['depositCount']),
      totalChargedCents: _asInt(json['totalChargedCents']),
      totalStripeFeeCents: _asInt(json['totalStripeFeeCents']),
      totalInternationalFeeCents: _asInt(json['totalInternationalFeeCents']),
      totalAdditionalStripeFeeCents: _asInt(json['totalAdditionalStripeFeeCents']),
      totalNetCents: _asInt(json['totalNetCents']),
      walletAvailableCents: json['walletAvailableCents'] == null
          ? null
          : _asInt(json['walletAvailableCents']),
      lastDepositAt: json['lastDepositAt'] == null
          ? null
          : DateTime.tryParse('${json['lastDepositAt']}'),
    );
  }
}

/// [GET /api/admin/advertiser-deposits] paginated response.
@immutable
class PlatformDepositTotals {
  const PlatformDepositTotals({
    required this.currency,
    required this.totalChargedCents,
    required this.totalNetCents,
    required this.depositCount,
  });

  final String currency;
  final int totalChargedCents;
  final int totalNetCents;
  final int depositCount;

  factory PlatformDepositTotals.fromJson(Map<String, dynamic> json) {
    return PlatformDepositTotals(
      currency: '${json['currency'] ?? 'USD'}'.toUpperCase(),
      totalChargedCents: _asInt(json['totalChargedCents']),
      totalNetCents: _asInt(json['totalNetCents']),
      depositCount: _asInt(json['depositCount']),
    );
  }
}

@immutable
class AdvertiserDepositsPage {
  const AdvertiserDepositsPage({
    required this.rows,
    required this.total,
    required this.page,
    required this.limit,
    this.platformSummary = const [],
  });

  final List<AdvertiserDepositTotalRow> rows;
  final int total;
  final int page;
  final int limit;
  final List<PlatformDepositTotals> platformSummary;

  int get totalPages => limit <= 0 ? 1 : ((total + limit - 1) / limit).ceil();

  /// Prefer USD / first summary row (matches web admin home).
  PlatformDepositTotals? get preferredPlatformSummary {
    if (platformSummary.isEmpty) return null;
    for (final row in platformSummary) {
      if (row.currency == 'USD') return row;
    }
    return platformSummary.first;
  }

  factory AdvertiserDepositsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['rows'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => AdvertiserDepositTotalRow.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AdvertiserDepositTotalRow>[];
    final summaryRaw = json['platformSummary'];
    final summary = summaryRaw is List
        ? summaryRaw
            .whereType<Map>()
            .map((e) => PlatformDepositTotals.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PlatformDepositTotals>[];
    return AdvertiserDepositsPage(
      rows: list,
      total: _asInt(json['total']),
      page: _asInt(json['page'] ?? 1),
      limit: _asInt(json['limit'] ?? 20),
      platformSummary: summary,
    );
  }
}

@immutable
class PaymentAuditsPage {
  const PaymentAuditsPage({
    required this.records,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<PaymentAuditRecord> records;
  final int total;
  final int page;
  final int limit;

  int get totalPages => limit <= 0 ? 1 : ((total + limit - 1) / limit).ceil();
}

@immutable
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.source,
    required this.action,
    required this.createdAt,
    this.actorId,
    this.actorEmail,
    this.targetUserId,
    this.targetEmail,
    this.reason,
    this.ipAddress,
  });

  final String id;
  final String source;
  final String action;
  final DateTime createdAt;
  final String? actorId;
  final String? actorEmail;
  final String? targetUserId;
  final String? targetEmail;
  final String? reason;
  final String? ipAddress;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: '${json['id'] ?? ''}',
      source: '${json['source'] ?? 'admin'}',
      action: '${json['action'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      actorId: json['actorId']?.toString(),
      actorEmail: json['actorEmail']?.toString(),
      targetUserId: json['targetUserId']?.toString(),
      targetEmail: json['targetEmail']?.toString(),
      reason: json['reason']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
    );
  }
}

@immutable
class AuditLogPage {
  const AuditLogPage({
    required this.entries,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<AuditLogEntry> entries;
  final int total;
  final int limit;
  final int offset;
}

@immutable
class PlatformHealthSnapshot {
  const PlatformHealthSnapshot({
    required this.activeCampaigns,
    required this.totalCreators,
    required this.clicks24h,
    required this.validatedClicks,
    required this.rejectedFraud,
    required this.fraudRatePct,
    required this.pendingWithdrawals,
    required this.platformFeePayoutCents,
    required this.platformFeeActivationCents,
  });

  final int activeCampaigns;
  final int totalCreators;
  final int clicks24h;
  final int validatedClicks;
  final int rejectedFraud;
  final int fraudRatePct;
  final int pendingWithdrawals;
  final int platformFeePayoutCents;
  final int platformFeeActivationCents;

  int get platformFeeTotalCents =>
      platformFeePayoutCents + platformFeeActivationCents;

  factory PlatformHealthSnapshot.fromJson(Map<String, dynamic> json) {
    final payout = _asInt(
      json['platformFeePayoutCents'] ?? json['platformFeeCents'],
    );
    final activation = _asInt(json['platformFeeActivationCents']);
    final explicitTotal = json['platformFeeTotalCents'] == null
        ? null
        : _asInt(json['platformFeeTotalCents']);
    return PlatformHealthSnapshot(
      activeCampaigns: _asInt(json['activeCampaigns']),
      totalCreators: _asInt(json['totalCreators']),
      clicks24h: _asInt(json['clicks24h'] ?? json['totalClicks24h']),
      validatedClicks: _asInt(json['validatedClicks']),
      rejectedFraud: _asInt(json['rejectedFraud'] ?? json['rejectedFraudCount']),
      fraudRatePct: _asInt(json['fraudRatePct']),
      pendingWithdrawals: _asInt(json['pendingWithdrawals']),
      platformFeePayoutCents: payout,
      // If only an aggregate is present, keep it on payout so the total matches.
      platformFeeActivationCents: activation == 0 &&
              payout == 0 &&
              explicitTotal != null
          ? explicitTotal
          : activation,
    );
  }
}

@immutable
class AdminServiceStatus {
  const AdminServiceStatus({
    required this.name,
    required this.status,
    this.latencyMs,
    this.message,
  });

  final String name;
  final String status;
  final int? latencyMs;
  final String? message;

  bool get isOk {
    final s = status.toLowerCase();
    return s == 'ok' || s == 'up' || s == 'online';
  }

  bool get isDegraded => status.toLowerCase() == 'degraded';

  factory AdminServiceStatus.fromJson(Map<String, dynamic> json) {
    return AdminServiceStatus(
      name: '${json['name'] ?? ''}',
      status: '${json['status'] ?? 'unknown'}',
      latencyMs: json['latencyMs'] is num ? (json['latencyMs'] as num).toInt() : null,
      message: json['message']?.toString(),
    );
  }
}

// ─── P1 ops panels ───────────────────────────────────────────────────────────

@immutable
class TokenPurchaseRecord {
  const TokenPurchaseRecord({
    required this.id,
    required this.tokenCount,
    required this.packageName,
    required this.amountCents,
    required this.taxCents,
    required this.currency,
    required this.createdAt,
    this.packageId,
    this.psReference,
    this.creatorId,
    this.creatorName,
    this.creatorEmail,
  });

  final String id;
  final int tokenCount;
  final String packageName;
  final int amountCents;
  final int taxCents;
  final String currency;
  final DateTime createdAt;
  final String? packageId;
  final String? psReference;
  final String? creatorId;
  final String? creatorName;
  final String? creatorEmail;

  factory TokenPurchaseRecord.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    Map<String, dynamic>? c;
    if (creator is Map) c = Map<String, dynamic>.from(creator);
    return TokenPurchaseRecord(
      id: '${json['id'] ?? ''}',
      tokenCount: _asInt(json['tokenCount']),
      packageId: json['packageId']?.toString(),
      packageName: '${json['packageName'] ?? ''}',
      amountCents: _asInt(json['amountCents']),
      taxCents: _asInt(json['taxCents']),
      currency: '${json['currency'] ?? 'EUR'}'.toUpperCase(),
      psReference: json['psReference']?.toString(),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      creatorId: c?['id']?.toString(),
      creatorName: c?['name']?.toString(),
      creatorEmail: c?['email']?.toString(),
    );
  }
}

@immutable
class TokenPackageStat {
  const TokenPackageStat({
    required this.packageId,
    required this.packageName,
    required this.tokenCount,
    required this.sales,
    required this.revenueCents,
  });

  final String packageId;
  final String packageName;
  final int tokenCount;
  final int sales;
  final int revenueCents;

  factory TokenPackageStat.fromJson(Map<String, dynamic> json) {
    return TokenPackageStat(
      packageId: '${json['packageId'] ?? ''}',
      packageName: '${json['packageName'] ?? ''}',
      tokenCount: _asInt(json['tokenCount']),
      sales: _asInt(json['sales']),
      revenueCents: _asInt(json['revenueCents']),
    );
  }
}

@immutable
class TokenPurchasesPage {
  const TokenPurchasesPage({
    required this.purchases,
    required this.total,
    required this.page,
    required this.totalTokens,
    required this.totalRevenueCents,
    required this.totalTaxCents,
    this.packageStats = const [],
  });

  final List<TokenPurchaseRecord> purchases;
  final int total;
  final int page;
  final int totalTokens;
  final int totalRevenueCents;
  final int totalTaxCents;
  final List<TokenPackageStat> packageStats;
}

@immutable
class ClickPipelineSnapshot {
  const ClickPipelineSnapshot({
    required this.counts,
    this.oldestPendingBudgetAgeMinutes,
  });

  final Map<String, int> counts;
  final int? oldestPendingBudgetAgeMinutes;

  int countFor(String status) => counts[status] ?? 0;

  int get totalClicks => counts.values.fold(0, (a, b) => a + b);

  factory ClickPipelineSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['counts'];
    final map = <String, int>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        map['${e.key}'] = _asInt(e.value);
      }
    }
    final age = json['oldestPendingBudgetAgeMinutes'];
    return ClickPipelineSnapshot(
      counts: map,
      oldestPendingBudgetAgeMinutes: age == null ? null : _asInt(age),
    );
  }
}

@immutable
class CreatorVelocityRow {
  const CreatorVelocityRow({
    required this.creatorId,
    required this.creatorName,
    required this.velocityChangePercent,
    required this.riskLevel,
    this.trustScore,
  });

  final String creatorId;
  final String creatorName;
  final double velocityChangePercent;
  final String riskLevel;
  final int? trustScore;

  factory CreatorVelocityRow.fromJson(Map<String, dynamic> json) {
    return CreatorVelocityRow(
      creatorId: '${json['creatorId'] ?? ''}',
      creatorName: '${json['creatorName'] ?? 'Unknown'}',
      velocityChangePercent: _asDouble(json['velocityChangePercent']),
      riskLevel: '${json['riskLevel'] ?? 'LOW'}',
      trustScore: json['trustScore'] == null ? null : _asInt(json['trustScore']),
    );
  }
}

@immutable
class CreatorVelocitySnapshot {
  const CreatorVelocitySnapshot({
    required this.period,
    required this.topCreators,
  });

  final String period;
  final List<CreatorVelocityRow> topCreators;
}

@immutable
class EmailLogRecord {
  const EmailLogRecord({
    required this.id,
    required this.toEmail,
    required this.subject,
    required this.status,
    required this.sentAt,
    this.toName,
    this.templateName,
    this.errorMessage,
  });

  final String id;
  final String toEmail;
  final String subject;
  final String status;
  final DateTime sentAt;
  final String? toName;
  final String? templateName;
  final String? errorMessage;

  factory EmailLogRecord.fromJson(Map<String, dynamic> json) {
    return EmailLogRecord(
      id: '${json['id'] ?? ''}',
      toEmail: '${json['toEmail'] ?? ''}',
      toName: json['toName']?.toString(),
      subject: '${json['subject'] ?? ''}',
      templateName: json['templateName']?.toString(),
      status: '${json['status'] ?? ''}',
      sentAt: DateTime.tryParse('${json['sentAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      errorMessage: json['errorMessage']?.toString(),
    );
  }
}

@immutable
class EmailLogsPage {
  const EmailLogsPage({
    required this.logs,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<EmailLogRecord> logs;
  final int total;
  final int limit;
  final int offset;
}

@immutable
class RecentActivityItem {
  const RecentActivityItem({
    required this.id,
    required this.type,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.title,
    this.amountCents,
  });

  final String id;
  final String type;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;
  final String? title;
  final int? amountCents;

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    Map<String, dynamic>? u;
    if (user is Map) u = Map<String, dynamic>.from(user);
    final data = json['data'];
    Map<String, dynamic>? d;
    if (data is Map) d = Map<String, dynamic>.from(data);
    return RecentActivityItem(
      id: '${json['id'] ?? ''}',
      type: '${json['type'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      userName: u?['name']?.toString(),
      userEmail: u?['email']?.toString(),
      title: d?['title']?.toString(),
      amountCents: d == null
          ? null
          : (d['budgetCents'] != null
              ? _asInt(d['budgetCents'])
              : (d['amountCents'] != null ? _asInt(d['amountCents']) : null)),
    );
  }
}

@immutable
class RecentActivityPage {
  const RecentActivityPage({
    required this.activities,
    required this.total,
  });

  final List<RecentActivityItem> activities;
  final int total;
}

@immutable
class AdminInvoiceRecord {
  const AdminInvoiceRecord({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceType,
    required this.roleType,
    required this.status,
    required this.totalAmountCents,
    required this.taxAmountCents,
    required this.platformFeeCents,
    required this.createdAt,
    this.paymentMethod,
    this.paidAt,
    this.pdfUrl,
    this.userName,
    this.userEmail,
  });

  final String id;
  final String invoiceNumber;
  final String invoiceType;
  final String roleType;
  final String status;
  final int totalAmountCents;
  final int taxAmountCents;
  final int platformFeeCents;
  final DateTime createdAt;
  final String? paymentMethod;
  final DateTime? paidAt;
  final String? pdfUrl;
  final String? userName;
  final String? userEmail;

  factory AdminInvoiceRecord.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    Map<String, dynamic>? u;
    if (user is Map) u = Map<String, dynamic>.from(user);
    return AdminInvoiceRecord(
      id: '${json['id'] ?? ''}',
      invoiceNumber: '${json['invoiceNumber'] ?? ''}',
      invoiceType: '${json['invoiceType'] ?? ''}',
      roleType: '${json['roleType'] ?? ''}',
      status: '${json['status'] ?? ''}',
      totalAmountCents: _asInt(json['totalAmountCents']),
      taxAmountCents: _asInt(json['taxAmountCents']),
      platformFeeCents: _asInt(json['platformFeeCents']),
      paymentMethod: json['paymentMethod']?.toString(),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      paidAt: DateTime.tryParse('${json['paidAt'] ?? ''}'),
      pdfUrl: json['pdfUrl']?.toString(),
      userName: u?['name']?.toString(),
      userEmail: u?['email']?.toString(),
    );
  }
}

@immutable
class AdminInvoicesPage {
  const AdminInvoicesPage({
    required this.invoices,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<AdminInvoiceRecord> invoices;
  final int total;
  final int page;
  final int totalPages;
}

@immutable
class AdminPaymentStatement {
  const AdminPaymentStatement({
    required this.id,
    required this.statementNumber,
    required this.creatorName,
    required this.creatorEmail,
    required this.grossEarningsCents,
    required this.platformFeeCents,
    required this.netPayoutCents,
    required this.currency,
    required this.paymentMethod,
    required this.statementDate,
    required this.status,
    this.taxCents,
    this.payoutDate,
    this.pdfUrl,
  });

  final String id;
  final String statementNumber;
  final String creatorName;
  final String creatorEmail;
  final int grossEarningsCents;
  final int platformFeeCents;
  final int? taxCents;
  final int netPayoutCents;
  final String currency;
  final String paymentMethod;
  final DateTime statementDate;
  final DateTime? payoutDate;
  final String status;
  final String? pdfUrl;

  factory AdminPaymentStatement.fromJson(Map<String, dynamic> json) {
    return AdminPaymentStatement(
      id: '${json['id'] ?? ''}',
      statementNumber: '${json['statementNumber'] ?? ''}',
      creatorName: '${json['creatorName'] ?? ''}',
      creatorEmail: '${json['creatorEmail'] ?? ''}',
      grossEarningsCents: _asInt(json['grossEarningsCents']),
      platformFeeCents: _asInt(json['platformFeeCents']),
      taxCents: json['taxCents'] == null ? null : _asInt(json['taxCents']),
      netPayoutCents: _asInt(json['netPayoutCents']),
      currency: '${json['currency'] ?? 'EUR'}'.toUpperCase(),
      paymentMethod: '${json['paymentMethod'] ?? ''}',
      statementDate: DateTime.tryParse('${json['statementDate'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      payoutDate: DateTime.tryParse('${json['payoutDate'] ?? ''}'),
      status: '${json['status'] ?? ''}',
      pdfUrl: json['pdfUrl']?.toString(),
    );
  }
}

@immutable
class AdminPaymentStatementsPage {
  const AdminPaymentStatementsPage({
    required this.statements,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<AdminPaymentStatement> statements;
  final int total;
  final int page;
  final int totalPages;
}

// ─── P2: jobs / YT / settings ────────────────────────────────────────────────

@immutable
class YoutubeMonitoringStats {
  const YoutubeMonitoringStats({
    required this.postsByStatus,
    required this.quotaUsed,
    required this.quotaLimit,
    required this.quotaPercentUsed,
    this.recentSnapshotCount = 0,
  });

  final Map<String, int> postsByStatus;
  final int quotaUsed;
  final int quotaLimit;
  final double quotaPercentUsed;
  final int recentSnapshotCount;

  int get totalPosts => postsByStatus.values.fold(0, (a, b) => a + b);

  int countFor(String status) => postsByStatus[status] ?? 0;

  factory YoutubeMonitoringStats.fromJson(Map<String, dynamic> json) {
    final byStatus = <String, int>{};
    final raw = json['postsByStatus'];
    if (raw is List) {
      for (final row in raw.whereType<Map>()) {
        final status = '${row['status'] ?? ''}';
        final count = row['_count'];
        if (count is Map) {
          byStatus[status] = _asInt(count['status'] ?? count['_all'] ?? 0);
        } else {
          byStatus[status] = _asInt(count);
        }
      }
    } else if (raw is Map) {
      for (final e in raw.entries) {
        byStatus['${e.key}'] = _asInt(e.value);
      }
    }
    final quota = json['quotaUsage'];
    Map<String, dynamic>? q;
    if (quota is Map) q = Map<String, dynamic>.from(quota);
    final snaps = json['recentSnapshots'];
    return YoutubeMonitoringStats(
      postsByStatus: byStatus,
      quotaUsed: _asInt(q?['used']),
      quotaLimit: _asInt(q?['limit'] ?? 10000),
      quotaPercentUsed: _asDouble(q?['percentUsed']),
      recentSnapshotCount: snaps is List ? snaps.length : 0,
    );
  }
}

@immutable
class AdminTokenPackage {
  const AdminTokenPackage({
    required this.slug,
    required this.name,
    required this.tokens,
    required this.bonusTokens,
    required this.priceCents,
    required this.currency,
    required this.isActive,
    required this.isBestValue,
    required this.sortOrder,
    this.appleProductId,
    this.googleProductId,
  });

  final String slug;
  final String name;
  final int tokens;
  final int bonusTokens;
  final int priceCents;
  final String currency;
  final bool isActive;
  final bool isBestValue;
  final int sortOrder;
  /// Native IAP product IDs (Studio mobile). Null => Stripe stays the
  /// purchase path for that package.
  final String? appleProductId;
  final String? googleProductId;

  int get totalTokens => tokens + bonusTokens;

  factory AdminTokenPackage.fromJson(Map<String, dynamic> json) {
    return AdminTokenPackage(
      slug: '${json['slug'] ?? ''}',
      name: '${json['name'] ?? ''}',
      tokens: _asInt(json['tokens']),
      bonusTokens: _asInt(json['bonusTokens']),
      priceCents: _asInt(json['priceCents']),
      currency: '${json['currency'] ?? 'USD'}'.toUpperCase(),
      isActive: json['isActive'] == true,
      isBestValue: json['isBestValue'] == true,
      sortOrder: _asInt(json['sortOrder']),
      appleProductId: (json['appleProductId'] as String?)?.trim().isNotEmpty == true
          ? json['appleProductId'] as String
          : null,
      googleProductId: (json['googleProductId'] as String?)?.trim().isNotEmpty == true
          ? json['googleProductId'] as String
          : null,
    );
  }
}

@immutable
class PlatformSettingsSnapshot {
  const PlatformSettingsSnapshot({
    required this.platformFeeRate,
    required this.platformFeePercentage,
    required this.defaultCurrency,
    required this.minimumWithdrawalCents,
    required this.pendingHoldDays,
    required this.viewSettlementHoldHours,
    required this.platformName,
    required this.stripeActiveMode,
    this.platformFeeDescription,
  });

  final double platformFeeRate;
  final double platformFeePercentage;
  final String defaultCurrency;
  final int minimumWithdrawalCents;
  final int pendingHoldDays;
  final int viewSettlementHoldHours;
  final String platformName;
  final String stripeActiveMode;
  final String? platformFeeDescription;

  factory PlatformSettingsSnapshot.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] is Map
        ? Map<String, dynamic>.from(json['settings'] as Map)
        : json;
    return PlatformSettingsSnapshot(
      platformFeeRate: _asDouble(settings['platformFeeRate']),
      platformFeePercentage: _asDouble(
        settings['platformFeePercentage'] ??
            (_asDouble(settings['platformFeeRate']) * 100),
      ),
      defaultCurrency: '${settings['defaultCurrency'] ?? 'EUR'}'.toUpperCase(),
      minimumWithdrawalCents: _asInt(settings['minimumWithdrawalCents']),
      pendingHoldDays: _asInt(settings['pendingHoldDays']),
      viewSettlementHoldHours: _asInt(settings['viewSettlementHoldHours']),
      platformName: '${settings['platformName'] ?? 'Wayo'}',
      stripeActiveMode: '${settings['stripeActiveMode'] ?? 'TEST'}',
      platformFeeDescription: settings['platformFeeDescription']?.toString(),
    );
  }
}

@immutable
class StripeModeStatus {
  const StripeModeStatus({
    required this.mode,
    this.publishableKeyMasked,
    this.secretKeyMasked,
    this.webhookSecretMasked,
    this.lastVerifiedOk,
    this.lastVerifiedAt,
  });

  final String mode;
  final String? publishableKeyMasked;
  final String? secretKeyMasked;
  final String? webhookSecretMasked;
  final bool? lastVerifiedOk;
  final DateTime? lastVerifiedAt;

  bool get hasKeys =>
      (publishableKeyMasked != null && publishableKeyMasked!.isNotEmpty) ||
      (secretKeyMasked != null && secretKeyMasked!.isNotEmpty);

  factory StripeModeStatus.fromJson(String mode, Map<String, dynamic> json) {
    return StripeModeStatus(
      mode: mode,
      publishableKeyMasked: json['publishableKeyMasked']?.toString(),
      secretKeyMasked: json['secretKeyMasked']?.toString(),
      webhookSecretMasked: json['webhookSecretMasked']?.toString(),
      lastVerifiedOk: json['lastVerifiedOk'] is bool
          ? json['lastVerifiedOk'] as bool
          : null,
      lastVerifiedAt: DateTime.tryParse('${json['lastVerifiedAt'] ?? ''}'),
    );
  }
}

@immutable
class StripeSettingsStatus {
  const StripeSettingsStatus({
    required this.activeMode,
    required this.test,
    required this.live,
  });

  final String activeMode;
  final StripeModeStatus test;
  final StripeModeStatus live;

  factory StripeSettingsStatus.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'];
    Map<String, dynamic> root = {};
    if (settings is Map) root = Map<String, dynamic>.from(settings);
    final testMap = root['TEST'] is Map
        ? Map<String, dynamic>.from(root['TEST'] as Map)
        : <String, dynamic>{};
    final liveMap = root['LIVE'] is Map
        ? Map<String, dynamic>.from(root['LIVE'] as Map)
        : <String, dynamic>{};
    return StripeSettingsStatus(
      activeMode: '${json['activeMode'] ?? 'TEST'}',
      test: StripeModeStatus.fromJson('TEST', testMap),
      live: StripeModeStatus.fromJson('LIVE', liveMap),
    );
  }
}

/// Generic success/message result for sensitive admin actions
/// (test emails, hard delete confirmations, etc.).
@immutable
class AdminActionResult {
  const AdminActionResult({required this.success, required this.message});

  final bool success;
  final String message;

  factory AdminActionResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true || json['ok'] == true;
    final message = json['message']?.toString() ??
        json['error']?.toString() ??
        (success ? 'Done' : 'Failed');
    return AdminActionResult(success: success, message: message);
  }
}

@immutable
class StripeTestConnectionResult {
  const StripeTestConnectionResult({
    required this.success,
    required this.message,
    this.mode,
    this.accountId,
    this.accountName,
    this.country,
    this.chargesEnabled,
    this.payoutsEnabled,
  });

  final bool success;
  final String message;
  final String? mode;
  final String? accountId;
  final String? accountName;
  final String? country;
  final bool? chargesEnabled;
  final bool? payoutsEnabled;

  factory StripeTestConnectionResult.fromJson(Map<String, dynamic> json) {
    final details = json['details'] is Map
        ? Map<String, dynamic>.from(json['details'] as Map)
        : <String, dynamic>{};
    return StripeTestConnectionResult(
      success: json['success'] == true,
      message: '${json['message'] ?? ''}',
      mode: details['mode']?.toString(),
      accountId: details['accountId']?.toString(),
      accountName: details['accountName']?.toString(),
      country: details['country']?.toString(),
      chargesEnabled:
          details['chargesEnabled'] is bool ? details['chargesEnabled'] as bool : null,
      payoutsEnabled:
          details['payoutsEnabled'] is bool ? details['payoutsEnabled'] as bool : null,
    );
  }
}

@immutable
class EmailSettingsSnapshot {
  const EmailSettingsSnapshot({
    required this.host,
    required this.port,
    required this.secure,
    required this.fromEmail,
    required this.isEnabled,
    this.id,
    this.usernameMasked,
    this.fromName,
    this.replyToEmail,
    this.updatedAt,
    this.updatedByName,
    this.updatedByEmail,
  });

  final String? id;
  final String host;
  final int port;
  final bool secure;
  final String? usernameMasked;
  final String fromEmail;
  final String? fromName;
  final String? replyToEmail;
  final bool isEnabled;
  final DateTime? updatedAt;
  final String? updatedByName;
  final String? updatedByEmail;

  static const EmailSettingsSnapshot empty = EmailSettingsSnapshot(
    host: '',
    port: 587,
    secure: true,
    fromEmail: '',
    isEnabled: false,
  );

  factory EmailSettingsSnapshot.fromJson(Map<String, dynamic> json) {
    final updatedBy = json['updatedBy'];
    Map<String, dynamic>? u;
    if (updatedBy is Map) u = Map<String, dynamic>.from(updatedBy);
    return EmailSettingsSnapshot(
      id: json['id']?.toString(),
      host: '${json['host'] ?? ''}',
      port: _asInt(json['port'] ?? 587),
      secure: json['secure'] == true,
      usernameMasked: json['usernameMasked']?.toString(),
      fromEmail: '${json['fromEmail'] ?? ''}',
      fromName: json['fromName']?.toString(),
      replyToEmail: json['replyToEmail']?.toString(),
      isEnabled: json['isEnabled'] == true,
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
      updatedByName: u?['name']?.toString(),
      updatedByEmail: u?['email']?.toString(),
    );
  }
}

@immutable
class AdminJobRunResult {
  const AdminJobRunResult({
    required this.ok,
    required this.summary,
  });

  final bool ok;
  final String summary;
}

@immutable
class AdminEmailTemplate {
  const AdminEmailTemplate({
    required this.name,
    required this.subject,
    required this.previewText,
    required this.category,
    required this.description,
  });

  final String name;
  final String subject;
  final String previewText;
  final String category;
  final String description;

  factory AdminEmailTemplate.fromJson(Map<String, dynamic> json) {
    return AdminEmailTemplate(
      name: '${json['name'] ?? ''}',
      subject: '${json['subject'] ?? ''}',
      previewText: '${json['previewText'] ?? ''}',
      category: '${json['category'] ?? 'other'}',
      description: '${json['description'] ?? ''}',
    );
  }
}

@immutable
class AdminEmailTemplatePreview {
  const AdminEmailTemplatePreview({
    required this.templateName,
    required this.subject,
    required this.previewText,
    required this.text,
    this.html,
  });

  final String templateName;
  final String subject;
  final String previewText;
  final String text;
  final String? html;

  factory AdminEmailTemplatePreview.fromJson(Map<String, dynamic> json) {
    return AdminEmailTemplatePreview(
      templateName: '${json['templateName'] ?? ''}',
      subject: '${json['subject'] ?? ''}',
      previewText: '${json['previewText'] ?? ''}',
      text: '${json['text'] ?? ''}',
      html: json['html']?.toString(),
    );
  }
}

@immutable
class AdminUserCampaignSummary {
  const AdminUserCampaignSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.totalBudgetCents,
    required this.spentBudgetCents,
    required this.totalBillableViews,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String status;
  final int totalBudgetCents;
  final int spentBudgetCents;
  final int totalBillableViews;
  final DateTime createdAt;

  factory AdminUserCampaignSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserCampaignSummary(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      status: '${json['status'] ?? ''}',
      totalBudgetCents: _asInt(json['totalBudgetCents']),
      spentBudgetCents: _asInt(json['spentBudgetCents']),
      totalBillableViews: _asInt(json['totalBillableViews']),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

@immutable
class AdminUserApplicationSummary {
  const AdminUserApplicationSummary({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.campaignStatus,
    required this.status,
    required this.createdAt,
    this.message,
    this.reviewedAt,
  });

  final String id;
  final String campaignId;
  final String campaignTitle;
  final String campaignStatus;
  final String status;
  final DateTime createdAt;
  final String? message;
  final DateTime? reviewedAt;

  factory AdminUserApplicationSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserApplicationSummary(
      id: '${json['id'] ?? ''}',
      campaignId: '${json['campaignId'] ?? ''}',
      campaignTitle: '${json['campaignTitle'] ?? ''}',
      campaignStatus: '${json['campaignStatus'] ?? ''}',
      status: '${json['status'] ?? ''}',
      message: json['message']?.toString(),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reviewedAt: DateTime.tryParse('${json['reviewedAt'] ?? ''}'),
    );
  }
}

@immutable
class AdminUserDetail {
  const AdminUserDetail({
    required this.campaigns,
    required this.applications,
    required this.campaignsTotal,
    required this.applicationsTotal,
    required this.campaignsPage,
    required this.applicationsPage,
    required this.pageSize,
  });

  final List<AdminUserCampaignSummary> campaigns;
  final List<AdminUserApplicationSummary> applications;
  final int campaignsTotal;
  final int applicationsTotal;
  final int campaignsPage;
  final int applicationsPage;
  final int pageSize;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final camps = json['campaigns'];
    final apps = json['applications'];
    return AdminUserDetail(
      campaigns: camps is List
          ? camps
              .whereType<Map>()
              .map(
                (e) => AdminUserCampaignSummary.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      applications: apps is List
          ? apps
              .whereType<Map>()
              .map(
                (e) => AdminUserApplicationSummary.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      campaignsTotal: _asInt(json['campaignsTotal']),
      applicationsTotal: _asInt(json['applicationsTotal']),
      campaignsPage: _asInt(json['campaignsPage'] ?? 1),
      applicationsPage: _asInt(json['applicationsPage'] ?? 1),
      pageSize: _asInt(json['pageSize'] ?? 10),
    );
  }
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _asDouble(Object? v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
