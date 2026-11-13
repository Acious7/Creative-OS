import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design_tokens.dart';
import '../../../documents/data/document_repository.dart';
import '../../../email/presentation/widgets/send_document_email_sheet.dart';
import '../../domain/image_rasterizer.dart';
import '../../domain/pdf_builder.dart';
import '../../domain/pdf_template_style.dart';

class PdfPreviewScreen extends StatefulWidget {
  final CompleteDocument completeDoc;

  const PdfPreviewScreen({super.key, required this.completeDoc});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late PdfTemplateType _selectedTemplate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = PdfTemplateType.fromString(
      widget.completeDoc.document.pdfTemplate,
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    return PdfBuilder.buildDocumentPdf(
      completeDoc: widget.completeDoc,
      templateType: _selectedTemplate,
    );
  }

  Future<void> _shareAsPdf() async {
    final bytes = await _generatePdf(PdfPageFormat.a4);
    final docNum = widget.completeDoc.document.docNumber;
    await Printing.sharePdf(bytes: bytes, filename: '$docNum.pdf');
  }

  Future<void> _shareAsImage() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _generatePdf(PdfPageFormat.a4);
      final doc = widget.completeDoc.document;
      final brand = widget.completeDoc.brand;
      await ImageRasterizer.shareAsImages(
        pdfBytes: bytes,
        docNumber: doc.docNumber,
        subject: '${brand.name} - ${doc.docNumber}',
        message: 'Here is document ${doc.docNumber} from ${brand.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveToDownloads() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _generatePdf(PdfPageFormat.a4);
      final path = await ImageRasterizer.savePdfToDownloads(
        pdfBytes: bytes,
        docNumber: widget.completeDoc.document.docNumber,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved PDF to Downloads: $path'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _openEmailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SendDocumentEmailSheet(completeDoc: widget.completeDoc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.completeDoc.document;

    return Scaffold(
      appBar: AppBar(
        title: Text('${doc.docNumber} Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Save PDF to Downloads',
            onPressed: _isExporting ? null : _saveToDownloads,
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            tooltip: 'Send via Email',
            onPressed: _openEmailSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Template Selector Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spacingM,
              vertical: AppDesignTokens.spacingS,
            ),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Text(
                  'Template:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: AppDesignTokens.spacingM),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PdfTemplateType.values.map((t) {
                        final isSelected = _selectedTemplate == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(t.displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedTemplate = t;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Interactive PDF Preview Canvas
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(format),
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowPrinting: true,
              allowSharing: true,
              previewPageMargin: const EdgeInsets.all(AppDesignTokens.spacingM),
              pdfFileName: '${doc.docNumber}.pdf',
              loadingWidget: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spacingM,
          vertical: AppDesignTokens.spacingM,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Share Image'),
                  onPressed: _isExporting ? null : _shareAsImage,
                ),
              ),
              const SizedBox(width: AppDesignTokens.spacingM),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share PDF'),
                  onPressed: _isExporting ? null : _shareAsPdf,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
