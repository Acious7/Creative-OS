class NumberInWords {
  static final List<String> _units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static final List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String convert(double amount, {String currencyCode = 'KES'}) {
    if (amount.isNaN || amount.isInfinite) return '';
    
    final integerPart = amount.floor();
    final decimalPart = ((amount - integerPart) * 100).round();

    final currencyName = _getCurrencyName(currencyCode);
    final centName = _getCentName(currencyCode);

    if (integerPart == 0 && decimalPart == 0) {
      return '$currencyName Zero Only';
    }

    String words = '';
    if (integerPart > 0) {
      words = _convertChunk(integerPart);
    } else {
      words = 'Zero';
    }

    String result = '$currencyName $words';

    if (decimalPart > 0) {
      final centWords = _convertChunk(decimalPart);
      result += ' and $centName $centWords';
    }

    return '$result Only';
  }

  static String _convertChunk(int number) {
    if (number == 0) return '';
    if (number < 20) return _units[number];
    if (number < 100) {
      final ten = _tens[number ~/ 10];
      final unit = _units[number % 10];
      return unit.isNotEmpty ? '$ten-$unit' : ten;
    }
    if (number < 1000) {
      final hundred = '${_units[number ~/ 100]} Hundred';
      final remainder = number % 100;
      return remainder > 0 ? '$hundred ${_convertChunk(remainder)}' : hundred;
    }
    if (number < 1000000) {
      final thousand = '${_convertChunk(number ~/ 1000)} Thousand';
      final remainder = number % 1000;
      return remainder > 0 ? '$thousand ${_convertChunk(remainder)}' : thousand;
    }
    if (number < 1000000000) {
      final million = '${_convertChunk(number ~/ 1000000)} Million';
      final remainder = number % 1000000;
      return remainder > 0 ? '$million ${_convertChunk(remainder)}' : million;
    }
    final billion = '${_convertChunk(number ~/ 1000000000)} Billion';
    final remainder = number % 1000000000;
    return remainder > 0 ? '$billion ${_convertChunk(remainder)}' : billion;
  }

  static String _getCurrencyName(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'KES':
        return 'Kenya Shillings';
      case 'USD':
        return 'US Dollars';
      case 'EUR':
        return 'Euros';
      case 'GBP':
        return 'Pounds Sterling';
      default:
        return currencyCode;
    }
  }

  static String _getCentName(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'KES':
      case 'USD':
      case 'EUR':
        return 'Cents';
      case 'GBP':
        return 'Pence';
      default:
        return 'Cents';
    }
  }
}
