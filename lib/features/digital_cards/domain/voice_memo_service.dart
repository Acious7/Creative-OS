import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceMemoItem {
  final String id;
  final String filePath;
  final int durationSeconds;
  final DateTime createdAt;

  VoiceMemoItem({
    required this.id,
    required this.filePath,
    required this.durationSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'durationSeconds': durationSeconds,
    'createdAt': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toMap() => toJson();

  factory VoiceMemoItem.fromJson(Map<String, dynamic> json) => VoiceMemoItem(
    id: json['id'] as String? ?? UniqueKey().toString(),
    filePath: json['filePath'] as String,
    durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

class VoiceMemoService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer _player = AudioPlayer();

  static bool _isRecording = false;
  static DateTime? _recordStartTime;
  static String? _currentRecordPath;

  static bool get isRecording => _isRecording;
  bool get recording => _isRecording;

  // Instance methods for convenience
  bool get isRecordingMemo => _isRecording;
  Future<bool> start() => startRecording();
  Future<VoiceMemoItem?> stopMemo() => stopRecording();

  /// Start recording voice memo to app private documents directory
  static Future<bool> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return false;

      final docsDir = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${docsDir.path}/voice_memos');
      if (!voiceDir.existsSync()) {
        voiceDir.createSync(recursive: true);
      }

      final fileName = 'memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordPath = '${voiceDir.path}/$fileName';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: _currentRecordPath!,
      );

      _isRecording = true;
      _recordStartTime = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('VoiceMemoService startRecording error: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return a VoiceMemoItem
  static Future<VoiceMemoItem?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      final path = await _recorder.stop();
      _isRecording = false;

      final elapsed = _recordStartTime != null
          ? DateTime.now().difference(_recordStartTime!).inSeconds
          : 0;

      final actualPath = path ?? _currentRecordPath;
      if (actualPath == null || !File(actualPath).existsSync()) return null;

      return VoiceMemoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: actualPath,
        durationSeconds: elapsed > 0 ? elapsed : 1,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('VoiceMemoService stopRecording error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Play audio file
  static Future<void> play(String filePath, {VoidCallback? onComplete}) async {
    try {
      await _player.stop();
      _player.onPlayerComplete.listen((_) {
        onComplete?.call();
      });
      await _player.play(DeviceFileSource(filePath));
    } catch (e) {
      debugPrint('VoiceMemoService play error: $e');
    }
  }

  /// Stop audio playback
  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('VoiceMemoService stop error: $e');
    }
  }

  /// Delete audio file from private storage
  static Future<void> deleteMemo(String filePath) async {
    try {
      await stop();
      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('VoiceMemoService deleteMemo error: $e');
    }
  }
}
