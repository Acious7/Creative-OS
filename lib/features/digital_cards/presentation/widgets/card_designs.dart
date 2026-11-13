import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/vcard_builder.dart';

enum QrDisplayMode { vCard, whatsApp, reelUrl, customUrl }

/// Helper color palette for the 5 tribal designs
class TribalCardTheme {
  final Color bg;
  final Color surface;
  final Color accent;
  final Color patternColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const TribalCardTheme({
    required this.bg,
    required this.surface,
    required this.accent,
    required this.patternColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  static TribalCardTheme forStyle(String style, Color? customAccent) {
    switch (style.toLowerCase()) {
      case 'savannah':
        return TribalCardTheme(
          bg: const Color(0xFF14110B),
          surface: const Color(0xFF1E1A12),
          accent: customAccent ?? const Color(0xFFE59819),
          patternColor: const Color(0xFFE59819).withValues(alpha: 0.16),
          textPrimary: const Color(0xFFFFF3D6),
          textSecondary: const Color(0xFFC7B28B),
          border: const Color(0xFF382F1D),
        );
      case 'ochre_line':
      case 'ochre':
        return TribalCardTheme(
          bg: const Color(0xFF140D09),
          surface: const Color(0xFF1F140E),
          accent: customAccent ?? const Color(0xFFE0531C),
          patternColor: const Color(0xFFE0531C).withValues(alpha: 0.18),
          textPrimary: const Color(0xFFFDE8E0),
          textSecondary: const Color(0xFFBFA094),
          border: const Color(0xFF3D251A),
        );
      case 'night_market':
        return TribalCardTheme(
          bg: const Color(0xFF070809),
          surface: const Color(0xFF101214),
          accent: customAccent ?? EtoleColors.gold,
          patternColor: (customAccent ?? EtoleColors.gold).withValues(
            alpha: 0.24,
          ),
          textPrimary: EtoleColors.cream,
          textSecondary: const Color(0xFF9CA3AF),
          border: const Color(0xFF22272B),
        );
      case 'clay':
        return TribalCardTheme(
          bg: const Color(0xFF12100E),
          surface: const Color(0xFF1C1815),
          accent: customAccent ?? const Color(0xFFB45309),
          patternColor: const Color(0xFFB45309).withValues(alpha: 0.18),
          textPrimary: const Color(0xFFF5F2EB),
          textSecondary: const Color(0xFFA8A29E),
          border: const Color(0xFF38312B),
        );
      case 'ember':
      default:
        return TribalCardTheme(
          bg: const Color(0xFF0A0C0D),
          surface: const Color(0xFF141719),
          accent: customAccent ?? EtoleColors.cyan,
          patternColor: (customAccent ?? EtoleColors.cyan).withValues(
            alpha: 0.18,
          ),
          textPrimary: EtoleColors.cream,
          textSecondary: EtoleColors.muted,
          border: const Color(0xFF262D30),
        );
    }
  }
}

// ==============================================================================
// BUSINESS CARD FRONT VIEW (5 East African Tribal Designs)
// ==============================================================================

class BusinessCardFrontView extends StatelessWidget {
  final BusinessCard card;
  final Brand brand;
  final Color? customAccentOverride;

  const BusinessCardFrontView({
    super.key,
    required this.card,
    required this.brand,
    this.customAccentOverride,
  });

  @override
  Widget build(BuildContext context) {
    final style = card.designStyle;
    final customAccent =
        customAccentOverride ??
        (card.accentColorOverride != null
            ? _parseColor(card.accentColorOverride!)
            : null);
    final theme = TribalCardTheme.forStyle(style, customAccent);

    // Guaranteed phone number
    final phone = card.primaryPhone?.isNotEmpty == true
        ? card.primaryPhone!
        : '+254 718 013 579';

    return Container(
      width: double.infinity,
      height: 224,
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg - 1.5),
        child: Stack(
          children: [
            // Tribal Vector Pattern Background
            Positioned.fill(
              child: CustomPaint(
                painter: _getTribalPainter(
                  style,
                  theme.patternColor,
                  theme.accent,
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Brand / Studio Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: theme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (card.companyName ?? 'ETOLE STUDIO').toUpperCase(),
                            style: TextStyle(
                              fontFamily: EtoleTypography.displayFontFamily,
                              color: theme.textSecondary,
                              fontSize: 16,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: theme.border, width: 0.8),
                        ),
                        child: Text(
                          card.address ?? 'NAIROBI, KE',
                          style: TextStyle(
                            fontFamily: EtoleTypography.bodyFontFamily,
                            color: theme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Middle: Name & Title & Monogram
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.personName.toUpperCase(),
                              style: TextStyle(
                                fontFamily: EtoleTypography.displayFontFamily,
                                color: theme.textPrimary,
                                fontSize: 34,
                                letterSpacing: 1.5,
                                height: 0.95,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (card.personRole ??
                                      'CREATIVE DIRECTOR / CINEMATOGRAPHER')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontFamily: EtoleTypography.bodyFontFamily,
                                color: theme.accent,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            if (card.tagline != null &&
                                card.tagline!.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                card.tagline!,
                                style: TextStyle(
                                  fontFamily: EtoleTypography.bodyFontFamily,
                                  color: theme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Monogram Seal
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.accent.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          color: theme.surface.withValues(alpha: 0.8),
                        ),
                        child: Center(
                          child: Text(
                            'BE',
                            style: TextStyle(
                              fontFamily: EtoleTypography.displayFontFamily,
                              color: theme.textPrimary,
                              fontSize: 18,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Contact Strip
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: theme.border.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildContactBadge(Icons.phone_outlined, phone, theme),
                        if (card.email != null)
                          _buildContactBadge(
                            Icons.alternate_email_rounded,
                            card.email!,
                            theme,
                          ),
                        Text(
                          (card.website ?? 'brianetole.com')
                              .replaceAll('https://', '')
                              .replaceAll('http://', ''),
                          style: TextStyle(
                            fontFamily: EtoleTypography.bodyFontFamily,
                            color: theme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactBadge(IconData icon, String text, TribalCardTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: theme.accent),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: EtoleTypography.bodyFontFamily,
            color: theme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ==============================================================================
// BUSINESS CARD BACK VIEW (5 East African Tribal Designs with QR & NFC)
// ==============================================================================

class BusinessCardBackView extends StatelessWidget {
  final BusinessCard card;
  final Brand brand;
  final QrDisplayMode mode;
  final Color? customAccentOverride;

  const BusinessCardBackView({
    super.key,
    required this.card,
    required this.brand,
    required this.mode,
    this.customAccentOverride,
  });

  @override
  Widget build(BuildContext context) {
    final style = card.designStyle;
    final customAccent =
        customAccentOverride ??
        (card.accentColorOverride != null
            ? _parseColor(card.accentColorOverride!)
            : null);
    final theme = TribalCardTheme.forStyle(style, customAccent);

    final qrData = _getQrData();
    final qrLabel = _getQrLabel();
    final phone = card.primaryPhone?.isNotEmpty == true
        ? card.primaryPhone!
        : '+254 718 013 579';

    return Container(
      width: double.infinity,
      height: 224,
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg - 1.5),
        child: Stack(
          children: [
            // Tribal Vector Pattern Background
            Positioned.fill(
              child: CustomPaint(
                painter: _getTribalPainter(
                  style,
                  theme.patternColor,
                  theme.accent,
                  isBack: true,
                ),
              ),
            ),

            // Back Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Left Side: Identity, Contact details & Links
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.personName.toUpperCase(),
                          style: TextStyle(
                            fontFamily: EtoleTypography.displayFontFamily,
                            color: theme.textPrimary,
                            fontSize: 22,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          (card.personRole ?? 'CREATIVE DIRECTOR')
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: EtoleTypography.bodyFontFamily,
                            color: theme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Prominent Phone Number
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              color: theme.accent,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              phone,
                              style: TextStyle(
                                fontFamily: EtoleTypography.bodyFontFamily,
                                color: theme.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Row(
                          children: [
                            Icon(
                              Icons.alternate_email_rounded,
                              color: theme.accent,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              card.email ?? 'brian@etole.com',
                              style: TextStyle(
                                fontFamily: EtoleTypography.bodyFontFamily,
                                color: theme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Website / Portfolio
                        Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              color: theme.accent,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              (card.website ?? 'brianetole.com').replaceAll(
                                'https://',
                                '',
                              ),
                              style: TextStyle(
                                fontFamily: EtoleTypography.bodyFontFamily,
                                color: theme.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // NFC Wave Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: theme.border, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.contactless_rounded,
                                color: theme.accent,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'NFC TAP ENABLED',
                                style: TextStyle(
                                  fontFamily: EtoleTypography.bodyFontFamily,
                                  color: theme.textPrimary,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right Side: Crisp QR Code Box
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EAD9), // Light cream background for instant camera scanning
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 108,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0A0C0D),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0A0C0D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: theme.border, width: 0.8),
                          ),
                          child: Text(
                            qrLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: EtoleTypography.bodyFontFamily,
                              color: theme.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 8.5,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getQrData() {
    switch (mode) {
      case QrDisplayMode.vCard:
        return VCardBuilder.buildVCard(card).vCardString;
      case QrDisplayMode.whatsApp:
        final phone =
            (card.whatsappNumber ?? card.primaryPhone ?? '254718013579')
                .replaceAll(RegExp(r'\D'), '');
        final msg = Uri.encodeComponent(
          card.whatsappTemplate ?? 'Hi Brian, nice meeting you!',
        );
        return 'https://wa.me/$phone?text=$msg';
      case QrDisplayMode.reelUrl:
        return card.showreelUrl ??
            card.portfolioUrl ??
            card.website ??
            'https://brianetole.com';
      case QrDisplayMode.customUrl:
        return card.customQrUrl ??
            card.bookingUrl ??
            card.website ??
            'https://brianetole.com';
    }
  }

  String _getQrLabel() {
    switch (mode) {
      case QrDisplayMode.vCard:
        return 'SCAN FOR VCARD';
      case QrDisplayMode.whatsApp:
        return 'CHAT ON WHATSAPP';
      case QrDisplayMode.reelUrl:
        return 'WATCH SHOWREEL';
      case QrDisplayMode.customUrl:
        return card.customQrLabel?.toUpperCase() ?? 'OPEN LINK';
    }
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ==============================================================================
// 5 EAST AFRICAN TRIBAL VECTOR CUSTOM PAINTERS
// ==============================================================================

CustomPainter _getTribalPainter(
  String style,
  Color color,
  Color accent, {
  bool isBack = false,
}) {
  switch (style.toLowerCase()) {
    case 'savannah':
      return SavannahTribalPainter(
        color: color,
        accent: accent,
        isBack: isBack,
      );
    case 'ochre_line':
    case 'ochre':
      return OchreLineTribalPainter(
        color: color,
        accent: accent,
        isBack: isBack,
      );
    case 'night_market':
      return NightMarketTribalPainter(
        color: color,
        accent: accent,
        isBack: isBack,
      );
    case 'clay':
      return ClayTribalPainter(color: color, accent: accent, isBack: isBack);
    case 'ember':
    default:
      return EmberTribalPainter(color: color, accent: accent, isBack: isBack);
  }
}

/// 1. EMBER: African geometric textile weave line grid & ember chevron nodes
class EmberTribalPainter extends CustomPainter {
  final Color color;
  final Color accent;
  final bool isBack;

  EmberTribalPainter({
    required this.color,
    required this.accent,
    this.isBack = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // Diagonal woven textile line grid across top-right quadrant
    const spacing = 18.0;
    for (double i = 0; i < size.width * 1.5; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }

    // Bold African chevron accent glyphs in corner
    final chevronPath = Path();
    final startX = size.width - 48;
    const startY = 16.0;
    chevronPath.moveTo(startX, startY);
    chevronPath.lineTo(startX + 14, startY + 12);
    chevronPath.lineTo(startX, startY + 24);

    chevronPath.moveTo(startX + 12, startY);
    chevronPath.lineTo(startX + 26, startY + 12);
    chevronPath.lineTo(startX + 12, startY + 24);
    canvas.drawPath(chevronPath, accentPaint);

    // Subtle ember dot matrix nodes along the bottom
    final dotPaint = Paint()
      ..color = accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    for (int col = 0; col < 12; col++) {
      canvas.drawCircle(
        Offset(24.0 + col * 14.0, size.height - 8),
        1.2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. SAVANNAH: Acacia geometric thorn lattice & sunburst rays
class SavannahTribalPainter extends CustomPainter {
  final Color color;
  final Color accent;
  final bool isBack;

  SavannahTribalPainter({
    required this.color,
    required this.accent,
    this.isBack = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.30)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Radiating Golden Sunburst Rays from bottom-left
    const rayCount = 14;
    final origin = Offset(-20, size.height + 20);
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * (3.14159 / 2);
      final dest = Offset(
        origin.dx + 400 * cos(angle),
        origin.dy - 400 * sin(angle),
      );
      canvas.drawLine(origin, dest, paint);
    }

    // Vertical rhythmic reed columns on right edge
    for (double x = size.width - 60; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
      for (double y = 14; y < size.height; y += 24) {
        canvas.drawCircle(
          Offset(x, y),
          1.5,
          Paint()
            ..color = accent.withValues(alpha: 0.4)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. OCHRE LINE: Minimal razor-sharp lines, triangles & terracotta zig-zags
class OchreLineTribalPainter extends CustomPainter {
  final Color color;
  final Color accent;
  final bool isBack;

  OchreLineTribalPainter({
    required this.color,
    required this.accent,
    this.isBack = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.40)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Horizontal stepped chevron band across the upper third
    final path = Path();
    const yBase = 32.0;
    const stepW = 16.0;
    const stepH = 10.0;
    path.moveTo(0, yBase);
    for (double x = 0; x < size.width; x += stepW * 2) {
      path.lineTo(x + stepW, yBase - stepH);
      path.lineTo(x + stepW * 2, yBase);
    }
    canvas.drawPath(path, accentPaint);

    // Parallel fine echo lines
    final echoPath = Path();
    const echoBase = 40.0;
    echoPath.moveTo(0, echoBase);
    for (double x = 0; x < size.width; x += stepW * 2) {
      echoPath.lineTo(x + stepW, echoBase - stepH);
      echoPath.lineTo(x + stepW * 2, echoBase);
    }
    canvas.drawPath(echoPath, paint);

    // Triangles on the right
    final triPaint = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final triPath = Path();
    final rx = size.width - 32;
    triPath.moveTo(rx, size.height - 40);
    triPath.lineTo(rx + 20, size.height - 40);
    triPath.lineTo(rx + 10, size.height - 20);
    triPath.close();
    canvas.drawPath(triPath, triPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. NIGHT MARKET: Obsidian dark, pulsing geometric marketplace lattice
class NightMarketTribalPainter extends CustomPainter {
  final Color color;
  final Color accent;
  final bool isBack;

  NightMarketTribalPainter({
    required this.color,
    required this.accent,
    this.isBack = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // Intricate interconnected diamond lattice
    const dSize = 24.0;
    for (double y = 0; y < size.height + dSize; y += dSize) {
      for (double x = size.width * 0.45; x < size.width + dSize; x += dSize) {
        final path = Path()
          ..moveTo(x, y - dSize / 2)
          ..lineTo(x + dSize / 2, y)
          ..lineTo(x, y + dSize / 2)
          ..lineTo(x - dSize / 2, y)
          ..close();
        canvas.drawPath(path, linePaint);
      }
    }

    // Glowing corner geometric node
    final cornerDiamond = Path()
      ..moveTo(size.width - 24, 16)
      ..lineTo(size.width - 12, 28)
      ..lineTo(size.width - 24, 40)
      ..lineTo(size.width - 36, 28)
      ..close();
    canvas.drawPath(cornerDiamond, accentPaint);

    final centerDotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width - 24, 28), 2.5, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. CLAY: Terracotta earth with stamped tribal glyphs and stepped pyramids
class ClayTribalPainter extends CustomPainter {
  final Color color;
  final Color accent;
  final bool isBack;

  ClayTribalPainter({
    required this.color,
    required this.accent,
    this.isBack = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final glyphPaint = Paint()
      ..color = accent.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Stepped pyramid motif at top-right
    final cx = size.width - 32;
    const cy = 28.0;
    for (int step = 0; step < 4; step++) {
      final halfW = (step + 1) * 8.0;
      final y = cy + (step * 7.0);
      canvas.drawLine(Offset(cx - halfW, y), Offset(cx + halfW, y), glyphPaint);
    }

    // Organic terracotta ripple lines along left border
    for (double y = 20; y < size.height - 20; y += 14) {
      canvas.drawLine(Offset(10, y), Offset(22, y), strokePaint);
      canvas.drawLine(Offset(22, y), Offset(28, y + 4), strokePaint);
    }

    // Center-bottom tribal stamped dots
    final dotPaint = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.4 + i * 16, size.height - 14),
        2.0,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
