import 'package:flutter_test/flutter_test.dart';
import 'package:crabihost/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('format produces standard currency format', () {
      expect(CurrencyFormatter.format(15000.0, currency: 'LKR'), 'Rs. 15,000.00');
      expect(CurrencyFormatter.format(120.50, currency: 'USD'), '\$ 120.50');
      expect(CurrencyFormatter.format(null), '—');
    });

    test('formatCompact produces readable abbreviations', () {
      expect(CurrencyFormatter.formatCompact(1500000.0, currency: 'LKR'), 'Rs. 1.5M');
      expect(CurrencyFormatter.formatCompact(25000.0, currency: 'LKR'), 'Rs. 25.0K');
      expect(CurrencyFormatter.formatCompact(500.0, currency: 'USD'), '\$ 500');
      expect(CurrencyFormatter.formatCompact(null), '—');
    });
  });
}
