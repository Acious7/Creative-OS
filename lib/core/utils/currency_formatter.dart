import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
    double amount, {
    String currencyCode = 'KES',
    bool includeSymbol = true,
  }) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final formattedNumber = formatter.format(amount);

    if (!includeSymbol) return formattedNumber;

    switch (currencyCode.toUpperCase()) {
      case 'KES':
        return 'KES $formattedNumber';
      case 'USD':
        return '\$ $formattedNumber';
      case 'EUR':
        return '€ $formattedNumber';
      case 'GBP':
        return '£ $formattedNumber';
      default:
        return '$currencyCode $formattedNumber';
    }
  }

  static String symbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'KES':
        return 'KES';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currencyCode;
    }
  }
}
