import 'package:flutter/material.dart';

/// Etole Design System — Spacing & Layout Scale
/// Strict scale: 4, 8, 12, 16, 24, 32, 48, 64.
/// Generous margins: 24 on mobile edges.
/// 48dp minimum tap targets for accessibility.
class EtoleSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;
  static const double xl = 24.0;

  // Screen horizontal gutter
  static const double screenGutter = 24.0;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: screenGutter);

  // Accessible minimum tap target
  static const double minTapTarget = 48.0;

  // Hairline thickness
  static const double hairline = 1.0;

  // Radius scale
  static const double rPill = 999.0;
  static const double rGlass = 16.0;
  static const double rSubtle = 8.0;
}
