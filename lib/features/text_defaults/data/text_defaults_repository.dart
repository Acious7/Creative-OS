import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

final textDefaultsRepositoryProvider = Provider<TextDefaultsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TextDefaultsRepository(db);
});

class TextDefaultsRepository {
  final AppDatabase _db;

  TextDefaultsRepository(this._db);

  Future<TextDefault?> getDefaultsForDocType(
    int brandId,
    String docType,
  ) async {
    return (_db.select(_db.textDefaults)
          ..where((t) => t.brandId.equals(brandId) & t.docType.equals(docType)))
        .getSingleOrNull();
  }

  Future<void> saveOrUpdateDefaults({
    required int brandId,
    required String docType,
    String? titleOverride,
    String? introText,
    String? closingNotes,
    String? termsConditions,
    String? footerOverride,
  }) async {
    final existing = await getDefaultsForDocType(brandId, docType);
    if (existing == null) {
      await _db
          .into(_db.textDefaults)
          .insert(
            TextDefaultsCompanion.insert(
              brandId: brandId,
              docType: docType,
              titleOverride: titleOverride != null
                  ? drift.Value(titleOverride)
                  : const drift.Value.absent(),
              introText: introText != null
                  ? drift.Value(introText)
                  : const drift.Value.absent(),
              closingNotes: closingNotes != null
                  ? drift.Value(closingNotes)
                  : const drift.Value.absent(),
              termsConditions: termsConditions != null
                  ? drift.Value(termsConditions)
                  : const drift.Value.absent(),
              footerOverride: footerOverride != null
                  ? drift.Value(footerOverride)
                  : const drift.Value.absent(),
            ),
          );
    } else {
      await (_db.update(
        _db.textDefaults,
      )..where((t) => t.id.equals(existing.id))).write(
        TextDefaultsCompanion(
          titleOverride: drift.Value(titleOverride),
          introText: drift.Value(introText),
          closingNotes: drift.Value(closingNotes),
          termsConditions: drift.Value(termsConditions),
          footerOverride: drift.Value(footerOverride),
        ),
      );
    }
  }
}
