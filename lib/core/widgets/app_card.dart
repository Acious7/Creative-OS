import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';

enum AppCardVariant { low, surface, high, outlined, hero }

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AppCardVariant variant;
  final Color? customColor;
  final Color? borderColor;
  final double? borderRadius;
  final BorderRadius? customBorderRadius;
  final bool isHeroAsymmetric;
  final bool clip;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(AppDesignTokens.spaceLg),
    this.margin,
    this.variant = AppCardVariant.surface,
    this.customColor,
    this.borderColor,
    this.borderRadius,
    this.customBorderRadius,
    this.isHeroAsymmetric = false,
    this.clip = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color border;

    if (customColor != null) {
      bg = customColor!;
      border = borderColor ?? theme.colorScheme.outlineVariant;
    } else {
      switch (variant) {
        case AppCardVariant.low:
          bg = theme.colorScheme.surfaceContainerLow;
          border = isDark ? AppDesignTokens.darkBorderSubtle : AppDesignTokens.lightBorderSubtle;
          break;
        case AppCardVariant.surface:
          bg = theme.colorScheme.surfaceContainer;
          border = borderColor ?? theme.colorScheme.outlineVariant;
          break;
        case AppCardVariant.high:
          bg = theme.colorScheme.surfaceContainerHigh;
          border = borderColor ?? theme.colorScheme.outline;
          break;
        case AppCardVariant.outlined:
          bg = Colors.transparent;
          border = borderColor ?? theme.colorScheme.outline;
          break;
        case AppCardVariant.hero:
          bg = theme.colorScheme.primary;
          border = borderColor ?? theme.colorScheme.primary;
          break;
      }
    }

    final BorderRadius radius = customBorderRadius ??
        ((isHeroAsymmetric || variant == AppCardVariant.hero)
            ? const BorderRadius.only(
                topLeft: Radius.circular(AppDesignTokens.radiusHero),
                topRight: Radius.circular(AppDesignTokens.radiusLg),
                bottomLeft: Radius.circular(AppDesignTokens.radiusLg),
                bottomRight: Radius.circular(AppDesignTokens.radiusLg),
              )
            : BorderRadius.circular(borderRadius ?? AppDesignTokens.radiusLg));

    Widget content = padding != null ? Padding(padding: padding!, child: child) : child;

    if (onTap != null || onLongPress != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: content,
    );
  }
}
