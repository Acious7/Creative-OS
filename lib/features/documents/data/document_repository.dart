import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/document_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/utils/number_generator.dart';
import '../domain/models/proposal_options.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DocumentRepository(db);
});

class CompleteDocument {
  final Document document;
  final Brand brand;
  final Client? client;
  final List<DocumentItem> items;
  final List<CustomFieldWithValue> customFields;
  final List<DocumentAttachment> attachments;
  final List<DocumentActivityLog> activityLogs;
  final PaymentProfile? paymentProfile;

  CompleteDocument({
    required this.document,
    required this.brand,
    this.client,
    required this.items,
    this.customFields = const [],
    required this.attachments,
    required this.activityLogs,
    this.paymentProfile,
  });
}

class CustomFieldDefinition {
  final String fieldLabel;
  CustomFieldDefinition({required this.fieldLabel});
}

class CustomFieldWithValue {
  final CustomFieldDefinition definition;
  final String? value;

  CustomFieldWithValue({required this.definition, this.value});
}

class DocumentRepository {
  final AppDatabase _db;

  DocumentRepository(this._db);

  // Watch recent documents for brand
  Stream<List<DocumentWithClient>> watchRecentDocuments(
    int brandId, {
    int limit = 50,
  }) {
    return (_db.select(_db.documents)
          ..where((t) => t.brandId.equals(brandId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .watch()
        .asyncMap((docs) async {
          try {
            final clientIds = docs
                .map((d) => d.clientId)
                .whereType<int>()
                .toSet();
            final clients = clientIds.isEmpty
                ? <int, Client>{}
                : Map.fromEntries(
                    (await (_db.select(
                      _db.clients,
                    )..where((t) => t.id.isIn(clientIds))).get()).map(
                      (c) => MapEntry(c.id, c),
                    ),
                  );
            return docs
                .map(
                  (doc) => DocumentWithClient(
                    document: doc,
                    client: doc.clientId != null ? clients[doc.clientId] : null,
                  ),
                )
                .toList();
          } catch (e) {
            return docs
                .map((doc) => DocumentWithClient(document: doc, client: null))
                .toList();
          }
        });
  }

  // Watch count metrics (Counts ONLY, NO money totals as per Rule 8)
  Stream<DocumentMetrics> watchBrandMetrics(int brandId) {
    final now = DateTime.now();
    final query = _db.select(_db.documents)
      ..where((tbl) => tbl.brandId.equals(brandId));

    return query.watch().map((docs) {
      int drafts = 0;
      int overdue = 0;
      int needFollowUp = 0;

      for (final doc in docs) {
        final status = doc.status.toLowerCase();
        if (status == 'draft') {
          drafts++;
        }
        if (doc.dueOrValidityDate != null &&
            doc.dueOrValidityDate!.isBefore(now) &&
            status != 'paid' &&
            status != 'cancelled') {
          overdue++;
        }
        if (doc.nextFollowUpDate != null &&
            doc.nextFollowUpDate!.isBefore(now.add(const Duration(days: 1))) &&
            status == 'sent') {
          needFollowUp++;
        }
      }

      return DocumentMetrics(
        draftCount: drafts,
        overdueCount: overdue,
        needFollowUpCount: needFollowUp,
        totalCount: docs.length,
      );
    });
  }

  // Fetch full document with all related tables
  Future<CompleteDocument?> getCompleteDocument(int docId) async {
    try {
      final doc = await (_db.select(
        _db.documents,
      )..where((t) => t.id.equals(docId))).getSingleOrNull();
      if (doc == null) return null;

      final brand =
          await (_db.select(
            _db.brands,
          )..where((t) => t.id.equals(doc.brandId))).getSingleOrNull() ??
          await (_db.select(_db.brands)..limit(1)).getSingleOrNull();
      if (brand == null) return null;

      final client = doc.clientId != null
          ? await (_db.select(
              _db.clients,
            )..where((t) => t.id.equals(doc.clientId!))).getSingleOrNull()
          : null;

      final items =
          await (_db.select(_db.documentItems)
                ..where((t) => t.documentId.equals(docId))
                ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
              .get();

      final attachments =
          await (_db.select(_db.documentAttachments)
                ..where((t) => t.documentId.equals(docId))
                ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
              .get();

      final logs =
          await (_db.select(_db.documentActivityLogs)
                ..where((t) => t.documentId.equals(docId))
                ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
              .get();

      final paymentProfile = doc.paymentProfileId != null
          ? await (_db.select(_db.paymentProfiles)
                  ..where((t) => t.id.equals(doc.paymentProfileId!)))
                .getSingleOrNull()
          : null;

      return CompleteDocument(
        document: doc,
        brand: brand,
        client: client,
        items: items,
        customFields: const [],
        attachments: attachments,
        activityLogs: logs,
        paymentProfile: paymentProfile,
      );
    } catch (e) {
      return null;
    }
  }

  // Watch full document
  Stream<CompleteDocument?> watchCompleteDocument(int docId) {
    return (_db.select(_db.documents)..where((t) => t.id.equals(docId)))
        .watchSingleOrNull()
        .asyncMap((doc) async {
          if (doc == null) return null;
          return getCompleteDocument(docId);
        });
  }

  // Update status
  Future<void> updateDocumentStatus(int docId, String newStatus) async {
    await (_db.update(_db.documents)..where((t) => t.id.equals(docId))).write(
      DocumentsCompanion(
        status: Value(newStatus),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await logActivity(
      docId,
      'STATUS_CHANGE',
      'Status changed to ${newStatus.toUpperCase()}',
    );
  }

  // Delete document and cascaded records
  Future<void> deleteDocument(int docId) async {
    await (_db.delete(
      _db.documentItems,
    )..where((t) => t.documentId.equals(docId))).go();
    await (_db.delete(
      _db.documentAttachments,
    )..where((t) => t.documentId.equals(docId))).go();
    await (_db.delete(
      _db.documentActivityLogs,
    )..where((t) => t.documentId.equals(docId))).go();
    await (_db.delete(_db.documents)..where((t) => t.id.equals(docId))).go();
  }

  // Record a payment
  Future<void> recordPayment({
    required int documentId,
    required double amount,
    required String paymentMethod,
    String? reference,
    required DateTime paymentDate,
    String? notes,
  }) async {
    final doc = await (_db.select(
      _db.documents,
    )..where((t) => t.id.equals(documentId))).getSingle();
    final newBalance = (doc.balanceDue - amount).clamp(0.0, double.infinity);
    final isFullyPaid = newBalance <= 0;

    await (_db.update(
      _db.documents,
    )..where((t) => t.id.equals(documentId))).write(
      DocumentsCompanion(
        balanceDue: Value(newBalance),
        status: Value(isFullyPaid ? 'paid' : 'part-paid'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final refText = reference != null && reference.isNotEmpty
        ? ' (Ref: $reference)'
        : '';
    await logActivity(
      documentId,
      'PAYMENT_RECEIVED',
      'Payment of ${doc.currencyCode} ${amount.toStringAsFixed(2)} received via $paymentMethod$refText',
    );
  }

  // Duplicate document
  Future<int> duplicateDocument(int docId, {String? targetDocType}) async {
    final complete = await getCompleteDocument(docId);
    if (complete == null) throw Exception('Document not found');

    final doc = complete.document;
    final docType = targetDocType ?? doc.docType;
    final nextNumber = await getNextDocumentNumber(doc.brandId, docType);
    final numberFormat = await getNumberFormat(doc.brandId, docType);
    final brand = complete.brand;
    final formattedDocNumber = generateFormattedDocNumber(
      pattern: numberFormat?.formatPattern ?? '{BRAND}-{TYPE}-{YEAR}-{NUMBER}',
      brandPrefix: brand.name.isNotEmpty
          ? brand.name.substring(0, 2).toUpperCase()
          : 'BE',
      docTypePrefix: DocTypeExtension.fromCode(docType).defaultPrefix,
      year: DateTime.now().year,
      number: nextNumber,
      padding: numberFormat?.numberPadding ?? 3,
    );

    final newDocId = await _db
        .into(_db.documents)
        .insert(
          DocumentsCompanion.insert(
            brandId: doc.brandId,
            clientId: Value(doc.clientId),
            docType: docType,
            docNumber: formattedDocNumber,
            status: const Value('draft'),
            issueDate: DateTime.now(),
            dueOrValidityDate: Value(doc.dueOrValidityDate),
            currencyCode: Value(doc.currencyCode),
            subtotal: Value(doc.subtotal),
            discountAmount: Value(doc.discountAmount),
            discountPercent: Value(doc.discountPercent),
            taxPercent: Value(doc.taxPercent),
            taxAmount: Value(doc.taxAmount),
            isTaxInclusive: Value(doc.isTaxInclusive),
            totalAmount: Value(doc.totalAmount),
            depositPercent: Value(doc.depositPercent),
            depositAmount: Value(doc.depositAmount),
            balanceDue: Value(doc.totalAmount),
            termsConditions: Value(doc.termsConditions),
            closingNotes: Value(doc.closingNotes),
            introText: Value(doc.introText),
            pdfTemplate: Value(doc.pdfTemplate),
            showSignature: Value(doc.showSignature),
            showStamp: Value(doc.showStamp),
            extraJsonData: Value(doc.extraJsonData),
            convertedFromId: Value(docId),
            whtPercent: Value(doc.whtPercent),
            whtAmount: Value(doc.whtAmount),
            netAmountPayable: Value(doc.netAmountPayable),
            isWhtPostVat: Value(doc.isWhtPostVat),
            showAmountInWords: Value(doc.showAmountInWords),
            kesEquivalentRate: Value(doc.kesEquivalentRate),
            kesEquivalentAmount: Value(doc.kesEquivalentAmount),
            kesEquivalentDate: Value(doc.kesEquivalentDate),
            paymentProfileId: Value(doc.paymentProfileId),
            jobId: Value(doc.jobId),
            headerImagePath: Value(doc.headerImagePath),
            footerImagePath: Value(doc.footerImagePath),
            backgroundImagePath: Value(doc.backgroundImagePath),
            hideGeneratedHeader: Value(doc.hideGeneratedHeader),
            printWithoutLetterhead: Value(doc.printWithoutLetterhead),
            pageSize: Value(doc.pageSize),
            roundingRule: Value(doc.roundingRule),
            whtCalculateOnFeesOnly: Value(doc.whtCalculateOnFeesOnly),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );

    // Duplicate Line Items or Convert Packages to Line Items
    if (complete.items.isNotEmpty) {
      for (final item in complete.items) {
        await _db
            .into(_db.documentItems)
            .insert(
              DocumentItemsCompanion.insert(
                documentId: newDocId,
                description: item.description,
                details: Value(item.details),
                unit: Value(item.unit),
                quantity: Value(item.quantity),
                unitPrice: Value(item.unitPrice),
                discountPercent: Value(item.discountPercent),
                lineTotal: Value(item.lineTotal),
                sortOrder: Value(item.sortOrder),
                category: Value(item.category),
              ),
            );
      }
    } else if (doc.extraJsonData != null && doc.extraJsonData!.isNotEmpty) {
      final meta = DocumentMetaData.fromRawJson(doc.extraJsonData);
      int order = 0;
      if (meta.packages.isNotEmpty) {
        final chosenPkg = meta.packages.firstWhere(
          (p) => p.isRecommended,
          orElse: () => meta.packages.first,
        );
        await _db
            .into(_db.documentItems)
            .insert(
              DocumentItemsCompanion.insert(
                documentId: newDocId,
                description: chosenPkg.title,
                details: Value(chosenPkg.deliverables.join('\n')),
                unit: const Value('lump sum'),
                quantity: const Value(1.0),
                unitPrice: Value(chosenPkg.price),
                lineTotal: Value(chosenPkg.price),
                sortOrder: Value(order++),
              ),
            );
      }
      for (final addon in meta.addons) {
        if (addon.isSelected) {
          await _db
              .into(_db.documentItems)
              .insert(
                DocumentItemsCompanion.insert(
                  documentId: newDocId,
                  description: addon.name,
                  details: Value(addon.details),
                  unit: const Value('item'),
                  quantity: const Value(1.0),
                  unitPrice: Value(addon.price),
                  lineTotal: Value(addon.price),
                  sortOrder: Value(order++),
                ),
              );
        }
      }
    }

    await logActivity(
      newDocId,
      'CREATED',
      'Document created by duplicating / converting $docId',
    );
    return newDocId;
  }

  // Convert Quotation -> Proforma -> Invoice -> Receipt
  Future<int> convertDocument(int sourceDocId, String targetDocType) async {
    return duplicateDocument(sourceDocId, targetDocType: targetDocType);
  }

  // Convert Production Budget -> Quotation
  Future<int> convertBudgetToQuotation(int budgetDocId) async {
    final complete = await getCompleteDocument(budgetDocId);
    if (complete == null) throw Exception('Budget document not found');

    final budgetDoc = complete.document;
    final nextNumber = await getNextDocumentNumber(
      budgetDoc.brandId,
      'quotation',
    );
    final numberFormat = await getNumberFormat(budgetDoc.brandId, 'quotation');
    final brand = complete.brand;
    final formattedDocNumber = generateFormattedDocNumber(
      pattern: numberFormat?.formatPattern ?? '{BRAND}-QT-{YEAR}-{NUMBER}',
      brandPrefix: brand.name.isNotEmpty
          ? brand.name.substring(0, 2).toUpperCase()
          : 'BE',
      docTypePrefix: 'QT',
      year: DateTime.now().year,
      number: nextNumber,
      padding: numberFormat?.numberPadding ?? 3,
    );

    final newDocId = await _db
        .into(_db.documents)
        .insert(
          DocumentsCompanion.insert(
            brandId: budgetDoc.brandId,
            clientId: Value(budgetDoc.clientId),
            docType: 'quotation',
            docNumber: formattedDocNumber,
            status: const Value('draft'),
            issueDate: DateTime.now(),
            dueOrValidityDate: Value(
              DateTime.now().add(const Duration(days: 30)),
            ),
            currencyCode: Value(budgetDoc.currencyCode),
            subtotal: Value(budgetDoc.subtotal),
            discountAmount: Value(budgetDoc.discountAmount),
            discountPercent: Value(budgetDoc.discountPercent),
            taxPercent: Value(budgetDoc.taxPercent),
            taxAmount: Value(budgetDoc.taxAmount),
            isTaxInclusive: Value(budgetDoc.isTaxInclusive),
            totalAmount: Value(budgetDoc.totalAmount),
            depositPercent: const Value(50.0),
            depositAmount: Value(budgetDoc.totalAmount * 0.5),
            balanceDue: Value(budgetDoc.totalAmount),
            termsConditions: const Value(
              '50% deposit required upon confirmation, balance upon final delivery.',
            ),
            closingNotes: Value(
              budgetDoc.closingNotes ??
                  'Converted from Production Budget ${budgetDoc.docNumber}',
            ),
            pdfTemplate: Value(budgetDoc.pdfTemplate),
            showSignature: const Value(true),
            showStamp: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );

    // Transfer line items
    if (complete.items.isNotEmpty) {
      for (final item in complete.items) {
        await _db
            .into(_db.documentItems)
            .insert(
              DocumentItemsCompanion.insert(
                documentId: newDocId,
                description: item.description,
                details: Value(item.details),
                unit: Value(item.unit),
                quantity: Value(item.quantity),
                unitPrice: Value(item.unitPrice),
                lineTotal: Value(item.lineTotal),
                sortOrder: Value(item.sortOrder),
                category: Value(item.category),
              ),
            );
      }
    } else if (budgetDoc.extraJsonData != null) {
      try {
        final data =
            jsonDecode(budgetDoc.extraJsonData!) as Map<String, dynamic>;
        final categories = data['categories'] as List<dynamic>? ?? [];
        int sort = 0;
        for (final cat in categories) {
          final catName = cat['name'] as String? ?? 'Production Category';
          final items = cat['items'] as List<dynamic>? ?? [];
          for (final it in items) {
            final title = it['title'] as String? ?? 'Item';
            final desc = it['description'] as String?;
            final unit = it['unit'] as String? ?? 'Day';
            final qty = (it['quantity'] as num?)?.toDouble() ?? 1.0;
            final rate = (it['unitPrice'] as num?)?.toDouble() ?? 0.0;
            final total = qty * rate;

            await _db
                .into(_db.documentItems)
                .insert(
                  DocumentItemsCompanion.insert(
                    documentId: newDocId,
                    description: '[$catName] $title',
                    details: Value(desc),
                    unit: Value(unit),
                    quantity: Value(qty),
                    unitPrice: Value(rate),
                    lineTotal: Value(total),
                    sortOrder: Value(sort++),
                    category: Value(catName),
                  ),
                );
          }
        }
      } catch (_) {}
    }

    await logActivity(
      newDocId,
      'CONVERTED',
      'Created from Budget ${budgetDoc.docNumber}',
    );
    return newDocId;
  }

  Future<void> logActivity(
    int documentId,
    String actionType,
    String description,
  ) async {
    await _db
        .into(_db.documentActivityLogs)
        .insert(
          DocumentActivityLogsCompanion.insert(
            documentId: documentId,
            action: Value(actionType),
            actionType: Value(actionType),
            description: Value(description),
            timestamp: Value(DateTime.now()),
          ),
        );
  }

  Future<NumberingSequence?> getNumberFormat(
    int brandId,
    String docType,
  ) async {
    return (_db.select(_db.numberingSequences)..where(
          (tbl) => tbl.brandId.equals(brandId) & tbl.docType.equals(docType),
        ))
        .getSingleOrNull();
  }

  Future<int> getNextDocumentNumber(int brandId, String docType) async {
    final seq =
        await (_db.select(_db.numberingSequences)..where(
              (tbl) =>
                  tbl.brandId.equals(brandId) & tbl.docType.equals(docType),
            ))
            .getSingleOrNull();

    if (seq == null) return 1;
    final nextNumber = seq.currentNumber + 1;
    await (_db.update(
      _db.numberingSequences,
    )..where((tbl) => tbl.id.equals(seq.id))).write(
      NumberingSequencesCompanion(
        currentNumber: Value(nextNumber),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return nextNumber;
  }

  Future<void> incrementSequenceNumber(int brandId, String docType) async {
    final seq =
        await (_db.select(_db.numberingSequences)..where(
              (tbl) =>
                  tbl.brandId.equals(brandId) & tbl.docType.equals(docType),
            ))
            .getSingleOrNull();

    if (seq != null) {
      await (_db.update(
        _db.numberingSequences,
      )..where((tbl) => tbl.id.equals(seq.id))).write(
        NumberingSequencesCompanion(
          currentNumber: Value(seq.currentNumber + 1),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  String generateFormattedDocNumber({
    required String pattern,
    required String brandPrefix,
    required String docTypePrefix,
    required int year,
    required int number,
    required int padding,
  }) {
    return NumberGenerator.formatNumber(
      pattern: pattern,
      brandName: brandPrefix,
      docPrefix: docTypePrefix,
      number: number,
      padding: padding,
      date: DateTime(year),
    );
  }
}

class DocumentWithClient {
  final Document document;
  final Client? client;

  DocumentWithClient({required this.document, this.client});
}

class DocumentMetrics {
  final int draftCount;
  final int overdueCount;
  final int needFollowUpCount;
  final int totalCount;

  DocumentMetrics({
    required this.draftCount,
    required this.overdueCount,
    required this.needFollowUpCount,
    required this.totalCount,
  });
}
