import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/ambient_soundscape_service.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';

class MonkModeScreen extends ConsumerStatefulWidget {
  const MonkModeScreen({super.key});

  @override
  ConsumerState<MonkModeScreen> createState() => _MonkModeScreenState();
}

class _MonkModeScreenState extends ConsumerState<MonkModeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  Timer? _timer;
  int _secondsLeft = 25 * 60; // Default 25 min Pomodoro
  bool _isRunning = false;
  int _initialSeconds = 25 * 60;
  bool _blindFocusHaptics = true; // Closed-eye tactile breathing guide

  final TextEditingController _focusTopicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.88, end: 1.14).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _breathController.addStatusListener((status) {
      if (!_blindFocusHaptics || !_isRunning) return;
      if (status == AnimationStatus.forward) {
        HapticFeedback.lightImpact(); // Inhale wave begins
      } else if (status == AnimationStatus.reverse) {
        HapticFeedback.mediumImpact(); // Exhale wave begins
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    _focusTopicController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_initialSeconds == 0) return; // Flow mode
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() {
          _isRunning = false;
          _secondsLeft = 0;
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer(int minutes) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _initialSeconds = minutes * 60;
      _secondsLeft = minutes * 60;
    });
  }

  String _formatTime() {
    if (_initialSeconds == 0) return 'FLOW';
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final soundscapeState = ref.watch(ambientSoundscapeProvider);
    final accent = studioTheme.primaryAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF07090C),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient ember glow behind the breathing circle
            Positioned.fill(
              child: Center(
                child: AnimatedBuilder(
                  animation: _breathAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 280 * _breathAnimation.value,
                      height: 280 * _breathAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.18),
                            accent.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Top Header: Exit and Mode Title
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                  Column(
                    children: [
                      Text(
                        'MONK MODE',
                        style: EtoleTypography.labelCaps(color: accent).copyWith(
                          fontSize: 11,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Deep Solitary Focus',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48), // Spacer to balance close button
                ],
              ),
            ),

            // Central Content: Breathing Sphere & Timer
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 36),

                    // Single Thought Focus Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101418),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _focusTopicController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'What is the single thing that matters right now?',
                          hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 44),

                    // Breathing Sphere with Timer
                    AnimatedBuilder(
                      animation: _breathAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _breathAnimation.value,
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0F1318),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.45),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.16),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isRunning ? 'INHALE / EXHALE' : 'PAUSED',
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 44),

                    // Play / Pause / Reset Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            if (_isRunning) {
                              _pauseTimer();
                            } else {
                              _startTimer();
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          onPressed: () => _resetTimer(_initialSeconds ~/ 60),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 26),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Presets: 15m, 25m, 45m, Flow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPresetButton('15m', 15),
                        const SizedBox(width: 8),
                        _buildPresetButton('25m', 25),
                        const SizedBox(width: 8),
                        _buildPresetButton('45m', 45),
                        const SizedBox(width: 8),
                        _buildPresetButton('Flow', 0),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Soundscape Selector Capsule
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11151A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.headphones_rounded, color: accent, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Ambient Soundscape',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: SoundscapeType.values.map((type) {
                              final isSelected = soundscapeState.activeType == type;
                              return ChoiceChip(
                                label: Text(type.title),
                                selected: isSelected,
                                onSelected: (_) {
                                  ref
                                      .read(ambientSoundscapeProvider.notifier)
                                      .setSoundscape(type);
                                },
                                selectedColor: accent.withValues(alpha: 0.25),
                                backgroundColor: const Color(0xFF181D24),
                                labelStyle: TextStyle(
                                  color: isSelected ? accent : const Color(0xFF94A3B8),
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 8),

                          // Blind Focus Micro-Haptics Toggle
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Blind Focus (Tactile Breathing)',
                              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Gentle haptic pulses on inhale & exhale so you can close your eyes',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                            ),
                            value: _blindFocusHaptics,
                            activeColor: accent,
                            onChanged: (val) {
                              setState(() => _blindFocusHaptics = val);
                              if (val) HapticFeedback.mediumImpact();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, int minutes) {
    final isSelected = (_initialSeconds ~/ 60 == minutes && minutes != 0) ||
        (_initialSeconds == 0 && minutes == 0);
    return InkWell(
      onTap: () => _resetTimer(minutes),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF14181E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.white54 : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
