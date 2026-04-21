import 'package:intl/intl.dart';

/// Currency formatting for dashboard balances.
abstract final class MoneyFormatter {
  static String format(
    double amount, {
    String currency = 'EUR',
    String locale = 'fr_FR',
  }) {
    final symbol = _symbol(currency);
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    );
    return fmt.format(amount);
  }

  static String _symbol(String c) => switch (c.toUpperCase()) {
        'EUR' => '€',
        'USD' => r'$',
        'GBP' => '£',
        'TND' => 'DT',
        _ => c,
      };
}
