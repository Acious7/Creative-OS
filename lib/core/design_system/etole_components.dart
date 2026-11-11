import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'etole_colors.dart';
import 'etole_spacing.dart';
import 'etole_typography.dart';

// --- Haptics Utility ---
class EtoleHaptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void selection() => HapticFeedback.selectionClick();
  static void warning() => HapticFeedback.heavyImpact();
  static void success() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }
}

// --- Primary Pill Button ---
class EtoleButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isOutline;
  final IconData? icon;
  final bool isFullWidth;
  final bool isSubtle;
  final Color? customAccent;

  const EtoleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isOutline = false,
    this.icon,
    this.isFullWidth = false,
    this.isSubtle = false,
    this.customAccent,
  });

  const EtoleButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.customAccent,
  }) : isPrimary = true,
       isOutline = false,
       isSubtle = false;

  const EtoleButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isFullWidth = false,
  }) : isPrimary = false,
       isOutline = true,
       isSubtle = false,
       customAccent = null;

  const EtoleButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  }) : isPrimary = false,
       isOutline = false,
       isSubtle = true,
       isFullWidth = false,
       customAccent = null;

  @override
  State<EtoleButton> createState() => _EtoleButtonState();
}

class _EtoleButtonState extends State<EtoleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _springController.forward();
    EtoleHaptics.light();
  }

  void _onTapUp(TapUpDetails _) {
    _springController.reverse();
  }

  void _onTapCancel() {
    _springController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.customAccent ?? EtoleColors.cyan;

    Widget child;

    if (widget.isPrimary) {
      final contentColor = accent.computeLuminance() > 0.55
          ? Colors.black
          : Colors.white;
      child = Container(
        height: EtoleSpacing.minTapTarget,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          color: widget.onPressed != null
              ? accent
              : accent.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(EtoleSpacing.rPill),
          boxShadow: widget.onPressed != null
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: widget.isFullWidth
              ? MainAxisSize.max
              : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 18, color: contentColor),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: EtoleTypography.buttonText(color: contentColor)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    } else if (widget.isOutline) {
      final borderColor = isDark
          ? EtoleColors.cream.withValues(alpha: 0.22)
          : EtoleColors.lightTextPrimary.withValues(alpha: 0.2);
      final textColor = isDark
          ? EtoleColors.cream
          : EtoleColors.lightTextPrimary;

      child = Container(
        height: EtoleSpacing.minTapTarget,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(EtoleSpacing.rPill),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          mainAxisSize: widget.isFullWidth
              ? MainAxisSize.max
              : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 18, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: EtoleTypography.buttonText(color: textColor),
            ),
          ],
        ),
      );
    } else {
      // Subtle / Text button
      final textColor = isDark ? EtoleColors.muted : EtoleColors.lightTextMuted;
      child = Container(
        height: EtoleSpacing.minTapTarget,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 16, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: EtoleTypography.buttonText(color: textColor),
            ),
          ],
        ),
      );
    }

    final disableMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.label,
      child: GestureDetector(
        onTapDown: disableMotion ? null : _onTapDown,
        onTapUp: disableMotion ? null : _onTapUp,
        onTapCancel: disableMotion ? null : _onTapCancel,
        onTap: widget.onPressed,
        child: disableMotion
            ? child
            : ScaleTransition(scale: _scaleAnimation, child: child),
      ),
    );
  }
}

// --- Hairline Divider (1px Low-opacity Cream) ---
class EtoleHairline extends StatelessWidget {
  final double? indent;
  final double? endIndent;
  final Color? color;

  const EtoleHairline({super.key, this.indent, this.endIndent, this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1.0,
      thickness: EtoleSpacing.hairline,
      indent: indent,
      endIndent: endIndent,
      color: color ?? EtoleColors.hairline(context),
    );
  }
}

// --- Minimal Input (Label above, hairline underline/field, ember focus state) ---
class EtoleInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final bool autofocus;

  const EtoleInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.keyboardType,
    this.isPassword = false,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  State<EtoleInput> createState() => _EtoleInputState();
}

