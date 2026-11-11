import 'package:pdf/pdf.dart';

enum PdfTemplateType {
  classic,
  modern,
  minimal,
  bold;

  String get displayName {
    switch (this) {
      case PdfTemplateType.classic:
        return 'Classic';
      case PdfTemplateType.modern:
        return 'Modern';
      case PdfTemplateType.minimal:
        return 'Minimal';
      case PdfTemplateType.bold:
        return 'Bold';
    }
  }

  String get description {
    switch (this) {
      case PdfTemplateType.classic:
        return 'Formal serif corporate layout with elegant borders and structured tables';
      case PdfTemplateType.modern:
        return 'Sleek clean sans-serif layout with vibrant brand accent banners';
      case PdfTemplateType.minimal:
        return 'Contemporary Swiss style with generous white space and hairline dividers';
      case PdfTemplateType.bold:
        return 'High-impact high-contrast design with punchy headers and solid color blocks';
    }
  }

  static PdfTemplateType fromString(String? name) {
    if (name == null) return PdfTemplateType.modern;
    return PdfTemplateType.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => PdfTemplateType.modern,
    );
  }
}

class PdfColorPalette {
  final PdfColor primary;
  final PdfColor secondary;
  final PdfColor surface;
  final PdfColor textPrimary;
  final PdfColor textSecondary;
  final PdfColor border;
  final PdfColor lightAccent;

  PdfColorPalette({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.lightAccent,
  });

  factory PdfColorPalette.fromHex(String hexColor) {
    final cleanHex = hexColor.replaceAll('#', '');
    int colorInt = 0xFF38B6DB; // Default Etole Cyan (#38B6DB)
    if (cleanHex.length == 6) {
      colorInt = int.parse('FF$cleanHex', radix: 16);
    } else if (cleanHex.length == 8) {
      colorInt = int.parse(cleanHex, radix: 16);
    }

    final primary = PdfColor.fromInt(colorInt);
    
    // Compute complementary or lighter tint
    final r = (primary.red * 255).round();
    final g = (primary.green * 255).round();
    final b = (primary.blue * 255).round();
    
    // Light tint
    final lightAccent = PdfColor(
      r / 255 * 0.15 + 0.85,
      g / 255 * 0.15 + 0.85,
      b / 255 * 0.15 + 0.85,
    );

    return PdfColorPalette(
      primary: primary,
      secondary: const PdfColor.fromInt(0xFFF5A623), // Etole Gold (#F5A623)
      surface: const PdfColor.fromInt(0xFFFBFBF9),   // Gallery off-white
      textPrimary: const PdfColor.fromInt(0xFF111827), // Charcoal
      textSecondary: const PdfColor.fromInt(0xFF6B7280),
      border: const PdfColor.fromInt(0xFFE5E7EB),
      lightAccent: lightAccent,
    );
  }
}
