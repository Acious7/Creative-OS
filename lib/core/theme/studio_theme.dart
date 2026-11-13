import 'package:flutter/material.dart';

import '../design_system/etole_typography.dart';

/// Available Studio Theme IDs
enum StudioThemeId {
  tribalOrange, // Default, matches brianetole.com
  nightWarrior, // Dark charcoal, glowing orange accents
  savannahLight, // Warm cream, terracotta accents
  nairobiNeon, // Dark navy, cyan and magenta accents
}

/// Central Theme Definition for Etole Studio
/// Holding all colors, typography, glass tints, and ambient background parameters.
class StudioThemeData {
  final StudioThemeId id;
  final String name;
  final String subtitle;
  final bool isDark;

  // Accents
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color highlightAccent;

  // Background Canvas & Ambient Gradients
  final Color backgroundBase;
  final List<Color> backgroundGradient;
  final Color ambientKeyLight;
  final Color ambientFloorFill;

  // Tribal Background Sketch Tint
  final Color tribalSketchTint;
  final Color tribalGlowTint;

  // Glass Window Panes
  final List<Color> glassTintColors;
  final Color glassBorderColor;
  final Color glassCardColor;

  // Surfaces & Containers
  final Color surfaceColor;
  final Color surfaceCardColor;
  final Color surfaceElevatedColor;

  // Typography Colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;

  // Status & Utility
  final Color dividerColor;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;

