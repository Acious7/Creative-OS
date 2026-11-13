import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/design_system/etole_colors.dart';

class VoiceCapsuleResult {
  final String filePath;
  final int durationSeconds;

  VoiceCapsuleResult({required this.filePath, required this.durationSeconds});
}

class VoiceCapsuleRecorderSheet extends StatefulWidget {
  final String? recordingPrefix;
  const VoiceCapsuleRecorderSheet({super.key, this.recordingPrefix});

  static Future<VoiceCapsuleResult?> show(BuildContext context, {String? recordingPrefix}) {
    return showModalBottomSheet<VoiceCapsuleResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C0F14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => VoiceCapsuleRecorderSheet(recordingPrefix: recordingPrefix),
    );
  }

  @override
  State<VoiceCapsuleRecorderSheet> createState() => _VoiceCapsuleRecorderSheetState();
}

class _VoiceCapsuleRecorderSheetState extends State<VoiceCapsuleRecorderSheet>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  late AnimationController _reelController;

  bool _isRecording = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reelController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/sanctuary/audio_capsules');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final prefix = widget.recordingPrefix ?? 'capsule';
      final path = '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _secondsElapsed = 0;
      });
      _reelController.repeat();

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_secondsElapsed >= 60) {
          _stopAndSave();
        } else {
          setState(() => _secondsElapsed++);
        }
      });
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _stopAndSave() async {
    _timer?.cancel();
    _reelController.stop();

    if (_isRecording) {
      final path = await _recorder.stop();
      _isRecording = false;
      if (path != null && mounted) {
        Navigator.pop(
          context,
          VoiceCapsuleResult(filePath: path, durationSeconds: _secondsElapsed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VOICE CAPSULE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () {
                  _recorder.stop().catchError((_) => null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Analog Reel-to-Reel Tape Animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildReel(),
              Container(
                width: 70,
                height: 2,
                color: const Color(0xFFFF7A00).withValues(alpha: 0.4),
              ),
              _buildReel(),
            ],
          ),
          const SizedBox(height: 20),

          // Timer readout
          Text(
            '00:${_secondsElapsed.toString().padLeft(2, '0')} / 01:00',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Recording raw acoustic thought...',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Stop & Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _stopAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.stop_rounded, color: Colors.black),
              label: const Text(
                'Seal Voice Capsule',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildReel() {
    return AnimatedBuilder(
      animation: _reelController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _reelController.value * 2 * 3.14159,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF161A22),
              border: Border.all(color: const Color(0xFFFF7A00), width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF7A00),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
