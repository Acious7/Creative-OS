import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

import '../../../core/notifications/local_notification_service.dart';
import 'whisper_model_service.dart';

class TranscriptSegment {
  final int startMs;
  final int endMs;
  final String text;

  TranscriptSegment({
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
    'startMs': startMs,
    'endMs': endMs,
    'text': text,
  };

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) =>
      TranscriptSegment(
        startMs: json['startMs'] as int? ?? 0,
        endMs: json['endMs'] as int? ?? 0,
        text: json['text'] as String? ?? '',
      );

  String get formattedTime {
    final totalSeconds = (startMs / 1000).floor();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class TranscriptionResult {
  final String fullText;
  final List<TranscriptSegment> segments;
  final int processingDurationMs;
  final WhisperModelTier modelUsed;
  final String languageUsed;

  TranscriptionResult({
    required this.fullText,
    required this.segments,
    required this.processingDurationMs,
    required this.modelUsed,
    required this.languageUsed,
  });

  String get segmentsJson =>
      jsonEncode(segments.map((s) => s.toJson()).toList());
}

class TranscriptionRunner {
  /// Transcribe audio file offline using chosen model and language
  static Future<TranscriptionResult> transcribeAudio({
    required String audioPath,
    required WhisperModelTier tier,
    required String languageChoice, // 'en', 'sw', or 'auto' (mixed)
    required String meetingTitle,
  }) async {
    final startTime = DateTime.now();

    // Show ongoing foreground notification while processing (isolated)
    try {
      await LocalNotificationService.showTranscriptionNotification(
        meetingTitle: meetingTitle,
        status: 'Transcribing speech using ${tier.label}...',
      );
    } catch (_) {}

    try {
      WhisperModel model;
      switch (tier) {
        case WhisperModelTier.fast:
          model = WhisperModel.tiny;
          break;
        case WhisperModelTier.balanced:
          model = WhisperModel.base;
          break;
        case WhisperModelTier.accurate:
          model = WhisperModel.small;
          break;
      }

      final modelDir = await WhisperModelService.getModelDirectory();

      final whisper = Whisper(
        model: model,
        modelDir: modelDir.path,
        downloadHost:
            'https://huggingface.co/ggerganov/whisper.cpp/resolve/main',
      );

      final response = await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: languageChoice, // 'en', 'sw', or 'auto'
          isTranslate: false,
          isNoTimestamps: false,
          threads: 4,
        ),
      );

      final segments = <TranscriptSegment>[];
      if (response.segments != null) {
        for (final s in response.segments!) {
          final trimmedText = s.text.trim();
          if (trimmedText.isNotEmpty) {
            segments.add(
              TranscriptSegment(
                startMs: s.fromTs.inMilliseconds,
                endMs: s.toTs.inMilliseconds,
                text: trimmedText,
              ),
            );
          }
        }
      }

      // Fallback if no segments parsed
      if (segments.isEmpty && response.text.isNotEmpty) {
        segments.add(
          TranscriptSegment(startMs: 0, endMs: 0, text: response.text.trim()),
        );
      }

      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

      return TranscriptionResult(
        fullText: response.text.trim(),
        segments: segments,
        processingDurationMs: elapsedMs,
        modelUsed: tier,
        languageUsed: languageChoice,
      );
    } catch (e) {
      debugPrint('Transcription error: $e');
      rethrow;
    } finally {
      try {
        await LocalNotificationService.hideTranscriptionNotification();
      } catch (_) {}
    }
  }
}
