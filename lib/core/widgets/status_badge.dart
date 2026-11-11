import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_design_tokens.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showDot;
  final bool compact;
  final Color? customColor;

  const StatusBadge({
    super.key,
    required this.status,
    this.showDot = true,
    this.compact = false,
    this.customColor,
  });

  static Color getStatusColor(String rawStatus) {
    switch (rawStatus.toLowerCase().replaceAll('_', '-').trim()) {
      case 'draft':
        return AppDesignTokens.statusDraft;
      case 'sent':
        return AppDesignTokens.statusSent;
      case 'accepted':
      case 'approved':
        return AppDesignTokens.statusAccepted;
      case 'declined':
      case 'rejected':
        return AppDesignTokens.statusDeclined;
      case 'paid':
        return AppDesignTokens.statusPaid;
      case 'part-paid':
      case 'partpaid':
        return AppDesignTokens.statusPartPaid;
      case 'overdue':
        return AppDesignTokens.statusOverdue;
      case 'cancelled':
      case 'canceled':
        return AppDesignTokens.statusCancelled;
      case 'signed':
        return AppDesignTokens.statusSigned;
      case 'under-review':
      case 'in-progress':
        return AppDesignTokens.statusUnderReview;
      default:
        return AppDesignTokens.statusDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? getStatusColor(status);
    final displayLabel = status.isEmpty ? 'Draft' : status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: compact ? 5 : 6,
              height: compact ? 5 : 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            displayLabel,
            style: GoogleFonts.inter(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
