import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'etole_colors.dart';

/// Etole Design System — Master Typography
/// Inspired by Brian Etole VisualStoryteller Editorial Identity:
/// - Display / Title font: Playfair Display (High-contrast, dramatic, elegant editorial serif matching "Quotation")
/// - Body font: Inter (Clean modern geometric sans-serif)
/// - Tabular numbers: FontFeature.tabularFigures() for all financial/metric figures
class EtoleTypography {
  static const String displayFontFamily = 'PlayfairDisplay';
  static const String bodyFontFamily = 'Inter';

  static TextStyle get h1 => pageTitle();
  static TextStyle get h2 => subheading();
  static TextStyle get h3 => sectionTitle();

  // --- Display Headings (Playfair Display Editorial Serif) ---
  static TextStyle heroDisplay({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 42.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
        color: color ?? EtoleColors.charcoal,
      );

  static TextStyle pageTitle({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 32.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: color ?? EtoleColors.charcoal,
      );

  static TextStyle sectionTitle({Color? color}) => GoogleFonts.inter(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.2,
        color: color ?? EtoleColors.charcoal,
      );

  static TextStyle subheading({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.2,
        color: color ?? EtoleColors.charcoal,
      );

  // --- Body Typography (Inter) ---
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: -0.1,
        color: color ?? EtoleColors.charcoal,
      );

  static TextStyle body({Color? color}) => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: -0.1,
        color: color ?? EtoleColors.charcoal,
      );

  static TextStyle bodyMuted({Color? color}) => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: -0.1,
        color: color ?? EtoleColors.lightTextMuted,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color ?? EtoleColors.lightTextMuted,
      );

  // --- Uppercase Wide Labels (Section tags, metadata, statuses) ---
  static TextStyle labelCaps({Color? color, double letterSpacing = 1.5}) => GoogleFonts.inter(
        fontSize: 11.0,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
        height: 1.2,
        color: color ?? EtoleColors.lightTextMuted,
      );

  static TextStyle buttonText({Color? color}) => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: color ?? Colors.white,
      );

  // --- Tabular Figures for Currency, Amounts, Counters ---
  static TextStyle tabularAmount({
    double fontSize = 24.0,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.5,
        color: color ?? EtoleColors.charcoal,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle tabularSmall({
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: 13.0,
        fontWeight: fontWeight,
        color: color ?? EtoleColors.charcoal,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get bodyMedium => body();
  static TextStyle get labelSmall => labelCaps();
}
