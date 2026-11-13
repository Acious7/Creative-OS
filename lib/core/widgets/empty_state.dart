import 'package:flutter/material.dart';

import '../design_system/etole_colors.dart';
import '../design_system/etole_components.dart';
import '../design_system/etole_typography.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyStateWidget({
    super.key,
    this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? EtoleColors.cream
        : EtoleColors.lightTextPrimary;
    final mutedTextColor = isDark
        ? EtoleColors.muted
        : EtoleColors.lightTextMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Elegant ink illustration (delicate aperture geometry, no big circles)
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _InkLineIllustrationPainter(
                  color: EtoleColors.cyan.withValues(alpha: 0.65),
                  accentColor: isDark
                      ? EtoleColors.cream.withValues(alpha: 0.25)
                      : Colors.black26,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: EtoleTypography.subheading(color: primaryTextColor)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: EtoleTypography.bodySmall(color: mutedTextColor)
                  .copyWith(height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              EtoleButton.outline(
                label: actionLabel!,
                icon: actionIcon ?? Icons.add_rounded,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InkLineIllustrationPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  _InkLineIllustrationPainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final hairlinePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final emberPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Subtle intersecting diamond & delicate aperture lines
    final path = Path();
    path.moveTo(center.dx, center.dy - radius * 0.85);
    path.lineTo(center.dx + radius * 0.85, center.dy);
    path.lineTo(center.dx, center.dy + radius * 0.85);
    path.lineTo(center.dx - radius * 0.85, center.dy);
    path.close();
    canvas.drawPath(path, hairlinePaint);

    // Dynamic intersecting golden tick lines
    canvas.drawLine(
      Offset(center.dx - radius * 0.45, center.dy),
      Offset(center.dx + radius * 0.45, center.dy),
      emberPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.45),
      Offset(center.dx, center.dy + radius * 0.45),
      emberPaint,
    );

    // Center focal point dot
    final dotPaint = Paint()
      ..color = EtoleColors.cyan
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _InkLineIllustrationPainter oldDelegate) =>
      false;
}
