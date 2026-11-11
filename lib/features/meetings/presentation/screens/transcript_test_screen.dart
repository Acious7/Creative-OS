import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../data/meeting_recording_service.dart';
import '../../data/transcription_runner.dart';
import '../../data/whisper_model_service.dart';

class TranscriptTestScreen extends ConsumerStatefulWidget {
  const TranscriptTestScreen({super.key});

  @override
  ConsumerState<TranscriptTestScreen> createState() =>
      _TranscriptTestScreenState();
}

class _TranscriptTestScreenState extends ConsumerState<TranscriptTestScreen> {
  // Services
  final MeetingRecordingService _recordingService = MeetingRecordingService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Settings
  WhisperModelTier _selectedTier = WhisperModelTier.balanced;
  String _selectedLanguage = 'en'; // 'en', 'sw', 'auto'

  // Model download state
  bool _isCheckingModel = true;
  bool _isModelDownloaded = false;
  bool _isDownloadingModel = false;
  WhisperModelDownloadProgress? _downloadProgressData;
  StreamSubscription<WhisperModelDownloadProgress>? _downloadSub;
  int _partialDownloadedBytes = 0;
  String? _downloadError;
  String? _technicalErrorDetails;
  bool _showErrorDetails = false;

  // Recording state
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordSeconds = 0;
  StreamSubscription<int>? _timerSubscription;

  // Interruption handling (phone calls / audio focus changes)
  RecordingInterruption? _activeInterruption;
  List<RecordingInterruption> _recordedInterruptions = [];
  StreamSubscription<RecordingInterruption?>? _interruptionSubscription;

  // Audio file & player state
  String? _savedAudioPath;
  int _audioDurationSeconds = 0;
  int _audioFileSizeBytes = 0;
  PlayerState _playerState = PlayerState.stopped;
  Duration _playerPosition = Duration.zero;
  Duration _playerDuration = Duration.zero;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _playerPositionSub;
  StreamSubscription? _playerDurationSub;

  // Transcription state
  bool _isTranscribing = false;
  TranscriptionResult? _transcriptionResult;
  String? _transcriptionError;

  @override
  void initState() {
    super.initState();
    _checkSelectedModel();
    _initAudioPlayerListeners();
    _initInterruptionListener();
  }

  void _initInterruptionListener() {
    _interruptionSubscription = _recordingService.interruptionStream.listen((
      interruption,
    ) {
      if (mounted) {
        setState(() {
          _activeInterruption = interruption;
          if (interruption != null) {
            _isPaused = true;
          }
        });
      }
    });
  }