  const StudioThemeData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.isDark,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.highlightAccent,
    required this.backgroundBase,
    required this.backgroundGradient,
    required this.ambientKeyLight,
    required this.ambientFloorFill,
    required this.tribalSketchTint,
    required this.tribalGlowTint,
    required this.glassTintColors,
    required this.glassBorderColor,
    required this.glassCardColor,
    required this.surfaceColor,
    required this.surfaceCardColor,
    required this.surfaceElevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.dividerColor,
    this.successColor = const Color(0xFF10B981),
    this.warningColor = const Color(0xFFF59E0B),
    this.errorColor = const Color(0xFFEF4444),
  });

  Color get accentColor => primaryAccent;
  Color get accent => primaryAccent;
  Color get scaffoldBgColor => backgroundBase;

  // --- 1. TRIBAL ORANGE (Default, matches brianetole.com) ---
  static const tribalOrange = StudioThemeData(
    id: StudioThemeId.tribalOrange,
    name: 'Tribal Orange',
    subtitle:
        'Matches brianetole.com with signature obsidian glass & sunset amber',
    isDark: true,
    primaryAccent: Color(0xFFFF6B00), // Sunset Tribal Orange
    secondaryAccent: Color(0xFFF5A623), // Golden Ochre
    highlightAccent: Color(0xFF38B6DB), // Cyan glint
    backgroundBase: Color(0xFF080B0F),
    backgroundGradient: [Color(0xFF0F141C), Color(0xFF080B0F)],
    ambientKeyLight: Color(0x18FF6B00),
    ambientFloorFill: Color(0x12F5A623),
    tribalSketchTint: Color(0xFFFF6B00),
    tribalGlowTint: Color(0xFFB4460F),
    glassTintColors: [Color(0x350A0C0D), Color(0x28FF6B00), Color(0x3812161D)],
    glassBorderColor: Color(0x55FF6B00),
    glassCardColor: Color(0x18FFFFFF),
    surfaceColor: Color(0xFF13171F),
    surfaceCardColor: Color(0xFF1A212B),
    surfaceElevatedColor: Color(0xFF222B38),
    textPrimary: Color(0xFFF3EAD9), // Warm Cream
    textSecondary: Color(0xFFD8CEBD),
    textMuted: Color(0xFF8E95A2),
    textOnAccent: Color(0xFF080B0F),
    dividerColor: Color(0x1FFFFFFF),
  );

  // --- 2. NIGHT WARRIOR ---
  static const nightWarrior = StudioThemeData(
    id: StudioThemeId.nightWarrior,
    name: 'Night Warrior',
    subtitle: 'Deep dark charcoal canvas with intense glowing orange accents',
    isDark: true,
    primaryAccent: Color(0xFFFF5722), // Fiery Orange
    secondaryAccent: Color(0xFFFF8A65), // Ember Glow
    highlightAccent: Color(0xFFFFB74D),
    backgroundBase: Color(0xFF101216),
    backgroundGradient: [Color(0xFF181B20), Color(0xFF101216)],
    ambientKeyLight: Color(0x22FF5722),
    ambientFloorFill: Color(0x16E64A19),
    tribalSketchTint: Color(0xFFFF5722),
    tribalGlowTint: Color(0xFFD84315),
    glassTintColors: [Color(0x3A12151A), Color(0x30FF5722), Color(0x40161A20)],
    glassBorderColor: Color(0x60FF5722),
    glassCardColor: Color(0x1AFFFFFF),
    surfaceColor: Color(0xFF1C2026),
    surfaceCardColor: Color(0xFF242A33),
    surfaceElevatedColor: Color(0xFF2D3540),
    textPrimary: Color(0xFFF8F9FA),
    textSecondary: Color(0xFFD2D7DF),
    textMuted: Color(0xFF828C9B),
    textOnAccent: Color(0xFF101216),
    dividerColor: Color(0x22FFFFFF),
  );

  // --- 3. SAVANNAH LIGHT ---
  static const savannahLight = StudioThemeData(
    id: StudioThemeId.savannahLight,
    name: 'Savannah Light',
    subtitle: 'Warm cream canvas with rich terracotta & earth clay accents',
    isDark: false,
    primaryAccent: Color(0xFFC85A32), // Terracotta
    secondaryAccent: Color(0xFFD97736), // Warm Ochre
    highlightAccent: Color(0xFF9C4120),
    backgroundBase: Color(0xFFF7F2EB),
    backgroundGradient: [Color(0xFFFDFBF7), Color(0xFFF2E8DC)],
    ambientKeyLight: Color(0x18C85A32),
    ambientFloorFill: Color(0x12D97736),
    tribalSketchTint: Color(0xFFC85A32),
    tribalGlowTint: Color(0x50D97736),
    glassTintColors: [Color(0x65FFFFFF), Color(0x28C85A32), Color(0x50F5EBE1)],
    glassBorderColor: Color(0x45C85A32),
    glassCardColor: Color(0x50FFFFFF),
    surfaceColor: Color(0xFFEFE6D8),
    surfaceCardColor: Color(0xFFE7DCCF),
    surfaceElevatedColor: Color(0xFFDFD2C2),
    textPrimary: Color(0xFF1E1713), // Dark ink
    textSecondary: Color(0xFF4C3D35),
    textMuted: Color(0xFF7A6B63),
    textOnAccent: Color(0xFFFFFFFF),
    dividerColor: Color(0x1F000000),
  );

  // --- 4. NAIROBI NEON ---
  static const nairobiNeon = StudioThemeData(
    id: StudioThemeId.nairobiNeon,
    name: 'Nairobi Neon',
    subtitle: 'Dark midnight navy with electric cyan & vivid magenta accents',
    isDark: true,
    primaryAccent: Color(0xFF00F0FF), // Electric Cyan
    secondaryAccent: Color(0xFFFF007F), // Neon Magenta
    highlightAccent: Color(0xFF7000FF), // Cyber Violet
    backgroundBase: Color(0xFF070B16),
    backgroundGradient: [Color(0xFF0D1429), Color(0xFF070B16)],
    ambientKeyLight: Color(0x2200F0FF),
    ambientFloorFill: Color(0x18FF007F),
    tribalSketchTint: Color(0xFF00F0FF),
    tribalGlowTint: Color(0x70FF007F),
    glassTintColors: [Color(0x350A1020), Color(0x2800F0FF), Color(0x25FF007F)],
    glassBorderColor: Color(0x6000F0FF),
    glassCardColor: Color(0x1800F0FF),
    surfaceColor: Color(0xFF111A33),
    surfaceCardColor: Color(0xFF172344),
    surfaceElevatedColor: Color(0xFF1F2F59),
    textPrimary: Color(0xFFF0F6FC),
    textSecondary: Color(0xFFC2D3E8),
    textMuted: Color(0xFF6B7E99),
    textOnAccent: Color(0xFF070B16),
    dividerColor: Color(0x2500F0FF),
  );

  static StudioThemeData fromId(StudioThemeId id) {
    switch (id) {
      case StudioThemeId.tribalOrange:
        return tribalOrange;
      case StudioThemeId.nightWarrior:
        return nightWarrior;
      case StudioThemeId.savannahLight:
        return savannahLight;
      case StudioThemeId.nairobiNeon:
        return nairobiNeon;
    }
  }

  /// Converts to standard Flutter ThemeData for MaterialApp
  ThemeData toMaterialThemeData() {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primaryAccent,
      onPrimary: textOnAccent,
      secondary: secondaryAccent,
      onSecondary: textOnAccent,
      surface: surfaceColor,
      onSurface: textPrimary,
      error: errorColor,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundBase,
      canvasColor: backgroundBase,
      cardColor: surfaceCardColor,
      dividerColor: dividerColor,
      fontFamily: EtoleTypography.bodyFontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBase,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryAccent;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAccent.withValues(alpha: 0.35);
          }
          return dividerColor;
        }),
      ),
    );
  }
}
