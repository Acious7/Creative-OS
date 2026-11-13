import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/theme/brand_theme_provider.dart';

class LivingBackground extends ConsumerStatefulWidget {
  final Widget child;

  const LivingBackground({super.key, required this.child});

  @override
  ConsumerState<LivingBackground> createState() => LivingBackgroundState();
}

class LivingBackgroundState extends ConsumerState<LivingBackground>
    with SingleTickerProviderStateMixin {
  // Parallax tilt offsets normalized from -1.0 to 1.0
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // Touch drag offset fallback
  double _dragTiltX = 0.0;
  double _dragTiltY = 0.0;

  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  late AnimationController _particleController;
  final List<_EmberParticle> _particles = [];
  final Random _rng = Random(1234);

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initParticles();
    _startSensorListener();
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 36; i++) {
      _particles.add(
        _EmberParticle(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          size: 1.5 + _rng.nextDouble() * 3.5,
          speed: 0.03 + _rng.nextDouble() * 0.06,
          swaySpeed: 1.0 + _rng.nextDouble() * 2.0,
          opacity: 0.25 + _rng.nextDouble() * 0.65,
          isEmber: _rng.nextDouble() < 0.7,
        ),
      );
    }
  }

  void _startSensorListener() {
    final reduceMotion = ref.read(reduceMotionProvider);
    if (reduceMotion) return;

    try {
      _sensorSubscription = accelerometerEventStream().listen(
        (event) {
          if (!mounted) return;
          final currentReduceMotion = ref.read(reduceMotionProvider);
          if (currentReduceMotion) return;

          // Low-pass filter damping for smooth cinematic tilt
          setState(() {
            // In portrait: X is horizontal tilt (-10 to 10), Y is vertical tilt
            final targetX = (-event.x / 6.0).clamp(-1.0, 1.0);
            final targetY = ((event.y - 6.0) / 6.0).clamp(-1.0, 1.0);
            _tiltX = _tiltX * 0.85 + targetX * 0.15;
            _tiltY = _tiltY * 0.85 + targetY * 0.15;
          });
        },
        onError: (_) {
          // Fallback gracefully on devices without sensor support
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel().catchError((_) {});
    _particleController.dispose();
    super.dispose();
  }

  void onPanUpdate(DragUpdateDetails details, Size screenSize) {
    final reduceMotion = ref.read(reduceMotionProvider);
    if (reduceMotion) return;

    setState(() {
      _dragTiltX = (_dragTiltX + details.delta.dx / (screenSize.width * 0.5))
          .clamp(-1.0, 1.0);
      _dragTiltY = (_dragTiltY + details.delta.dy / (screenSize.height * 0.5))
          .clamp(-1.0, 1.0);
    });
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      _dragTiltX = 0.0;
      _dragTiltY = 0.0;
    });
  }

  Color _getTimeOfDayTint() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 9) {
      // Dawn: Subtle warm amber/rose tint
      return const Color(0xFF8B4513).withValues(alpha: 0.07);
    } else if (hour >= 17 && hour < 20) {
      // Sunset: Ember warmth
      return const Color(0xFFFF5722).withValues(alpha: 0.08);
    } else if (hour >= 20 || hour < 5) {
      // Night: Deep obsidian-blue atmospheric tint
      return const Color(0xFF0A101D).withValues(alpha: 0.12);
    }
    // Midday: Neutral cinematic obsidian
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(reduceMotionProvider);
    final studioTheme = ref.watch(currentStudioThemeProvider);

    final effectiveTiltX = reduceMotion
        ? 0.0
        : (_tiltX + _dragTiltX).clamp(-1.0, 1.0);
    final effectiveTiltY = reduceMotion
        ? 0.0
        : (_tiltY + _dragTiltY).clamp(-1.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanUpdate: (d) => onPanUpdate(d, size),
          onPanEnd: onPanEnd,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Pristine velvety studio obsidian / theme base canvas
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: studioTheme.backgroundGradient,
                  ),
                ),
              ),

              // 2. Tribal Sketch Background Layer (tints with active theme)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(effectiveTiltX * 16, effectiveTiltY * 16),
                  child: CustomPaint(
                    painter: _TribalSketchCanvasPainter(
                      tintColor: studioTheme.tribalSketchTint,
                      glowColor: studioTheme.tribalGlowTint,
                      isDark: studioTheme.isDark,
                    ),
                  ),
                ),
              ),

              // 3. Ultra-subtle, smooth studio ambient key-light (top)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.6),
                    radius: 1.1,
                    colors: [studioTheme.ambientKeyLight, Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),

              // 4. Ultra-subtle warm floor studio fill (bottom)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 0.8),
                    radius: 1.0,
                    colors: [studioTheme.ambientFloorFill, Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),

              // Foreground Content (Window, Typography, Actions) with HubTiltScope
              HubTiltScope(
                tiltX: effectiveTiltX,
                tiltY: effectiveTiltY,
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Provides active tilt angles to descendants in the Hub
class HubTiltScope extends InheritedWidget {
  final double tiltX;
  final double tiltY;

  const HubTiltScope({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required super.child,
  });

  static (double, double) of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HubTiltScope>();
    if (scope == null) return (0.0, 0.0);
    return (scope.tiltX, scope.tiltY);
  }

  @override
  bool updateShouldNotify(covariant HubTiltScope oldWidget) {
    return oldWidget.tiltX != tiltX || oldWidget.tiltY != tiltY;
  }
}