class _EtoleInputState extends State<EtoleInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? EtoleColors.cream
        : EtoleColors.lightTextPrimary;
    final mutedTextColor = isDark
        ? EtoleColors.muted
        : EtoleColors.lightTextMuted;
    final underlineColor = _isFocused
        ? EtoleColors.cyan
        : (isDark ? EtoleColors.darkHairline : EtoleColors.lightHairline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: EtoleTypography.labelCaps(
            color: _isFocused ? EtoleColors.cyan : mutedTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: underlineColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(
                  widget.prefixIcon,
                  size: 18,
                  color: _isFocused ? EtoleColors.cyan : mutedTextColor,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  initialValue: widget.initialValue,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  onChanged: widget.onChanged,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.isPassword,
                  maxLines: widget.maxLines,
                  style: EtoleTypography.bodyLarge(color: primaryTextColor),
                  cursorColor: EtoleColors.cyan,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: EtoleTypography.body(
                      color: mutedTextColor.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
      ],
    );
  }
}

// --- Frosted Glass Container / Shard / Floating Pill ---
class EtoleGlassPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;

  const EtoleGlassPill({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    this.borderRadius = EtoleSpacing.rPill,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight =
        borderColor ??
        (isDark ? EtoleColors.glassHighlight : EtoleColors.lightGlassHighlight);
    final bg = isDark
        ? EtoleColors.glassBackground
        : EtoleColors.lightGlassBackground;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: highlight, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          EtoleHaptics.light();
          onTap!();
        },
        child: content,
      );
    }
    return content;
  }
}

// --- Clean Typographic List Row (NO boxes, sits directly on background) ---
class EtoleListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final EdgeInsetsGeometry padding;

  const EtoleListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(vertical: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? EtoleColors.cream
        : EtoleColors.lightTextPrimary;
    final subtitleColor = isDark
        ? EtoleColors.muted
        : EtoleColors.lightTextMuted;

    return InkWell(
      onTap: onTap != null
          ? () {
              EtoleHaptics.light();
              onTap!();
            }
          : null,
      splashColor: EtoleColors.cyan.withValues(alpha: 0.08),
      highlightColor: EtoleColors.cyan.withValues(alpha: 0.04),
      child: Column(
        children: [
          Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 16)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: EtoleTypography.bodyLarge(color: titleColor)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: EtoleTypography.bodySmall(
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
          if (showDivider) const EtoleHairline(),
        ],
      ),
    );
  }
}

// --- Animated Letter-by-Letter Title Reveal ---
class EtoleLetterRevealTitle extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration totalDuration;
  final VoidCallback? onComplete;

  const EtoleLetterRevealTitle({
    super.key,
    required this.text,
    this.style,
    this.totalDuration = const Duration(milliseconds: 600),
    this.onComplete,
  });

  @override
  State<EtoleLetterRevealTitle> createState() => _EtoleLetterRevealTitleState();
}

class _EtoleLetterRevealTitleState extends State<EtoleLetterRevealTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    if (!_controller.isCompleted) {
      _controller.value = 1.0;
      setState(() {
        _skipped = true;
      });
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations || _skipped) {
      return Text(
        widget.text,
        style: widget.style ?? EtoleTypography.pageTitle(),
      );
    }

    final letters = widget.text.split('');
    final length = letters.length;

    return GestureDetector(
      onTap: _skip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Wrap(
            children: List.generate(length, (index) {
              final letter = letters[index];
              final start = index / (length + 2);
              final end = (index + 2) / (length + 2);
              final letterProgress = ((progress - start) / (end - start)).clamp(
                0.0,
                1.0,
              );

              final opacity = Curves.easeOut.transform(letterProgress);
              final offsetY = (1.0 - letterProgress) * 12.0;

              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Text(
                    letter,
                    style: widget.style ?? EtoleTypography.pageTitle(),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// --- Subtle Film Grain Background Overlay ---
class EtoleFilmGrain extends StatelessWidget {
  final double opacity;
  final Widget? child;

  const EtoleFilmGrain({super.key, this.opacity = 0.035, this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FilmGrainPainter(opacity: opacity),
      child: child,
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  final double opacity;
  static final Random _rng = Random(42);

  _FilmGrainPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.0;

    // Draw sparse static film noise dots
    const int dotCount = 120;
    for (int i = 0; i < dotCount; i++) {
      final dx = _rng.nextDouble() * size.width;
      final dy = _rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter oldDelegate) => false;
}

// --- Signature Asymmetric Hero Card (Budget Breakdown style) ---
class EtoleHeroCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const EtoleHeroCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(EtoleSpacing.xl),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? EtoleColors.cyan;
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28.0),
          topRight: Radius.circular(12.0),
          bottomLeft: Radius.circular(12.0),
          bottomRight: Radius.circular(12.0),
        ),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          EtoleHaptics.light();
          onTap!();
        },
        child: card,
      );
    }
    return card;
  }
}

