import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/advertiser_creators/domain/advertiser_creator.dart';
import 'package:wayoadsgo/features/wallet/domain/wallet_models.dart';

void main() {
  group('AdvertiserCreatorsPage.fromJson', () {
    test('parses creators page', () {
      final page = AdvertiserCreatorsPage.fromJson({
        'page': 2,
        'totalPages': 5,
        'totalCount': 40,
        'creators': [
          {
            'trustScore': 88,
            'views': 10,
            'clicks': 2,
            'earningsGenerated': 1500,
            'creator': {
              'id': 'c1',
              'name': 'Alex',
              'image': 'https://example.com/a.png',
            },
            'campaigns': [
              {'title': 'Summer'},
              {'title': 'Fall'},
            ],
          },
        ],
      });

      expect(page.page, 2);
      expect(page.totalPages, 5);
      expect(page.totalCount, 40);
      expect(page.creators, hasLength(1));
      expect(page.creators.first.creatorId, 'c1');
      expect(page.creators.first.name, 'Alex');
      expect(page.creators.first.trustScore, 88);
      expect(page.creators.first.campaigns, ['Summer', 'Fall']);
    });
  });

  group('WalletSavedCard', () {
    test('fromJson + dedupe', () {
      final a = WalletSavedCard.fromJson({
        'id': 'pm_1',
        'brand': 'visa',
        'last4': '4242',
        'expMonth': 12,
        'expYear': 2030,
        'isDefault': true,
      });
      final b = WalletSavedCard.fromJson({
        'id': 'pm_2',
        'brand': 'visa',
        'last4': '4242',
        'expMonth': 12,
        'expYear': 2030,
        'isDefault': false,
      });
      expect(a.displayBrand, 'Visa');
      expect(WalletSavedCard.dedupe([a, b]), hasLength(1));
    });
  });
}
