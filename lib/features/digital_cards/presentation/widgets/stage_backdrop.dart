import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/theme/brand_theme_provider.dart';

/// The Stage Backdrop for World 1 (Brian).
/// Features a dark cinematic stage, an overhead warm spotlight cone
/// shining down on the card, and subtle floating dust particles.
class StageBackdrop extends ConsumerStatefulWidget {
  final Widget child;

  const StageBackdrop({super.key, required this.child});

  @override
  ConsumerState<StageBackdrop> createState() => _StageBackdropState();
}

class _StageBackdropState extends ConsumerState<StageBackdrop>
    with SingleTickerProviderStateMixin {
  late AnimationController _dustController;
  final List<_DustMote> _dustMotes = [];
  final Random _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _dustController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _initDustMotes();
  }

  void _initDustMotes() {
    _dustMotes.clear();
    for (int i = 0; i < 28; i++) {
      _dustMotes.add(
        _DustMote(
          x:
              0.2 +
              _rng.nextDouble() * 0.6, // clustered in center spotlight cone
          y: _rng.nextDouble(),
          size: 1.0 + _rng.nextDouble() * 2.5,
          speed: 0.02 + _rng.nextDouble() * 0.05,
          opacity: 0.15 + _rng.nextDouble() * 0.45,
          wobblePhase: _rng.nextDouble() * 2 * pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _dustController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = ref.watch(reduceMotionProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Stage Floor and Backdrop Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF040506),
                      const Color(0xFF0A0C0D),
                      const Color(0xFF070809),
                      const Color(0xFF020304),
                    ]
                  : [
                      const Color(0xFFEDE8E1),
                      const Color(0xFFF7F4EE),
                      const Color(0xFFEBE5DC),
                      const Color(0xFFDDD6CB),
                    ],
              stops: const [0.0, 0.45, 0.75, 1.0],
            ),
          ),
        ),

        // 2. Overhead Warm Spotlight Cone
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _SpotlightPainter(isDark: isDark)),
          ),
        ),

        // 3. Subtle floating dust motes caught in the spotlight beam
        if (!reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _dustController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DustMotesPainter(
                      motes: _dustMotes,
                      progress: _dustController.value,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),
          ),

        // 4. Center Stage Floor Ellipse Glow (where the spotlight hits the floor)
        Positioned(
          left: 0,
          right: 0,
          bottom: 120,
          height: 120,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(
                  Radius.elliptical(MediaQuery.of(context).size.width, 100),
                ),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    isDark
                        ? EtoleColors.cyan.withValues(alpha: 0.12)
                        : EtoleColors.cyan.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // 5. Stage Content (Card, Controls, Drawers)
        widget.child,
      ],
    );
  }
}

class _DustMote {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double wobblePhase;

  _DustMote({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.wobblePhase,
  });
}

class _SpotlightPainter extends CustomPainter {
  final bool isDark;

  _SpotlightPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Overhead spotlight apex
    final apex = Offset(w * 0.5, -40);

    // Spotlight Cone Path
    final conePath = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(w * 0.05, h * 0.85)
      ..lineTo(w * 0.95, h * 0.85)
      ..close();

    final spotlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.85),
        radius: 1.1,
        colors: [
          isDark
              ? const Color(0xFFFFF7EB).withValues(alpha: 0.14)
              : const Color(0xFFFFE8D1).withValues(alpha: 0.22),
          isDark
              ? EtoleColors.cyan.withValues(alpha: 0.06)
              : EtoleColors.cyan.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(conePath, spotlightPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _DustMotesPainter extends CustomPainter {
  final List<_DustMote> motes;
  final double progress;
  final bool isDark;

  _DustMotesPainter({
    required this.motes,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in motes) {
      final currentY = (m.y - (progress * m.speed * 8.0)) % 1.0;
      final currentX = m.x + sin(progress * 2 * pi + m.wobblePhase) * 0.02;

      final px = currentX * size.width;
      final py = currentY * size.height;

      // Only draw when inside the spotlight cone
      final coneHalfWidthAtY =
          (size.width * 0.45) * (py / size.height).clamp(0.1, 1.0);
      final distFromCenter = (px - (size.width * 0.5)).abs();

      if (distFromCenter < coneHalfWidthAtY) {
        final beamFactor = (1.0 - (distFromCenter / coneHalfWidthAtY)).clamp(
          0.0,
          1.0,
        );
        final paint = Paint()
          ..color = (isDark ? const Color(0xFFFFF5E6) : const Color(0xFFB5651D))
              .withValues(alpha: m.opacity * beamFactor * 0.85);

        canvas.drawCircle(Offset(px, py), m.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DustMotesPainter oldDelegate) => true;
}
