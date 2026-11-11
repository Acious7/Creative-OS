import 'package:flutter_test/flutter_test.dart';
import 'package:creative_os/core/database/app_database.dart';
import 'package:creative_os/features/digital_cards/domain/vcard_builder.dart';

void main() {
  group('VCardBuilder Tests', () {
    test('generates valid vCard 3.0 specification string', () {
      final card = BusinessCard(
        id: 1,
        brandId: 1,
        cardTitle: 'Filmmaker Card',
        personName: 'Brian Etole',
        personRole: 'Hybrid Filmmaker & Photographer',
        companyName: 'Brian Etole Studios',
        tagline: 'REAL STORIES. IMAGINED WORLDS.',
        primaryPhone: '+254700000000',
        email: 'hello@brianetole.com',
        website: 'https://brianetole.com',
        isDefault: true,
        designStyle: 'ember',
        defaultQrMode: 'vCard',
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = VCardBuilder.buildVCard(card);

      expect(result.vCardString, contains('BEGIN:VCARD'));
      expect(result.vCardString, contains('VERSION:3.0'));
      expect(result.vCardString, contains('FN:Brian Etole'));
      expect(result.vCardString, contains('TITLE:Hybrid Filmmaker & Photographer'));
      expect(result.vCardString, contains('EMAIL;TYPE=INTERNET:hello@brianetole.com'));
      expect(result.vCardString, contains('URL:https://brianetole.com'));
      expect(result.vCardString, contains('END:VCARD'));
    });
  });
}
