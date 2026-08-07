import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/wallet/domain/wallet_models.dart';

void main() {
  group('AdvertiserDepositMethod.normalize', () {
    test('recognizes ach and wire, defaults to card', () {
      expect(AdvertiserDepositMethod.normalize('ACH'), 'ach');
      expect(AdvertiserDepositMethod.normalize('wire'), 'wire');
      expect(AdvertiserDepositMethod.normalize('card'), 'card');
      expect(AdvertiserDepositMethod.normalize('bogus'), 'card');
      expect(AdvertiserDepositMethod.normalize(null), 'card');
    });
  });

  group('WalletSavedCard.fromJson', () {
    test('parses brand/last4/expiry and default flag', () {
      final card = WalletSavedCard.fromJson({
        'id': 'pm_1',
        'brand': 'visa',
        'last4': '4242',
        'expMonth': 4,
        'expYear': 2030,
        'isDefault': true,
      });

      expect(card.id, 'pm_1');
      expect(card.displayBrand, 'Visa');
      expect(card.expiryLabel, '04/30');
      expect(card.isDefault, isTrue);
    });

    test('displayBrand falls back to Card when brand is empty', () {
      final card = WalletSavedCard.fromJson({
        'id': 'pm_2',
        'last4': '0000',
        'expMonth': 1,
        'expYear': 2027,
      });
      expect(card.displayBrand, 'Card');
      expect(card.isDefault, isFalse);
    });
  });

  group('WalletSavedCard.dedupe', () {
    test('collapses duplicates and prefers the default card', () {
      const a = WalletSavedCard(
        id: 'pm_a',
        brand: 'visa',
        last4: '4242',
        expMonth: 4,
        expYear: 2030,
        isDefault: false,
      );
      const b = WalletSavedCard(
        id: 'pm_b',
        brand: 'VISA',
        last4: '4242',
        expMonth: 4,
        expYear: 2030,
        isDefault: true,
      );
      const c = WalletSavedCard(
        id: 'pm_c',
        brand: 'mastercard',
        last4: '4444',
        expMonth: 8,
        expYear: 2028,
        isDefault: false,
      );

      final result = WalletSavedCard.dedupe([a, b, c]);

      expect(result, hasLength(2));
      final visa = result.firstWhere((e) => e.brand.toLowerCase() == 'visa');
      expect(visa.id, 'pm_b');
      expect(visa.isDefault, isTrue);
    });
  });

  group('SavedCardsResult.fromJson', () {
    test('dedupes cards and parses sync metadata', () {
      final result = SavedCardsResult.fromJson({
        'cards': [
          {
            'id': 'pm_1',
            'brand': 'visa',
            'last4': '4242',
            'expMonth': 4,
            'expYear': 2030,
            'isDefault': true,
          },
          {
            'id': 'pm_2',
            'brand': 'visa',
            'last4': '4242',
            'expMonth': 4,
            'expYear': 2030,
            'isDefault': false,
          },
        ],
        'projectionInitialized': true,
        'syncStatus': 'SYNCED',
        'stripeStatusUpdatedAt': '2026-08-01T10:00:00.000Z',
      });

      expect(result.cards, hasLength(1));
      expect(result.projectionInitialized, isTrue);
      expect(result.syncStatus, 'SYNCED');
      expect(result.stripeStatusUpdatedAt, isNotNull);
    });

    test('empty constant has no cards and NEVER_SYNCED status', () {
      expect(SavedCardsResult.empty.cards, isEmpty);
      expect(SavedCardsResult.empty.syncStatus, 'NEVER_SYNCED');
    });
  });

  group('BankTransferFundingInstructions.tryParse', () {
    test('parses addresses and normalizes currency', () {
      final instr = BankTransferFundingInstructions.tryParse({
        'amountRemainingCents': 150000,
        'currency': 'usd',
        'reference': 'WAYO-REF-1',
        'transferType': 'us_bank_transfer',
        'addresses': [
          {
            'network': 'ach',
            'bankName': 'Example Bank',
            'accountNumber': '000123456789',
            'routingNumber': '110000000',
          },
        ],
      });

      expect(instr, isNotNull);
      expect(instr!.currency, 'USD');
      expect(instr.amountRemainingCents, 150000);
      expect(instr.addresses, hasLength(1));
      expect(instr.addresses.first.bankName, 'Example Bank');
    });

    test('returns null when amountRemainingCents or currency is missing', () {
      expect(BankTransferFundingInstructions.tryParse(null), isNull);
      expect(BankTransferFundingInstructions.tryParse('nope'), isNull);
      expect(
        BankTransferFundingInstructions.tryParse({'currency': 'usd'}),
        isNull,
      );
    });
  });

  group('AchProcessingDeposit.fromJson', () {
    test('parses intent/amount/currency', () {
      final d = AchProcessingDeposit.fromJson({
        'intentId': 'pi_ach_1',
        'amountCents': 5000,
        'currency': 'usd',
        'createdAt': '2026-08-01T10:00:00.000Z',
      });

      expect(d.intentId, 'pi_ach_1');
      expect(d.amountCents, 5000);
      expect(d.currency, 'USD');
      expect(d.createdAt, isNotNull);
    });
  });

  group('WireAwaitingDeposit.fromJson', () {
    test('parses nested bankTransferInstructions', () {
      final d = WireAwaitingDeposit.fromJson({
        'intentId': 'pi_wire_1',
        'amountCents': 200000,
        'currency': 'usd',
        'reference': 'WAYO-REF-9',
        'bankTransferInstructions': {
          'amountRemainingCents': 200000,
          'currency': 'usd',
          'addresses': [],
        },
      });

      expect(d.intentId, 'pi_wire_1');
      expect(d.reference, 'WAYO-REF-9');
      expect(d.bankTransferInstructions, isNotNull);
      expect(d.bankTransferInstructions!.amountRemainingCents, 200000);
    });

    test('bankTransferInstructions is null when absent', () {
      final d = WireAwaitingDeposit.fromJson({
        'intentId': 'pi_wire_2',
        'amountCents': 1000,
        'currency': 'usd',
      });
      expect(d.bankTransferInstructions, isNull);
    });
  });

  group('AdvertiserPendingDepositsSnapshot', () {
    test('isEmpty is true only when pending/ach/wire are all empty', () {
      expect(AdvertiserPendingDepositsSnapshot.empty.isEmpty, isTrue);

      const withAch = AdvertiserPendingDepositsSnapshot(
        achProcessing: [
          AchProcessingDeposit(intentId: 'pi_1', amountCents: 100, currency: 'USD'),
        ],
      );
      expect(withAch.isEmpty, isFalse);

      const withPending = AdvertiserPendingDepositsSnapshot(
        pending: AdvertiserPendingDeposit(
          intentId: 'pi_2',
          clientSecret: 'secret',
          walletAmountCents: 100,
          bankFeeCents: 0,
          totalAmountCents: 100,
          currency: 'USD',
        ),
      );
      expect(withPending.isEmpty, isFalse);
    });
  });
}
