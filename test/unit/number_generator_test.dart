import 'package:flutter_test/flutter_test.dart';
import 'package:creative_os/core/utils/number_generator.dart';

void main() {
  group('NumberGenerator Tests', () {
    test('formats sequence number correctly for Brian Etole (BE-QT-2026-001)', () {
      final formatted = NumberGenerator.formatNumber(
        pattern: '{BRAND}-{TYPE}-{YEAR}-{NUMBER}',
        brandName: 'Brian Etole',
        docPrefix: 'QT',
        number: 1,
        padding: 3,
        date: DateTime(2026, 1, 1),
      );

      expect(formatted, equals('BE-QT-2026-001'));
    });

    test('formats invoice and receipt numbers with BE prefix', () {
      final inv = NumberGenerator.formatNumber(
        pattern: '{BRAND}-{TYPE}-{YEAR}-{NUMBER}',
        brandName: 'Etole Studios',
        docPrefix: 'INV',
        number: 42,
        padding: 3,
        date: DateTime(2026, 5, 15),
      );
      expect(inv, equals('BE-INV-2026-042'));

      final rec = NumberGenerator.formatNumber(
        pattern: '{BRAND}-{TYPE}-{YEAR}-{NUMBER}',
        brandName: 'Brian Etole',
        docPrefix: 'REC',
        number: 5,
        padding: 3,
        date: DateTime(2026, 10, 1),
      );
      expect(rec, equals('BE-REC-2026-005'));
    });
  });
}