  void _initAudioPlayerListeners() {
    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _playerPositionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _playerPosition = pos);
    });
    _playerDurationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _playerDuration = dur);
    });
  }

  Future<void> _checkSelectedModel() async {
    setState(() {
      _isCheckingModel = true;
      _downloadError = null;
      _technicalErrorDetails = null;
      _showErrorDetails = false;
    });
    final isDownloaded = await WhisperModelService.isModelDownloaded(
      _selectedTier,
    );
    final partialBytes = await WhisperModelService.getPartialDownloadBytes(
      _selectedTier,
    );
    if (mounted) {
      setState(() {
        _isModelDownloaded = isDownloaded;
        _partialDownloadedBytes = partialBytes;
        _isCheckingModel = false;
      });
    }
  }

  Future<void> _startModelDownload() async {
    setState(() {
      _isDownloadingModel = true;
      _downloadError = null;
      _technicalErrorDetails = null;
      _showErrorDetails = false;
    });

    await _downloadSub?.cancel();
    _downloadSub = WhisperModelService.downloadModel(_selectedTier).listen(
      (progress) {
        if (!mounted) return;
        setState(() {
          _downloadProgressData = progress;
          _partialDownloadedBytes = progress.downloadedBytes;
          if (progress.isCompleted) {
            _isDownloadingModel = false;
            _isModelDownloaded = true;
          }
        });
      },
      onError: (e) async {
        if (!mounted) return;
        final partialBytes = await WhisperModelService.getPartialDownloadBytes(
          _selectedTier,
        );
        setState(() {
          _isDownloadingModel = false;
          _partialDownloadedBytes = partialBytes;
          _downloadError =
              'Download interrupted. Check your connection and tap Resume.';
          _technicalErrorDetails = '$e';
        });
      },
      onDone: () async {
        if (!mounted) return;
        final isDownloaded = await WhisperModelService.isModelDownloaded(
          _selectedTier,
        );
        setState(() {
          _isDownloadingModel = false;
          _isModelDownloaded = isDownloaded;
        });
      },
      cancelOnError: true,
    );
  }

  Future<void> _pauseModelDownload() async {
    await _downloadSub?.cancel();
    _downloadSub = null;
    final partialBytes = await WhisperModelService.getPartialDownloadBytes(
      _selectedTier,
    );
    if (mounted) {
      setState(() {
        _isDownloadingModel = false;
        _partialDownloadedBytes = partialBytes;
      });
    }
  }

  Future<void> _discardPartialDownload() async {
    await _downloadSub?.cancel();
    _downloadSub = null;
    await WhisperModelService.deletePartialDownload(_selectedTier);
    if (mounted) {
      setState(() {
        _isDownloadingModel = false;
        _partialDownloadedBytes = 0;
        _downloadProgressData = null;
        _downloadError = null;
        _technicalErrorDetails = null;
        _showErrorDetails = false;
      });
    }
  }

  Future<bool> _showPermissionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E21),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: const Text(
          'Microphone Access Needed',
          style: TextStyle(
            color: EtoleColors.cream,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Etole records meeting audio directly on your phone to generate private transcripts. No audio is ever sent to the internet, and your voice never leaves your phone.',
          style: TextStyle(color: EtoleColors.muted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: EtoleColors.muted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: EtoleColors.cyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Allow Microphone',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // STOP recording
      EtoleHaptics.medium();
      try {
        final result = await _recordingService.stopRecording();
        _timerSubscription?.cancel();
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _activeInterruption = null;
          _recordedInterruptions = result.interruptions;
          _savedAudioPath = result.filePath;
          _audioDurationSeconds = result.durationSeconds;
          _audioFileSizeBytes = result.fileSizeBytes;
        });
        // Set up player
        await _audioPlayer.setSource(DeviceFileSource(result.filePath));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error stopping recording: $e')),
          );
        }
      }
    } else {
      // START recording
      EtoleHaptics.selection();

      // Check microphone permission first
      final hasMic = await _recordingService.hasMicrophonePermission();
      if (!hasMic) {
        final userConfirmed = await _showPermissionDialog();
        if (!userConfirmed) return;
      }

      // Quietly request notification permission on Android 13+
      await LocalNotificationService.requestPermissions();

      try {
        await _recordingService.startRecording(
          meetingTitle: 'Speech Benchmark Test',
        );
        _timerSubscription = _recordingService.elapsedSecondsStream.listen((
          sec,
        ) {
          if (mounted) setState(() => _recordSeconds = sec);
        });
        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordSeconds = 0;
          _activeInterruption = null;
          _recordedInterruptions = [];
          _transcriptionResult = null;
          _transcriptionError = null;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not start recording: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _togglePauseRecording() async {
    if (!_isRecording) return;
    EtoleHaptics.light();
    if (_isPaused) {
      await _recordingService.resumeRecording();
      setState(() => _isPaused = false);
    } else {
      await _recordingService.pauseRecording();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _runTranscription() async {
    if (_savedAudioPath == null) return;
    if (!_isModelDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please download the ${_selectedTier.label} model first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isTranscribing = true;
      _transcriptionError = null;
    });

    try {
      final result = await TranscriptionRunner.transcribeAudio(
        audioPath: _savedAudioPath!,
        tier: _selectedTier,
        languageChoice: _selectedLanguage,
        meetingTitle: 'Speech Benchmark Test',
      );

      if (mounted) {
        setState(() {
          _transcriptionResult = result;
          _isTranscribing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
          _transcriptionError = 'Transcription error: $e';
        });
      }
    }
  }

  Future<void> _playAudioFrom(int timestampMs) async {
    if (_savedAudioPath == null) return;
    EtoleHaptics.selection();
    await _audioPlayer.seek(Duration(milliseconds: timestampMs));
    await _audioPlayer.resume();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    _timerSubscription?.cancel();
    _interruptionSubscription?.cancel();
    _playerStateSub?.cancel();
    _playerPositionSub?.cancel();
    _playerDurationSub?.cancel();
    _audioPlayer.dispose();
    _recordingService.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOled = ref.watch(isOledModeProvider);
    final cream = isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary;
    final muted = isDark ? EtoleColors.muted : EtoleColors.lightTextMuted;

    return Scaffold(
      backgroundColor: isDark
          ? (isOled ? EtoleColors.pitchBlack : EtoleColors.obsidian)
          : EtoleColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: cream,
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPEECH BENCHMARK',
                          style: EtoleTypography.pageTitle(color: cream)
                              .copyWith(fontSize: 18, letterSpacing: 1.2),
                        ),
                        Text(
                          'ON-DEVICE WHISPER TEST LAB',
                          style: EtoleTypography.labelCaps(
                            color: EtoleColors.cyan,
                          ).copyWith(fontSize: 8.5, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                  if (_isModelDownloaded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 11,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'OFFLINE READY',
                            style: EtoleTypography.labelCaps(
                              color: Colors.greenAccent,
                            ).copyWith(fontSize: 8.5),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const EtoleHairline(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // 1. Model Tier Selector (Fast, Balanced, Accurate)
                  _buildSectionHeader('1. SELECT MODEL ACCURACY', cream),
                  const SizedBox(height: 8),
                  Row(
                    children: WhisperModelTier.values.map((tier) {
                      final isSelected = _selectedTier == tier;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isDownloadingModel || _isTranscribing) return;
                            setState(() => _selectedTier = tier);
                            _checkSelectedModel();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? EtoleColors.cyan.withValues(alpha: 0.18)
                                  : (isDark
                                        ? const Color(0x22FFFFFF)
                                        : const Color(0x0C000000)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? EtoleColors.cyan
                                    : (isDark
                                          ? const Color(0x28FFFFFF)
                                          : const Color(0x18000000)),
                                width: isSelected ? 1.5 : 0.8,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  tier.name.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily:
                                        EtoleTypography.displayFontFamily,
                                    fontSize: 13,
                                    color: isSelected
                                        ? EtoleColors.cyan
                                        : cream,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tier.approximateSize,
                                  style: TextStyle(
                                    fontFamily: EtoleTypography.bodyFontFamily,
                                    fontSize: 9.5,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // Model Download Action / Status Card
                  _buildModelDownloadCard(cream, muted),

                  const SizedBox(height: 18),

                  // 2. Language Selector (English, Swahili, Mixed)
                  _buildSectionHeader('2. SELECT LANGUAGE MODE', cream),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLangChoice('en', 'ENGLISH', 'Standard', cream),
                      _buildLangChoice('sw', 'SWAHILI', 'Standard', cream),
                      _buildLangChoice(
                        'auto',
                        'MIXED',
                        'Eng + Swa (Sheng)',
                        cream,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3. Audio Recorder & Safety Card
                  _buildSectionHeader('3. AUDIO RECORDER (SAVED FIRST)', cream),
                  const SizedBox(height: 8),
                  _buildRecorderCard(cream, muted),

                  const SizedBox(height: 18),

                  // 4. Transcription Action & Live Benchmark Box
                  if (_savedAudioPath != null) ...[
                    _buildSectionHeader('4. TRANSCRIPTION BENCHMARK', cream),
                    const SizedBox(height: 8),
                    _buildBenchmarkActionCard(cream, muted),
                    const SizedBox(height: 18),
                  ],

                  // 5. Interactive Timestamped Transcript (Tap line to hear playback)
                  if (_transcriptionResult != null) ...[
                    _buildSectionHeader('5. TRANSCRIPT (TAP TO LISTEN)', cream),
                    const SizedBox(height: 8),
                    _buildTranscriptList(cream, muted),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color cream) {
    return Text(
      title,
      style: EtoleTypography.labelCaps(color: EtoleColors.cyan)
          .copyWith(fontSize: 10, letterSpacing: 1.2),
    );
  }

  Widget _buildModelDownloadCard(Color cream, Color muted) {
    if (_isCheckingModel) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x18FFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: EtoleColors.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Checking local model cache...',
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (_isModelDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.greenAccent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedTier.label} Model Cached Offline',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Stored safely in phone memory · No internet needed',
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final downloadedMb = (_partialDownloadedBytes / (1024 * 1024))
        .toStringAsFixed(1);
    final totalExpectedMb = (_selectedTier.expectedSizeBytes / (1024 * 1024))
        .toStringAsFixed(1);
    final currentFraction = _downloadProgressData != null
        ? _downloadProgressData!.fraction
        : (_partialDownloadedBytes / _selectedTier.expectedSizeBytes).clamp(
            0.0,
            1.0,
          );
    final percentStr = (currentFraction * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EtoleColors.cyan.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EtoleColors.cyan.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.downloading_rounded,
                color: EtoleColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'One-Time Download Needed (${_selectedTier.approximateSize})',
                  style: TextStyle(
                    color: cream,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Requires internet once to download. Downloads are resumable if your connection drops. Once stored, it works 100% offline forever.',
            style: TextStyle(color: muted, fontSize: 10.5),
          ),
          const SizedBox(height: 10),

          // 1. ACTIVE DOWNLOADING STATE
          if (_isDownloadingModel) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: currentFraction > 0 ? currentFraction : null,
                backgroundColor: const Color(0x33FFFFFF),
                color: EtoleColors.cyan,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Downloading: $downloadedMb / $totalExpectedMb MB ($percentStr%)',
                  style: const TextStyle(
                    color: EtoleColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pauseModelDownload,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.pause_rounded, size: 16),
                  label: const Text('Pause', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ]
          // 2. PAUSED / INTERRUPTED RESUMABLE STATE
          else if (_partialDownloadedBytes > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: currentFraction,
                backgroundColor: const Color(0x33FFFFFF),
                color: Colors.amber,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Partially saved: $downloadedMb MB of $totalExpectedMb MB ($percentStr%)',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _startModelDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text(
                    'Resume Download',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _discardPartialDownload,
                  style: TextButton.styleFrom(
                    foregroundColor: muted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text(
                    'Discard & Restart',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ]
          // 3. FRESH START STATE
          else ...[
            ElevatedButton.icon(
              onPressed: _startModelDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: EtoleColors.cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.cloud_download_rounded, size: 16),
              label: Text(
                'Download ${_selectedTier.label} (${_selectedTier.approximateSize})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],

          // 4. CLEAN ERROR / INTERRUPTED NOTICE
          if (_downloadError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x30D9534F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _downloadError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_technicalErrorDetails != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showErrorDetails = !_showErrorDetails;
                            });
                          },
                          child: Text(
                            _showErrorDetails ? 'Hide' : 'Details',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_showErrorDetails && _technicalErrorDetails != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _technicalErrorDetails!,
                      style: TextStyle(
                        fontFamily: EtoleTypography.bodyFontFamily,
                        fontSize: 9.5,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLangChoice(String code, String label, String sub, Color cream) {
    final isSelected = _selectedLanguage == code;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isTranscribing) return;
          setState(() => _selectedLanguage = code);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? EtoleColors.cyan.withValues(alpha: 0.18)
                : const Color(0x18FFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? EtoleColors.cyan : const Color(0x28FFFFFF),
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: EtoleTypography.bodyFontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? EtoleColors.cyan : cream,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(fontSize: 8.5, color: EtoleColors.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecorderCard(Color cream, Color muted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x28141719),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecording
              ? Colors.redAccent.withValues(alpha: 0.6)
              : const Color(0x28FFFFFF),
          width: _isRecording ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Active Interruption Notice (Phone Call or Audio Interruption)
          if (_activeInterruption != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1B0E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_in_talk_rounded,
                        color: Color(0xFFFF9800),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'RECORDING INTERRUPTED BY CALL',
                          style: TextStyle(
                            color: Color(0xFFFF9800),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'at ${_formatDuration(_activeInterruption!.timestampSeconds)}',
                          style: const TextStyle(
                            color: EtoleColors.cream,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Microphone was taken by a call or another app. Recording is safely paused. Zero silent gap was saved to your audio file.',
                    style: TextStyle(
                      color: EtoleColors.cream,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _recordingService.resumeRecording();
                            setState(() {
                              _isPaused = false;
                              _activeInterruption = null;
                            });
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text(
                            'Resume Recording',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _toggleRecording,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Stop & Save',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Live Timer or Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? (_isPaused ? Colors.amber : Colors.redAccent)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRecording
                        ? (_isPaused ? 'PAUSED' : 'RECORDING (16 kHz WAV)')
                        : (_savedAudioPath != null ? 'AUDIO READY' : 'STANDBY'),
                    style: TextStyle(
                      fontFamily: EtoleTypography.bodyFontFamily,
                      fontSize: 10.5,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: _isRecording
                          ? (_isPaused ? Colors.amber : Colors.redAccent)
                          : muted,
                    ),
                  ),
                ],
              ),
              Text(
                _isRecording
                    ? _formatDuration(_recordSeconds)
                    : (_audioDurationSeconds > 0
                          ? _formatDuration(_audioDurationSeconds)
                          : '00:00'),
                style: TextStyle(
                  fontFamily: EtoleTypography.displayFontFamily,
                  fontSize: 22,
                  color: cream,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                IconButton(
                  icon: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 28,
                    color: Colors.amber,
                  ),
                  onPressed: _togglePauseRecording,
                ),
                const SizedBox(width: 16),
              ],

              // Big Main Record / Stop Button
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.redAccent : EtoleColors.cyan,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isRecording ? Colors.redAccent : EtoleColors.cyan)
                                .withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),

          // File Info If Saved
          if (_savedAudioPath != null && !_isRecording) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x18FFFFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.audio_file_outlined,
                    size: 16,
                    color: EtoleColors.cyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final totalSec = _playerDuration.inSeconds > 0
                            ? _playerDuration.inSeconds
                            : _audioDurationSeconds;
                        return Text(
                          '${_formatDuration(_playerPosition.inSeconds)} / ${_formatDuration(totalSec)} (${_formatBytes(_audioFileSizeBytes)})',
                          style: TextStyle(color: muted, fontSize: 10.5),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _playerState == PlayerState.playing
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: EtoleColors.cyan,
                      size: 24,
                    ),
                    onPressed: () {
                      if (_playerState == PlayerState.playing) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.resume();
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_recordedInterruptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x28FF9800),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x66FF9800)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_paused_rounded,
                      size: 14,
                      color: Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_recordedInterruptions.length} call interruption(s) marked at ${_recordedInterruptions.map((i) => _formatDuration(i.timestampSeconds)).join(', ')}. Zero silent gaps saved.',
                        style: const TextStyle(
                          color: Color(0xFFFFD59E),
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBenchmarkActionCard(Color cream, Color muted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x28141719),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x28FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Convert With: ${_selectedTier.label}',
                style: TextStyle(
                  color: cream,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isTranscribing ? null : _runTranscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EtoleColors.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                icon: _isTranscribing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.subtitles_outlined, size: 16),
                label: Text(
                  _isTranscribing ? 'Processing...' : 'Transcribe Now',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          if (_isTranscribing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              backgroundColor: Color(0x33FFFFFF),
              color: EtoleColors.cyan,
              minHeight: 4,
            ),
            const SizedBox(height: 6),
            Text(
              'Running offline speech decoding on your phone processor...',
              style: TextStyle(color: muted, fontSize: 10),
            ),
          ],

          if (_transcriptionError != null) ...[
            const SizedBox(height: 8),
            Text(
              _transcriptionError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 10.5),
            ),
          ],

          // Real Live Benchmark Box
          if (_transcriptionResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EtoleColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: EtoleColors.cyan.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.speed_rounded,
                        color: EtoleColors.cyan,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'REAL DEVICE BENCHMARK RESULT',
                        style: EtoleTypography.labelCaps(
                          color: EtoleColors.cyan,
                        ).copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Processing Time: ${(_transcriptionResult!.processingDurationMs / 1000).toStringAsFixed(1)} seconds',
                    style: TextStyle(color: cream, fontSize: 11),
                  ),
                  Text(
                    '• Audio Length: $_audioDurationSeconds seconds',
                    style: TextStyle(color: cream, fontSize: 11),
                  ),
                  Text(
                    '• Speed Ratio: ${(_audioDurationSeconds / (_transcriptionResult!.processingDurationMs / 1000 + 0.001)).toStringAsFixed(1)}x real-time',
                    style: TextStyle(color: cream, fontSize: 11),
                  ),
                  Text(
                    '• Model Tested: ${_transcriptionResult!.modelUsed.label}',
                    style: TextStyle(color: cream, fontSize: 11),
                  ),
                  Text(
                    '• Language Setting: ${_transcriptionResult!.languageUsed.toUpperCase()}',
                    style: TextStyle(color: cream, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranscriptList(Color cream, Color muted) {
    final segments = _transcriptionResult!.segments;

    if (segments.isEmpty) {
      return Text(
        'No speech detected in audio.',
        style: TextStyle(color: muted, fontSize: 11),
      );
    }

    return Column(
      children: [
        if (_recordedInterruptions.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x28FF9800),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x55FF9800)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.phone_paused_rounded,
                  size: 14,
                  color: Color(0xFFFF9800),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recorded during phone call interruption(s). No empty silent gap exists in the audio or transcript.',
                    style: TextStyle(color: Color(0xFFFFD59E), fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ),
        ],
        ...segments.map((seg) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x18FFFFFF)),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _playAudioFrom(seg.startMs),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timestamp Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EtoleColors.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          seg.formattedTime,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: EtoleColors.cyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          seg.text,
                          style: TextStyle(
                            fontFamily: EtoleTypography.bodyFontFamily,
                            color: cream,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: EtoleColors.cyan,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
