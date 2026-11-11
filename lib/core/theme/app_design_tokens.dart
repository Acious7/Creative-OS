import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Etole Design Tokens (Material 3 Expressive System)
/// Palette extracted from Brian Etole VisualStoryteller Quotation Document
class AppDesignTokens {
  // --- Corner Radii Scale ---
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusS = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusM = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusHero = 28.0; // Signature Budget Breakdown top-left radius
  static const double radiusFull = 999.0;

  static BorderRadius get borderXs => BorderRadius.circular(radiusXs);
  static BorderRadius get borderSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderFull => BorderRadius.circular(radiusFull);

  // --- Spacing Scale ---
  static const double spaceXxs = 2.0;
  static const double spaceXs = 4.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double spaceSm = 8.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double spaceMd = 12.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double spaceLg = 16.0;
  static const double space16 = 16.0;
  static const double spaceXl = 20.0;
  static const double space20 = 20.0;
  static const double spaceXxl = 24.0;
  static const double space24 = 24.0;
  static const double spaceXxxl = 32.0;
  static const double space32 = 32.0;

  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;

  // --- Brand Studio Palette (From Official Quotation Document) ---
  static const Color etoleCyan = Color(0xFF38B6DB);       // Primary Cyan / Cerulean Hero
  static const Color etoleGold = Color(0xFFF5A623);       // Signature Total Badge Warm Gold
  static const Color etoleGreen = Color(0xFF007A3D);      // Forest Kenyan Green
  static const Color etoleRed = Color(0xFFD32F2F);        // Crimson Red
  static const Color etoleSlate = Color(0xFF4A90E2);      // Slate Blue
  static const Color etoleCharcoal = Color(0xFF111827);   // Rich Black Ink

  // Aliases
  static const Color etoleOrange = etoleCyan;
  static const Color etoleAccent = etoleGold;
  static const Color brandCyan = etoleCyan;
  static const Color brandAmber = etoleGold;
  static const Color brandEmerald = etoleGreen;
  static const Color brandRed = etoleRed;
  static const Color brandSlate = etoleSlate;
  static const Color brandCharcoal = etoleCharcoal;
  static const Color brandHero = etoleCyan;
  static const Color brandTotal = etoleGold;

  // --- Semantic Status Colors ---
  static const Color statusDraft = Color(0xFF6B7280);       // Muted Stone
  static const Color statusSent = etoleSlate;               // Slate Blue
  static const Color statusAccepted = etoleGreen;           // Forest Green
  static const Color statusActive = etoleCyan;              // Cerulean Cyan
  static const Color statusDeclined = etoleRed;             // Crimson Red
  static const Color statusPaid = etoleGreen;               // Forest Green
  static const Color statusPartPaid = etoleGold;            // Golden Amber
  static const Color statusOverdue = etoleRed;              // Crimson Red
  static const Color statusCancelled = Color(0xFF4B5563);
  static const Color statusSigned = etoleGreen;
  static const Color statusUnderReview = etoleGold;
  static const Color statusWarning = etoleGold;
  static const Color statusError = etoleRed;
  static const Color statusDanger = etoleRed;
  static const Color statusSuccess = etoleGreen;

  // --- Dark Neutral Palette ---
  static const Color darkBg = Color(0xFF0D0F14);
  static const Color darkSurfaceLowest = Color(0xFF11141A);
  static const Color darkSurfaceLow = Color(0xFF161A22);
  static const Color darkSurface = Color(0xFF1C2230);
  static const Color darkSurfaceHigh = Color(0xFF242C3E);
  static const Color darkSurfaceHighest = Color(0xFF2E374C);
  static const Color darkBorder = Color(0xFF2A3447);
  static const Color darkBorderSubtle = Color(0xFF1F2633);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // --- OLED Neutral Palette (Pure Pitch Black #000000 Base) ---
  static const Color oledBg = Color(0xFF000000);
  static const Color oledSurfaceLowest = Color(0xFF000000);
  static const Color oledSurfaceLow = Color(0xFF08090C);
  static const Color oledSurface = Color(0xFF101217);
  static const Color oledSurfaceHigh = Color(0xFF181B22);
  static const Color oledSurfaceHighest = Color(0xFF222630);
  static const Color oledBorder = Color(0xFF282D3B);
  static const Color oledBorderSubtle = Color(0xFF1C202B);

  // --- Light Neutral Palette (Matches Gallery Quotation Canvas #FAF7F2) ---
  static const Color lightBg = Color(0xFFFAF7F2);
  static const Color lightSurfaceLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceLow = Color(0xFFF7F4EE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFF3EFE7);
  static const Color lightSurfaceHighest = Color(0xFFEAE5DA);
  static const Color lightBorder = Color(0xFFE8E4DC);
  static const Color lightBorderSubtle = Color(0xFFF2EEE6);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF8C95A3);

  // --- Tabular Typography Font Features ---
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static TextStyle tabular(TextStyle? style) {
    final s = style ?? const TextStyle();
    return s.copyWith(
      fontFeatures: [
        ...?s.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
  }

  static TextStyle tabularStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: tabularFigures,
    );
  }
}
