import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/hub_models.dart';
import 'shard_clippers.dart';

class ShardItem extends ConsumerStatefulWidget {
  final EtoleWorld world;
  final double width;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double floatPhase;

  const ShardItem({
    super.key,
    required this.world,
    required this.width,
    required this.height,
    required this.onTap,
    this.onLongPress,
    this.floatPhase = 0.0,
  });

  @override
  ConsumerState<ShardItem> createState() => _ShardItemState();
}

class _ShardItemState extends ConsumerState<ShardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isPressed = false;
  Offset _touchPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(reduceMotionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check status notification indicators
    final hasTodayOccasion =
        ref.watch(hasTodayOccasionProvider).valueOrNull ?? false;
    final hasOverdueDocs =
        ref.watch(hasOverdueDocsProvider).valueOrNull ?? false;
    final showIndicator =
        (widget.world == EtoleWorld.network && hasTodayOccasion) ||
        (widget.world == EtoleWorld.docs && hasOverdueDocs);

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // Subtle floating sine wave
        final t = _floatController.value * 2 * pi + widget.floatPhase;
        final floatY = reduceMotion ? 0.0 : sin(t) * 4.5;
        final floatRotate = reduceMotion ? 0.0 : sin(t * 0.7) * 0.018;

        // Interactive touch scale & tilt
        final pressScale = _isPressed ? 0.95 : 1.0;
        final tiltX = _isPressed
            ? (_touchPosition.dx - widget.width / 2) / 200
            : 0.0;
        final tiltY = _isPressed
            ? (_touchPosition.dy - widget.height / 2) / 200
            : 0.0;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateZ(floatRotate)
              ..rotateX(-tiltY)
              ..rotateY(tiltX)
              ..scaleByDouble(pressScale, pressScale, 1.0, 1.0),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (details) {
          setState(() {
            _isPressed = true;
            _touchPosition = details.localPosition;
          });
          EtoleHaptics.light();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Soft dropped ambient shadow
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ShardShadowPainter(world: widget.world),
                  ),
                ),
              ),

              // 2. Frosted Glass Shard Content
              ClipPath(
                clipper: ShardPolygonClipper(world: widget.world),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0x350A0C0D),
                                const Color(0x22111417),
                                const Color(0x400A0C0D),
                              ]
                            : [
                                const Color(0x40FFFFFF),
                                const Color(0x22FFFFFF),
                                const Color(0x35FFFFFF),
                              ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Living glimpse inside the shard
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildLivingGlimpse(widget.world, isDark),
                          ),
                        ),

                        // Shard Label (Strictly BRIAN, NETWORK, DOCS, SETTINGS)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 18,
                          child: Center(
                            child: Text(
                              widget.world.displayName,
                              style:
                                  EtoleTypography.sectionTitle(
                                    color: isDark
                                        ? EtoleColors.cream
                                        : EtoleColors.lightTextPrimary,
                                  ).copyWith(
                                    fontSize: 18,
                                    letterSpacing: 1.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Fine bright glint outline border
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: ShardBorderPainter(
                      world: widget.world,
                      glintIntensity: _isPressed ? 1.0 : 0.6,
                      isHovered: _isPressed,
                    ),
                  ),
                ),
              ),

              // 4. Status Notification Ember Dot
              if (showIndicator)
                Positioned(top: 14, right: 18, child: _buildPulsingEmberDot()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingEmberDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: EtoleColors.cyan,
            boxShadow: [
              BoxShadow(
                color: EtoleColors.cyan.withValues(alpha: value * 0.8),
                blurRadius: 6 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLivingGlimpse(EtoleWorld world, bool isDark) {
    switch (world) {
      case EtoleWorld.brian:
        // Mini Card Silhouette with foil glint & BE monogram
        return Center(
          child: Container(
            width: 72,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EtoleColors.darkSurfaceElevated,
                  EtoleColors.darkSurface,
                ],
              ),
              border: Border.all(
                color: EtoleColors.cyan.withValues(alpha: 0.45),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: EtoleColors.cyan.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Diagonal subtle foil sheen
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 20,
                  width: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          EtoleColors.cream.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'BE',
                    style: EtoleTypography.labelCaps(color: EtoleColors.cream)
                        .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );

      case EtoleWorld.network:
        // Constellation of glowing interconnected nodes
        return CustomPaint(
          size: const Size(80, 50),
          painter: _ConstellationGlimpsePainter(),
        );

      case EtoleWorld.docs:
        // Paper sheet corner with BE seal mark
        return Center(
          child: Container(
            width: 48,
            height: 58,
            decoration: BoxDecoration(
              color: EtoleColors.cream.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(2),
                topRight: Radius.circular(10), // folded corner
              ),
              border: Border.all(
                color: EtoleColors.cream.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 3,
                  color: EtoleColors.cyan.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 32,
                  height: 1.5,
                  color: EtoleColors.cream.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 24,
                  height: 1.5,
                  color: EtoleColors.cream.withValues(alpha: 0.2),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: EtoleColors.cyan.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case EtoleWorld.production:
        // Clapperboard cinema slate
        return const Center(
          child: Icon(
            Icons.movie_creation_outlined,
            color: EtoleColors.cyan,
            size: 36,
          ),
        );

      case EtoleWorld.meetings:
        return const Center(
          child: Icon(Icons.forum_outlined, color: EtoleColors.cyan, size: 36),
        );

      case EtoleWorld.settings:
        // Engraved concentric tribal dials
        return Center(
          child: SizedBox(
            width: 52,
            height: 52,
            child: CustomPaint(painter: _DialGlimpsePainter()),
          ),
        );
    }
  }
}

class _ShardShadowPainter extends CustomPainter {
  final EtoleWorld world;

  _ShardShadowPainter({required this.world});

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = ShardPolygonClipper(world: world);
    final path = clipper.getClip(size);

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.65), 18.0, false);
  }

  @override
  bool shouldRepaint(covariant _ShardShadowPainter oldDelegate) =>
      oldDelegate.world != world;
}

class _ConstellationGlimpsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint = Paint()
      ..color = EtoleColors.cream.withValues(alpha: 0.85);
    final emberNodePaint = Paint()
      ..color = EtoleColors.cyan
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final linePaint = Paint()
      ..color = EtoleColors.cream.withValues(alpha: 0.2)
      ..strokeWidth = 0.8;

    final points = [
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.45, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.4),
      Offset(size.width * 0.55, size.height * 0.75),
      Offset(size.width * 0.35, size.height * 0.8),
    ];

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        if ((points[i] - points[j]).distance < 38) {
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
    }

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (i == 1 || i == 2) {
        canvas.drawCircle(p, 3.0, emberNodePaint);
      } else {
        canvas.drawCircle(p, 2.0, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationGlimpsePainter oldDelegate) =>
      false;
}

class _DialGlimpsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final linePaint = Paint()
      ..color = EtoleColors.cream.withValues(alpha: 0.25)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final emberPaint = Paint()
      ..color = EtoleColors.cyan.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 22, linePaint);
    canvas.drawCircle(center, 14, emberPaint);
    canvas.drawCircle(center, 6, linePaint);

    // Crosshair ticks
    canvas.drawLine(
      center - const Offset(26, 0),
      center - const Offset(18, 0),
      linePaint,
    );
    canvas.drawLine(
      center + const Offset(18, 0),
      center + const Offset(26, 0),
      linePaint,
    );
    canvas.drawLine(
      center - const Offset(0, 26),
      center - const Offset(0, 18),
      linePaint,
    );
    canvas.drawLine(
      center + const Offset(0, 18),
      center + const Offset(0, 26),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DialGlimpsePainter oldDelegate) => false;
}
