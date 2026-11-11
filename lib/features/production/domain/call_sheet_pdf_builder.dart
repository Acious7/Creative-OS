import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/database/app_database.dart';
import 'production_models.dart';

class CallSheetPdfBuilder {
  static Future<Uint8List> buildCallSheetPdf({
    required CallSheet cs,
    required Brand brand,
  }) async {
    final pdf = pw.Document(
      title: '${cs.title} - Call Sheet',
      author: brand.name,
    );

    final regularFont = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();

    // Parse Crew
    List<CrewMember> crewList = [];
    if (cs.crewJson != null && cs.crewJson!.isNotEmpty) {
      try {
        final list = jsonDecode(cs.crewJson!) as List<dynamic>;
        crewList = list
            .map((e) => CrewMember.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Parse Schedule
    List<ScheduleScene> scheduleList = [];
    if (cs.scheduleJson != null && cs.scheduleJson!.isNotEmpty) {
      try {
        final list = jsonDecode(cs.scheduleJson!) as List<dynamic>;
        scheduleList = list
            .map((e) => ScheduleScene.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Load logo if available
    pw.MemoryImage? logoImage;
    if (brand.logoPath != null && brand.logoPath!.isNotEmpty) {
      try {
        if (brand.logoPath!.startsWith('assets/')) {
          final data = await rootBundle.load(brand.logoPath!);
          logoImage = pw.MemoryImage(data.buffer.asUint8List());
        } else {
          final file = File(brand.logoPath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            logoImage = pw.MemoryImage(bytes);
          }
        }
      } catch (_) {}
    }

    final emberColor = PdfColor.fromHex('#38B6DB');
    final darkBase = PdfColor.fromHex('#111417');
    final greyText = PdfColor.fromHex('#6B7280');
    final lightGreyBg = PdfColor.fromHex('#F3F4F6');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 40,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Text(
                        brand.name.toUpperCase(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: darkBase,
                          letterSpacing: 2,
                        ),
                      ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'OFFICIAL PRODUCTION CALL SHEET',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 9,
                        color: emberColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: emberColor,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'GENERAL CREW CALL',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: PdfColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.Text(
                        cs.callTime,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(height: 1.5, color: darkBase),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (context) => [
          // Project Title & Date
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGreyBg,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SHOOT / PRODUCTION',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: greyText,
                        font: boldFont,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      cs.title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        font: boldFont,
                        color: darkBase,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'DATE',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: greyText,
                        font: boldFont,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      DateFormat('EEEE, d MMMM yyyy').format(cs.shootDate),
                      style: pw.TextStyle(
                        fontSize: 12,
                        font: boldFont,
                        color: darkBase,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Location & Sun/Weather Row
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Location Column
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LOCATION / SET',
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: boldFont,
                          color: emberColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        cs.locationName,
                        style: pw.TextStyle(
                          fontSize: 11,
                          font: boldFont,
                          color: darkBase,
                        ),
                      ),
                      if (cs.locationAddress != null &&
                          cs.locationAddress!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          cs.locationAddress!,
                          style: pw.TextStyle(fontSize: 9, color: greyText),
                        ),
                      ],
                      if (cs.locationGps != null &&
                          cs.locationGps!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'GPS: ${cs.locationGps!}',
                          style: pw.TextStyle(fontSize: 8, color: greyText),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),

              // Sun & Weather Column
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SUN & WEATHER',
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: boldFont,
                          color: emberColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      if (cs.weatherForecast != null)
                        pw.Text(
                          cs.weatherForecast!,
                          style: pw.TextStyle(
                            fontSize: 9,
                            font: boldFont,
                            color: darkBase,
                          ),
                        ),
                      if (cs.sunriseTime != null)
                        pw.Text(
                          'Sunrise: ${cs.sunriseTime!}',
                          style: pw.TextStyle(fontSize: 8, color: greyText),
                        ),
                      if (cs.sunsetTime != null)
                        pw.Text(
                          'Sunset: ${cs.sunsetTime!}',
                          style: pw.TextStyle(fontSize: 8, color: greyText),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Nearest Hospital Banner
          if (cs.nearestHospital != null && cs.nearestHospital!.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FEF2F2'),
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColor.fromHex('#FCA5A5')),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'EMERGENCY / HOSPITAL: ',
                    style: pw.TextStyle(
                      fontSize: 8,
                      font: boldFont,
                      color: PdfColor.fromHex('#DC2626'),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      cs.nearestHospital!,
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: boldFont,
                        color: darkBase,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 16),

          // Schedule Section
          if (scheduleList.isNotEmpty) ...[
            pw.Text(
              'SHOOTING SCHEDULE',
              style: pw.TextStyle(
                fontSize: 10,
                font: boldFont,
                color: darkBase,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E5E7EB'),
                width: 0.5,
              ),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGreyBg),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'TIME',
                        style: pw.TextStyle(fontSize: 8, font: boldFont),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'SCENE / DESCRIPTION',
                        style: pw.TextStyle(fontSize: 8, font: boldFont),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'LOCATION / SET',
                        style: pw.TextStyle(fontSize: 8, font: boldFont),
                      ),
                    ),
                  ],
                ),
                ...scheduleList.map(
                  (s) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          s.time,
                          style: pw.TextStyle(fontSize: 8, font: boldFont),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              s.scene,
                              style: pw.TextStyle(fontSize: 8, font: boldFont),
                            ),
                            if (s.description.isNotEmpty)
                              pw.Text(
                                s.description,
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  color: greyText,
                                ),
                              ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          s.location,
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Crew Section
          if (crewList.isNotEmpty) ...[
            pw.Text(
              'CREW ROSTER & CALL TIMES',
              style: pw.TextStyle(
                fontSize: 10,
                font: boldFont,
                color: darkBase,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E5E7EB'),
                width: 0.5,
              ),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGreyBg),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'ROLE',
                        style: pw.TextStyle(fontSize: 8, font: boldFont),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'NAME',
                        style: pw.TextStyle(fontSize: 8, font: boldFont),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'PHONE',
                        style: pw.TextStyle(fontSize: 8, font: boldFont),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'CALL',
                        style: pw.TextStyle(fontSize: 8, font: boldFont),
                      ),
                    ),
                  ],
                ),
                ...crewList.map(
                  (c) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          c.role,
                          style: pw.TextStyle(
                            fontSize: 8,
                            font: boldFont,
                            color: emberColor,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          c.name,
                          style: pw.TextStyle(fontSize: 8, font: boldFont),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          c.phone,
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          c.callTime,
                          style: pw.TextStyle(fontSize: 8, font: boldFont),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Production Notes
          if (cs.generalNotes != null && cs.generalNotes!.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: lightGreyBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DIRECTOR & SAFETY NOTES',
                    style: pw.TextStyle(
                      fontSize: 8,
                      font: boldFont,
                      color: emberColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    cs.generalNotes!,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: darkBase,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }
}
