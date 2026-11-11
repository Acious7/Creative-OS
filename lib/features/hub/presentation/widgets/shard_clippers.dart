import 'package:flutter/material.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../domain/hub_models.dart';

/// Irregular shattered polygon clippers for each of the 4 shards
class ShardPolygonClipper extends CustomClipper<Path> {
  final EtoleWorld world;

  const ShardPolygonClipper({required this.world});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (world) {
      case EtoleWorld.brian:
        // Top Shard: Asymmetrical faceted apex
        path.moveTo(w * 0.48, h * 0.04);
        path.lineTo(w * 0.94, h * 0.42);
        path.lineTo(w * 0.82, h * 0.92);
        path.lineTo(w * 0.52, h * 0.98);
        path.lineTo(w * 0.12, h * 0.74);
        path.lineTo(w * 0.08, h * 0.36);
        path.close();
        break;

      case EtoleWorld.network:
        // Left Shard: Dynamic faceted left wing
        path.moveTo(w * 0.32, h * 0.08);
        path.lineTo(w * 0.96, h * 0.28);
        path.lineTo(w * 0.84, h * 0.84);
        path.lineTo(w * 0.38, h * 0.96);
        path.lineTo(w * 0.06, h * 0.62);
        path.lineTo(w * 0.12, h * 0.22);
        path.close();
        break;

      case EtoleWorld.docs:
        // Right Shard: Angular right facet
        path.moveTo(w * 0.08, h * 0.24);
        path.lineTo(w * 0.72, h * 0.06);
        path.lineTo(w * 0.94, h * 0.48);
        path.lineTo(w * 0.88, h * 0.88);
        path.lineTo(w * 0.24, h * 0.94);
        path.lineTo(w * 0.04, h * 0.72);
        path.close();
        break;

      case EtoleWorld.production:
      case EtoleWorld.meetings:
      case EtoleWorld.settings:
        // Bottom Shard: Inverted apex talisman facet
        path.moveTo(w * 0.18, h * 0.08);
        path.lineTo(w * 0.82, h * 0.06);
        path.lineTo(w * 0.94, h * 0.58);
        path.lineTo(w * 0.52, h * 0.96);
        path.lineTo(w * 0.08, h * 0.64);
        path.close();
        break;
    }

    return path;
  }

  @override
  bool shouldReclip(covariant ShardPolygonClipper oldClipper) =>
      oldClipper.world != world;
}

/// Border painter that outlines the exact polygon shard path with a fine bright edge
class ShardBorderPainter extends CustomPainter {
  final EtoleWorld world;
  final double glintIntensity; // 0.0 to 1.0 based on tilt / touch
  final bool isHovered;

  ShardBorderPainter({
    required this.world,
    this.glintIntensity = 0.5,
    this.isHovered = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = ShardPolygonClipper(world: world);
    final path = clipper.getClip(size);

    // Subtle edge glow
    final glowPaint = Paint()
      ..color = EtoleColors.cyan.withValues(
        alpha: isHovered ? 0.4 : 0.12 * glintIntensity,
      )
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(path, glowPaint);

    // Fine bright glint border
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          EtoleColors.cream.withValues(
            alpha: (0.4 + glintIntensity * 0.5).clamp(0.0, 1.0),
          ),
          EtoleColors.cream.withValues(alpha: 0.15),
          EtoleColors.cyan.withValues(
            alpha: (0.2 + glintIntensity * 0.6).clamp(0.0, 1.0),
          ),
          EtoleColors.cream.withValues(alpha: 0.25),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = isHovered ? 1.5 : 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ShardBorderPainter oldDelegate) {
    return oldDelegate.world != world ||
        oldDelegate.glintIntensity != glintIntensity ||
        oldDelegate.isHovered != isHovered;
  }
}

/// Paints the delicate fracture / crack lines connecting the shards
class CrackLinesPainter extends CustomPainter {
  final Offset brianPos;
  final Offset networkPos;
  final Offset docsPos;
  final Offset settingsPos;
  final double animationPhase;

  CrackLinesPainter({
    required this.brianPos,
    required this.networkPos,
    required this.docsPos,
    required this.settingsPos,
    this.animationPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final crackPaint = Paint()
      ..color = EtoleColors.cream.withValues(alpha: 0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Fracture lines radiating from center to the four shard positions
    _drawFracture(canvas, center, brianPos, crackPaint);
    _drawFracture(canvas, center, networkPos, crackPaint);
    _drawFracture(canvas, center, docsPos, crackPaint);
    _drawFracture(canvas, center, settingsPos, crackPaint);

    // Cross crack lines connecting neighbor shards
    _drawFracture(canvas, brianPos, networkPos, crackPaint);
    _drawFracture(canvas, brianPos, docsPos, crackPaint);
    _drawFracture(canvas, settingsPos, networkPos, crackPaint);
    _drawFracture(canvas, settingsPos, docsPos, crackPaint);

    // Subtle center energy node
    final nodePaint = Paint()
      ..color = EtoleColors.cyan.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, 4, nodePaint);
  }

  void _drawFracture(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    // Slight jagged fracture deviation
    final mid = Offset(
      (p1.dx + p2.dx) / 2 + (p1.dy - p2.dy) * 0.04,
      (p1.dy + p2.dy) / 2 + (p2.dx - p1.dx) * 0.04,
    );

    path.lineTo(mid.dx, mid.dy);
    path.lineTo(p2.dx, p2.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CrackLinesPainter oldDelegate) {
    return oldDelegate.brianPos != brianPos ||
        oldDelegate.networkPos != networkPos ||
        oldDelegate.docsPos != docsPos ||
        oldDelegate.settingsPos != settingsPos ||
        oldDelegate.animationPhase != animationPhase;
  }
}
