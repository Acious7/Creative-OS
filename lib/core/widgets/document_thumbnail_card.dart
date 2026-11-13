import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_design_tokens.dart';
import 'app_card.dart';
import 'status_badge.dart';

class DocumentThumbnailCard extends StatelessWidget {
  final String docNumber;
  final String docType;
  final String clientName;
  final DateTime issueDate;
  final double? totalAmount;
  final String currency;
  final String status;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final Widget? trailing;

  const DocumentThumbnailCard({
    super.key,
    required this.docNumber,
    required this.docType,
    required this.clientName,
    required this.issueDate,
    this.totalAmount,
    this.currency = 'KES',
    required this.status,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final numberFormatter = NumberFormat('#,##0.00');

    Color docTypeColor;
    final lowerType = docType.toLowerCase();
    if (lowerType.contains('quote') || lowerType.contains('quotation')) {
      docTypeColor = AppDesignTokens.brandCyan;
    } else if (lowerType.contains('invoice')) {
      docTypeColor = AppDesignTokens.brandEmerald;
    } else if (lowerType.contains('receipt')) {
      docTypeColor = AppDesignTokens.brandSlate;
    } else {
      docTypeColor = AppDesignTokens.brandAmber;
    }

    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      borderColor: isSelected ? theme.colorScheme.primary : null,
      customColor: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : null,
      isHeroAsymmetric: isSelected,
      padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: docTypeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        AppDesignTokens.radiusXs,
                      ),
                    ),
                    child: Text(
                      docType.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: docTypeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    docNumber,
                    style: AppDesignTokens.tabularStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              StatusBadge(status: status, compact: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  clientName.isEmpty ? 'No Client Specified' : clientName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalAmount != null && totalAmount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesignTokens.brandAmber,
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusSm,
                    ),
                  ),
                  child: Text(
                    '$currency ${numberFormatter.format(totalAmount)}',
                    style: AppDesignTokens.tabularStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(issueDate),
                    style: AppDesignTokens.tabularStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}
