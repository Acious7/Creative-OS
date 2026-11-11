import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ImageRasterizer {
  // Rasterizes PDF bytes into a list of PNG image files
  static Future<List<File>> rasterizePdfToImages({
    required Uint8List pdfBytes,
    required String docNumber,
    double dpi = 200,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final cleanDocNum = docNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    final List<File> imageFiles = [];

    int pageIndex = 1;
    await for (final page in Printing.raster(pdfBytes, dpi: dpi)) {
      final pngBytes = await page.toPng();
      final file = File('${tempDir.path}/${cleanDocNum}_page_$pageIndex.png');
      await file.writeAsBytes(pngBytes);
      imageFiles.add(file);
      pageIndex++;
    }

    return imageFiles;
  }

  // Share images via WhatsApp / system share
  static Future<void> shareAsImages({
    required Uint8List pdfBytes,
    required String docNumber,
    String? subject,
    String? message,
  }) async {
    final files = await rasterizePdfToImages(pdfBytes: pdfBytes, docNumber: docNumber);
    if (files.isEmpty) return;

    final xFiles = files.map((f) => XFile(f.path)).toList();
    await Share.shareXFiles(
      xFiles,
      text: message ?? 'Document $docNumber',
      subject: subject ?? docNumber,
    );
  }

  // Save PDF to downloads folder
  static Future<String> savePdfToDownloads({
    required Uint8List pdfBytes,
    required String docNumber,
  }) async {
    final cleanDocNum = docNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    Directory? downloadsDir;

    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        downloadsDir = await getExternalStorageDirectory();
      }
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    final filePath = '${downloadsDir!.path}/$cleanDocNum.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return filePath;
  }
}
