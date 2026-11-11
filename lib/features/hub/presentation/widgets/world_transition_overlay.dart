import 'package:flutter/material.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/hub_models.dart';

class WorldTransitionOverlay extends StatefulWidget {
  final EtoleWorld world;
  final bool reduceMotion;
  final VoidCallback onCompleted;

  const WorldTransitionOverlay({
    super.key,
    required this.world,
    required this.reduceMotion,
    required this.onCompleted,
  });

  @override
  State<WorldTransitionOverlay> createState() => _WorldTransitionOverlayState();
}

class _WorldTransitionOverlayState extends State<WorldTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<String> _letters;

  @override
  void initState() {
    super.initState();
    _letters = widget.world.letterSequence;

    final durationMs = widget.reduceMotion ? 220 : 680;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    if (_controller.isAnimating) {
      _controller.stop();
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return GestureDetector(
        onTap: _skip,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              color: EtoleColors.darkBase.withValues(alpha: _controller.value),
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: _skip,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          // Background canvas fade-in (darkens as shard flies forward)
          final bgOpacity = (progress * 1.5).clamp(0.0, 1.0);

          return Container(
            color: EtoleColors.darkBase.withValues(alpha: bgOpacity),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Glowing expanding shard flash in the center
                Center(
                  child: Opacity(
                    opacity: (1.0 - progress * 1.1).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 + progress * 3.2,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              EtoleColors.cyan.withValues(alpha: 0.35),
                              EtoleColors.cream.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Vertical Stacked Letters (e.g. N · E · T · W · O · R · K)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _letters.length; i++) ...[
                        _buildAnimatedLetter(
                          letter: _letters[i],
                          index: i,
                          totalLetters: _letters.length,
                          progress: progress,
                        ),
                        if (i < _letters.length - 1)
                          _buildAnimatedDot(
                            index: i,
                            totalLetters: _letters.length,
                            progress: progress,
                          ),
                      ],
                    ],
                  ),
                ),

                // Tap to skip hint at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: Center(
                    child: Opacity(
                      opacity: (progress > 0.4 ? (progress - 0.4) * 1.6 : 0.0)
                          .clamp(0.0, 0.5),
                      child: Text(
                        'TAP TO SKIP',
                        style: EtoleTypography.labelCaps(
                          color: EtoleColors.muted,
                        ).copyWith(fontSize: 10, letterSpacing: 2.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLetter({
    required String letter,
    required int index,
    required int totalLetters,
    required double progress,
  }) {
    // Staggered reveal per letter
    final start = (index / (totalLetters + 2)) * 0.55;
    final end = (start + 0.35).clamp(0.0, 1.0);

    final letterProgress = ((progress - start) / (end - start)).clamp(0.0, 1.0);
    final curved = Curves.easeOutBack.transform(letterProgress);

    return Opacity(
      opacity: letterProgress,
      child: Transform.scale(
        scale: 0.6 + curved * 0.4,
        child: Text(
          letter,
          style: EtoleTypography.pageTitle(color: EtoleColors.cream).copyWith(
            fontSize: 28,
            letterSpacing: 2.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDot({
    required int index,
    required int totalLetters,
    required double progress,
  }) {
    final start = ((index + 0.5) / (totalLetters + 2)) * 0.55;
    final end = (start + 0.25).clamp(0.0, 1.0);
    final dotProgress = ((progress - start) / (end - start)).clamp(0.0, 1.0);

    return Opacity(
      opacity: dotProgress * 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(
          '·',
          style: TextStyle(
            color: EtoleColors.cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
