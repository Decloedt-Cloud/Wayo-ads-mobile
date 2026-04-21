import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/format/money_formatter.dart';

void main() {
  test('formats EUR fr / en / ar locales', () {
    expect(
      MoneyFormatter.format(1234.5, currency: 'EUR', locale: 'fr_FR'),
      contains('1'),
    );
    expect(
      MoneyFormatter.format(99.99, currency: 'EUR', locale: 'en_US'),
      contains('99'),
    );
    expect(
      MoneyFormatter.format(10, currency: 'EUR', locale: 'ar_SA'),
      isNotEmpty,
    );
  });

  test('USD symbol', () {
    final s = MoneyFormatter.format(5, currency: 'USD', locale: 'en_US');
    expect(s, contains(r'$'));
  });
}
