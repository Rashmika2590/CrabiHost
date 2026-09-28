import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double? amount, {String currency = 'LKR'}) {
    if (amount == null) return '—';
    final formatter = NumberFormat.currency(
      symbol: _symbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatCompact(double? amount, {String currency = 'LKR'}) {
    if (amount == null) return '—';
    final symbol = _symbol(currency);
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String _symbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'LKR':
        return 'Rs. ';
      case 'USD':
        return '\$ ';
      case 'EUR':
        return '€ ';
      case 'GBP':
        return '£ ';
      default:
        return '$currency ';
    }
  }
}
