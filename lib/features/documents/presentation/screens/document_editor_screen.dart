import 'dart:ui';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/constants/document_type_defaults.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/number_generator.dart';
import '../../../clients/presentation/screens/clients_list_screen.dart';
import '../../../text_defaults/data/text_defaults_repository.dart';
import '../../data/document_repository.dart';
import '../../domain/document_calculator.dart';
import '../../domain/editable_line_item.dart';
import '../widgets/attachments_editor_card.dart';
import '../widgets/library_item_picker_sheet.dart';

class DocumentEditorScreen extends ConsumerStatefulWidget {
  final DocType docType;
  final Document? initialDocument;
  final int? initialClientId;
  final int? initialJobId;
  final Document? linkedInvoice;
  final Function(int savedDocId)? onDocumentSaved;

  const DocumentEditorScreen({
    super.key,
    required this.docType,
    this.initialDocument,
    this.initialClientId,
    this.initialJobId,
    this.linkedInvoice,
    this.onDocumentSaved,
  });

  @override
  ConsumerState<DocumentEditorScreen> createState() =>
      _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  final _uuid = const Uuid();

  // Document Properties
  int? _selectedClientId;
  late String _docNumber;
  late DateTime _issueDate;
  DateTime? _dueDate;
  String _currencyCode = 'KES';
  String _status = 'draft';
  String? _etimsNumber;
  String _paymentMethod = 'M-Pesa';

  // Line Items
  final List<EditableLineItem> _lineItems = [];

  // Taxes & Discounts
  bool _isTaxEnabled = true;
  double _taxPercent = 16.0;
  bool _isTaxInclusive = false;
  double _discountPercent = 0.0;
  double _discountFixed = 0.0;
  bool _isWhtEnabled = false;
  double _whtPercent = 5.0;
  double _depositPercent = 0.0;
  double _depositFixed = 0.0;

  // Text Defaults & Headings
  late TextEditingController _titleOverrideCtrl;
  late TextEditingController _introTextCtrl;
  late TextEditingController _closingNotesCtrl;
  late TextEditingController _termsConditionsCtrl;

  // Signatures & Stamp
  bool _showSignature = true;
  bool _showClientSignature = false;
  bool _showStamp = true;

