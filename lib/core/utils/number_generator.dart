class NumberGenerator {
  static String formatNumber({
    required String pattern,
    required String brandName,
    required String docPrefix,
    required int number,
    required int padding,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final yearFull = now.year.toString();
    final yearShort = (now.year % 100).toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final numStr = number.toString().padLeft(padding, '0');

    String brandCode = getBrandCode(brandName);

    String result = pattern
        .replaceAll('{BRAND}', brandCode)
        .replaceAll('{TYPE}', docPrefix.toUpperCase())
        .replaceAll('{YEAR}', yearFull)
        .replaceAll('{YY}', yearShort)
        .replaceAll('{MONTH}', month)
        .replaceAll('{NUMBER}', numStr);

    return result;
  }

  static String getBrandCode(String brandName) {
    final clean = brandName.trim();
    if (clean.toLowerCase().contains('etole') || clean.toLowerCase().contains('brian')) {
      return 'BE';
    } else {
      // Auto-extract first letter of each word or first 2 chars
      final words = clean.split(RegExp(r'\s+'));
      if (words.length >= 2) {
        return (words[0][0] + words[1][0]).toUpperCase();
      } else if (clean.length >= 2) {
        return clean.substring(0, 2).toUpperCase();
      }
      return clean.toUpperCase();
    }
  }
}
