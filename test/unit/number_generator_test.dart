import 'package:flutter_test/flutter_test.dart';
import 'package:creative_os/core/utils/number_generator.dart';

void main() {
  group('NumberGenerator Tests', () {
    test('formats sequence number correctly for Creative OS (COS-QT-2026-001)', () {
      final formatted = NumberGenerator.formatNumber(
        pattern: '{BRAND}-{TYPE}-{YEAR}-{NUMBER}',
        brandName: 'Creative OS',
        docPrefix: 'QT',
        number: 1,
        padding: 3,
        date: DateTime(2026, 1, 1),
      );

      expect(formatted, equals('COS-QT-2026-001'));
    });

    test('formats invoice and receipt numbers with COS and generic prefixes', () {
      final inv = NumberGenerator.formatNumber(
        pattern: '{PREFIX}-{YEAR}-{NUM}',
        brandName: 'Creative OS',
        docPrefix: 'COS-INV',
        number: 42,
        padding: 3,
        date: DateTime(2026, 5, 15),
      );
      expect(inv, equals('COS-INV-2026-042'));

      final rec = NumberGenerator.formatNumber(
        pattern: '{PREFIX}-{NUM}',
        brandName: 'Creative Studio',
        docPrefix: 'COS-REC',
        number: 5,
        padding: 4,
        date: DateTime(2026, 10, 1),
      );
      expect(rec, equals('COS-REC-0005'));
    });
  });
}
