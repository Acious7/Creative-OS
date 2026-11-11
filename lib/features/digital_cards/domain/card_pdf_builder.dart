import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/database/app_database.dart';
import 'vcard_builder.dart';

enum CardPrintSize {
  standardEu, // 85 x 55 mm
  standardUs, // 3.5 x 2.0 in (88.9 x 50.8 mm)
}

class CardPdfBuilder {
  static Future<Uint8List> buildPrintPdf({
    required BusinessCard card,
    required Brand brand,
    CardPrintSize printSize = CardPrintSize.standardEu,
    bool includeBleed = true,
    bool includeCropMarks = true,
    bool includeSafeAreaGuides = false,
    bool isGangSheet = false, // 10 cards per A4 page
  }) async {
    final doc = pw.Document();

    // Dimensions in points (1 mm = 2.83465 pt, 1 inch = 72 pt)
    final cardWidthMm = printSize == CardPrintSize.standardEu ? 85.0 : 88.9;
    final cardHeightMm = printSize == CardPrintSize.standardEu ? 55.0 : 50.8;
    final bleedMm = includeBleed ? 3.0 : 0.0;

    final cardWidthPt = cardWidthMm * 2.83465;
    final cardHeightPt = cardHeightMm * 2.83465;
    final bleedPt = bleedMm * 2.83465;

    final totalWidthPt = cardWidthPt + (bleedPt * 2);
    final totalHeightPt = cardHeightPt + (bleedPt * 2);

    final brandColorHex = card.accentColorOverride ?? brand.accentColorHex;
    final primaryColor = _parseHexColor(brandColorHex);
    final vCardData = VCardBuilder.buildVCard(card).vCardString;

    if (isGangSheet) {
      // 10 cards per A4 page (2 columns x 5 rows)
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: cardWidthPt / cardHeightPt,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: List.generate(
                10,
                (index) => _buildCardFrontWidget(
                  card: card,
                  brand: brand,
                  primaryColor: primaryColor,
                  width: cardWidthPt,
                  height: cardHeightPt,
                  showSafeArea: includeSafeAreaGuides,
                ),
              ),
            );
          },
        ),
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: cardWidthPt / cardHeightPt,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: List.generate(
                10,
                (index) => _buildCardBackWidget(
                  card: card,
                  brand: brand,
                  primaryColor: primaryColor,
                  vCardData: vCardData,
                  width: cardWidthPt,
                  height: cardHeightPt,
                  showSafeArea: includeSafeAreaGuides,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Single card pages with crop marks & bleed
      final pageFormat = PdfPageFormat(totalWidthPt + 40, totalHeightPt + 40);

      // Page 1: Front
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Stack(
                children: [
                  pw.Container(
                    width: totalWidthPt,
                    height: totalHeightPt,
                    padding: pw.EdgeInsets.all(bleedPt),
                    child: _buildCardFrontWidget(
                      card: card,
                      brand: brand,
                      primaryColor: primaryColor,
                      width: cardWidthPt,
                      height: cardHeightPt,
                      showSafeArea: includeSafeAreaGuides,
                    ),
                  ),
                  if (includeCropMarks)
                    ..._buildCropMarks(totalWidthPt, totalHeightPt, bleedPt),
                ],
              ),
            );
          },
        ),
      );

      // Page 2: Back
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Stack(
                children: [
                  pw.Container(
                    width: totalWidthPt,
                    height: totalHeightPt,
                    padding: pw.EdgeInsets.all(bleedPt),
                    child: _buildCardBackWidget(
                      card: card,
                      brand: brand,
                      primaryColor: primaryColor,
                      vCardData: vCardData,
                      width: cardWidthPt,
                      height: cardHeightPt,
                      showSafeArea: includeSafeAreaGuides,
                    ),
                  ),
                  if (includeCropMarks)
                    ..._buildCropMarks(totalWidthPt, totalHeightPt, bleedPt),
                ],
              ),
            );
          },
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _buildCardFrontWidget({
    required BusinessCard card,
    required Brand brand,
    required PdfColor primaryColor,
    required double width,
    required double height,
    required bool showSafeArea,
  }) {
    final isBold = card.designStyle == 'bold';
    final bgColor = isBold ? primaryColor : PdfColors.white;
    final textColor = isBold ? PdfColors.white : PdfColors.grey900;
    final subColor = isBold ? PdfColors.grey300 : PdfColors.grey700;

    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        border: showSafeArea
            ? pw.Border.all(color: PdfColors.red300, width: 0.5)
            : pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                (card.companyName ?? brand.name).toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: isBold ? PdfColors.white : primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Container(
                width: 6,
                height: 6,
                decoration: pw.BoxDecoration(
                  color: isBold ? PdfColors.white : primaryColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                card.personName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (card.personRole != null && card.personRole!.isNotEmpty)
                pw.Text(
                  card.personRole!,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: isBold ? PdfColors.grey200 : primaryColor,
                  ),
                ),
              if (card.tagline != null && card.tagline!.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  card.tagline!,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontStyle: pw.FontStyle.italic,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (card.website != null && card.website!.isNotEmpty)
                pw.Text(
                  card.website!,
                  style: pw.TextStyle(fontSize: 7, color: subColor),
                ),
              if (card.email != null && card.email!.isNotEmpty)
                pw.Text(
                  card.email!,
                  style: pw.TextStyle(fontSize: 7, color: subColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCardBackWidget({
    required BusinessCard card,
    required Brand brand,
    required PdfColor primaryColor,
    required String vCardData,
    required double width,
    required double height,
    required bool showSafeArea,
  }) {
    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        border: showSafeArea
            ? pw.Border.all(color: PdfColors.red300, width: 0.5)
            : pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (card.primaryPhone != null)
                  pw.Text(
                    'TEL: ${card.primaryPhone}',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey800,
                    ),
                  ),
                if (card.email != null)
                  pw.Text(
                    'EMAIL: ${card.email}',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey800,
                    ),
                  ),
                if (card.website != null)
                  pw.Text(
                    'WEB: ${card.website}',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey800,
                    ),
                  ),
                if (card.address != null)
                  pw.Text(
                    'LOC: ${card.address}',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey800,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.BarcodeWidget(
            data: vCardData,
            barcode: pw.Barcode.qrCode(),
            width: 50,
            height: 50,
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildCropMarks(
    double width,
    double height,
    double bleed,
  ) {
    const markLength = 12.0;
    return [
      // Top-Left crop marks
      pw.Positioned(
        left: 0,
        top: bleed,
        child: pw.Container(
          width: markLength,
          height: 0.5,
          color: PdfColors.black,
        ),
      ),
      pw.Positioned(
        left: bleed,
        top: 0,
        child: pw.Container(
          width: 0.5,
          height: markLength,
          color: PdfColors.black,
        ),
      ),
      // Top-Right crop marks
      pw.Positioned(
        right: 0,
        top: bleed,
        child: pw.Container(
          width: markLength,
          height: 0.5,
          color: PdfColors.black,
        ),
      ),
      pw.Positioned(
        right: bleed,
        top: 0,
        child: pw.Container(
          width: 0.5,
          height: markLength,
          color: PdfColors.black,
        ),
      ),
      // Bottom-Left crop marks
      pw.Positioned(
        left: 0,
        bottom: bleed,
        child: pw.Container(
          width: markLength,
          height: 0.5,
          color: PdfColors.black,
        ),
      ),
      pw.Positioned(
        left: bleed,
        bottom: 0,
        child: pw.Container(
          width: 0.5,
          height: markLength,
          color: PdfColors.black,
        ),
      ),
      // Bottom-Right crop marks
      pw.Positioned(
        right: 0,
        bottom: bleed,
        child: pw.Container(
          width: markLength,
          height: 0.5,
          color: PdfColors.black,
        ),
      ),
      pw.Positioned(
        right: bleed,
        bottom: 0,
        child: pw.Container(
          width: 0.5,
          height: markLength,
          color: PdfColors.black,
        ),
      ),
    ];
  }

  static PdfColor _parseHexColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    final val = int.parse(buffer.toString(), radix: 16);
    return PdfColor.fromInt(val);
  }
}