  // Attachments
  final List<EditableAttachment> _attachments = [];

  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleOverrideCtrl = TextEditingController();
    _introTextCtrl = TextEditingController();
    _closingNotesCtrl = TextEditingController();
    _termsConditionsCtrl = TextEditingController();
    _issueDate = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 14));
    _docNumber = '...';

    if (widget.docType == DocType.contract) {
      _showClientSignature = true;
    }
    if (widget.docType == DocType.receipt) {
      _status = 'paid';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDocumentData();
    });
  }

  @override
  void dispose() {
    _titleOverrideCtrl.dispose();
    _introTextCtrl.dispose();
    _closingNotesCtrl.dispose();
    _termsConditionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _initDocumentData() async {
    final activeBrand = ref.read(activeBrandProvider);
    final brandId = activeBrand?.id ?? 1;
    final docTypeStr = widget.docType.code;
    final db = ref.read(databaseProvider);

    if (widget.initialDocument != null) {
      final doc = widget.initialDocument!;
      _selectedClientId = doc.clientId;
      _docNumber = doc.docNumber;
      _issueDate = doc.issueDate;
      _dueDate = doc.dueOrValidityDate;
      _currencyCode = doc.currencyCode;
      _status = doc.status;
      _taxPercent = doc.taxPercent;
      _isTaxInclusive = doc.isTaxInclusive;
      _isTaxEnabled = doc.taxAmount > 0 || doc.taxPercent > 0;
      _discountAmountToPercent(doc.discountAmount, doc.subtotal);
      _depositPercent = doc.depositPercent;
      _depositFixed = doc.depositAmount;
      _titleOverrideCtrl.text = doc.titleOverride ?? '';
      _introTextCtrl.text = doc.introText ?? '';
      _closingNotesCtrl.text = doc.closingNotes ?? '';
      _termsConditionsCtrl.text = doc.termsConditions ?? '';
      _etimsNumber = doc.etimsNumber;
      _showSignature = doc.showSignature;
      _showStamp = doc.showStamp;

      // Load items
      final items = await (db.select(
        db.documentItems,
      )..where((t) => t.documentId.equals(doc.id))).get();
      for (final it in items) {
        _lineItems.add(
          EditableLineItem(
            id: _uuid.v4(),
            description: it.description,
            details: it.details ?? '',
            quantity: it.quantity,
            unit: it.unit,
            unitPrice: it.unitPrice,
            discountPercent: it.discountPercent,
            category: it.category ?? 'General',
          ),
        );
      }

      // Load attachments
      final atts = await (db.select(
        db.documentAttachments,
      )..where((t) => t.documentId.equals(doc.id))).get();
      for (final a in atts) {
        _attachments.add(
          EditableAttachment(
            filePath: a.filePath,
            caption: a.caption ?? '',
            includeInPdf: a.includeInPdf,
          ),
        );
      }
    } else if (widget.linkedInvoice != null) {
      // SPECIAL FLOW 1: Receipt from an Invoice
      final inv = widget.linkedInvoice!;
      _selectedClientId = inv.clientId;
      _currencyCode = inv.currencyCode;
      _status = 'paid';
      _isTaxEnabled = inv.taxPercent > 0;
      _taxPercent = inv.taxPercent;
      _closingNotesCtrl.text =
          'Payment received for Invoice ${inv.docNumber} via $_paymentMethod on ${DateFormatter.format(DateTime.now())}.';

      // Load items from invoice
      final items = await (db.select(
        db.documentItems,
      )..where((t) => t.documentId.equals(inv.id))).get();
      for (final it in items) {
        _lineItems.add(
          EditableLineItem(
            id: _uuid.v4(),
            description: it.description,
            details: it.details ?? '',
            quantity: it.quantity,
            unit: it.unit,
            unitPrice: it.unitPrice,
            discountPercent: it.discountPercent,
            category: it.category ?? 'General',
          ),
        );
      }

      // Generate receipt number
      await _generateSequentialNumber(brandId, docTypeStr, activeBrand);
    } else {
      // NEW DOCUMENT: Load defaults & generate number
      final textRepo = ref.read(textDefaultsRepositoryProvider);
      final defaults = await textRepo.getDefaultsForDocType(
        brandId,
        docTypeStr,
      );
      final fallback = DocumentTypeDefaults.getDefaults(widget.docType);

      _titleOverrideCtrl.text = defaults?.titleOverride ?? fallback.title;
      _introTextCtrl.text = defaults?.introText ?? fallback.introText;
      _closingNotesCtrl.text = defaults?.closingNotes ?? fallback.closingNotes;
      _termsConditionsCtrl.text =
          defaults?.termsConditions ?? fallback.termsConditions;

      await _generateSequentialNumber(brandId, docTypeStr, activeBrand);

      // SPECIAL FLOW 2: Rate Card pre-loads services from ItemsLibrary
      if (widget.docType == DocType.rateCard) {
        final libItems = await (db.select(
          db.itemsLibrary,
        )..where((t) => t.isDeleted.equals(false))).get();
        if (libItems.isNotEmpty) {
          for (final it in libItems) {
            _lineItems.add(
              EditableLineItem(
                id: _uuid.v4(),
                description: it.title,
                details: it.description ?? '',
                quantity: 1,
                unit: it.unit,
                unitPrice: it.unitPrice,
                category: it.category,
              ),
            );
          }
        }
      }

      // SPECIAL FLOW 3: Contract pre-loads standard clauses
      if (widget.docType == DocType.contract) {
        final clauses = await (db.select(
          db.reusableClauses,
        )..orderBy([(t) => drift.OrderingTerm.asc(t.category)])).get();
        if (clauses.isNotEmpty && _termsConditionsCtrl.text.isEmpty) {
          final buffer = StringBuffer();
          for (int i = 0; i < clauses.length; i++) {
            buffer.writeln('${i + 1}. ${clauses[i].title.toUpperCase()}');
            buffer.writeln(clauses[i].bodyText);
            buffer.writeln();
          }
          _termsConditionsCtrl.text = buffer.toString().trim();
        }
        _showSignature = true;
        _showClientSignature = true;
      }

      // Starter item if line items empty and doc has line items
      if (widget.docType.hasLineItems && _lineItems.isEmpty) {
        _lineItems.add(
          EditableLineItem(
            id: _uuid.v4(),
            description: 'Production Services',
            quantity: 1,
            unit: 'day',
            unitPrice: 0.0,
          ),
        );
      }

      if (widget.initialClientId != null) {
        _selectedClientId = widget.initialClientId;
      }
    }

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _generateSequentialNumber(
    int brandId,
    String docTypeStr,
    Brand? activeBrand,
  ) async {
    final db = ref.read(databaseProvider);
    final seq =
        await (db.select(db.numberingSequences)..where(
              (t) => t.brandId.equals(brandId) & t.docType.equals(docTypeStr),
            ))
            .getSingleOrNull();

    if (seq != null) {
      _docNumber = NumberGenerator.formatNumber(
        pattern: seq.formatPattern,
        brandName: activeBrand?.name ?? 'BE',
        docPrefix: seq.prefix,
        number: seq.currentNumber + 1,
        padding: seq.numberPadding,
      );
    } else {
      _docNumber = '${widget.docType.defaultPrefix}-${DateTime.now().year}-001';
    }

    if (_docNumber.contains('{') ||
        _docNumber.contains('PREFIX') ||
        _docNumber.contains('NUM')) {
      final safeNum = ((seq?.currentNumber ?? 0) + 1).toString().padLeft(3, '0');
      _docNumber = '${widget.docType.defaultPrefix}-${DateTime.now().year}-$safeNum';
    }
  }

  void _discountAmountToPercent(double discountAmt, double subtotal) {
    if (subtotal > 0 && discountAmt > 0) {
      _discountPercent = (discountAmt / subtotal) * 100.0;
    }
  }

  CalculationResult _calculateTotals() {
    return DocumentCalculator.calculate(
      lineTotals: _lineItems.map((e) => e.total).toList(),
      docDiscountPercent: _discountPercent,
      docDiscountFixed: _discountFixed,
      isTaxEnabled: _isTaxEnabled,
      taxPercent: _taxPercent,
      isTaxInclusive: _isTaxInclusive,
      whtPercent: _isWhtEnabled ? _whtPercent : 0.0,
      depositPercent: _depositPercent,
      depositFixed: _depositFixed,
    );
  }

  Future<void> _saveDocument() async {
    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      final activeBrand = ref.read(activeBrandProvider);
      final brandId = activeBrand?.id ?? 1;
      final totals = _calculateTotals();
      final isNew = widget.initialDocument == null;

      if (isNew) {
        final nextSeqNum = await ref
            .read(documentRepositoryProvider)
            .getNextDocumentNumber(brandId, widget.docType.code);
        final seq =
            await (db.select(db.numberingSequences)..where(
                  (t) =>
                      t.brandId.equals(brandId) &
                      t.docType.equals(widget.docType.code),
                ))
                .getSingleOrNull();

        if (seq != null) {
          _docNumber = NumberGenerator.formatNumber(
            pattern: seq.formatPattern,
            brandName: activeBrand?.name ?? 'BE',
            docPrefix: seq.prefix,
            number: nextSeqNum,
            padding: seq.numberPadding,
          );
        } else {
          _docNumber = '${widget.docType.defaultPrefix}-${DateTime.now().year}-${nextSeqNum.toString().padLeft(3, '0')}';
        }

        if (_docNumber.contains('{') ||
            _docNumber.contains('PREFIX') ||
            _docNumber.contains('NUM')) {
          _docNumber = '${widget.docType.defaultPrefix}-${DateTime.now().year}-${nextSeqNum.toString().padLeft(3, '0')}';
        }
      }

      final docCompanion = DocumentsCompanion(
        brandId: drift.Value(brandId),
        clientId: drift.Value(_selectedClientId),
        jobId: widget.initialJobId != null
            ? drift.Value(widget.initialJobId.toString())
            : (widget.initialDocument?.jobId != null
                  ? drift.Value(widget.initialDocument!.jobId)
                  : const drift.Value.absent()),
        docType: drift.Value(widget.docType.code),
        docNumber: drift.Value(_docNumber),
        status: drift.Value(_status),
        issueDate: drift.Value(_issueDate),
        dueOrValidityDate: drift.Value(_dueDate),
        currencyCode: drift.Value(_currencyCode),
        subtotal: drift.Value(totals.subtotal),
        discountAmount: drift.Value(totals.discountAmount),
        discountPercent: drift.Value(_discountPercent),
        taxPercent: drift.Value(_isTaxEnabled ? _taxPercent : 0.0),
        isTaxInclusive: drift.Value(_isTaxInclusive),
        taxAmount: drift.Value(totals.taxAmount),
        depositAmount: drift.Value(totals.depositAmount),
        depositPercent: drift.Value(_depositPercent),
        totalAmount: drift.Value(totals.totalAmount),
        balanceDue: drift.Value(totals.balanceDue),
        titleOverride: drift.Value(
          _titleOverrideCtrl.text.trim().isNotEmpty
              ? _titleOverrideCtrl.text.trim()
              : null,
        ),
        introText: drift.Value(
          _introTextCtrl.text.trim().isNotEmpty
              ? _introTextCtrl.text.trim()
              : null,
        ),
        closingNotes: drift.Value(
          _closingNotesCtrl.text.trim().isNotEmpty
              ? _closingNotesCtrl.text.trim()
              : null,
        ),
        termsConditions: drift.Value(
          _termsConditionsCtrl.text.trim().isNotEmpty
              ? _termsConditionsCtrl.text.trim()
              : null,
        ),
        showSignature: drift.Value(_showSignature),
        showStamp: drift.Value(_showStamp),
        etimsNumber: drift.Value(
          _etimsNumber?.trim().isNotEmpty == true ? _etimsNumber!.trim() : null,
        ),
        updatedAt: drift.Value(DateTime.now()),
      );

      int docId;
      if (isNew) {
        docId = await db.into(db.documents).insert(docCompanion);
        await db
            .into(db.documentActivityLogs)
            .insert(
              DocumentActivityLogsCompanion.insert(
                documentId: docId,
                action: const drift.Value('created'),
                actionType: const drift.Value('created'),
                description: drift.Value(
                  'Created ${widget.docType.displayName} $_docNumber',
                ),
              ),
            );
      } else {
        docId = widget.initialDocument!.id;
        await (db.update(
          db.documents,
        )..where((t) => t.id.equals(docId))).write(docCompanion);
        await db
            .into(db.documentActivityLogs)
            .insert(
              DocumentActivityLogsCompanion.insert(
                documentId: docId,
                action: const drift.Value('edited'),
                actionType: const drift.Value('edited'),
                description: drift.Value(
                  'Updated ${widget.docType.displayName} $_docNumber',
                ),
              ),
            );
      }

      // Save line items
      await (db.delete(
        db.documentItems,
      )..where((t) => t.documentId.equals(docId))).go();
      for (int i = 0; i < _lineItems.length; i++) {
        final it = _lineItems[i];
        await db
            .into(db.documentItems)
            .insert(
              DocumentItemsCompanion.insert(
                documentId: docId,
                sortOrder: drift.Value(i),
                description: it.description,
                details: it.details.isNotEmpty
                    ? drift.Value(it.details)
                    : const drift.Value.absent(),
                quantity: drift.Value(it.quantity),
                unit: drift.Value(it.unit),
                unitPrice: drift.Value(it.unitPrice),
                discountPercent: drift.Value(it.discountPercent),
                lineTotal: drift.Value(it.total),
                category: drift.Value(it.category),
              ),
            );
      }

      // Save attachments
      await (db.delete(
        db.documentAttachments,
      )..where((t) => t.documentId.equals(docId))).go();
      for (int i = 0; i < _attachments.length; i++) {
        final a = _attachments[i];
        await db
            .into(db.documentAttachments)
            .insert(
              DocumentAttachmentsCompanion.insert(
                documentId: docId,
                filePath: a.filePath,
                caption: a.caption.isNotEmpty
                    ? drift.Value(a.caption)
                    : const drift.Value.absent(),
                sortOrder: drift.Value(i),
                includeInPdf: drift.Value(a.includeInPdf),
              ),
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.docType.displayName} $_docNumber saved'),
            backgroundColor: const Color(0xFF14171A),
          ),
        );
        if (widget.onDocumentSaved != null) {
          widget.onDocumentSaved!(docId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddClauseSheet() {
    final db = ref.read(databaseProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14171A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<ReusableClause>>(
          future: (db.select(
            db.reusableClauses,
          )..orderBy([(t) => drift.OrderingTerm.asc(t.category)])).get(),
          builder: (ctx, snapshot) {
            final clauses = snapshot.data ?? [];
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CLAUSE LIBRARY',
                          style: EtoleTypography.labelCaps(
                            color: EtoleColors.cyan,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: EtoleColors.creamSecondary,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (clauses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No standard clauses in library.',
                          style: TextStyle(color: EtoleColors.creamSecondary),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: clauses.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: Color(0x18F3EAD9),
                            height: 1,
                          ),
                          itemBuilder: (ctx, idx) {
                            final c = clauses[idx];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              title: Text(
                                c.title,
                                style: GoogleFonts.inter(
                                  color: EtoleColors.cream,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: Text(
                                c.bodyText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: EtoleColors.creamSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: EtoleColors.cyan,
                                size: 20,
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  final current = _termsConditionsCtrl.text
                                      .trim();
                                  _termsConditionsCtrl.text = current.isEmpty
                                      ? '${c.title.toUpperCase()}\n${c.bodyText}'
                                      : '$current\n\n${c.title.toUpperCase()}\n${c.bodyText}';
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDocNumberDialog() {
    final ctrl = TextEditingController(text: _docNumber);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF38B6DB).withValues(alpha: 0.3),
          ),
        ),
        title: Text(
          'Edit Document Number',
          style: EtoleTypography.h3.copyWith(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customize document reference number for your client or tax records:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF38B6DB),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D1015),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF38B6DB)),
                ),
                hintText:
                    '${widget.docType.defaultPrefix}-${DateTime.now().year}-001',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38B6DB),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final newNum = ctrl.text.trim();
              if (newNum.isNotEmpty) {
                setState(() => _docNumber = newNum);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0C0E),
        body: Center(child: CircularProgressIndicator(color: EtoleColors.cyan)),
      );
    }

    final totals = _calculateTotals();
    final clientsAsync = ref.watch(allClientsStreamProvider);
    final selectedClient = clientsAsync.value
        ?.where((c) => c.id == _selectedClientId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0C0E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: EtoleColors.cream,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialDocument == null
                  ? 'NEW ${widget.docType.displayName.toUpperCase()}'
                  : 'EDIT $_docNumber',
              style: EtoleTypography.h3.copyWith(
                color: EtoleColors.cream,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            InkWell(
              onTap: _showEditDocNumberDialog,
              borderRadius: BorderRadius.circular(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _docNumber,
                    style: GoogleFonts.spaceMono(
                      color: EtoleColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit_outlined,
                    color: EtoleColors.cyan,
                    size: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Subtle Autosave / Saved Indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: EtoleColors.cyan,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  'Saved',
                  style: GoogleFonts.inter(
                    color: EtoleColors.creamSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ==========================================
          // TOP HALF: LIVE DOCUMENT PREVIEW (updates as typed)
          // ==========================================
          Container(
            height: 235,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF13161A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x33F3EAD9), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BRIAN ETOLE',
                            style: GoogleFonts.inter(
                              color: EtoleColors.cream,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                          Text(
                            'REAL STORIES. IMAGINED WORLDS.',
                            style: GoogleFonts.inter(
                              color: EtoleColors.creamSecondary,
                              fontSize: 8.5,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EtoleColors.cyan.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: EtoleColors.cyan.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          widget.docType.displayName.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            color: EtoleColors.cyan,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0x18F3EAD9), height: 1),
                  const SizedBox(height: 8),

                  // Bill To & Document Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BILL TO:',
                              style: GoogleFonts.spaceMono(
                                color: EtoleColors.creamSecondary,
                                fontSize: 8.5,
                              ),
                            ),
                            Text(
                              selectedClient?.name ?? 'Select Contact Below',
                              style: GoogleFonts.inter(
                                color: selectedClient != null
                                    ? EtoleColors.cream
                                    : EtoleColors.creamSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (selectedClient?.organization != null)
                              Text(
                                selectedClient!.organization!,
                                style: GoogleFonts.inter(
                                  color: EtoleColors.creamSecondary,
                                  fontSize: 9.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: _showEditDocNumberDialog,
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _docNumber,
                                  style: GoogleFonts.spaceMono(
                                    color: EtoleColors.cream,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_outlined,
                                  color:
                                      EtoleColors.cream.withValues(alpha: 0.6),
                                  size: 10,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Issued: ${DateFormatter.format(_issueDate)}',
                            style: GoogleFonts.inter(
                              color: EtoleColors.creamSecondary,
                              fontSize: 9.5,
                            ),
                          ),
                          if (_dueDate != null)
                            Text(
                              'Due: ${DateFormatter.format(_dueDate!)}',
                              style: GoogleFonts.inter(
                                color: EtoleColors.creamSecondary,
                                fontSize: 9.5,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Live Line Items Table
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x12F3EAD9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'DESCRIPTION',
                            style: GoogleFonts.spaceMono(
                              fontSize: 8,
                              color: EtoleColors.creamSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'QTY',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceMono(
                              fontSize: 8,
                              color: EtoleColors.creamSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'RATE',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.spaceMono(
                              fontSize: 8,
                              color: EtoleColors.creamSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'AMOUNT',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.spaceMono(
                              fontSize: 8,
                              color: EtoleColors.creamSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final it in _lineItems)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              it.description.isNotEmpty
                                  ? it.description
                                  : 'Item',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: EtoleColors.cream,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${it.quantity}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: EtoleColors.creamSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              CurrencyFormatter.format(
                                it.unitPrice,
                                currencyCode: _currencyCode,
                              ),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: EtoleColors.creamSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              CurrencyFormatter.format(
                                it.total,
                                currencyCode: _currencyCode,
                              ),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: EtoleColors.cream,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),
                  const Divider(color: Color(0x18F3EAD9), height: 1),
                  const SizedBox(height: 6),

                  // Live Financials Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stamp
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _status == 'paid'
                                ? EtoleColors.green
                                : const Color(0xFF8C8275),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          _status.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            color: _status == 'paid'
                                ? EtoleColors.green
                                : const Color(0xFF8C8275),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_isTaxEnabled)
                            Text(
                              'VAT (16%): ${CurrencyFormatter.format(totals.taxAmount, currencyCode: _currencyCode)}',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: EtoleColors.creamSecondary,
                              ),
                            ),
                          if (_isWhtEnabled)
                            Text(
                              'WHT (5%): -${CurrencyFormatter.format(totals.whtAmount, currencyCode: _currencyCode)}',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: EtoleColors.creamSecondary,
                              ),
                            ),
                          Text(
                            'TOTAL: ${CurrencyFormatter.format(totals.totalAmount, currencyCode: _currencyCode)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: EtoleColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Thin split divider label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: const Color(0x18F3EAD9)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'EDITING SHEET',
                    style: GoogleFonts.spaceMono(
                      color: EtoleColors.creamSecondary.withValues(alpha: 0.6),
                      fontSize: 9.5,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: const Color(0x18F3EAD9)),
                ),
              ],
            ),
          ),

          // ==========================================
          // BOTTOM HALF: SCROLLING SHEET TO FILL IN DETAILS
          // ==========================================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                // 1. CONTACT PICKER
                _buildSectionCard(
                  title: 'CONTACT / BILL TO',
                  child: clientsAsync.when(
                    data: (clients) => Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _selectedClientId,
                            dropdownColor: const Color(0xFF14171A),
                            style: GoogleFonts.inter(
                              color: EtoleColors.cream,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              fillColor: const Color(0xFF1A1E24),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0x22F3EAD9),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0x22F3EAD9),
                                ),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No Contact Assigned'),
                              ),
                              ...clients.map(
                                (c) => DropdownMenuItem<int?>(
                                  value: c.id,
                                  child: Text(
                                    '${c.name}${c.organization != null ? " (${c.organization})" : ""}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedClientId = val),
                          ),
                        ),
                      ],
                    ),
                    loading: () =>
                        const LinearProgressIndicator(color: EtoleColors.cyan),
                    error: (_, __) => const Text(
                      'Error loading clients',
                      style: TextStyle(color: EtoleColors.creamSecondary),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. DATES & CURRENCY
                _buildSectionCard(
                  title: 'DATES & CURRENCY',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _issueDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null)
                                  setState(() => _issueDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1E24),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0x22F3EAD9),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Issued',
                                      style: GoogleFonts.inter(
                                        color: EtoleColors.creamSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormatter.format(_issueDate),
                                      style: GoogleFonts.inter(
                                        color: EtoleColors.cream,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dueDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null)
                                  setState(() => _dueDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1E24),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0x22F3EAD9),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.docType == DocType.quotation
                                          ? 'Valid Until'
                                          : 'Due Date',
                                      style: GoogleFonts.inter(
                                        color: EtoleColors.creamSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _dueDate != null
                                          ? DateFormatter.format(_dueDate!)
                                          : 'None',
                                      style: GoogleFonts.inter(
                                        color: EtoleColors.cream,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Currency row: KES, USD, GBP, EUR
                      Row(
                        children: ['KES', 'USD', 'GBP', 'EUR'].map((cur) {
                          final isSelected = _currencyCode == cur;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _currencyCode = cur),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? EtoleColors.cyan.withValues(
                                            alpha: 0.18,
                                          )
                                        : const Color(0xFF1A1E24),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? EtoleColors.cyan
                                          : const Color(0x22F3EAD9),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    cur,
                                    style: GoogleFonts.spaceMono(
                                      color: isSelected
                                          ? EtoleColors.cyan
                                          : EtoleColors.cream,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. ITEMS SECTION
                _buildSectionCard(
                  title: 'LINE ITEMS (${_lineItems.length})',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: EtoleColors.cyan,
                        ),
                        label: Text(
                          'Services Library',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: EtoleColors.cyan,
                          ),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => LibraryItemPickerSheet(
                              onItemSelected: (libItem) {
                                setState(() {
                                  _lineItems.add(
                                    EditableLineItem(
                                      id: _uuid.v4(),
                                      description: libItem.title,
                                      details: libItem.description ?? '',
                                      quantity: 1,
                                      unit: libItem.unit,
                                      unitPrice: libItem.unitPrice,
                                      category: libItem.category,
                                    ),
                                  );
                                });
                              },
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(
                          Icons.add,
                          size: 14,
                          color: EtoleColors.cyan,
                        ),
                        label: Text(
                          'Add Item',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: EtoleColors.cyan,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _lineItems.add(
                              EditableLineItem(
                                id: _uuid.v4(),
                                description: '',
                                quantity: 1,
                                unit: 'item',
                                unitPrice: 0.0,
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < _lineItems.length; i++)
                        _buildLineItemRow(_lineItems[i], i),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 4. TAXES & DISCOUNTS
                _buildSectionCard(
                  title: 'TAXES & DISCOUNTS',
                  child: Column(
                    children: [
                      // VAT Toggle (16%)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '16% VAT',
                          style: GoogleFonts.inter(
                            color: EtoleColors.cream,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Kenya standard value-added tax',
                          style: GoogleFonts.inter(
                            color: EtoleColors.creamSecondary,
                            fontSize: 11,
                          ),
                        ),
                        value: _isTaxEnabled,
                        activeColor: EtoleColors.cyan,
                        onChanged: (val) => setState(() => _isTaxEnabled = val),
                      ),
                      const Divider(color: Color(0x18F3EAD9), height: 1),

                      // Withholding Tax Toggle (5%)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '5% Withholding Tax (WHT)',
                          style: GoogleFonts.inter(
                            color: EtoleColors.cream,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Deducted at source by corporate clients',
                          style: GoogleFonts.inter(
                            color: EtoleColors.creamSecondary,
                            fontSize: 11,
                          ),
                        ),
                        value: _isWhtEnabled,
                        activeColor: EtoleColors.cyan,
                        onChanged: (val) => setState(() => _isWhtEnabled = val),
                      ),
                      const Divider(color: Color(0x18F3EAD9), height: 1),
                      const SizedBox(height: 10),

                      // Discount & Deposit Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _discountPercent > 0
                                  ? _discountPercent.toStringAsFixed(0)
                                  : '',
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                color: EtoleColors.cream,
                                fontSize: 12.5,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Discount %',
                                labelStyle: TextStyle(
                                  color: EtoleColors.creamSecondary,
                                  fontSize: 11,
                                ),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _discountPercent =
                                      double.tryParse(val) ?? 0.0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _depositFixed > 0
                                  ? _depositFixed.toStringAsFixed(0)
                                  : '',
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                color: EtoleColors.cream,
                                fontSize: 12.5,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Deposit Paid',
                                labelStyle: TextStyle(
                                  color: EtoleColors.creamSecondary,
                                  fontSize: 11,
                                ),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _depositFixed = double.tryParse(val) ?? 0.0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 5. NOTES & TERMS
                _buildSectionCard(
                  title: 'NOTES & PAYMENT TERMS',
                  action: widget.docType == DocType.contract
                      ? TextButton.icon(
                          onPressed: _showAddClauseSheet,
                          icon: const Icon(
                            Icons.gavel_rounded,
                            size: 14,
                            color: EtoleColors.cyan,
                          ),
                          label: Text(
                            'Add Clauses',
                            style: GoogleFonts.inter(
                              color: EtoleColors.cyan,
                              fontSize: 11.5,
                            ),
                          ),
                        )
                      : null,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _closingNotesCtrl,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          color: EtoleColors.cream,
                          fontSize: 12.5,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Closing Notes / Payment Instructions',
                          labelStyle: TextStyle(
                            color: EtoleColors.creamSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _termsConditionsCtrl,
                        maxLines: 3,
                        style: GoogleFonts.inter(
                          color: EtoleColors.cream,
                          fontSize: 12.5,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Terms & Conditions / Agreement Clauses',
                          labelStyle: TextStyle(
                            color: EtoleColors.creamSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 6. SIGNATURE & ATTACHMENTS
                _buildSectionCard(
                  title: 'SIGNATURES',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Authorized Studio Signature',
                          style: GoogleFonts.inter(
                            color: EtoleColors.cream,
                            fontSize: 13,
                          ),
                        ),
                        value: _showSignature,
                        activeColor: EtoleColors.cyan,
                        onChanged: (val) =>
                            setState(() => _showSignature = val),
                      ),
                      if (widget.docType == DocType.contract) ...[
                        const Divider(color: Color(0x18F3EAD9), height: 1),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Client Signing Block',
                            style: GoogleFonts.inter(
                              color: EtoleColors.cream,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            'Dual signature block for client acceptance',
                            style: GoogleFonts.inter(
                              color: EtoleColors.creamSecondary,
                              fontSize: 11,
                            ),
                          ),
                          value: _showClientSignature,
                          activeColor: EtoleColors.cyan,
                          onChanged: (val) =>
                              setState(() => _showClientSignature = val),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // ==========================================
          // PINNED RUNNING TOTAL & ACTION BAR
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EtoleTotalBadge(
                      label: 'Total:',
                      amount: CurrencyFormatter.format(
                        totals.totalAmount,
                        currencyCode: _currencyCode,
                        includeSymbol: false,
                      ),
                      currency: _currencyCode,
                      fontSize: 14,
                    ),
                    if (totals.balanceDue != totals.totalAmount) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${CurrencyFormatter.format(totals.balanceDue, currencyCode: _currencyCode)}',
                        style: GoogleFonts.inter(
                          color: EtoleColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveDocument,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Document',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14171A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x18F3EAD9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceMono(
                  color: EtoleColors.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildLineItemRow(EditableLineItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x18F3EAD9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.description,
                  style: GoogleFonts.inter(
                    color: EtoleColors.cream,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Item description...',
                    hintStyle: TextStyle(
                      color: EtoleColors.creamSecondary,
                      fontSize: 12,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => item.description = val),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE54D2E),
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _lineItems.removeAt(index);
                  });
                },
              ),
            ],
          ),
          Row(
            children: [
              // Qty
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    color: EtoleColors.cream,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    labelStyle: TextStyle(
                      color: EtoleColors.creamSecondary,
                      fontSize: 10,
                    ),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    setState(() {
                      item.quantity = double.tryParse(val) ?? 1.0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Unit
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.unit,
                  style: GoogleFonts.inter(
                    color: EtoleColors.cream,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    labelStyle: TextStyle(
                      color: EtoleColors.creamSecondary,
                      fontSize: 10,
                    ),
                    isDense: true,
                  ),
                  onChanged: (val) => item.unit = val,
                ),
              ),
              const SizedBox(width: 8),
              // Rate
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.unitPrice > 0
                      ? item.unitPrice.toStringAsFixed(0)
                      : '',
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    color: EtoleColors.cream,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Rate ($_currencyCode)',
                    labelStyle: const TextStyle(
                      color: EtoleColors.creamSecondary,
                      fontSize: 10,
                    ),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    setState(() {
                      item.unitPrice = double.tryParse(val) ?? 0.0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Line total
              Text(
                CurrencyFormatter.format(
                  item.total,
                  currencyCode: _currencyCode,
                ),
                style: GoogleFonts.inter(
                  color: EtoleColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
