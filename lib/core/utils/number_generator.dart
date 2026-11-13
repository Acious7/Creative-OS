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

    final String brandCode = getBrandCode(brandName);

    // Normalize docPrefix
    final String cleanPrefix = docPrefix.trim().toUpperCase();
    String typeCode = cleanPrefix;
    if (typeCode.startsWith('$brandCode-')) {
      typeCode = typeCode.substring(brandCode.length + 1);
    } else if (typeCode.startsWith('${brandCode}_')) {
      typeCode = typeCode.substring(brandCode.length + 1);
    }

    final String fullPrefix = cleanPrefix.isNotEmpty ? cleanPrefix : 'COS-DOC';

    // Normalize pattern
    String result = pattern.trim();
    if (result.isEmpty) {
      result = '{PREFIX}-{YEAR}-{NUM}';
    }

    // Replace all token permutations (case-insensitive where helpful)
    result = result
        .replaceAll(RegExp(r'\{PREFIX\}', caseSensitive: false), fullPrefix)
        .replaceAll(RegExp(r'\{PRE\}', caseSensitive: false), fullPrefix)
        .replaceAll(RegExp(r'\{NUM\}', caseSensitive: false), numStr)
        .replaceAll(RegExp(r'\{NUMBER\}', caseSensitive: false), numStr)
        .replaceAll(RegExp(r'\{COUNT\}', caseSensitive: false), numStr)
        .replaceAll(RegExp(r'\{BRAND\}', caseSensitive: false), brandCode)
        .replaceAll(RegExp(r'\{TYPE\}', caseSensitive: false), typeCode)
        .replaceAll(RegExp(r'\{YEAR\}', caseSensitive: false), yearFull)
        .replaceAll(RegExp(r'\{YYYY\}', caseSensitive: false), yearFull)
        .replaceAll(RegExp(r'\{YY\}', caseSensitive: false), yearShort)
        .replaceAll(RegExp(r'\{MONTH\}', caseSensitive: false), month)
        .replaceAll(RegExp(r'\{MM\}', caseSensitive: false), month);

    // Safety fallback: If any unreplaced braces remain or result is broken
    if (result.contains('{') || result.trim().isEmpty) {
      result = '$fullPrefix-$yearFull-$numStr';
    }

    return result;
  }

  static String getBrandCode(String brandName) {
    final clean = brandName.trim();
    if (clean.isEmpty) return 'COS';
    if (clean.toLowerCase().contains('creative') &&
        clean.toLowerCase().contains('os')) {
      return 'COS';
    }
    // Auto-extract first letter of each word or first 2 chars
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    } else if (clean.length >= 2) {
      return clean.substring(0, 2).toUpperCase();
    }
    return clean.toUpperCase();
  }
}
