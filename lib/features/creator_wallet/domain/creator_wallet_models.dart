import 'package:equatable/equatable.dart';

/// Withdrawable + pending balance for a creator — `GET /api/creator/withdrawal`.
///
/// Amounts are kept in **cents** (server is source of truth). UI converts only
/// at display time (via `MoneyFormatter`).
final class CreatorBalance extends Equatable {
  const CreatorBalance({
    required this.availableCents,
    required this.pendingCents,
    required this.totalEarnedCents,
    required this.currency,
    this.payoutDelayDays,
    this.lockedReserveCents,
    this.riskLevel,
  });

  /// Funds ready to withdraw.
  final int availableCents;

  /// Funds accruing (not yet past the hold window).
  final int pendingCents;

  /// Lifetime earnings, cumulative.
  final int totalEarnedCents;

  /// ISO 4217 currency code (`EUR`, `USD`, ...).
  final String currency;

  /// Days a pending credit must age before it becomes available.
  final int? payoutDelayDays;

  /// Funds held due to risk/fraud reasons (rare — admin-controlled).
  final int? lockedReserveCents;

  /// `low` | `medium` | `high` — affects holding windows.
  final String? riskLevel;

  static CreatorBalance empty({String currency = 'EUR'}) => CreatorBalance(
    availableCents: 0,
    pendingCents: 0,
    totalEarnedCents: 0,
    currency: currency,
  );

  factory CreatorBalance.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String? asNStr(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;

    return CreatorBalance(
      availableCents: asInt(json['availableCents']),
      pendingCents: asInt(json['pendingCents']),
      totalEarnedCents: asInt(json['totalEarnedCents']),
      currency:
          (json['currency'] as String?)?.trim().toUpperCase().isNotEmpty == true
          ? (json['currency'] as String).toUpperCase()
          : 'EUR',
      payoutDelayDays: json['payoutDelayDays'] is int
          ? json['payoutDelayDays'] as int
          : (json['payoutDelayDays'] as num?)?.toInt(),
      lockedReserveCents: json['lockedReserveCents'] == null
          ? null
          : asInt(json['lockedReserveCents']),
      riskLevel: asNStr(json['riskLevel']),
    );
  }

  double get available => availableCents / 100.0;
  double get pending => pendingCents / 100.0;
  double get totalEarned => totalEarnedCents / 100.0;

  @override
  List<Object?> get props => [
    availableCents,
    pendingCents,
    totalEarnedCents,
    currency,
    payoutDelayDays,
    lockedReserveCents,
    riskLevel,
  ];
}

/// Platform-level withdrawal rules (returned alongside the balance).
final class CreatorPlatformLimits extends Equatable {
  const CreatorPlatformLimits({
    required this.minimumWithdrawalCents,
    required this.pendingHoldDays,
    required this.defaultCurrency,
    required this.platformFeeRate,
    this.platformFeeDescription,
  });

  final int minimumWithdrawalCents;
  final int pendingHoldDays;
  final String defaultCurrency;
  final double platformFeeRate;
  final String? platformFeeDescription;

  static const CreatorPlatformLimits fallback = CreatorPlatformLimits(
    minimumWithdrawalCents: 5000,
    pendingHoldDays: 7,
    defaultCurrency: 'EUR',
    platformFeeRate: 0,
  );

  factory CreatorPlatformLimits.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return CreatorPlatformLimits(
      minimumWithdrawalCents: asInt(
        json['minimumWithdrawalCents'] ?? fallback.minimumWithdrawalCents,
      ),
      pendingHoldDays: asInt(
        json['pendingHoldDays'] ?? fallback.pendingHoldDays,
      ),
      defaultCurrency:
          (json['defaultCurrency'] as String?)?.toUpperCase() ?? 'EUR',
      platformFeeRate: asDouble(json['platformFeeRate']),
      platformFeeDescription: json['platformFeeDescription'] as String?,
    );
  }

  double get minimumWithdrawal => minimumWithdrawalCents / 100.0;

  @override
  List<Object?> get props => [
    minimumWithdrawalCents,
    pendingHoldDays,
    defaultCurrency,
    platformFeeRate,
    platformFeeDescription,
  ];
}

/// A single payout row from `GET /api/creator/withdrawal`.
final class CreatorWithdrawal extends Equatable {
  const CreatorWithdrawal({
    required this.id,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.platformFeeCents,
    this.grossAmountCentsFromApi,
    this.psReference,
    this.failureReason,
    this.processedAt,
  });

  final String id;
  final int amountCents;
  final String currency;
  final CreatorWithdrawalStatus status;
  final DateTime createdAt;
  final int? platformFeeCents;
  /// When the API sends gross explicitly (`grossAmountCents`, `amountGrossCents`).
  final int? grossAmountCentsFromApi;
  final String? psReference;
  final String? failureReason;
  final DateTime? processedAt;

  factory CreatorWithdrawal.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    int? asOptionalPositiveInt(dynamic v) {
      if (v == null) return null;
      final n = asInt(v);
      return n > 0 ? n : null;
    }

