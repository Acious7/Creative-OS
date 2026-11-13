import 'package:flutter/material.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../domain/hub_models.dart';

/// Custom clipper for each of the 4 window panes in the 2x2 grid.
/// Each pane has an ancient, handmade broken-glass character with
/// a unique chipped corner or bevel.
class WindowPaneClipper extends CustomClipper<Path> {
  final EtoleWorld world;

  const WindowPaneClipper({required this.world});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (world) {
      case EtoleWorld.production:
      case EtoleWorld.brian:
        // Top-Left Pane: Chipped top-left corner notch, subtle organic bevels
        path.moveTo(18, 0);
        path.lineTo(w - 6, 0);
        path.quadraticBezierTo(w, 0, w, 6);
        path.lineTo(w, h - 6);
        path.quadraticBezierTo(w, h, w - 6, h);
        path.lineTo(6, h);
        path.quadraticBezierTo(0, h, 0, h - 6);
        path.lineTo(0, 20);
        // Chipped angle facet at top-left
        path.lineTo(18, 0);
        path.close();
        break;

      case EtoleWorld.network:
        // Top-Right Pane: Chipped top-right corner notch
        path.moveTo(6, 0);
        path.lineTo(w - 22, 0);
        // Chipped angle facet at top-right
        path.lineTo(w, 16);
        path.lineTo(w, h - 6);
        path.quadraticBezierTo(w, h, w - 6, h);
        path.lineTo(6, h);
        path.quadraticBezierTo(0, h, 0, h - 6);
        path.lineTo(0, 6);
        path.quadraticBezierTo(0, 0, 6, 0);
        path.close();
        break;

      case EtoleWorld.docs:
        // Bottom-Left Pane: Chipped bottom-left corner notch
        path.moveTo(6, 0);
        path.lineTo(w - 6, 0);
        path.quadraticBezierTo(w, 0, w, 6);
        path.lineTo(w, h - 6);
        path.quadraticBezierTo(w, h, w - 6, h);
        path.lineTo(16, h);
        // Chipped angle facet at bottom-left
        path.lineTo(0, h - 18);
        path.lineTo(0, 6);
        path.quadraticBezierTo(0, 0, 6, 0);
        path.close();
        break;

      case EtoleWorld.meetings:
      case EtoleWorld.settings:
        // Bottom-Right Pane: Chipped bottom-right corner notch
        path.moveTo(6, 0);
        path.lineTo(w - 6, 0);
        path.quadraticBezierTo(w, 0, w, 6);
        path.lineTo(w, h - 22);
        // Chipped angle facet at bottom-right
        path.lineTo(w - 20, h);
        path.lineTo(6, h);
        path.quadraticBezierTo(0, h, 0, h - 6);
        path.lineTo(0, 6);
        path.quadraticBezierTo(0, 0, 6, 0);
        path.close();
        break;
    }

    return path;
  }

  @override
  bool shouldReclip(covariant WindowPaneClipper oldClipper) =>
      oldClipper.world != world;
}

/// Outlines the window pane with fine warm-cream and ember-orange glints,
/// and draws the handmade hairline fractures inside each pane.
class WindowPaneBorderPainter extends CustomPainter {
  final EtoleWorld world;
  final double glintIntensity; // 0.0 to 1.0
  final bool isPressed;
  final Color? accentColor;
  final Color? borderColor;

  WindowPaneBorderPainter({
    required this.world,
    this.glintIntensity = 0.5,
    this.isPressed = false,
    this.accentColor,
    this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = WindowPaneClipper(world: world);
    final path = clipper.getClip(size);

    final w = size.width;
    final h = size.height;

    final effectiveAccent = accentColor ?? EtoleColors.cyan;
    final effectiveBorder = borderColor ?? EtoleColors.cream;

    // 1. Subtle ember edge glow
    final glowPaint = Paint()
      ..color = effectiveAccent.withValues(
        alpha: isPressed ? 0.45 : 0.12 * glintIntensity,
      )
      ..strokeWidth = isPressed ? 3.5 : 2.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(path, glowPaint);

    // 2. Fine bright glint outline
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          effectiveBorder.withValues(
            alpha: (0.45 + glintIntensity * 0.45).clamp(0.0, 1.0),
          ),
          effectiveBorder.withValues(alpha: 0.15),
          effectiveAccent.withValues(
            alpha: (0.25 + glintIntensity * 0.55).clamp(0.0, 1.0),
          ),
          effectiveBorder.withValues(alpha: 0.3),
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = isPressed ? 1.6 : 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    // 3. Ancient handmade hairline cracks per pane
    final crackPaint = Paint()
      ..color = EtoleColors.cream.withValues(
        alpha: 0.16 + (glintIntensity * 0.14),
      )
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final crackPath = Path();

    switch (world) {
      case EtoleWorld.production:
      case EtoleWorld.brian:
        // Hairline fracture starting from the chipped top-left corner
        crackPath.moveTo(18, 0);
        crackPath.lineTo(34, 18);
        crackPath.lineTo(42, 36);
        // Branch
        crackPath.moveTo(34, 18);
        crackPath.lineTo(24, 32);
        break;

      case EtoleWorld.network:
        // Hairline fissure from the chipped top-right corner
        crackPath.moveTo(w - 22, 0);
        crackPath.lineTo(w - 38, 20);
        crackPath.lineTo(w - 52, 28);
        // Branch
        crackPath.moveTo(w - 38, 20);
        crackPath.lineTo(w - 32, 42);
        break;

      case EtoleWorld.docs:
        // Hairline crack from bottom-left chip
        crackPath.moveTo(16, h);
        crackPath.lineTo(28, h - 22);
        crackPath.lineTo(44, h - 34);
        // Branch
        crackPath.moveTo(28, h - 22);
        crackPath.lineTo(18, h - 38);
        break;

      case EtoleWorld.meetings:
      case EtoleWorld.settings:
        // Hairline curved crack from bottom-right chip
        crackPath.moveTo(w - 20, h);
        crackPath.lineTo(w - 34, h - 22);
        crackPath.lineTo(w - 48, h - 30);
        // Branch
        crackPath.moveTo(w - 34, h - 22);
        crackPath.lineTo(w - 30, h - 44);
        break;
    }

    canvas.drawPath(crackPath, crackPaint);
  }

  @override
  bool shouldRepaint(covariant WindowPaneBorderPainter oldDelegate) {
    return oldDelegate.world != world ||
        oldDelegate.glintIntensity != glintIntensity ||
        oldDelegate.isPressed != isPressed;
  }
}

/// Paints the subtle ambient drop shadow under each pane
class WindowPaneShadowPainter extends CustomPainter {
  final EtoleWorld world;

  WindowPaneShadowPainter({required this.world});

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = WindowPaneClipper(world: world);
    final path = clipper.getClip(size);

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.60), 16.0, false);
  }

  @override
  bool shouldRepaint(covariant WindowPaneShadowPainter oldDelegate) =>
      oldDelegate.world != world;
}