// --- Signature Warm Gold Total Badge (Total: Ksh. 50,000 style) ---
class EtoleTotalBadge extends StatelessWidget {
  final String label;
  final String amount;
  final String currency;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const EtoleTotalBadge({
    super.key,
    this.label = 'Total:',
    String? amount,
    String? amountText,
    this.currency = 'Ksh.',
    this.fontSize = 14.0,
    this.padding,
  }) : amount = amount ?? amountText ?? '0';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: EtoleColors.gold,
        borderRadius: BorderRadius.circular(EtoleSpacing.rPill),
        boxShadow: [
          BoxShadow(
            color: EtoleColors.gold.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label.isEmpty ? '$currency $amount' : '$label $currency $amount',
        style: EtoleTypography.tabularAmount(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}

// --- Etole Brand Logo ("etole VisualStoryteller" with 5-color typography) ---
class EtoleBrandLogo extends StatelessWidget {
  final double fontSize;
  final bool showSubtitle;
  final Color? tColor;
  final Color? subtitleColor;
  final bool? isDark;

  const EtoleBrandLogo({
    super.key,
    double? fontSize,
    double? size,
    this.showSubtitle = true,
    this.tColor,
    this.subtitleColor,
    this.isDark,
  }) : fontSize = fontSize ?? size ?? 28.0;

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final effectiveTColor =
        tColor ??
        (effectiveIsDark ? EtoleColors.cream : const Color(0xFF111827));
    final effectiveSubColor =
        subtitleColor ??
        (effectiveIsDark ? EtoleColors.muted : EtoleColors.lightTextMuted);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: [
              const TextSpan(
                text: 'c',
                style: TextStyle(color: EtoleColors.green),
              ),
              TextSpan(
                text: 'r',
                style: TextStyle(color: effectiveTColor),
              ),
              const TextSpan(
                text: 'e',
                style: TextStyle(color: EtoleColors.gold),
              ),
              const TextSpan(
                text: 'a',
                style: TextStyle(color: EtoleColors.slate),
              ),
              const TextSpan(
                text: 't',
                style: TextStyle(color: EtoleColors.red),
              ),
              const TextSpan(
                text: 'i',
                style: TextStyle(color: EtoleColors.cyan),
              ),
              const TextSpan(
                text: 'v',
                style: TextStyle(color: EtoleColors.gold),
              ),
              TextSpan(
                text: 'e',
                style: TextStyle(color: effectiveTColor),
              ),
              const TextSpan(
                text: ' os',
                style: TextStyle(color: EtoleColors.red, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 2),
          Text(
            'Creative Operating System',
            style: TextStyle(
              fontSize: fontSize * 0.35,
              fontWeight: FontWeight.w600,
              color: effectiveSubColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}

// --- Etole Abstract Bauhaus & Modernist Graphic Cluster ---
// Extracted directly from top-right of the quotation document:
// - Crimson Red square
// - Warm Golden Yellow quadrant
// - Cerulean Cyan circle
// - Forest Green semicircle
// - Soft Olive/Sage quadrant with 3x3 dot matrix
class EtoleBauhausCluster extends StatelessWidget {
  final double size;

  const EtoleBauhausCluster({super.key, this.size = 54.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BauhausClusterPainter()),
    );
  }
}

class _BauhausClusterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = w / 4.0;

    // 1. Crimson Red Square (top left-ish)
    final redPaint = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.fill;
    final redRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(unit * 0.4, 0, unit * 1.8, unit * 1.8),
      const Radius.circular(3),
    );
    canvas.drawRRect(redRect, redPaint);

    // 2. Warm Golden Amber Quadrant (top right)
    final goldPaint = Paint()
      ..color = const Color(0xFFF5A623)
      ..style = PaintingStyle.fill;
    final goldPath = Path()
      ..moveTo(unit * 2.2, 0)
      ..lineTo(unit * 4.0, 0)
      ..arcToPoint(
        Offset(unit * 2.2, unit * 1.8),
        radius: Radius.circular(unit * 1.8),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(goldPath, goldPaint);

    // 3. Cerulean Cyan Circle (center right)
    final cyanPaint = Paint()
      ..color = const Color(0xFF38B6DB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(unit * 2.0, unit * 2.6), unit * 1.0, cyanPaint);

    // 4. Forest Green Semicircle (left)
    final greenPaint = Paint()
      ..color = const Color(0xFF007A3D)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(unit * 0.4, unit * 1.8)
      ..arcToPoint(
        Offset(unit * 0.4, unit * 3.4),
        radius: Radius.circular(unit * 0.8),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 5. Olive Sage Quadrant with 3x3 dot matrix (bottom right)
    final sagePaint = Paint()
      ..color = const Color(0xFFC5D6C6)
      ..style = PaintingStyle.fill;
    final sageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(unit * 2.5, unit * 2.4, unit * 1.4, unit * 1.4),
      const Radius.circular(3),
    );
    canvas.drawRRect(sageRect, sagePaint);

    // 3x3 dot matrix
    final dotPaint = Paint()
      ..color = const Color(0xFF007A3D)
      ..style = PaintingStyle.fill;
    final startX = unit * 2.75;
    final startY = unit * 2.65;
    final step = unit * 0.45;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        canvas.drawCircle(
          Offset(startX + (c * step * 0.8), startY + (r * step * 0.8)),
          1.2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Etole Maasai & Kenyan Flag Corner Motif ---
// Extracted from bottom-left of the quotation document:
// Rounded striped shape (vertical black and crimson red stripes) + Forest Green circle
class EtoleMaasaiAccent extends StatelessWidget {
  final double height;

  const EtoleMaasaiAccent({super.key, this.height = 24.0});

  @override
  Widget build(BuildContext context) {
    final width = height * 1.8;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _MaasaiAccentPainter()),
    );
  }
}

class _MaasaiAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final stripeWidth = h * 1.0;

    // 1. Rounded vertical striped element
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, stripeWidth, h),
      Radius.circular(h * 0.45),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    final blackPaint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.fill;
    final redPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    const int numStripes = 6;
    final colWidth = stripeWidth / numStripes;
    for (int i = 0; i < numStripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * colWidth, 0, colWidth, h),
        i % 2 == 0 ? redPaint : blackPaint,
      );
    }
    canvas.restore();

    // 2. Solid Forest Green Circle beside it
    final greenPaint = Paint()
      ..color = const Color(0xFF007A3D)
      ..style = PaintingStyle.fill;
    final circleRadius = h * 0.42;
    canvas.drawCircle(
      Offset(stripeWidth + circleRadius + 4, h * 0.5),
      circleRadius,
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Signature Budget Breakdown Sky Cyan Card ---
// Replicates the iconic quotation centerpiece:
// Solid Cerulean Cyan (#38B6DB) background, asymmetric 28px top-left corner,
// crisp white typography, and white hairline divider
class EtoleBudgetBreakdownCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const EtoleBudgetBreakdownCard({
    super.key,
    this.title = 'Budget Breakdown.',
    this.subtitle = 'Price (Ksh.)',
    required this.child,
    this.padding = const EdgeInsets.all(18.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(28.0),
      topRight: Radius.circular(14.0),
      bottomLeft: Radius.circular(14.0),
      bottomRight: Radius.circular(14.0),
    );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: EtoleColors.cyan,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: EtoleColors.cyan.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // White Hairline Divider
          Container(height: 1.5, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          EtoleHaptics.light();
          onTap!();
        },
        child: content,
      );
    }
    return content;
  }
}