    DateTime? parseDate(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

    final grossRaw =
        json['grossAmountCents'] ?? json['amountGrossCents'];

    return CreatorWithdrawal(
      id: (json['id'] as String?) ?? '',
      amountCents: asInt(json['amountCents']),
      currency:
          (json['currency'] as String?)?.toUpperCase().trim().isNotEmpty == true
          ? (json['currency'] as String).toUpperCase()
          : 'EUR',
      status: CreatorWithdrawalStatus.fromApi(json['status']),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      platformFeeCents: json['platformFeeCents'] == null
          ? null
          : asInt(json['platformFeeCents']),
      grossAmountCentsFromApi: asOptionalPositiveInt(grossRaw),
      psReference: json['psReference'] as String?,
      failureReason: json['failureReason'] as String?,
      processedAt: parseDate(json['processedAt']),
    );
  }

  double get amount => amountCents / 100.0;

  /// **Gross** withdrawal (before platform fee) for payout history UI.
  ///
  /// Prefer an explicit API field when present; otherwise assume [amountCents]
  /// is **net** and add [platformFeeCents] (when fee is known).
  int get payoutHistoryGrossCents {
    if (grossAmountCentsFromApi != null) return grossAmountCentsFromApi!;
    final fee = platformFeeCents ?? 0;
    return amountCents + fee;
  }

  double get payoutHistoryGross => payoutHistoryGrossCents / 100.0;

  @override
  List<Object?> get props => [
    id,
    amountCents,
    currency,
    status,
    createdAt,
    platformFeeCents,
    grossAmountCentsFromApi,
    psReference,
    failureReason,
    processedAt,
  ];
}

enum CreatorWithdrawalStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  unknown;

  static CreatorWithdrawalStatus fromApi(dynamic raw) {
    final s = (raw as String?)?.trim().toUpperCase() ?? '';
    return switch (s) {
      'PENDING' => CreatorWithdrawalStatus.pending,
      'PROCESSING' => CreatorWithdrawalStatus.processing,
      'SUCCEEDED' ||
      'SUCCESS' ||
      'COMPLETED' => CreatorWithdrawalStatus.succeeded,
      'FAILED' || 'ERROR' => CreatorWithdrawalStatus.failed,
      'CANCELLED' || 'CANCELED' => CreatorWithdrawalStatus.cancelled,
      _ => CreatorWithdrawalStatus.unknown,
    };
  }
}

/// Merged payload exposed to the UI — one provider call → one screen render.
final class CreatorWalletPage extends Equatable {
  const CreatorWalletPage({
    required this.balance,
    required this.limits,
    required this.withdrawals,
    required this.canSimulate,
  });

  final CreatorBalance balance;
  final CreatorPlatformLimits limits;
  final List<CreatorWithdrawal> withdrawals;
  final bool canSimulate;

  static const CreatorWalletPage empty = CreatorWalletPage(
    balance: CreatorBalance(
      availableCents: 0,
      pendingCents: 0,
      totalEarnedCents: 0,
      currency: 'EUR',
    ),
    limits: CreatorPlatformLimits.fallback,
    withdrawals: [],
    canSimulate: false,
  );

  @override
  List<Object?> get props => [balance, limits, withdrawals, canSimulate];
}

/// `GET /api/creator/stripe-connect/status` — is the creator onboarded?
final class CreatorStripeStatus extends Equatable {
  const CreatorStripeStatus({
    required this.connected,
    required this.onboardingCompleted,
    required this.chargesEnabled,
    required this.payoutsEnabled,
    required this.requirementsDue,
    this.accountId,
    this.accountStatus,
  });

  final bool connected;
  final bool onboardingCompleted;
  final bool chargesEnabled;
  final bool payoutsEnabled;
  final bool requirementsDue;
  final String? accountId;
  final String? accountStatus;

  static const CreatorStripeStatus disconnected = CreatorStripeStatus(
    connected: false,
    onboardingCompleted: false,
    chargesEnabled: false,
    payoutsEnabled: false,
    requirementsDue: false,
  );

  factory CreatorStripeStatus.fromJson(Map<String, dynamic> json) {
    final id = json['stripeAccountId'] as String?;
    return CreatorStripeStatus(
      connected: id != null && id.isNotEmpty,
      onboardingCompleted: json['stripeOnboardingCompleted'] == true,
      chargesEnabled: json['stripeChargesEnabled'] == true,
      payoutsEnabled: json['stripePayoutsEnabled'] == true,
      requirementsDue: json['requirementsDue'] == true,
      accountId: id,
      accountStatus: json['stripeAccountStatus'] as String?,
    );
  }

  /// Creator can actually request a payout.
  bool get canWithdraw =>
      connected && onboardingCompleted && payoutsEnabled && !requirementsDue;

  @override
  List<Object?> get props => [
    connected,
    onboardingCompleted,
    chargesEnabled,
    payoutsEnabled,
    requirementsDue,
    accountId,
    accountStatus,
  ];
}
