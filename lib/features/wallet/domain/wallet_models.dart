import 'package:equatable/equatable.dart';

import '../../dashboard/domain/entities/advertiser_balance.dart';

/// PSP config from [GET /api/wallet/config](Wayo-ads).
final class WalletPspConfig extends Equatable {
  const WalletPspConfig({
    required this.pspMode,
    required this.isStripe,
    required this.publishableKey,
    required this.isTestMode,
    this.keysMismatch = false,
  });

  final String pspMode;
  final bool isStripe;
  final String? publishableKey;
  final bool isTestMode;
  /// Server `pk_*` and `sk_*` prefixes disagree (Apple Pay / cards may fail oddly).
  final bool keysMismatch;

  @override
  List<Object?> get props =>
      [pspMode, isStripe, publishableKey, isTestMode, keysMismatch];
}

/// Advertiser wallet top-up method — mirrors `WalletDepositMethod` in Wayo-ads.
abstract final class AdvertiserDepositMethod {
  static const String card = 'card';
  static const String ach = 'ach';
  static const String wire = 'wire';

  static String normalize(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == ach) return ach;
    if (v == wire) return wire;
    return card;
  }
}

/// One bank/wire routing address block — mirrors `BankTransferFundingInstructions.addresses`.
final class BankTransferAddress extends Equatable {
  const BankTransferAddress({
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

  factory BankTransferAddress.fromJson(Map<String, dynamic> json) {
    return BankTransferAddress(
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

  @override
  List<Object?> get props => [
    network,
    accountHolderName,
    bankName,
    accountNumber,
    routingNumber,
    sortCode,
    swiftCode,
    iban,
    bic,
    country,
  ];
}

/// Normalized bank-transfer / wire instructions — mirrors
/// `BankTransferFundingInstructions` in Wayo-ads `lib/finance/types.ts`.
final class BankTransferFundingInstructions extends Equatable {
  const BankTransferFundingInstructions({
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
  final List<BankTransferAddress> addresses;

  static BankTransferFundingInstructions? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final amountRemainingCents = json['amountRemainingCents'];
    final currency = json['currency'];
    if (amountRemainingCents == null || currency == null) return null;
    final addressesRaw = json['addresses'];
    final addresses = addressesRaw is List
        ? addressesRaw
            .whereType<Map>()
            .map((e) => BankTransferAddress.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <BankTransferAddress>[];
    return BankTransferFundingInstructions(
      amountRemainingCents: _asInt(amountRemainingCents),
      currency: '$currency'.toUpperCase(),
      reference: json['reference']?.toString(),
      hostedInstructionsUrl: json['hostedInstructionsUrl']?.toString(),
      transferType: json['transferType']?.toString(),
      addresses: addresses,
    );
  }

  @override
  List<Object?> get props => [
    amountRemainingCents,
    currency,
    reference,
    hostedInstructionsUrl,
    transferType,
    addresses,
  ];
}

/// Deposit intent from [POST /api/wallet/deposit-intent].
final class DepositIntentResult extends Equatable {
  const DepositIntentResult({
    required this.intentId,
    required this.clientSecret,
    required this.amountCents,
    required this.currency,
    required this.canSimulate,
    this.walletAmountCents,
    this.bankFeeCents,
    this.depositMethod = AdvertiserDepositMethod.card,
    this.bankTransferInstructions,
  });

  final String intentId;
  final String clientSecret;
  /// Total charged (wallet + bank fee).
  final int amountCents;
  final String currency;

  /// Dev mock PSP: use [simulate] instead of Stripe PaymentSheet.
  final bool canSimulate;

  final int? walletAmountCents;
  final int? bankFeeCents;

  /// `card` | `ach` | `wire` — see [AdvertiserDepositMethod].
  final String depositMethod;

  /// Present only for `wire` deposits — bank routing details to display.
  final BankTransferFundingInstructions? bankTransferInstructions;

  @override
  List<Object?> get props => [
    intentId,
    clientSecret,
    amountCents,
    currency,
    canSimulate,
    walletAmountCents,
    bankFeeCents,
    depositMethod,
    bankTransferInstructions,
  ];
}

/// One saved Stripe card — mirrors `SavedCardDto` from
/// `GET/POST /api/wallet/saved-cards*` (Wayo-ads).
final class WalletSavedCard extends Equatable {
  const WalletSavedCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
  });

  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  String get displayBrand {
    if (brand.isEmpty) return 'Card';
    return brand[0].toUpperCase() + brand.substring(1).toLowerCase();
  }

  String get expiryLabel =>
      '${expMonth.toString().padLeft(2, '0')}/${expYear.toString().padLeft(4, '0').substring(2)}';

  factory WalletSavedCard.fromJson(Map<String, dynamic> json) {
    return WalletSavedCard(
      id: '${json['id'] ?? ''}',
      brand: '${json['brand'] ?? ''}',
      last4: '${json['last4'] ?? ''}',
      expMonth: _asInt(json['expMonth']),
      expYear: _asInt(json['expYear']),
      isDefault: json['isDefault'] == true,
    );
  }

  /// Client-side safety net for accidental duplicates (server already
  /// dedupes by Stripe card fingerprint) — collapses same brand/last4/exp,
  /// preferring the default card.
  static List<WalletSavedCard> dedupe(List<WalletSavedCard> cards) {
    final byKey = <String, WalletSavedCard>{};
    for (final card in cards) {
      final key = '${card.brand.toLowerCase()}:${card.last4}:${card.expMonth}:${card.expYear}';
      final existing = byKey[key];
      if (existing == null || (card.isDefault && !existing.isDefault)) {
        byKey[key] = card;
      }
    }
    return byKey.values.toList();
  }

  @override
  List<Object?> get props => [id, brand, last4, expMonth, expYear, isDefault];
}

/// [GET /api/wallet/saved-cards] and [POST .../refresh] response.
final class SavedCardsResult extends Equatable {
  const SavedCardsResult({
    required this.cards,
    required this.projectionInitialized,
    required this.syncStatus,
    this.stripeStatusUpdatedAt,
  });

  final List<WalletSavedCard> cards;
  final bool projectionInitialized;
  final String syncStatus;
  final DateTime? stripeStatusUpdatedAt;

  factory SavedCardsResult.fromJson(Map<String, dynamic> json) {
    final raw = json['cards'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => WalletSavedCard.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <WalletSavedCard>[];
    return SavedCardsResult(
      cards: WalletSavedCard.dedupe(list),
      projectionInitialized: json['projectionInitialized'] == true,
      syncStatus: '${json['syncStatus'] ?? 'NEVER_SYNCED'}',
      stripeStatusUpdatedAt: json['stripeStatusUpdatedAt'] == null
          ? null
          : DateTime.tryParse('${json['stripeStatusUpdatedAt']}'),
    );
  }

  static const empty = SavedCardsResult(
    cards: [],
    projectionInitialized: false,
    syncStatus: 'NEVER_SYNCED',
  );

  @override
  List<Object?> get props => [cards, projectionInitialized, syncStatus, stripeStatusUpdatedAt];
}

/// One ACH deposit awaiting bank debit settlement (few business days).
final class AchProcessingDeposit extends Equatable {
  const AchProcessingDeposit({
    required this.intentId,
    required this.amountCents,
    required this.currency,
    this.createdAt,
  });

  final String intentId;
  final int amountCents;
  final String currency;
  final DateTime? createdAt;

  factory AchProcessingDeposit.fromJson(Map<String, dynamic> json) {
    return AchProcessingDeposit(
      intentId: '${json['intentId'] ?? ''}',
      amountCents: _asInt(json['amountCents']),
      currency: '${json['currency'] ?? 'USD'}'.toUpperCase(),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    );
  }

  @override
  List<Object?> get props => [intentId, amountCents, currency, createdAt];
}

/// One wire/bank-transfer deposit awaiting the advertiser's bank transfer.
final class WireAwaitingDeposit extends Equatable {
  const WireAwaitingDeposit({
    required this.intentId,
    required this.amountCents,
    required this.currency,
    this.createdAt,
    this.reference,
    this.bankTransferInstructions,
  });

  final String intentId;
  final int amountCents;
  final String currency;
  final DateTime? createdAt;
  final String? reference;
  final BankTransferFundingInstructions? bankTransferInstructions;

  factory WireAwaitingDeposit.fromJson(Map<String, dynamic> json) {
    return WireAwaitingDeposit(
      intentId: '${json['intentId'] ?? ''}',
      amountCents: _asInt(json['amountCents']),
      currency: '${json['currency'] ?? 'USD'}'.toUpperCase(),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      reference: json['reference']?.toString(),
      bankTransferInstructions:
          BankTransferFundingInstructions.tryParse(json['bankTransferInstructions']),
    );
  }

  @override
  List<Object?> get props =>
      [intentId, amountCents, currency, createdAt, reference, bankTransferInstructions];
}

final class WalletTransactionRow extends Equatable {
  const WalletTransactionRow({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.currency,
    required this.description,
    required this.createdAt,
    this.status,
    this.stripeFeeCents,
    this.chargedCents,
  });

  final String id;
  final String type;
  final int amountCents;
  final String currency;
  final String description;
  final DateTime? createdAt;
  final String? status;

  /// Actual Stripe processing fee from payment audit (web parity).
  final int? stripeFeeCents;

  /// Gross amount charged to the payment method (web parity).
  final int? chargedCents;

  @override
  List<Object?> get props => [
    id,
    type,
    amountCents,
    currency,
    description,
    createdAt,
    status,
    stripeFeeCents,
    chargedCents,
  ];
}

/// In-progress deposit from [GET /api/wallet/deposit-intent](Wayo-ads).
final class AdvertiserPendingDeposit extends Equatable {
  const AdvertiserPendingDeposit({
    required this.intentId,
    required this.clientSecret,
    required this.walletAmountCents,
    required this.bankFeeCents,
    required this.totalAmountCents,
    required this.currency,
    this.depositMethod = AdvertiserDepositMethod.card,
    this.bankTransferInstructions,
  });

  final String intentId;
  final String clientSecret;
  final int walletAmountCents;
  final int bankFeeCents;
  final int totalAmountCents;
  final String currency;
  final String depositMethod;
  final BankTransferFundingInstructions? bankTransferInstructions;

  @override
  List<Object?> get props => [
    intentId,
    clientSecret,
    walletAmountCents,
    bankFeeCents,
    totalAmountCents,
    currency,
    depositMethod,
    bankTransferInstructions,
  ];
}

/// Full snapshot from [GET /api/wallet/deposit-intent] — a single in-progress
/// card/ACH checkout plus any ACH-processing / wire-awaiting deposits.
final class AdvertiserPendingDepositsSnapshot extends Equatable {
  const AdvertiserPendingDepositsSnapshot({
    this.pending,
    this.achProcessing = const [],
    this.wireAwaiting = const [],
  });

  final AdvertiserPendingDeposit? pending;
  final List<AchProcessingDeposit> achProcessing;
  final List<WireAwaitingDeposit> wireAwaiting;

  static const empty = AdvertiserPendingDepositsSnapshot();

  bool get isEmpty =>
      pending == null && achProcessing.isEmpty && wireAwaiting.isEmpty;

  @override
  List<Object?> get props => [pending, achProcessing, wireAwaiting];
}

/// [GET /api/wallet] — balance, history, simulation flag.
final class AdvertiserWalletPageData extends Equatable {
  const AdvertiserWalletPageData({
    required this.balance,
    required this.transactions,
    required this.canSimulate,
  });

  final AdvertiserBalance balance;
  final List<WalletTransactionRow> transactions;
  final bool canSimulate;

  @override
  List<Object?> get props => [
    balance,
    transactions,
    canSimulate,
  ];
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}
