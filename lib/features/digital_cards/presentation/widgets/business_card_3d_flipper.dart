import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/theme/brand_theme_provider.dart';

/// 3D Business Card Flipper with motion sensor tilt, specular sheen sweep,
/// tap-to-flip double-sided 3D transform, and animated concentric NFC pulse rings.
class BusinessCard3DFlipper extends ConsumerStatefulWidget {
  final Widget front;
  final Widget back;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final bool isNfcPulsing;

  const BusinessCard3DFlipper({
    super.key,
    required this.front,
    required this.back,
    this.onLongPress,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.isNfcPulsing = false,
  });

  @override
  ConsumerState<BusinessCard3DFlipper> createState() =>
      BusinessCard3DFlipperState();
}

class BusinessCard3DFlipperState extends ConsumerState<BusinessCard3DFlipper>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _nfcPulseController;

  bool _showFront = true;
  bool get isFront => _showFront;

  // Sensor tilt values (-0.22 to 0.22 radians)
  double _sensorTiltX = 0.0;
  double _sensorTiltY = 0.0;

  // Drag tilt fallback
  double _dragTiltX = 0.0;
  double _dragTiltY = 0.0;

  StreamSubscription<AccelerometerEvent>? _sensorSubscription;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    _nfcPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _startSensorListener();
  }

  void _startSensorListener() {
    final reduceMotion = ref.read(reduceMotionProvider);
    if (reduceMotion) return;

    try {
      _sensorSubscription = accelerometerEventStream().listen((event) {
        if (!mounted) return;
        final currentReduceMotion = ref.read(reduceMotionProvider);
        if (currentReduceMotion) return;

        setState(() {
          // Low-pass filter damping for smooth, subtle tactile tilt
          final targetX = ((event.y - 6.0) / 7.0).clamp(-1.0, 1.0) * 0.18;
          final targetY = (-event.x / 7.0).clamp(-1.0, 1.0) * 0.18;

          _sensorTiltX = _sensorTiltX * 0.88 + targetX * 0.12;
          _sensorTiltY = _sensorTiltY * 0.88 + targetY * 0.12;
        });
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant BusinessCard3DFlipper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNfcPulsing && !oldWidget.isNfcPulsing) {
      triggerNfcPulse();
    }
  }

  void triggerNfcPulse() {
    _nfcPulseController.forward(from: 0.0);
    EtoleHaptics.success();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel().catchError((_) {});
    _flipController.dispose();
    _nfcPulseController.dispose();
    super.dispose();
  }

  void flipCard() {
    EtoleHaptics.light();
    if (_showFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final reduceMotion = ref.read(reduceMotionProvider);
    if (reduceMotion) return;

    setState(() {
      _dragTiltX = (_dragTiltX + details.delta.dy * 0.008).clamp(-0.25, 0.25);
      _dragTiltY = (_dragTiltY - details.delta.dx * 0.008).clamp(-0.25, 0.25);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final vx = details.velocity.pixelsPerSecond.dx;
    if (vx < -240) {
      widget.onSwipeLeft?.call();
    } else if (vx > 240) {
      widget.onSwipeRight?.call();
    }
    setState(() {
      _dragTiltX = 0.0;
      _dragTiltY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(reduceMotionProvider);

    return GestureDetector(
      onTap: flipCard,
      onLongPress: widget.onLongPress,
      onPanUpdate: reduceMotion ? null : _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipAnimation, _nfcPulseController]),
        builder: (context, child) {
          final flipValue = _flipAnimation.value;
          final flipAngle = reduceMotion
              ? (_showFront ? 0.0 : pi)
              : flipValue * pi;

          final effectiveTiltX = reduceMotion
              ? 0.0
              : (_sensorTiltX + _dragTiltX);
          final effectiveTiltY = reduceMotion
              ? 0.0
              : (_sensorTiltY + _dragTiltY);

          final totalAngleY = flipAngle + effectiveTiltY;
          final totalAngleX = effectiveTiltX;

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // Depth perspective
            ..rotateX(totalAngleX)
            ..rotateY(totalAngleY);

          final isBackVisible = flipAngle >= (pi / 2);

          // Specular light sheen gradient position based on combined tilt
          final sheenOffset = Alignment(
            -(effectiveTiltY * 6).clamp(-1.0, 1.0),
            -(effectiveTiltX * 6).clamp(-1.0, 1.0),
          );

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Concentric NFC Pulse Waves
              if (_nfcPulseController.isAnimating)
                ...List.generate(3, (index) {
                  final progress = (_nfcPulseController.value - (index * 0.2))
                      .clamp(0.0, 1.0);
                  if (progress <= 0.0 || progress >= 1.0)
                    return const SizedBox.shrink();

                  final ringScale = 1.0 + (progress * 0.85);
                  final ringOpacity = (1.0 - progress) * 0.8;

                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: ringScale,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusLg + 6,
                            ),
                            border: Border.all(
                              color: EtoleColors.cyan.withValues(
                                alpha: ringOpacity,
                              ),
                              width: 2.0 * (1.0 - progress * 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: EtoleColors.cyan.withValues(
                                  alpha: ringOpacity * 0.4,
                                ),
                                blurRadius: 16 * progress,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              // 2. 3D Card with double-sided rotation
              Transform(
                transform: transform,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    isBackVisible
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(pi),
                            alignment: Alignment.center,
                            child: widget.back,
                          )
                        : widget.front,

                    // 3. Diagonal Specular Sheen Sweep
                    if (!reduceMotion)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusLg,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(
                                    sheenOffset.x - 1.2,
                                    sheenOffset.y - 1.2,
                                  ),
                                  end: Alignment(
                                    sheenOffset.x + 1.2,
                                    sheenOffset.y + 1.2,
                                  ),
                                  colors: [
                                    Colors.transparent,
                                    EtoleColors.cream.withValues(alpha: 0.0),
                                    EtoleColors.cream.withValues(alpha: 0.12),
                                    EtoleColors.cyan.withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.4, 0.5, 0.58, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
