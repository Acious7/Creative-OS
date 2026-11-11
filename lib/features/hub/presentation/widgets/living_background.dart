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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              // 1. Pristine velvety studio obsidian base canvas
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F141C), Color(0xFF080B0F)],
                  ),
                ),
              ),

              // 2. Ultra-subtle, smooth studio ambient key-light (top)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.6),
                    radius: 1.1,
                    colors: [
                      const Color(0xFF38B6DB).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),

              // 3. Ultra-subtle warm floor studio fill (bottom)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 0.8),
                    radius: 1.0,
                    colors: [
                      const Color(0xFFF5A623).withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
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
