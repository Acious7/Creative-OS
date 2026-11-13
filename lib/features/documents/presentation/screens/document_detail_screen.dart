import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/document_repository.dart';
import 'document_editor_screen.dart';
import '../../../pdf_export/presentation/screens/pdf_preview_screen.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/action_bottom_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';

import 'package:google_fonts/google_fonts.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final int documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  void _openPdfPreview(CompleteDocument completeDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PdfPreviewScreen(completeDoc: completeDoc),
      ),
    );
  }

  void _openEditor(CompleteDocument completeDoc) {
    final doc = completeDoc.document;
    final docType = DocTypeExtension.fromCode(doc.docType);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) =>
            DocumentEditorScreen(docType: docType, initialDocument: doc),
      ),
    );
  }

  Future<void> _showStatusPicker(CompleteDocument completeDoc) async {
    final repo = ref.read(documentRepositoryProvider);
    final currentStatus = completeDoc.document.status.toLowerCase();

    final newStatus = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Update Document Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ...['draft', 'sent', 'paid', 'overdue', 'cancelled'].map((status) {
              final isSelected = currentStatus == status;
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.getStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.success)
                    : null,
                onTap: () => Navigator.pop(ctx, status),
              );
            }),
          ],
        ),
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      await repo.updateDocumentStatus(completeDoc.document.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.toUpperCase()}'),
          ),
        );
      }
    }
  }

  Future<void> _recordPaymentDialog(CompleteDocument completeDoc) async {
    final repo = ref.read(documentRepositoryProvider);
    final doc = completeDoc.document;
    final amountController = TextEditingController(
      text: doc.balanceDue > 0 ? doc.balanceDue.toStringAsFixed(0) : '',
    );
    final refController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'M-Pesa';
    DateTime paymentDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Record Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Payment Amount (${doc.currencyCode}) *',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items:
                    ['M-Pesa', 'Bank Transfer', 'Cash', 'Credit Card', 'Cheque']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                onChanged: (val) => setModalState(() => paymentMethod = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Reference / Code',
                  hintText: 'e.g. QKJ48293KA',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amount <= 0) return;

                    await repo.recordPayment(
                      documentId: doc.id,
                      amount: amount,
                      paymentMethod: paymentMethod,
                      reference: refController.text.trim(),
                      paymentDate: paymentDate,
                      notes: notesController.text.trim(),
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _convertDocument(
    CompleteDocument completeDoc,
    String targetDocType,
  ) async {
    final repo = ref.read(documentRepositoryProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Convert to ${DocTypeExtension.fromCode(targetDocType).displayName}?',
        ),
        content: Text(
          'This will create a new sequential ${DocTypeExtension.fromCode(targetDocType).displayName} with identical line items and client information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      int newDocId;
      if (completeDoc.document.docType == 'productionBudget' &&
          targetDocType == 'quotation') {
        newDocId = await repo.convertBudgetToQuotation(completeDoc.document.id);
      } else {
        newDocId = await repo.convertDocument(
          completeDoc.document.id,
          targetDocType,
        );
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _StampAnimationDialog(
          targetTitle: DocTypeExtension.fromCode(targetDocType).displayName
              .toUpperCase(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document converted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => DocumentDetailScreen(documentId: newDocId),
          ),
        );
      }
    }
  }

  Future<void> _duplicateDoc(CompleteDocument completeDoc) async {
    final repo = ref.read(documentRepositoryProvider);
    final newId = await repo.duplicateDocument(completeDoc.document.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document duplicated!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => DocumentDetailScreen(documentId: newId),
        ),
      );
    }
  }

  Future<void> _deleteDoc(CompleteDocument completeDoc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text(
          'Are you sure you want to permanently delete ${completeDoc.document.docNumber}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(documentRepositoryProvider);
      await repo.deleteDocument(completeDoc.document.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Document deleted')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _scanSignedCopy(CompleteDocument completeDoc) async {
    try {
      final pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        final filePath = pictures.first;
        final db = ref.read(databaseProvider);
        await db
            .into(db.documentAttachments)
            .insert(
              DocumentAttachmentsCompanion.insert(
                documentId: completeDoc.document.id,
                filePath: filePath,
                caption: drift.Value(
                  'Signed copy received (${DateFormatter.format(DateTime.now())})',
                ),
              ),
            );
        final repo = ref.read(documentRepositoryProvider);
        await repo.updateDocumentStatus(
          completeDoc.document.id,
          'signed_received',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed copy saved & document status updated!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning signed copy: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(documentRepositoryProvider);
    final accent = ref.watch(activeAccentColorProvider);

    return StreamBuilder<CompleteDocument?>(
      stream: repo.watchCompleteDocument(widget.documentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Document Details')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load document #${widget.documentId}\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final completeDoc = snapshot.data;
        if (completeDoc == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Document Details')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: AppColors.darkTextMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Document #${widget.documentId} not found or has been deleted',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Return to Documents'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final doc = completeDoc.document;
        final client = completeDoc.client;
        final docType = DocTypeExtension.fromCode(doc.docType);
        final symbol = doc.currencyCode;
        final paidAmount = (doc.totalAmount - doc.balanceDue).clamp(
          0.0,
          double.infinity,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(doc.docNumber),
            actions: [
              IconButton(
                icon: const Icon(Icons.scanner_outlined),
                tooltip: 'Add Signed Copy',
                onPressed: () => _scanSignedCopy(completeDoc),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Document',
                onPressed: () => _openEditor(completeDoc),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'signed') _scanSignedCopy(completeDoc);
                  if (val == 'duplicate') _duplicateDoc(completeDoc);
                  if (val == 'delete') _deleteDoc(completeDoc);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'signed',
                    child: Row(
                      children: [
                        Icon(Icons.camera_front_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Add Signed Copy'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Executive Quotation Letterhead & Metadata
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDesignTokens.radiusHero),
                    topRight: Radius.circular(AppDesignTokens.radiusMd),
                    bottomLeft: Radius.circular(AppDesignTokens.radiusMd),
                    bottomRight: Radius.circular(AppDesignTokens.radiusMd),
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Serif Document Title ("Quotation") + Status + Brand Logo & Bauhaus Cluster
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                docType.displayName,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    doc.docNumber,
                                    style: AppDesignTokens.tabularStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: EtoleColors.cyan,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _showStatusPicker(completeDoc),
                                    borderRadius: BorderRadius.circular(
                                      AppDesignTokens.radiusSm,
                                    ),
                                    child: StatusBadge(
                                      status: doc.status,
                                      compact: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EtoleBrandLogo(
                              fontSize: 22,
                              showSubtitle: true,
                            ),
                            const SizedBox(width: 10),
                            const EtoleBauhausCluster(size: 40),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      height: 1,
                    ),
                    const SizedBox(height: 16),

                    // Two-Column Metadata: "Prepare For" (Client) & "Prepared By"
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Prepare For
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prepare For',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                client?.name ?? 'Walk-in Client',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                              if (client?.organization != null &&
                                  client!.organization!.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  client.organization!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                              Text(
                                client?.address ?? 'Nairobi, Kenya.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Prepared By
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prepared By',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                completeDoc.brand.name.isNotEmpty
                                    ? completeDoc.brand.name
                                    : 'Creative Studio',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'VisualStoryteller',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                              Text(
                                completeDoc.brand.address ?? 'Nairobi, Kenya.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    // Date metadata row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Issued: ${DateFormatter.format(doc.issueDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        if (doc.dueOrValidityDate != null)
                          Text(
                            docType == DocType.quotation
                                ? 'Valid Until: ${DateFormatter.format(doc.dueOrValidityDate!)}'
                                : 'Due: ${DateFormatter.format(doc.dueOrValidityDate!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Conversions & Actions Bar
              _buildConversionActions(completeDoc),
              const SizedBox(height: 14),

              // 2. The Signature Solid Sky Cyan "Budget Breakdown." Card
              if (completeDoc.items.isNotEmpty) ...[
                EtoleBudgetBreakdownCard(
                  title: 'Budget Breakdown.',
                  subtitle: 'Price (${symbol})',
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completeDoc.items.length,
                    separatorBuilder: (_, __) => Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.22),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    itemBuilder: (context, idx) {
                      final item = completeDoc.items[idx];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                                if (item.details != null &&
                                    item.details!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.details!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ],
                                if (item.quantity > 1) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} ${item.unit} @ ${CurrencyFormatter.format(item.unitPrice, currencyCode: symbol)}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            CurrencyFormatter.format(
                              item.lineTotal,
                              currencyCode: symbol,
                              includeSymbol: false,
                            ),
                            style: AppDesignTokens.tabularStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 3. Terms & Conditions + Iconic Warm Gold Total Badge
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Terms and Conditions
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terms and Conditions',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                doc.termsConditions != null &&
                                        doc.termsConditions!.isNotEmpty
                                    ? doc.termsConditions!
                                    : 'This ${docType.displayName.toLowerCase()} is issued specifically for the creative visual storytelling assignment by ${completeDoc.brand.name}.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'For more information call,\n${completeDoc.brand.name}\n${completeDoc.brand.phone ?? '+254 718 013 579'}\n${completeDoc.brand.email ?? 'hello@brianetole.com'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.45,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const EtoleMaasaiAccent(height: 20),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Right: Grand Total Badge in Signature Gold
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            EtoleTotalBadge(
                              label: 'Total:',
                              amount: CurrencyFormatter.format(
                                doc.totalAmount,
                                currencyCode: symbol,
                                includeSymbol: false,
                              ),
                              currency: symbol,
                              fontSize: 15,
                            ),
                            if (paidAmount > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Paid: ${CurrencyFormatter.format(paidAmount, currencyCode: symbol)}',
                                style: AppDesignTokens.tabularStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppDesignTokens.statusPaid,
                                ),
                              ),
                            ],
                            if (doc.balanceDue > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Due: ${CurrencyFormatter.format(doc.balanceDue, currencyCode: symbol)}',
                                style: AppDesignTokens.tabularStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppDesignTokens.statusOverdue,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Activity Log Section
              if (completeDoc.activityLogs.isNotEmpty) ...[
                Text(
                  'Activity & History',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completeDoc.activityLogs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final log = completeDoc.activityLogs[idx];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.history_rounded,
                          color: AppDesignTokens.statusSent,
                          size: 20,
                        ),
                        title: Text(
                          log.description ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          DateFormatter.format(log.timestamp),
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Record Payment Button
              if (doc.balanceDue > 0) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_card_outlined),
                  label: const Text('Record Payment / Deposit'),
                  onPressed: () => _recordPaymentDialog(completeDoc),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
          bottomNavigationBar: ActionBottomBar(
            child: FilledButton.icon(
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Preview & Export (PDF / Image)'),
              onPressed: () => _openPdfPreview(completeDoc),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppDesignTokens.tabularStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildConversionActions(CompleteDocument completeDoc) {
    final docType = completeDoc.document.docType;

    if (docType == 'quotation') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('Convert to Invoice'),
          onPressed: () => _convertDocument(completeDoc, 'invoice'),
        ),
      );
    } else if (docType == 'invoice') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.receipt_rounded, size: 16),
          label: const Text('Convert to Official Receipt'),
          onPressed: () => _convertDocument(completeDoc, 'receipt'),
        ),
      );
    } else if (docType == 'rateCard') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.request_quote_outlined, size: 16),
          label: const Text('Create Quotation from this Rate Card'),
          onPressed: () => _convertDocument(completeDoc, 'quotation'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _StampAnimationDialog extends StatefulWidget {
  final String targetTitle;

  const _StampAnimationDialog({required this.targetTitle});

  @override
  State<_StampAnimationDialog> createState() => _StampAnimationDialogState();
}

class _StampAnimationDialogState extends State<_StampAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnim = Tween<double>(
      begin: 2.2,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _rotAnim = Tween<double>(
      begin: -0.22,
      end: -0.06,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171A).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EtoleColors.cyan, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: EtoleColors.cyan.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CONVERTED',
                      style: GoogleFonts.spaceMono(
                        color: EtoleColors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.targetTitle,
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFFF3EAD9),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