class _EmberParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double swaySpeed;
  final double opacity;
  final bool isEmber;

  _EmberParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.swaySpeed,
    required this.opacity,
    required this.isEmber,
  });
}

class _DriftingParticlesPainter extends CustomPainter {
  final List<_EmberParticle> particles;
  final double progress;
  final double tiltX;
  final double tiltY;

  _DriftingParticlesPainter({
    required this.particles,
    required this.progress,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Particles drift upward with gentle sine sway
      final currentY = (p.y - progress * p.speed) % 1.0;
      final sway = sin(progress * pi * 2 * p.swaySpeed + p.x * 10) * 0.025;
      final currentX = (p.x + sway + tiltX * 0.03) % 1.0;

      final px = currentX * size.width;
      final py = currentY * size.height;

      final color = p.isEmber ? EtoleColors.cyan : EtoleColors.cream;
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity * 0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.4);

      canvas.drawCircle(Offset(px, py), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DriftingParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY;
  }
}

/// Paints the authentic tribal sketch background (concentric dials, warrior spears, chevron shields)
/// tinted with the active StudioTheme colors.
class _TribalSketchCanvasPainter extends CustomPainter {
  final Color tintColor;
  final Color glowColor;
  final bool isDark;

  const _TribalSketchCanvasPainter({
    required this.tintColor,
    required this.glowColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final primaryAlpha = isDark ? 0.16 : 0.22;
    final secondaryAlpha = isDark ? 0.08 : 0.12;

    final mainPaint = Paint()
      ..color = tintColor.withValues(alpha: primaryAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: secondaryAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    // 0. Night Starlight Field (when nighttime)
    final hour = DateTime.now().hour;
    if (hour >= 20 || hour < 5) {
      final starPaint = Paint()
        ..color = (isDark ? Colors.white : tintColor).withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      // Procedural starlight constellations in top half
      final starCoords = [
        Offset(w * 0.15, h * 0.12),
        Offset(w * 0.28, h * 0.08),
        Offset(w * 0.42, h * 0.15),
        Offset(w * 0.65, h * 0.10),
        Offset(w * 0.78, h * 0.18),
        Offset(w * 0.88, h * 0.06),
        Offset(w * 0.20, h * 0.25),
        Offset(w * 0.52, h * 0.22),
        Offset(w * 0.72, h * 0.28),
        Offset(w * 0.35, h * 0.32),
      ];
      for (final pt in starCoords) {
        canvas.drawCircle(pt, 1.2, starPaint);
      }
      // Faint constellation connector lines
      final constellPaint = Paint()
        ..color = (isDark ? Colors.white : tintColor).withValues(alpha: 0.08)
        ..strokeWidth = 0.6;
      canvas.drawLine(starCoords[0], starCoords[1], constellPaint);
      canvas.drawLine(starCoords[1], starCoords[2], constellPaint);
      canvas.drawLine(starCoords[3], starCoords[4], constellPaint);
      canvas.drawLine(starCoords[4], starCoords[5], constellPaint);
      canvas.drawLine(starCoords[6], starCoords[9], constellPaint);
      canvas.drawLine(starCoords[7], starCoords[8], constellPaint);
    }

    // 1. Concentric Tribal Dials in lower half
    final centerDial = Offset(w * 0.5, h * 0.78);
    for (double r = 40; r <= 220; r += 35) {
      canvas.drawCircle(centerDial, r, glowPaint);
      canvas.drawCircle(centerDial, r, mainPaint);
    }

    // Dial Radial Ticks
    for (int deg = 0; deg < 360; deg += 30) {
      final rad = deg * pi / 180;
      final p1 = centerDial + Offset(cos(rad) * 190, sin(rad) * 190);
      final p2 = centerDial + Offset(cos(rad) * 230, sin(rad) * 230);
      canvas.drawLine(p1, p2, mainPaint);
    }

    // 1.5 Sacred Geometry: Maasai Diamond Lattice Matrix above dial
    final diamondTop = h * 0.38;
    const diamondSize = 16.0;
    for (int col = -3; col <= 3; col++) {
      final dx = w * 0.5 + col * (diamondSize * 1.5);
      final dy = diamondTop + (col.abs() % 2 == 1 ? diamondSize * 0.5 : 0);
      final diamondPath = Path()
        ..moveTo(dx, dy - diamondSize * 0.5)
        ..lineTo(dx + diamondSize * 0.6, dy)
        ..lineTo(dx, dy + diamondSize * 0.5)
        ..lineTo(dx - diamondSize * 0.6, dy)
        ..close();
      canvas.drawPath(diamondPath, mainPaint..strokeWidth = 0.9);
    }

    // 2. Warrior Spear & Shield Axis
    canvas.drawLine(
      Offset(w * 0.5, h * 0.48),
      Offset(w * 0.5, h * 0.95),
      mainPaint..strokeWidth = 2.0,
    );

    // Stepped Chevron Pyramids along the vertical axis
    for (double y = h * 0.52; y <= h * 0.74; y += 38) {
      final path = Path()
        ..moveTo(w * 0.5, y - 14)
        ..lineTo(w * 0.5 - 28, y + 14)
        ..lineTo(w * 0.5 + 28, y + 14)
        ..close();
      canvas.drawPath(path, mainPaint..strokeWidth = 1.0);
    }

    // 3. Flanking Tribal Zig-zag Lines
    for (int i = 0; i < 4; i++) {
      final yOffset = h * 0.55 + i * 40;
      // Left flank
      final leftPath = Path()
        ..moveTo(20, yOffset)
        ..lineTo(70, yOffset - 30)
        ..lineTo(120, yOffset + 15)
        ..lineTo(160, yOffset - 10);
      canvas.drawPath(leftPath, glowPaint);
      canvas.drawPath(leftPath, mainPaint..strokeWidth = 1.1);

      // Right flank
      final rightPath = Path()
        ..moveTo(w - 20, yOffset)
        ..lineTo(w - 70, yOffset - 30)
        ..lineTo(w - 120, yOffset + 15)
        ..lineTo(w - 160, yOffset - 10);
      canvas.drawPath(rightPath, glowPaint);
      canvas.drawPath(rightPath, mainPaint..strokeWidth = 1.1);
    }
  }

  @override
  bool shouldRepaint(covariant _TribalSketchCanvasPainter oldDelegate) {
    return oldDelegate.tintColor != tintColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.isDark != isDark;
  }
}
