import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/hub_models.dart';
import 'living_background.dart';
import 'window_pane_item.dart';

/// The central 4-pane window representing the 4 Etole worlds in a 2x2 grid.
/// Tilts organically with the phone's motion sensor in subtle 3D perspective.
/// Tapping a pane swings it open on a hinge like a real window and flies through.
class HubWindow extends ConsumerStatefulWidget {
  final Function(EtoleWorld world) onWorldSelected;
  final VoidCallback onBrianLongPressed;
  final double maxWidth;

  const HubWindow({
    super.key,
    required this.onWorldSelected,
    required this.onBrianLongPressed,
    this.maxWidth = 348.0,
  });

  @override
  ConsumerState<HubWindow> createState() => _HubWindowState();
}

class _HubWindowState extends ConsumerState<HubWindow>
    with SingleTickerProviderStateMixin {
  late AnimationController _swingController;
  late Animation<double> _swingAnimation;
  late Animation<double> _flyThroughScaleAnimation;
  late Animation<double> _flyThroughOpacityAnimation;

  EtoleWorld? _swingingWorld;

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _swingAnimation = Tween<double>(begin: 0.0, end: 1.38).animate(
      CurvedAnimation(
        parent: _swingController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    _flyThroughScaleAnimation = Tween<double>(begin: 1.0, end: 3.4).animate(
      CurvedAnimation(
        parent: _swingController,
        curve: const Interval(0.18, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _flyThroughOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _swingController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _swingController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _swingingWorld != null) {
        final world = _swingingWorld!;
        widget.onWorldSelected(world);
        // Reset controller for when user navigates back
        _swingController.reset();
        setState(() {
          _swingingWorld = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  void _onPaneTapped(EtoleWorld world) {
    if (_swingController.isAnimating) return;
    setState(() {
      _swingingWorld = world;
    });
    _swingController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(reduceMotionProvider);

    // Read tilt from living background
    final (tiltX, tiltY) = reduceMotion ? (0.0, 0.0) : HubTiltScope.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final windowWidth = math.min(availableWidth - 36, widget.maxWidth);

        const crossGap = 8.0;
        final paneWidth = (windowWidth - crossGap) / 2;
        final paneHeight = paneWidth * 1.15;
        final windowHeight = (paneHeight * 2) + crossGap;

        return AnimatedBuilder(
          animation: _swingController,
          builder: (context, child) {
            final scale = _flyThroughScaleAnimation.value;
            final opacity = _flyThroughOpacityAnimation.value.clamp(0.0, 1.0);
            final swingAngle = _swingAnimation.value;

            return Opacity(
              opacity: opacity,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012) // subtle 3D perspective
                  ..rotateX(-tiltY * 0.12)
                  ..rotateY(tiltX * 0.15)
                  ..scale(scale),
                child: SizedBox(
                  width: windowWidth,
                  height: windowHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Thin ambient cross gap back-glow
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CrossGapGlowPainter(
                              crossGap: crossGap,
                              paneWidth: paneWidth,
                              paneHeight: paneHeight,
                            ),
                          ),
                        ),
                      ),

                      // 2x2 Grid of Window Panes
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Row: BRIAN (left) & NETWORK (right)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WindowPaneItem(
                                world: EtoleWorld.brian,
                                width: paneWidth,
                                height: paneHeight,
                                swingAngle: _swingingWorld == EtoleWorld.brian
                                    ? swingAngle
                                    : 0.0,
                                isSwinging: _swingingWorld == EtoleWorld.brian,
                                onTap: () => _onPaneTapped(EtoleWorld.brian),
                                onLongPress: widget.onBrianLongPressed,
                              ),
                              const SizedBox(width: crossGap),
                              WindowPaneItem(
                                world: EtoleWorld.network,
                                width: paneWidth,
                                height: paneHeight,
                                swingAngle: _swingingWorld == EtoleWorld.network
                                    ? swingAngle
                                    : 0.0,
                                isSwinging:
                                    _swingingWorld == EtoleWorld.network,
                                onTap: () => _onPaneTapped(EtoleWorld.network),
                              ),
                            ],
                          ),
                          const SizedBox(height: crossGap),

                          // Bottom Row: DOCS (left) & SETTINGS (right)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WindowPaneItem(
                                world: EtoleWorld.docs,
                                width: paneWidth,
                                height: paneHeight,
                                swingAngle: _swingingWorld == EtoleWorld.docs
                                    ? swingAngle
                                    : 0.0,
                                isSwinging: _swingingWorld == EtoleWorld.docs,
                                onTap: () => _onPaneTapped(EtoleWorld.docs),
                              ),
                              const SizedBox(width: crossGap),
                              WindowPaneItem(
                                world: EtoleWorld.settings,
                                width: paneWidth,
                                height: paneHeight,
                                swingAngle:
                                    _swingingWorld == EtoleWorld.settings
                                    ? swingAngle
                                    : 0.0,
                                isSwinging:
                                    _swingingWorld == EtoleWorld.settings,
                                onTap: () => _onPaneTapped(EtoleWorld.settings),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Paints the delicate hairline cross line in the gap between the four panes
class _CrossGapGlowPainter extends CustomPainter {
  final double crossGap;
  final double paneWidth;
  final double paneHeight;

  _CrossGapGlowPainter({
    required this.crossGap,
    required this.paneWidth,
    required this.paneHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = paneWidth + (crossGap / 2);
    final centerY = paneHeight + (crossGap / 2);

    final linePaint = Paint()
      ..color = EtoleColors.cream.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    final cyanCenterPaint = Paint()
      ..color = EtoleColors.cyan.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    // Vertical cross line
    canvas.drawLine(
      Offset(centerX, 12),
      Offset(centerX, size.height - 12),
      linePaint,
    );

    // Horizontal cross line
    canvas.drawLine(
      Offset(12, centerY),
      Offset(size.width - 12, centerY),
      linePaint,
    );

    // Center intersection glint dot
    canvas.drawCircle(Offset(centerX, centerY), 3.0, cyanCenterPaint);
  }

  @override
  bool shouldRepaint(covariant _CrossGapGlowPainter oldDelegate) {
    return oldDelegate.crossGap != crossGap ||
        oldDelegate.paneWidth != paneWidth ||
        oldDelegate.paneHeight != paneHeight;
  }
}
