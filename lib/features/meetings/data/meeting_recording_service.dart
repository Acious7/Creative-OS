import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/notifications/local_notification_service.dart';

class RecordingInterruption {
  final int timestampSeconds;
  final DateTime startedAt;
  DateTime? endedAt;
  final String reason;

  RecordingInterruption({
    required this.timestampSeconds,
    required this.startedAt,
    this.endedAt,
    this.reason = 'Phone call or audio interruption',
  });

  int get durationSeconds => endedAt != null
      ? endedAt!.difference(startedAt).inSeconds
      : DateTime.now().difference(startedAt).inSeconds;
}

class MeetingRecordingResult {
  final String filePath;
  final int durationSeconds;
  final int fileSizeBytes;
  final List<RecordingInterruption> interruptions;

  MeetingRecordingResult({
    required this.filePath,
    required this.durationSeconds,
    required this.fileSizeBytes,
    this.interruptions = const [],
  });
}

class MeetingRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _tickerTimer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  bool _isUserPaused = false;
  bool _isInterrupted = false;

  final List<RecordingInterruption> _interruptions = [];
  StreamSubscription<RecordState>? _stateSubscription;

  final _elapsedSecondsController = StreamController<int>.broadcast();
  Stream<int> get elapsedSecondsStream => _elapsedSecondsController.stream;

  final _interruptionController =
      StreamController<RecordingInterruption?>.broadcast();
  Stream<RecordingInterruption?> get interruptionStream =>
      _interruptionController.stream;

  bool get isRecordingActive => _currentRecordingPath != null;
  bool get isPaused => _isPaused;
  bool get isInterrupted => _isInterrupted;
  int get currentElapsedSeconds => _elapsedSeconds;
  List<RecordingInterruption> get interruptions =>
      List.unmodifiable(_interruptions);

  Future<bool> hasMicrophonePermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Start recording directly to a 16kHz mono WAV file (optimal for Whisper speech model)
  Future<String> startRecording({required String meetingTitle}) async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDocDir.path}/meeting_audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${audioDir.path}/meeting_$timestamp.wav';
    _currentRecordingPath = filePath;
    _recordingStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _isPaused = false;
    _isUserPaused = false;
    _isInterrupted = false;
    _interruptions.clear();

    // Listen to recorder hardware state changes (interceptions by phone calls / other apps)
    await _stateSubscription?.cancel();
    _stateSubscription = _audioRecorder.onStateChanged().listen((state) {
      if (state == RecordState.pause) {
        if (!_isUserPaused && isRecordingActive) {
          // Hardware or OS seized microphone (e.g., incoming phone call)
          _isInterrupted = true;
          _isPaused = true;
          final interruption = RecordingInterruption(
            timestampSeconds: _elapsedSeconds,
            startedAt: DateTime.now(),
          );
          _interruptions.add(interruption);
          _interruptionController.add(interruption);
        }
      } else if (state == RecordState.record) {
        if (_isInterrupted) {
          _resolveInterruption();
        }
        _isPaused = false;
      }
    });

    // Record in 16kHz 16-bit mono PCM WAV
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
        audioInterruption: AudioInterruptionMode.pause,
      ),
      path: filePath,
    );

    // Keep screen-off notification active (isolated so failure never stops recording)
    try {
      await LocalNotificationService.showRecordingNotification(
        meetingTitle: meetingTitle,
      );
    } catch (_) {}

    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isInterrupted) {
        _elapsedSeconds++;
        _elapsedSecondsController.add(_elapsedSeconds);
      }
    });

    return filePath;
  }

  /// Pause recording manually by user
  Future<void> pauseRecording() async {
    _isUserPaused = true;
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.pause();
      _isPaused = true;
    }
  }

  /// Resume recording after pause or after a phone call ends
  Future<void> resumeRecording() async {
    _isUserPaused = false;
    if (_isInterrupted) {
      _resolveInterruption();
    }
    if (await _audioRecorder.isPaused()) {
      await _audioRecorder.resume();
      _isPaused = false;
    }
  }

  void _resolveInterruption() {
    if (_interruptions.isNotEmpty && _interruptions.last.endedAt == null) {
      _interruptions.last.endedAt = DateTime.now();
    }
    _isInterrupted = false;
    _interruptionController.add(null);
  }

  /// Stop recording, finalize the file to disk, and remove ongoing notification
  Future<MeetingRecordingResult> stopRecording() async {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    await _stateSubscription?.cancel();
    _stateSubscription = null;

    if (_isInterrupted) {
      _resolveInterruption();
    }

    final path = await _audioRecorder.stop();
    try {
      await LocalNotificationService.hideRecordingNotification();
    } catch (_) {}

    final finalPath = path ?? _currentRecordingPath;
    _currentRecordingPath = null;
    _isPaused = false;
    _isUserPaused = false;
    _isInterrupted = false;

    if (finalPath == null) {
      throw Exception('Recording path could not be resolved');
    }

    final file = File(finalPath);
    if (!await file.exists()) {
      throw Exception('Recorded audio file was not saved to disk');
    }

    final sizeBytes = await file.length();
    final duration = _elapsedSeconds > 0
        ? _elapsedSeconds
        : (_recordingStartTime != null
              ? DateTime.now().difference(_recordingStartTime!).inSeconds
              : 0);

    return MeetingRecordingResult(
      filePath: finalPath,
      durationSeconds: duration,
      fileSizeBytes: sizeBytes,
      interruptions: List.unmodifiable(_interruptions),
    );
  }

  Future<void> dispose() async {
    _tickerTimer?.cancel();
    await _stateSubscription?.cancel();
    await _audioRecorder.dispose();
    await _elapsedSecondsController.close();
    await _interruptionController.close();
  }
}
