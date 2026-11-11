import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum WhisperModelTier {
  fast('tiny', 'Fast (Tiny)', '~75 MB', 77691713),
  balanced('base', 'Balanced (Base)', '~140 MB', 147951465),
  accurate('small', 'Accurate (Small)', '~460 MB', 487601967);

  final String modelName;
  final String label;
  final String approximateSize;
  final int expectedSizeBytes;

  const WhisperModelTier(
    this.modelName,
    this.label,
    this.approximateSize,
    this.expectedSizeBytes,
  );

  String get fileName => 'ggml-$modelName.bin';
}

class WhisperModelDownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double fraction;
  final bool isResumed;
  final bool isCompleted;

  const WhisperModelDownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.fraction,
    this.isResumed = false,
    this.isCompleted = false,
  });

  String get currentMb => (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get totalMb => (totalBytes / (1024 * 1024)).toStringAsFixed(1);
  int get percent => (fraction * 100).clamp(0, 100).toInt();
}

class WhisperModelService {
  static const String _downloadBaseUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main';

  /// Returns the directory where whisper model files are permanently cached
  static Future<Directory> getModelDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDocDir.path}/whisper_models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// Checks if a model file already exists on disk and is complete & valid
  static Future<bool> isModelDownloaded(WhisperModelTier tier) async {
    final modelDir = await getModelDirectory();
    final file = File('${modelDir.path}/${tier.fileName}');
    if (!await file.exists()) return false;
    final length = await file.length();
    // Verify file matches expected size within 1 MB tolerance
    return (length - tier.expectedSizeBytes).abs() < 1024 * 1024;
  }

  /// Returns the number of bytes saved in a partial (.part) download, or 0 if none
  static Future<int> getPartialDownloadBytes(WhisperModelTier tier) async {
    final modelDir = await getModelDirectory();
    final partFile = File('${modelDir.path}/${tier.fileName}.part');
    if (await partFile.exists()) {
      return await partFile.length();
    }
    return 0;
  }

  /// Discard partial download to start fresh
  static Future<void> deletePartialDownload(WhisperModelTier tier) async {
    final modelDir = await getModelDirectory();
    final partFile = File('${modelDir.path}/${tier.fileName}.part');
    if (await partFile.exists()) {
      await partFile.delete();
    }
  }

  /// Returns the local path to the model file if present and valid, null otherwise
  static Future<String?> getModelPath(WhisperModelTier tier) async {
    final modelDir = await getModelDirectory();
    final file = File('${modelDir.path}/${tier.fileName}');
    if (await file.exists()) {
      final length = await file.length();
      if ((length - tier.expectedSizeBytes).abs() < 1024 * 1024) {
        return file.path;
      }
    }
    return null;
  }

  /// Downloads a model file with HTTP range resumption support
  /// If interrupted, progress is saved in .part file and resumed when called again
  static Stream<WhisperModelDownloadProgress> downloadModel(
    WhisperModelTier tier,
  ) async* {
    final modelDir = await getModelDirectory();
    final targetFile = File('${modelDir.path}/${tier.fileName}');
    final partFile = File('${modelDir.path}/${tier.fileName}.part');

    // 1. If final file is already valid on disk, return immediately
    if (await targetFile.exists()) {
      final length = await targetFile.length();
      if ((length - tier.expectedSizeBytes).abs() < 1024 * 1024) {
        yield WhisperModelDownloadProgress(
          downloadedBytes: length,
          totalBytes: length,
          fraction: 1.0,
          isCompleted: true,
        );
        return;
      } else {
        // Corrupted or incomplete final file; delete and restart
        await targetFile.delete();
      }
    }

    // 2. Determine existing bytes in .part file
    int existingBytes = 0;
    if (await partFile.exists()) {
      existingBytes = await partFile.length();
      // If .part is already >= expected size, verify and finalize
      if (existingBytes >= tier.expectedSizeBytes) {
        if ((existingBytes - tier.expectedSizeBytes).abs() < 1024 * 1024) {
          await partFile.rename(targetFile.path);
          yield WhisperModelDownloadProgress(
            downloadedBytes: existingBytes,
            totalBytes: existingBytes,
            fraction: 1.0,
            isCompleted: true,
          );
          return;
        } else {
          // Incompatible partial file, reset
          await partFile.delete();
          existingBytes = 0;
        }
      }
    }

    final url = Uri.parse('$_downloadBaseUrl/${tier.fileName}');
    final client = HttpClient();
    client.autoUncompress = false;
    client.connectionTimeout = const Duration(seconds: 30);

    IOSink? sink;
    try {
      final request = await client.getUrl(url);

      if (existingBytes > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
      }

      final response = await request.close();

      int totalBytes = tier.expectedSizeBytes;
      bool isAppending = false;

      if (response.statusCode == HttpStatus.partialContent) {
        // 206 Partial Content: resume appending
        isAppending = true;
        sink = partFile.openWrite(mode: FileMode.append);
        yield WhisperModelDownloadProgress(
          downloadedBytes: existingBytes,
          totalBytes: totalBytes,
          fraction: (existingBytes / totalBytes).clamp(0.0, 1.0),
          isResumed: true,
        );
      } else if (response.statusCode == HttpStatus.ok) {
        // 200 OK: server started from beginning
        existingBytes = 0;
        sink = partFile.openWrite(mode: FileMode.write);
        if (response.contentLength > 0) {
          totalBytes = response.contentLength;
        }
      } else if (response.statusCode ==
          HttpStatus.requestedRangeNotSatisfiable) {
        // 416 Range Not Satisfiable: partial file may already be complete
        if ((existingBytes - tier.expectedSizeBytes).abs() < 1024 * 1024) {
          await partFile.rename(targetFile.path);
          yield WhisperModelDownloadProgress(
            downloadedBytes: existingBytes,
            totalBytes: existingBytes,
            fraction: 1.0,
            isCompleted: true,
          );
          return;
        } else {
          // Partial file corrupted, delete and start over
          await partFile.delete();
          existingBytes = 0;
          final retryReq = await client.getUrl(url);
          final retryRes = await retryReq.close();
          sink = partFile.openWrite(mode: FileMode.write);
          if (retryRes.contentLength > 0) totalBytes = retryRes.contentLength;
        }
      } else {
        throw HttpException(
          'Download failed: Server returned HTTP ${response.statusCode}',
          uri: url,
        );
      }

      int bytesReceived = existingBytes;
      DateTime lastYieldTime = DateTime.now();

      await for (final chunk in response) {
        sink.add(chunk);
        bytesReceived += chunk.length;

        final now = DateTime.now();
        if (now.difference(lastYieldTime).inMilliseconds >= 120 ||
            bytesReceived >= totalBytes) {
          lastYieldTime = now;
          final fraction = (bytesReceived / totalBytes).clamp(0.0, 1.0);
          yield WhisperModelDownloadProgress(
            downloadedBytes: bytesReceived,
            totalBytes: totalBytes,
            fraction: fraction,
            isResumed: isAppending,
          );
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      // 3. Verify downloaded file integrity before putting into service
      final finalPartLength = await partFile.length();
      if ((finalPartLength - tier.expectedSizeBytes).abs() > 1024 * 1024) {
        throw Exception(
          'Downloaded model file is incomplete (${(finalPartLength / (1024 * 1024)).toStringAsFixed(1)} MB of ${(tier.expectedSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB). Tap Resume to continue.',
        );
      }

      // Rename from .part to final
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await partFile.rename(targetFile.path);

      yield WhisperModelDownloadProgress(
        downloadedBytes: finalPartLength,
        totalBytes: finalPartLength,
        fraction: 1.0,
        isCompleted: true,
      );
    } catch (e) {
      // NOTE: We intentionally DO NOT delete partFile here so progress is preserved!
      try {
        await sink?.flush();
        await sink?.close();
      } catch (_) {}
      rethrow;
    } finally {
      client.close();
    }
  }
}
