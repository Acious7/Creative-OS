import 'package:flutter/material.dart';

/// Etole Design System — Master Color Palette
/// Inspired by the official Brian Etole VisualStoryteller Quotation identity:
/// - Hero Accent: Cyan / Cerulean Blue (#38B6DB) from the Budget Breakdown card
/// - Secondary Accent: Warm Golden Amber (#F5A623) from the Total badge
/// - Studio Color Quadrant: Forest Green (#007A3D), Crimson Red (#D32F2F), Slate Blue (#4A90E2)
/// - Light Canvas: Clean gallery off-white (#FBFBF9) with sharp charcoal text (#111827)
/// - Dark Canvas: Deep studio obsidian (#0D0F14) with luminous cyan & gold accents
class EtoleColors {
  // --- Master Palette Identifiers ---
  static const Color cyan = Color(
    0xFF38B6DB,
  ); // Primary Action & Budget Card Hero
  static const Color cyanDark = Color(0xFF1B8EA9);
  static const Color cyanLight = Color(0xFFE6F7FC);
  static const Color cyanGlow = Color(0x4D38B6DB);
  static const Color cyanSubtle = Color(0x1F38B6DB);

  static const Color gold = Color(
    0xFFF5A623,
  ); // Signature Total Badge Warm Gold
  static const Color goldLight = Color(0xFFFEF5E7);
  static const Color goldGlow = Color(0x4DF5A623);
  static const Color goldSubtle = Color(0x1FF5A623);

  static const Color green = Color(
    0xFF007A3D,
  ); // Forest Kenyan Green ('e' in etole)
  static const Color emerald = green;
  static const Color greenLight = Color(0xFFE6F4EA);
  static const Color red = Color(0xFFD32F2F); // Crimson Red ('l' in etole)
  static const Color redLight = Color(0xFFFCE8E6);
  static const Color slate = Color(0xFF4A90E2); // Slate Blue ('o' in etole)
  static const Color slateLight = Color(0xFFEBF3FC);

  // --- Abstract Bauhaus & Geometric Palette from Quotation Document ---
  static const Color oliveSage = Color(
    0xFFC5D6C6,
  ); // Soft sage quadrant with dot matrix
  static const Color oliveSageDots = Color(0xFF6B7F6D); // Dot matrix ink
  static const Color maasaiRed = Color(0xFFC62828); // Striped Maasai flag red
  static const Color maasaiBlack = Color(
    0xFF111827,
  ); // Striped Maasai flag black

  // --- Brand Aliases ---
  static const Color brandCyan = cyan;
  static const Color brandAmber = gold;
  static const Color brandEmerald = green;
  static const Color brandRed = red;
  static const Color brandSlate = slate;
  static const Color brandCharcoal = Color(0xFF111827);
  static const Color brandTotal = gold;
  static const Color brandHero = cyan;

  // --- Primary Hero Accent (Mapped to Studio Cyan) ---
  static const Color ember = cyan;
  static const Color emberGlow = cyanGlow;
  static const Color emberSubtle = cyanSubtle;

  // --- Dark Mode Surfaces ---
  static const Color darkBase = Color(0xFF0D0F14);
  static const Color oledBase = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF151922);
  static const Color darkSurfaceElevated = Color(0xFF1C2230);

  // Synonyms & Semantic Aliases
  static const Color obsidian = darkBase;
  static const Color pitchBlack = oledBase;
  static const Color charcoal = Color(0xFF111827);
  static const Color warmWhite = lightBase;

  // --- Dark Mode Typography ---
  static const Color cream = Color(0xFFF8FAFC);
  static const Color muted = Color(0xFF94A3B8);
  static const Color subtle = Color(0xFF64748B);
  static const Color creamSecondary = muted;
  static const Color creamMuted = muted;

  // --- Hairlines & Dividers ---
  static const Color darkHairline = Color(0x1AF8FAFC); // ~10% white
  static const Color darkHairlineFaint = Color(0x0DF8FAFC); // ~5% white

  // --- Glass Effects ---
  static const Color glassBackground = Color(0x240D0F14);
  static const Color glassHighlight = Color(0x3DF8FAFC);
  static const Color glassBorder = Color(0x1FF8FAFC);

  // --- Light Mode Surfaces & Text (Matches Gallery Quotation Canvas #FAF7F2) ---
  static const Color lightBase = Color(0xFFFAF7F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF3EFE7);
  static const Color lightBorder = Color(0xFFE8E4DC);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF6B7280);
  static const Color lightHairline = Color(0x14111827);
  static const Color lightGlassBackground = Color(0x66FFFFFF);
  static const Color lightGlassHighlight = Color(0x99FFFFFF);

  // --- Semantic Document Stamps & Statuses ---
  static const Color stampPaid = green; // Forest Green verified ink
  static const Color stampDraft = gold; // Warm Golden Amber
  static const Color stampSent = slate; // Slate Blue
  static const Color stampOverdue = red; // Crimson Red
  static const Color stampCancelled = Color(0xFF4B5563);

  // Context-aware color accessors
  static Color bg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBase
        : lightBase;
  }

  static Color text(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cream
        : lightTextPrimary;
  }

  static Color textMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? muted
        : lightTextMuted;
  }

  static Color hairline(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkHairline
        : lightHairline;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }
}
