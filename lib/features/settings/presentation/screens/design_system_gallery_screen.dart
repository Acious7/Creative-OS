import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_spacing.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';

class DesignSystemGalleryScreen extends ConsumerStatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  ConsumerState<DesignSystemGalleryScreen> createState() =>
      _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState
    extends ConsumerState<DesignSystemGalleryScreen> {
  final _testInputController = TextEditingController(
    text: 'Commercial Shoot — Serena Hotel',
  );
  final _amountController = TextEditingController(text: '450,000 KES');
  int _letterRevealKey = 0;
  bool _pressedFeedback = false;

  @override
  void dispose() {
    _testInputController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _triggerLetterReveal() {
    setState(() {
      _letterRevealKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOled = ref.watch(isOledModeProvider) && isDark;
    final reduceMotion = ref.watch(reduceMotionProvider);

    final bg = isDark
        ? (isOled ? EtoleColors.oledBase : EtoleColors.darkBase)
        : EtoleColors.lightBase;
    final textColor = isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary;
    final mutedColor = isDark ? EtoleColors.muted : EtoleColors.lightTextMuted;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Subtle film grain
          if (isDark)
            const Positioned.fill(child: EtoleFilmGrain(opacity: 0.04)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: EtoleSpacing.screenGutter,
                vertical: EtoleSpacing.s24,
              ),
              children: [
                // Top Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: textColor),
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        // OLED Toggle
                        if (isDark)
                          IconButton(
                            icon: Icon(
                              isOled ? Icons.circle : Icons.circle_outlined,
                              color: isOled ? EtoleColors.cyan : mutedColor,
                              size: 20,
                            ),
                            tooltip: isOled
                                ? 'OLED Pitch Black (Active)'
                                : 'OLED Pitch Black',
                            onPressed: () {
                              ref.read(isOledModeProvider.notifier).state =
                                  !isOled;
                              EtoleHaptics.selection();
                            },
                          ),
                        // Light / Dark Toggle
                        IconButton(
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: textColor,
                          ),
                          tooltip: isDark
                              ? 'Switch to Light Mode'
                              : 'Switch to Dark Mode',
                          onPressed: () {
                            ref.read(themeModeProvider.notifier).state = isDark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                            EtoleHaptics.selection();
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: EtoleSpacing.s16),

                // Screen Header
                Text(
                  'DESIGN SYSTEM',
                  style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
                ),
                const SizedBox(height: EtoleSpacing.s8),
                Text(
                  'SHARDS & WORLDS',
                  style: EtoleTypography.heroDisplay(color: textColor),
                ),
                const SizedBox(height: EtoleSpacing.s8),
                Text(
                  'Clean, typography-led Afrofuturist design language. No rounded boxes. Structure through hierarchy, generous spacing, and 1px hairline dividers.',
                  style: EtoleTypography.bodyMuted(color: mutedColor),
                ),

                const SizedBox(height: EtoleSpacing.s32),
                const EtoleHairline(),
                const SizedBox(height: EtoleSpacing.s32),

                // 1. TYPOGRAPHY SECTION
                _buildSectionTitle('01 · TYPOGRAPHY', textColor),
                const SizedBox(height: EtoleSpacing.s16),

                Text(
                  'HERO DISPLAY',
                  style: EtoleTypography.heroDisplay(color: textColor),
                ),
                const SizedBox(height: EtoleSpacing.s4),
                Text(
                  'BEBAS NEUE · 48DP CONDENSED',
                  style: EtoleTypography.labelCaps(color: mutedColor),
                ),
                const SizedBox(height: EtoleSpacing.s16),
                Text(
                  'PAGE TITLE',
                  style: EtoleTypography.pageTitle(color: textColor),
                ),
                const SizedBox(height: EtoleSpacing.s4),
                Text(
                  'BEBAS NEUE · 34DP CONDENSED',
                  style: EtoleTypography.labelCaps(color: mutedColor),
                ),
                const SizedBox(height: EtoleSpacing.s16),
                Text(
                  'SECTION TITLE',
                  style: EtoleTypography.sectionTitle(color: textColor),
                ),
                const SizedBox(height: EtoleSpacing.s4),
                Text(
                  'BEBAS NEUE · 22DP CONDENSED',
                  style: EtoleTypography.labelCaps(color: mutedColor),
                ),
                const SizedBox(height: EtoleSpacing.s24),

                Text(
                  'Body Large (Inter 16/24) — Clean, legible modern sans typography for editorial intros, client briefings, and artistic statements.',
                  style: EtoleTypography.bodyLarge(color: textColor),
                ),
                const SizedBox(height: EtoleSpacing.s12),
                Text(
                  'Body Regular (Inter 14/21) — Calm body copy sitting directly on the canvas without visual friction or nested box borders.',
                  style: EtoleTypography.body(color: textColor),
                ),
                const SizedBox(height: EtoleSpacing.s12),
                Text(
                  'UPPERCASE WIDE LABELS (INTER 11 / TRACKING +2.0)',
                  style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
                ),
                const SizedBox(height: EtoleSpacing.s24),

                // Tabular Numbers Demonstration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TABULAR FIGURE',
                            style: EtoleTypography.labelCaps(color: mutedColor),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'KES 1,850,000.00',
                              style: EtoleTypography.tabularAmount(
                                color: textColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'FIXED-WIDTH DIGITS',
                            style: EtoleTypography.labelCaps(color: mutedColor),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '00:42:19 · 24 FPS',
                              style: EtoleTypography.tabularAmount(
                                color: EtoleColors.gold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: EtoleSpacing.s32),
                const EtoleHairline(),
                const SizedBox(height: EtoleSpacing.s32),

                // 2. COLOURS SECTION
                _buildSectionTitle('02 · QUOTATION BRAND PALETTE', textColor),
                const SizedBox(height: EtoleSpacing.s16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildColorSwatch(
                      'CANVAS (#FAF7F2)',
                      isDark ? EtoleColors.darkBase : EtoleColors.lightBase,
                      textColor,
                      isBordered: true,
                    ),
                    _buildColorSwatch(
                      'CYAN (#38B6DB)',
                      EtoleColors.cyan,
                      Colors.white,
                    ),
                    _buildColorSwatch(
                      'GOLD (#F5A623)',
                      EtoleColors.gold,
                      Colors.black,
                    ),
                    _buildColorSwatch(
                      'EMERALD (#007A3D)',
                      EtoleColors.emerald,
                      Colors.white,
                    ),
                    _buildColorSwatch(
                      'CRIMSON (#D32F2F)',
                      EtoleColors.red,
                      Colors.white,
                    ),
                    _buildColorSwatch(
                      'SLATE (#4A90E2)',
                      EtoleColors.slate,
                      Colors.white,
                    ),
                    _buildColorSwatch(
                      'OLIVE SAGE (#C5D6C6)',
                      EtoleColors.oliveSage,
                      Colors.black,
                    ),
                    _buildColorSwatch(
                      'OBSIDIAN (#0D0F14)',
                      EtoleColors.obsidian,
                      Colors.white,
                      isBordered: true,
                    ),
                  ],
                ),
                const SizedBox(height: EtoleSpacing.s12),
                Text(
                  'Quotation Identity: Cerulean Cyan (#38B6DB) hero budget container, Warm Marigold Gold (#F5A623) total badges, and multi-color Bauhaus geometry on warm gallery parchment.',
                  style: EtoleTypography.bodySmall(color: mutedColor),
                ),

                const SizedBox(height: EtoleSpacing.s32),
                const EtoleHairline(),
                const SizedBox(height: EtoleSpacing.s32),

                // 3. BUTTONS & ACTIONS SECTION
                _buildSectionTitle('03 · BUTTONS & ACTIONS', textColor),
                const SizedBox(height: EtoleSpacing.s16),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Primary Pill Button
                    EtoleButton.primary(
                      label: 'PRIMARY PILL',
                      icon: Icons.flash_on_rounded,
                      onPressed: () {
                        setState(() {
                          _pressedFeedback = true;
                        });
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          if (mounted) setState(() => _pressedFeedback = false);
                        });
                      },
                    ),

                    // Outline Pill Button
                    EtoleButton.outline(
                      label: 'OUTLINE PILL',
                      icon: Icons.visibility_outlined,
                      onPressed: () {
                        EtoleHaptics.light();
                      },
                    ),

                    // Text / Ghost Button
                    EtoleButton.text(
                      label: 'TEXT ACTION',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        EtoleHaptics.light();
                      },
                    ),
                  ],
                ),

                if (_pressedFeedback) ...[
                  const SizedBox(height: EtoleSpacing.s12),
                  Text(
                    '✓ Haptic triggered & spring scale animated',
                    style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
                  ),
                ],

                const SizedBox(height: EtoleSpacing.s32),
                const EtoleHairline(),
                const SizedBox(height: EtoleSpacing.s32),

                // 4. MINIMAL INPUTS SECTION
                _buildSectionTitle('04 · MINIMAL INPUT FIELDS', textColor),
                const SizedBox(height: EtoleSpacing.s8),
                Text(
                  'Label above, minimal hairline underline, cyan glow on focus. No heavy grey boxes.',
                  style: EtoleTypography.bodySmall(color: mutedColor),
                ),
                const SizedBox(height: EtoleSpacing.s16),

                EtoleInput(
                  label: 'Project or Client Name',
                  controller: _testInputController,
                  prefixIcon: Icons.movie_creation_outlined,
                  hint: 'Enter production title...',
                ),

                const SizedBox(height: EtoleSpacing.s24),

                EtoleInput(
                  label: 'Fee / Amount (KES)',
                  controller: _amountController,
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: EtoleSpacing.s32),
                const EtoleHairline(),
                const SizedBox(height: EtoleSpacing.s32),

                // 5. CLEAN TYPOGRAPHIC LIST ROWS SECTION
                _buildSectionTitle(
                  '05 · CONTENT ON BACKGROUND (LIST ROWS)',
                  textColor,
                ),
                const SizedBox(height: EtoleSpacing.s8),
                Text(
                  'Content sits directly on canvas with 1px hairline dividers. No card containers.',
                  style: EtoleTypography.bodySmall(color: mutedColor),
                ),
                const SizedBox(height: EtoleSpacing.s16),

                EtoleListRow(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: EtoleColors.cyan,
                    size: 22,
                  ),
                  title: 'BE-INV-0042 · Safaricom Commercial',
                  subtitle: 'Production & Color Grade · Due in 5 days',
                  trailing: Text(
                    'KES 850,000',
                    style: EtoleTypography.tabularAmount(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  onTap: () {},
                ),

                EtoleListRow(
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: EtoleColors.muted,
                    size: 22,
                  ),
                  title: 'Wanjiku Kamau',
                  subtitle: 'Executive Producer · Kalasha Film Market',
                  trailing: Text(
                    'MET TODAY',
                    style: EtoleTypography.labelCaps(color: EtoleColors.gold),
                  ),
                  onTap: () {},
                ),

                EtoleListRow(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: EtoleColors.muted,
                    size: 22,
                  ),
                  title: 'RED V-Raptor 8K Camera Package',
                  subtitle: 'Daily dry hire rate with cine primes',
                  trailing: Text(
                    'KES 95,000 / day',
                    style: EtoleTypography.tabularSmall(color: textColor),
                  ),
                  showDivider: false,
                  onTap: () {},
                ),

                const SizedBox(height: EtoleSpacing.s32),
                const EtoleHairline(),
                const SizedBox(height: EtoleSpacing.s32),

                // 6. FROSTED GLASS & SHARDS SECTION
                _buildSectionTitle('06 · FROSTED GLASS & SHARDS', textColor),
                const SizedBox(height: EtoleSpacing.s8),
                Text(
                  'Frosted backdrop blur, fine bright edge highlight, and soft ambient shadow.',
                  style: EtoleTypography.bodySmall(color: mutedColor),
                ),
                const SizedBox(height: EtoleSpacing.s16),

                Center(
                  child: EtoleGlassPill(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    onTap: () {
                      EtoleHaptics.light();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: EtoleColors.cyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'FLOATING GLASS PILL · TAP ME',
                          style: EtoleTypography.labelCaps(color: textColor),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: EtoleSpacing.s32),
                const EtoleHairline(),
                const SizedBox(height: EtoleSpacing.s32),

                // 7. MOTION & ACCESSIBILITY SECTION
                _buildSectionTitle('07 · MOTION & ACCESSIBILITY', textColor),
                const SizedBox(height: EtoleSpacing.s8),
                Text(
                  'Spring physics, letter-by-letter reveal, haptic feedback, and full Reduce Motion support.',
                  style: EtoleTypography.bodySmall(color: mutedColor),
                ),
                const SizedBox(height: EtoleSpacing.s16),

                // Letter Reveal Demo
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? EtoleColors.darkSurface
                        : EtoleColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(EtoleSpacing.rSubtle),
                    border: Border.all(
                      color: isDark
                          ? EtoleColors.darkHairline
                          : EtoleColors.lightHairline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LETTER-BY-LETTER REVEAL',
                            style: EtoleTypography.labelCaps(color: mutedColor),
                          ),
                          GestureDetector(
                            onTap: _triggerLetterReveal,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.replay_rounded,
                                  size: 14,
                                  color: EtoleColors.cyan,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'REPLAY',
                                  style: EtoleTypography.labelCaps(
                                    color: EtoleColors.cyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      EtoleLetterRevealTitle(
                        key: ValueKey(_letterRevealKey),
                        text: 'N · E · T · W · O · R · K',
                        style: EtoleTypography.pageTitle(
                          color: EtoleColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: EtoleSpacing.s16),

                // Reduce Motion Toggle Demonstration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REDUCE MOTION',
                          style: EtoleTypography.body(color: textColor)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          reduceMotion
                              ? 'Enabled (Instant transitions & fades)'
                              : 'Disabled (Spring & physics active)',
                          style: EtoleTypography.bodySmall(color: mutedColor),
                        ),
                      ],
                    ),
                    Switch(
                      value: reduceMotion,
                      activeColor: EtoleColors.cyan,
                      onChanged: (val) {
                        ref.read(reduceMotionProvider.notifier).state = val;
                        EtoleHaptics.selection();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: EtoleSpacing.s32),
                const EtoleHairline(),
                const SizedBox(height: EtoleSpacing.s32),

                // 8. SIGNATURE QUOTATION ASSETS SECTION
                _buildSectionTitle(
                  '08 · SIGNATURE QUOTATION ASSETS',
                  textColor,
                ),
                const SizedBox(height: EtoleSpacing.s8),
                Text(
                  'Extracted directly from Brian Etole Official Quotation letterhead & modernist Bauhaus geometry.',
                  style: EtoleTypography.bodySmall(color: mutedColor),
                ),
                const SizedBox(height: EtoleSpacing.s20),

                // Brand Logo and Bauhaus Cluster Preview Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? EtoleColors.darkSurfaceElevated
                        : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: isDark
                          ? EtoleColors.darkHairline
                          : EtoleColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EtoleBrandLogo(size: 26, showSubtitle: true),
                          const EtoleBauhausCluster(size: 56),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const EtoleHairline(),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const EtoleMaasaiAccent(height: 32),
                          const EtoleTotalBadge(amount: '50,000'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: EtoleSpacing.s48),

                // Footer signature
                Center(
                  child: Text(
                    'BRIAN ETOLE · NAIROBI, KENYA\n+254 718 013 579 · HELLO@BRIANETOLE.COM',
                    textAlign: TextAlign.center,
                    style: EtoleTypography.labelCaps(
                      color: mutedColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: EtoleSpacing.s32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(title, style: EtoleTypography.sectionTitle(color: color));
  }

  Widget _buildColorSwatch(
    String label,
    Color color,
    Color textColor, {
    bool isBordered = false,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(EtoleSpacing.rSubtle),
        border: isBordered
            ? Border.all(color: EtoleColors.darkHairline, width: 1.0)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: EtoleTypography.labelCaps(color: textColor)),
        ],
      ),
    );
  }
}
