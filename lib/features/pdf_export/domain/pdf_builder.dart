import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/number_in_words.dart';
import '../../documents/data/document_repository.dart';
import '../../documents/domain/models/proposal_options.dart';
import 'pdf_template_style.dart';

class PdfBuilder {
  static Future<Uint8List> buildDocumentPdf({
    required CompleteDocument completeDoc,
    PdfTemplateType? templateType,
  }) async {
    final pdf = pw.Document(
      title: '${completeDoc.document.docNumber} - ${completeDoc.brand.name}',
      author: completeDoc.brand.name,
    );

    final selectedTemplate = templateType ??
        PdfTemplateType.fromString(completeDoc.document.pdfTemplate);

    final palette = PdfColorPalette.fromHex(completeDoc.brand.accentColorHex);

    // Load fonts
    final regularFont = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();
    final semiBoldFont = await PdfGoogleFonts.interSemiBold();

    // Load logo if exists
    pw.MemoryImage? logoImage;
    if (completeDoc.brand.logoPath != null && completeDoc.brand.logoPath!.isNotEmpty) {
      final logoPath = completeDoc.brand.logoPath!;
      try {
        if (logoPath.startsWith('assets/')) {
          final data = await rootBundle.load(logoPath);
          logoImage = pw.MemoryImage(data.buffer.asUint8List());
        } else {
          final file = File(logoPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            logoImage = pw.MemoryImage(bytes);
          }
        }
      } catch (_) {}
    }

    // Load signature if exists & enabled
    pw.MemoryImage? signatureImage;
    if (completeDoc.document.showSignature &&
        completeDoc.brand.signaturePath != null &&
        completeDoc.brand.signaturePath!.isNotEmpty) {
      final file = File(completeDoc.brand.signaturePath!);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          signatureImage = pw.MemoryImage(bytes);
        } catch (_) {}
      }
    }

    // Load stamp if exists & enabled
    pw.MemoryImage? stampImage;
    if (completeDoc.document.showStamp &&
        completeDoc.brand.stampPath != null &&
        completeDoc.brand.stampPath!.isNotEmpty) {
      final file = File(completeDoc.brand.stampPath!);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          stampImage = pw.MemoryImage(bytes);
        } catch (_) {}
      }
    }

    // Load attachments
    final List<pw.MemoryImage> attachmentImages = [];
    final List<String> attachmentCaptions = [];
    for (final att in completeDoc.attachments) {
      if (att.includeInPdf) {
        final file = File(att.filePath);
        if (await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            attachmentImages.add(pw.MemoryImage(bytes));
            attachmentCaptions.add(att.caption ?? 'Attachment');
          } catch (_) {}
        }
      }
    }

    final metaData = DocumentMetaData.fromRawJson(completeDoc.document.extraJsonData);
    final now = DateTime.now();
    final isExpired = (completeDoc.document.docType == 'quotation' || completeDoc.document.docType == 'proposal') &&
        completeDoc.document.dueOrValidityDate != null &&
        completeDoc.document.dueOrValidityDate!.isBefore(now);
    final symbol = completeDoc.document.currencyCode;
    final targetPageFormat = (completeDoc.document.pageSize.toLowerCase() == 'letter')
        ? PdfPageFormat.letter
        : PdfPageFormat.a4;

    // Main multi-page document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: targetPageFormat,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          italic: regularFont,
          boldItalic: boldFont,
        ),
        header: (context) => _buildHeader(
          context,
          completeDoc: completeDoc,
          palette: palette,
          logoImage: logoImage,
          template: selectedTemplate,
          boldFont: boldFont,
          semiBoldFont: semiBoldFont,
        ),
        footer: (context) => _buildFooter(
          context,
          completeDoc: completeDoc,
          palette: palette,
        ),
        build: (context) => [
          if (isExpired) _buildExpiredWatermark(palette, boldFont),
          _buildClientAndMetaSection(
            completeDoc: completeDoc,
            palette: palette,
            template: selectedTemplate,
            boldFont: boldFont,
          ),
          pw.SizedBox(height: 12),
          if (completeDoc.document.introText != null &&
              completeDoc.document.introText!.trim().isNotEmpty) ...[
            _buildIntroSection(completeDoc: completeDoc, palette: palette, boldFont: boldFont),
            pw.SizedBox(height: 12),
          ],
          if (metaData.showreelUrl != null && metaData.showreelUrl!.isNotEmpty) ...[
            _buildShowreelQrSection(metaData.showreelUrl!, palette, boldFont),
          ],
          if (completeDoc.customFields.isNotEmpty) ...[
            _buildCustomFieldsSection(completeDoc: completeDoc, palette: palette),
            pw.SizedBox(height: 12),
          ],
          if (metaData.packages.isNotEmpty) ...[
            _buildPackageOptionsSection(metaData.packages, symbol, palette, boldFont),
          ] else if (completeDoc.items.isNotEmpty) ...[
            _buildLineItemsTable(
              completeDoc: completeDoc,
              palette: palette,
              template: selectedTemplate,
              boldFont: boldFont,
            ),
            pw.SizedBox(height: 14),
          ],
          if (metaData.addons.isNotEmpty) ...[
            _buildOptionalAddonsSection(metaData.addons, symbol, palette, boldFont),
          ],
          if (metaData.milestones.isNotEmpty) ...[
            _buildPaymentMilestonesSection(metaData.milestones, symbol, palette, boldFont),
          ],
          if (completeDoc.items.isNotEmpty || completeDoc.document.totalAmount > 0 || metaData.packages.isNotEmpty) ...[
            _buildTotalsAndPaymentSection(
              completeDoc: completeDoc,
              palette: palette,
              template: selectedTemplate,
              boldFont: boldFont,
              signatureImage: signatureImage,
              stampImage: stampImage,
            ),
          ] else ...[
            _buildSignaturesAndStampSection(
              completeDoc: completeDoc,
              palette: palette,
              boldFont: boldFont,
              signatureImage: signatureImage,
              stampImage: stampImage,
            ),
          ],
          if (completeDoc.document.closingNotes != null &&
              completeDoc.document.closingNotes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNotesSection(completeDoc: completeDoc, palette: palette, boldFont: boldFont),
          ],
          if (completeDoc.document.termsConditions != null &&
              completeDoc.document.termsConditions!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildTermsSection(completeDoc: completeDoc, palette: palette, boldFont: boldFont),
          ],
        ],
      ),
    );

    // Attachments Page if any
    if (attachmentImages.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: targetPageFormat,
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'DOCUMENT ATTACHMENTS & MEDIA',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    color: palette.primary,
                  ),
                ),
                pw.Text(
                  completeDoc.document.docNumber,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          build: (context) => [
            pw.SizedBox(height: 16),
            pw.Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(attachmentImages.length, (idx) {
                return pw.Container(
                  width: 240,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        height: 160,
                        alignment: pw.Alignment.center,
                        child: pw.Image(
                          attachmentImages[idx],
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        attachmentCaptions[idx],
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }

  // Header
  static pw.Widget _buildHeader(
    pw.Context context, {
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
    pw.MemoryImage? logoImage,
    required PdfTemplateType template,
    required pw.Font boldFont,
    required pw.Font semiBoldFont,
  }) {
    final docType = DocTypeExtension.fromCode(completeDoc.document.docType);

    if (template == PdfTemplateType.bold) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: pw.BoxDecoration(
          color: palette.primary,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              children: [
                if (logoImage != null) ...[
                  pw.Container(
                    width: 48,
                    height: 48,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 12),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      completeDoc.brand.name.toUpperCase(),
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                    if (completeDoc.brand.address != null &&
                        completeDoc.brand.address!.isNotEmpty)
                      pw.Text(
                        completeDoc.brand.address!,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey200),
                      ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  docType.displayName.toUpperCase(),
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 18,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  completeDoc.document.docNumber,
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey200),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: template == PdfTemplateType.modern ? palette.primary : palette.border,
            width: template == PdfTemplateType.modern ? 3 : 1,
          ),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null) ...[
                  pw.Container(
                    width: 55,
                    height: 55,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 14),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        completeDoc.brand.name,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 17,
                          color: palette.primary,
                        ),
                      ),
                      if (completeDoc.brand.address != null &&
                          completeDoc.brand.address!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          completeDoc.brand.address!,
                          style: pw.TextStyle(fontSize: 8, color: palette.textSecondary),
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      if (completeDoc.brand.phone != null &&
                          completeDoc.brand.phone!.isNotEmpty)
                        pw.Text(
                          'Tel: ${completeDoc.brand.phone}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      if (completeDoc.brand.email != null &&
                          completeDoc.brand.email!.isNotEmpty)
                        pw.Text(
                          'Email: ${completeDoc.brand.email}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      if (completeDoc.brand.kraPin != null &&
                          completeDoc.brand.kraPin!.isNotEmpty)
                        pw.Text(
                          'KRA PIN: ${completeDoc.brand.kraPin}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                docType.displayName.toUpperCase(),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 20,
                  color: palette.primary,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                completeDoc.document.docNumber,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: palette.textPrimary,
                ),
              ),
              pw.SizedBox(height: 4),
              _buildStatusBadge(completeDoc.document.status, palette, boldFont),
            ],
          ),
        ],
      ),
    );
  }

  // Status Badge
  static pw.Widget _buildStatusBadge(
    String status,
    PdfColorPalette palette,
    pw.Font boldFont,
  ) {
    PdfColor badgeBg = PdfColors.grey200;
    PdfColor badgeText = PdfColors.grey800;

    switch (status.toLowerCase()) {
      case 'paid':
        badgeBg = PdfColors.green100;
        badgeText = PdfColors.green900;
        break;
      case 'sent':
        badgeBg = PdfColors.blue100;
        badgeText = PdfColors.blue900;
        break;
      case 'overdue':
        badgeBg = PdfColors.red100;
        badgeText = PdfColors.red900;
        break;
      case 'draft':
        badgeBg = PdfColors.grey200;
        badgeText = PdfColors.grey800;
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: badgeBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        status.toUpperCase(),
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 8,
          color: badgeText,
        ),
      ),
    );
  }

  // Client and Metadata Section
  static pw.Widget _buildClientAndMetaSection({
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
    required PdfTemplateType template,
    required pw.Font boldFont,
  }) {
    final client = completeDoc.client;
    final docType = DocTypeExtension.fromCode(completeDoc.document.docType);
    String recipientLabel = 'BILLED TO:';
    switch (docType) {
      case DocType.quotation:
        recipientLabel = 'PROPOSAL FOR / CLIENT:';
        break;
      case DocType.invoice:
        recipientLabel = 'BILLED TO:';
        break;
      case DocType.receipt:
        recipientLabel = 'RECEIVED FROM:';
        break;
      case DocType.rateCard:
        recipientLabel = 'PREPARED FOR:';
        break;
      case DocType.contract:
        recipientLabel = 'PARTIES / CLIENT:';
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: template == PdfTemplateType.minimal ? PdfColors.white : palette.surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: palette.border),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bill To / Client Info
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  recipientLabel,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: palette.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  client?.name ?? 'Client / Walk-in Customer',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    color: palette.textPrimary,
                  ),
                ),
                if (client?.organization != null &&
                    client!.organization!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    client.organization!,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
                if (client?.email != null && client!.email!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    client.email!,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
                if (client?.phone != null && client!.phone!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    client.phone!,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
                if (client?.address != null && client!.address!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    client.address!,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
                if (client?.kraPin != null && client!.kraPin!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'KRA PIN: ${client.kraPin}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(width: 20),

          // Document Dates and Meta
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildMetaRow('Date Issued:', DateFormatter.format(completeDoc.document.issueDate), boldFont),
                if (completeDoc.document.dueOrValidityDate != null) ...[
                  pw.SizedBox(height: 4),
                  _buildMetaRow(
                    completeDoc.document.docType == 'quotation' ? 'Valid Until:' : 'Due Date:',
                    DateFormatter.format(completeDoc.document.dueOrValidityDate!),
                    boldFont,
                  ),
                ],
                pw.SizedBox(height: 4),
                _buildMetaRow('Currency:', completeDoc.document.currencyCode, boldFont),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaRow(String label, String value, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey900),
        ),
      ],
    );
  }

  // Custom Fields Section
  static pw.Widget _buildCustomFieldsSection({
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
  }) {
    final validFields = completeDoc.customFields.where((cf) => cf.value != null && cf.value!.isNotEmpty).toList();
    if (validFields.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: palette.border),
      ),
      child: pw.Wrap(
        spacing: 20,
        runSpacing: 6,
        children: validFields.map((cf) {
          return pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                '${cf.definition.fieldLabel}: ',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                cf.value!,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Line Items Table
  static pw.Widget _buildLineItemsTable({
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
    required PdfTemplateType template,
    required pw.Font boldFont,
  }) {
    final symbol = completeDoc.document.currencyCode;

    final table = pw.TableHelper.fromTextArray(
      border: template == PdfTemplateType.minimal
          ? const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
            )
          : pw.TableBorder(
              horizontalInside: pw.BorderSide(color: palette.border, width: 0.5),
              bottom: pw.BorderSide(color: palette.border, width: 1),
            ),
      headerDecoration: pw.BoxDecoration(
        color: (template == PdfTemplateType.bold || template == PdfTemplateType.modern)
            ? palette.primary
            : template == PdfTemplateType.minimal
                ? PdfColors.white
                : palette.surface,
      ),
      headerHeight: 28,
      cellHeight: 28,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      headerStyle: pw.TextStyle(
        font: boldFont,
        fontSize: 8,
        color: (template == PdfTemplateType.bold || template == PdfTemplateType.modern)
            ? PdfColors.white
            : palette.primary,
        letterSpacing: 0.5,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
      headers: ['#', 'ITEM & DESCRIPTION', 'QTY', 'UNIT RATE', 'TOTAL'],
      data: List.generate(completeDoc.items.length, (index) {
        final item = completeDoc.items[index];
        final unitText = item.unit.isNotEmpty ? ' ${item.unit}' : '';
        return [
          '${index + 1}',
          item.details != null && item.details!.isNotEmpty
              ? '${item.description}\n${item.details}'
              : item.description,
          '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)}$unitText',
          CurrencyFormatter.format(item.unitPrice, currencyCode: symbol),
          CurrencyFormatter.format(item.lineTotal, currencyCode: symbol),
        ];
      }),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Budget Breakdown.',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 12,
            color: palette.primary,
          ),
        ),
        pw.SizedBox(height: 6),
        table,
      ],
    );
  }

  // Totals & Payment Section
  static pw.Widget _buildTotalsAndPaymentSection({
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
    required PdfTemplateType template,
    required pw.Font boldFont,
    pw.MemoryImage? signatureImage,
    pw.MemoryImage? stampImage,
  }) {
    final doc = completeDoc.document;
    final brand = completeDoc.brand;
    final symbol = doc.currencyCode;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Payment Details & QR Code & Signatures (Left)
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (brand.mpesaDetails != null || brand.bankDetails != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: palette.surface,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: palette.border),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'PAYMENT INSTRUCTIONS:',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8,
                                color: palette.primary,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            if (brand.mpesaDetails != null && brand.mpesaDetails!.isNotEmpty)
                              pw.Text(
                                brand.mpesaDetails!,
                                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
                              ),
                            if (brand.bankDetails != null && brand.bankDetails!.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                brand.bankDetails!,
                                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Payment QR Code
                      pw.Container(
                        width: 54,
                        height: 54,
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: '${brand.name} | Doc: ${doc.docNumber} | Total: ${doc.totalAmount} ${doc.currencyCode}',
                          drawText: false,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],

              // Signatures & Stamp
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (signatureImage != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 100,
                          height: 45,
                          child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                        ),
                        pw.Container(width: 110, height: 1, color: PdfColors.grey400),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Authorized Signature',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  if (stampImage != null) ...[
                    pw.SizedBox(width: 14),
                    pw.Container(
                      width: 55,
                      height: 55,
                      child: pw.Image(stampImage, fit: pw.BoxFit.contain),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(width: 20),

        // Totals Breakdown (Right)
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: palette.surface,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: palette.border),
            ),
            child: pw.Column(
              children: [
                _buildTotalRow('Subtotal', CurrencyFormatter.format(doc.subtotal, currencyCode: symbol), boldFont),
                if (doc.discountAmount > 0) ...[
                  pw.SizedBox(height: 4),
                  _buildTotalRow(
                    'Discount',
                    '- ${CurrencyFormatter.format(doc.discountAmount, currencyCode: symbol)}',
                    boldFont,
                    color: PdfColors.red800,
                  ),
                ],
                if (doc.taxAmount > 0) ...[
                  pw.SizedBox(height: 4),
                  _buildTotalRow(
                    'VAT (16%)',
                    CurrencyFormatter.format(doc.taxAmount, currencyCode: symbol),
                    boldFont,
                  ),
                ],
                pw.Divider(color: palette.border, thickness: 1),
                _buildTotalRow(
                  'TOTAL',
                  CurrencyFormatter.format(doc.totalAmount, currencyCode: symbol),
                  boldFont,
                  isGrandTotal: doc.whtAmount == 0,
                  palette: palette,
                ),
                if (doc.whtAmount > 0) ...[
                  pw.SizedBox(height: 4),
                  _buildTotalRow(
                    'Less: Withholding Tax (${doc.whtPercent.toStringAsFixed(1)}%)',
                    '- ${CurrencyFormatter.format(doc.whtAmount, currencyCode: symbol)}',
                    boldFont,
                    color: PdfColors.red800,
                  ),
                  pw.Divider(color: palette.border, thickness: 1),
                  _buildTotalRow(
                    'NET AMOUNT PAYABLE',
                    CurrencyFormatter.format(doc.netAmountPayable > 0 ? doc.netAmountPayable : doc.totalAmount - doc.whtAmount, currencyCode: symbol),
                    boldFont,
                    isGrandTotal: true,
                    palette: palette,
                  ),
                ],
                if (doc.showAmountInWords) ...[
                  pw.SizedBox(height: 6),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(5),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      'Amount in words: ${NumberInWords.convert(doc.netAmountPayable > 0 ? doc.netAmountPayable : doc.totalAmount, currencyCode: doc.currencyCode)}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 7,
                        color: PdfColors.grey900,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                if (doc.currencyCode.toUpperCase() != 'KES' && doc.kesEquivalentRate != null && doc.kesEquivalentRate! > 0) ...[
                  pw.SizedBox(height: 6),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: palette.border, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      'Equivalent: KES ${CurrencyFormatter.format(doc.kesEquivalentAmount ?? (doc.totalAmount * doc.kesEquivalentRate!), currencyCode: 'KES', includeSymbol: false)} (Rate: 1 ${doc.currencyCode} = ${doc.kesEquivalentRate!.toStringAsFixed(2)} KES${doc.kesEquivalentDate != null ? ' as at ${DateFormatter.format(doc.kesEquivalentDate!)}' : ''})',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
                if (doc.depositAmount > 0) ...[
                  pw.SizedBox(height: 4),
                  _buildTotalRow(
                    'Deposit Required',
                    CurrencyFormatter.format(doc.depositAmount, currencyCode: symbol),
                    boldFont,
                  ),
                ],
                if (doc.balanceDue < doc.totalAmount) ...[
                  pw.SizedBox(height: 4),
                  _buildTotalRow(
                    'Amount Paid',
                    CurrencyFormatter.format(doc.totalAmount - doc.balanceDue, currencyCode: symbol),
                    boldFont,
                    color: PdfColors.green800,
                  ),
                ],
                if (doc.balanceDue > 0) ...[
                  pw.SizedBox(height: 4),
                  _buildTotalRow(
                    'Balance Due',
                    CurrencyFormatter.format(doc.balanceDue, currencyCode: symbol),
                    boldFont,
                    color: PdfColors.red900,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value,
    pw.Font boldFont, {
    bool isGrandTotal = false,
    PdfColor? color,
    PdfColorPalette? palette,
  }) {
    if (isGrandTotal) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF5A623),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 9.5,
                color: PdfColors.black,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10.5,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            color: color ?? PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 8,
            color: color ?? PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  // Intro / Scope Section
  static pw.Widget _buildIntroSection({
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: palette.border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            completeDoc.document.titleOverride?.toUpperCase() ?? 'EXECUTIVE SUMMARY / SCOPE OF SERVICES',
            style: pw.TextStyle(font: boldFont, fontSize: 8, color: palette.primary, letterSpacing: 0.5),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            completeDoc.document.introText!,
            style: const pw.TextStyle(fontSize: 8, height: 1.4, color: PdfColors.grey900),
          ),
        ],
      ),
    );
  }

  // Non-financial Signatures & Stamp Section
  static pw.Widget _buildSignaturesAndStampSection({
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
    required pw.Font boldFont,
    pw.MemoryImage? signatureImage,
    pw.MemoryImage? stampImage,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: palette.border, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Left: Issued By & Signatures
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ISSUED & AUTHORIZED BY:',
                style: pw.TextStyle(font: boldFont, fontSize: 8, color: palette.primary),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                completeDoc.brand.name,
                style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: PdfColors.grey900),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (signatureImage != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 100,
                          height: 45,
                          child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                        ),
                        pw.Container(width: 110, height: 1, color: PdfColors.grey400),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Authorized Signatory',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  if (stampImage != null) ...[
                    pw.SizedBox(width: 14),
                    pw.Container(
                      width: 50,
                      height: 50,
                      child: pw.Image(stampImage, fit: pw.BoxFit.contain),
                    ),
                  ],
                ],
              ),
            ],
          ),
          // Right: Recipient Acceptance line
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'RECEIVED & ACKNOWLEDGED BY:',
                style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 38),
              pw.Container(width: 130, height: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 2),
              pw.Text(
                completeDoc.client?.name ?? 'Client / Recipient Signature',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Notes Section
  static pw.Widget _buildNotesSection({
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: palette.border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NOTES:',
            style: pw.TextStyle(font: boldFont, fontSize: 7, color: palette.primary),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            completeDoc.document.closingNotes!,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  // Terms Section
  static pw.Widget _buildTermsSection({
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: palette.border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TERMS & CONDITIONS:',
            style: pw.TextStyle(font: boldFont, fontSize: 7, color: palette.primary),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            completeDoc.document.termsConditions!,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  // Footer
  static pw.Widget _buildFooter(
    pw.Context context, {
    required CompleteDocument completeDoc,
    required PdfColorPalette palette,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Thank you for your business! - ${completeDoc.brand.name}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExpiredWatermark(PdfColorPalette palette, pw.Font boldFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.red600,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Center(
        child: pw.Text(
          '*** EXPIRED DOCUMENT - THIS QUOTATION / PROPOSAL HAS PASSED ITS VALIDITY DATE ***',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 10,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildShowreelQrSection(String url, PdfColorPalette palette, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: palette.primary, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 50,
            height: 50,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: url,
              drawText: false,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SHOWREEL & PORTFOLIO VIDEO',
                  style: pw.TextStyle(font: boldFont, fontSize: 9, color: palette.primary),
                ),
                pw.SizedBox(height: 2),
                pw.UrlLink(
                  destination: url,
                  child: pw.Text(
                    url,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.blue800,
                      decoration: pw.TextDecoration.underline,
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

  static pw.Widget _buildPackageOptionsSection(
      List<PackageOption> packages, String symbol, PdfColorPalette palette, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PROPOSAL PACKAGE OPTIONS', style: pw.TextStyle(font: boldFont, fontSize: 10, color: palette.primary)),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: packages.map((pkg) {
            return pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.only(right: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: pkg.isRecommended ? palette.surface : PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(
                    color: pkg.isRecommended ? palette.primary : PdfColors.grey300,
                    width: pkg.isRecommended ? 1.5 : 1,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (pkg.isRecommended)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: palette.primary,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text('RECOMMENDED', style: pw.TextStyle(font: boldFont, fontSize: 6, color: PdfColors.white)),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text(pkg.title, style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(CurrencyFormatter.format(pkg.price, currencyCode: symbol),
                        style: pw.TextStyle(font: boldFont, fontSize: 11, color: palette.primary)),
                    pw.SizedBox(height: 6),
                    ...pkg.deliverables.map((d) => pw.Text('• $d', style: const pw.TextStyle(fontSize: 7))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildOptionalAddonsSection(
      List<OptionalAddon> addons, String symbol, PdfColorPalette palette, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('OPTIONAL UPGRADES & ADD-ONS', style: pw.TextStyle(font: boldFont, fontSize: 10, color: palette.primary)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerDecoration: pw.BoxDecoration(color: palette.surface),
          headers: ['ADD-ON ITEM', 'DETAILS', 'PRICE ($symbol)'],
          headerStyle: pw.TextStyle(font: boldFont, fontSize: 8, color: palette.primary),
          cellStyle: const pw.TextStyle(fontSize: 8),
          data: addons.map((a) => [
            a.name,
            a.details ?? '-',
            CurrencyFormatter.format(a.price, currencyCode: symbol),
          ]).toList(),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildPaymentMilestonesSection(
      List<PaymentMilestone> milestones, String symbol, PdfColorPalette palette, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PAYMENT MILESTONES SCHEDULE', style: pw.TextStyle(font: boldFont, fontSize: 10, color: palette.primary)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerDecoration: pw.BoxDecoration(color: palette.surface),
          headers: ['MILESTONE PHASE', 'SHARE (%)', 'AMOUNT ($symbol)', 'DUE / TRIGGER'],
          headerStyle: pw.TextStyle(font: boldFont, fontSize: 8, color: palette.primary),
          cellStyle: const pw.TextStyle(fontSize: 8),
          data: milestones.map((m) => [
            m.title,
            '${m.percentage.toStringAsFixed(0)}%',
            CurrencyFormatter.format(m.amount, currencyCode: symbol),
            m.dueDateText ?? '-',
          ]).toList(),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }
}
