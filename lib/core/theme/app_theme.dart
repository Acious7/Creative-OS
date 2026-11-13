import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_design_tokens.dart';

class AppTheme {
  static ThemeData getDarkTheme(Color brandAccent, {bool isOled = false}) {
    final bg = isOled ? AppDesignTokens.oledBg : AppDesignTokens.darkBg;
    final surfaceLowest = isOled
        ? AppDesignTokens.oledSurfaceLowest
        : AppDesignTokens.darkSurfaceLowest;
    final surfaceLow = isOled
        ? AppDesignTokens.oledSurfaceLow
        : AppDesignTokens.darkSurfaceLow;
    final surface = isOled
        ? AppDesignTokens.oledSurface
        : AppDesignTokens.darkSurface;
    final surfaceHigh = isOled
        ? AppDesignTokens.oledSurfaceHigh
        : AppDesignTokens.darkSurfaceHigh;
    final surfaceHighest = isOled
        ? AppDesignTokens.oledSurfaceHighest
        : AppDesignTokens.darkSurfaceHighest;
    final border = isOled
        ? AppDesignTokens.oledBorder
        : AppDesignTokens.darkBorder;
    final borderSubtle = isOled
        ? AppDesignTokens.oledBorderSubtle
        : AppDesignTokens.darkBorderSubtle;

    final colorScheme = ColorScheme.dark(
      primary: brandAccent,
      onPrimary: Colors.white,
      primaryContainer: brandAccent.withValues(alpha: 0.22),
      onPrimaryContainer: Colors.white,
      secondary: AppDesignTokens.brandAmber,
      onSecondary: Colors.black,
      secondaryContainer: AppDesignTokens.brandAmber.withValues(alpha: 0.18),
      onSecondaryContainer: Colors.white,
      tertiary: AppDesignTokens.brandEmerald,
      onTertiary: Colors.white,
      surface: surface,
      onSurface: AppDesignTokens.darkTextPrimary,
      surfaceContainerLowest: surfaceLowest,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      outline: border,
      outlineVariant: borderSubtle,
      error: AppDesignTokens.statusOverdue,
      onError: Colors.white,
    );

    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          displaySmall: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(
          bodyColor: AppDesignTokens.darkTextPrimary,
          displayColor: AppDesignTokens.darkTextPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: AppDesignTokens.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppDesignTokens.darkTextPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          side: BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesignTokens.darkTextPrimary,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandAccent,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(color: brandAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: AppDesignTokens.statusOverdue,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppDesignTokens.darkTextSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppDesignTokens.darkTextMuted,
          fontSize: 14,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLow,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppDesignTokens.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLowest,
        selectedItemColor: brandAccent,
        unselectedItemColor: AppDesignTokens.darkTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDesignTokens.radiusXl),
          ),
        ),
      ),
    );
  }

  static ThemeData getLightTheme(Color brandAccent) {
    final colorScheme = ColorScheme.light(
      primary: brandAccent,
      onPrimary: Colors.white,
      primaryContainer: brandAccent.withValues(alpha: 0.12),
      onPrimaryContainer: brandAccent,
      secondary: AppDesignTokens.brandAmber,
      onSecondary: Colors.black,
      secondaryContainer: AppDesignTokens.brandAmber.withValues(alpha: 0.15),
      onSecondaryContainer: Colors.black,
      tertiary: AppDesignTokens.brandEmerald,
      onTertiary: Colors.white,
      surface: AppDesignTokens.lightSurface,
      onSurface: AppDesignTokens.lightTextPrimary,
      surfaceContainerLowest: AppDesignTokens.lightSurfaceLowest,
      surfaceContainerLow: AppDesignTokens.lightSurfaceLow,
      surfaceContainer: AppDesignTokens.lightSurface,
      surfaceContainerHigh: AppDesignTokens.lightSurfaceHigh,
      surfaceContainerHighest: AppDesignTokens.lightSurfaceHighest,
      outline: AppDesignTokens.lightBorder,
      outlineVariant: AppDesignTokens.lightBorderSubtle,
      error: AppDesignTokens.statusOverdue,
      onError: Colors.white,
    );

    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme)
        .copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          displaySmall: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(
          bodyColor: AppDesignTokens.lightTextPrimary,
          displayColor: AppDesignTokens.lightTextPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppDesignTokens.lightBg,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppDesignTokens.lightBg,
        foregroundColor: AppDesignTokens.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppDesignTokens.lightTextPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppDesignTokens.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          side: const BorderSide(color: AppDesignTokens.lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesignTokens.lightTextPrimary,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: const BorderSide(
            color: AppDesignTokens.lightBorder,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandAccent,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDesignTokens.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: AppDesignTokens.lightBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: AppDesignTokens.lightBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(color: brandAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: AppDesignTokens.statusOverdue,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppDesignTokens.lightTextSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppDesignTokens.lightTextMuted,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppDesignTokens.lightBorderSubtle,
        thickness: 1,
        space: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppDesignTokens.lightSurfaceLow,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppDesignTokens.lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
          side: const BorderSide(color: AppDesignTokens.lightBorder, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppDesignTokens.lightSurface,
        selectedItemColor: brandAccent,
        unselectedItemColor: AppDesignTokens.lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDesignTokens.lightSurface,
        modalBackgroundColor: AppDesignTokens.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDesignTokens.radiusXl),
          ),
        ),
      ),
    );
  }
}
