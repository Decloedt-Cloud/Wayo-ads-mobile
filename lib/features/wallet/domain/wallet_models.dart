import 'package:equatable/equatable.dart';

import '../../dashboard/domain/entities/advertiser_balance.dart';

/// PSP config from [GET /api/wallet/config](Wayo-ads).
final class WalletPspConfig extends Equatable {
  const WalletPspConfig({
    required this.pspMode,
    required this.isStripe,
    required this.publishableKey,
    required this.isTestMode,
  });

  final String pspMode;
  final bool isStripe;
  final String? publishableKey;
  final bool isTestMode;

  @override
  List<Object?> get props => [pspMode, isStripe, publishableKey, isTestMode];
}

/// Deposit intent from [POST /api/wallet/deposit-intent].
final class DepositIntentResult extends Equatable {
  const DepositIntentResult({
    required this.intentId,
    required this.clientSecret,
    required this.amountCents,
    required this.currency,
    required this.canSimulate,
  });

  final String intentId;
  final String clientSecret;
  final int amountCents;
  final String currency;

  /// Dev mock PSP: use [simulate] instead of Stripe PaymentSheet.
  final bool canSimulate;

  @override
  List<Object?> get props => [
    intentId,
    clientSecret,
    amountCents,
    currency,
    canSimulate,
  ];
}

final class WalletTransactionRow extends Equatable {
  const WalletTransactionRow({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.currency,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String type;
  final int amountCents;
  final String currency;
  final String description;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    type,
    amountCents,
    currency,
    description,
    createdAt,
  ];
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
