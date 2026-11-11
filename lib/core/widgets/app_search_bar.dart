import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_design_tokens.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;
  final String hintText;
  final Widget? trailing;
  final FocusNode? focusNode;

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onFilterTap,
    this.hasActiveFilters = false,
    this.hintText = 'Search documents, clients, items...',
    this.trailing,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: false,
              ),
            ),
          ),
          if (controller != null && controller!.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                controller?.clear();
                onClear?.call();
                onChanged?.call('');
              },
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              splashRadius: 18,
            ),
          if (onFilterTap != null) ...[
            Container(
              height: 20,
              width: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            IconButton(
              icon: Badge(
                isLabelVisible: hasActiveFilters,
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: hasActiveFilters
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              onPressed: onFilterTap,
              splashRadius: 20,
            ),
          ],
          if (trailing != null) trailing!,
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
