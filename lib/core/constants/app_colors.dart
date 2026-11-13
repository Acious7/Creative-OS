import 'package:flutter/material.dart';

class AppColors {
  // Brand Defaults (Brian Etole Studio Quotation Palette)
  static const Color etoleCyan = Color(
    0xFF38B6DB,
  ); // Primary Cyan / Cerulean Hero
  static const Color etoleCyanDark = Color(0xFF1D8EAE);
  static const Color etoleCyanLight = Color(0xFFE6F7FC);
  static const Color etoleGold = Color(
    0xFFF5A623,
  ); // Signature Total Badge Gold
  static const Color etoleGoldLight = Color(0xFFFEF5E7);
  static const Color etoleGreen = Color(
    0xFF007A3D,
  ); // Forest Green ('e' in etole)
  static const Color etoleRed = Color(0xFFD32F2F); // Crimson Red ('l' in etole)
  static const Color etoleSlate = Color(
    0xFF4A90E2,
  ); // Slate Blue ('o' in etole)
  static const Color etoleCharcoal = Color(0xFF111827); // Rich Black Ink

  // Aliases for compatibility
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

  // Status Colors (Aligned with Studio Palette)
  static const Color statusDraft = Color(0xFF6B7280);
  static const Color statusSent = etoleSlate;
  static const Color statusAccepted = etoleGreen;
  static const Color statusDeclined = etoleRed;
  static const Color statusPaid = etoleGreen;
  static const Color statusPartPaid = etoleGold;
  static const Color statusOverdue = etoleRed;
  static const Color statusCancelled = Color(0xFF4B5563);

  // Status Aliases
  static const Color success = etoleGreen;
  static const Color error = etoleRed;
  static const Color warning = etoleGold;
  static const Color info = etoleCyan;

  // Dark Theme Base Colors
  static const Color darkBackground = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF151922);
  static const Color darkCard = Color(0xFF1C2230);
  static const Color darkCardElevated = Color(0xFF242C3E);
  static const Color darkBorder = Color(0xFF2A3447);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Base Colors (Matches Gallery Off-White Quotation Canvas #FAF7F2)
  static const Color lightBackground = Color(0xFFFAF7F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E4DC);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF8C95A3);

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return statusDraft;
      case 'sent':
        return statusSent;
      case 'accepted':
        return statusAccepted;
      case 'declined':
        return statusDeclined;
      case 'paid':
        return statusPaid;
      case 'part-paid':
      case 'partpaid':
      case 'part_paid':
        return statusPartPaid;
      case 'overdue':
        return statusOverdue;
      case 'cancelled':
      case 'canceled':
        return statusCancelled;
      default:
        return statusDraft;
    }
  }

  static Color parseHex(String hexString, {Color fallback = etoleCyan}) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static String toHex(Color color) {
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
