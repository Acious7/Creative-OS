import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../../hub/domain/hub_models.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final themeSettings = ref.watch(studioThemeSettingsProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final openAppTo = ref.watch(openAppToProvider);

    final cream = studioTheme.textPrimary;
    final muted = studioTheme.textMuted;
    final isDark = studioTheme.isDark;

    return Scaffold(
      backgroundColor: studioTheme.backgroundBase,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: cream),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '06 · APPEARANCE',
                        style: EtoleTypography.labelCaps(
                          color: studioTheme.primaryAccent,
                        ),
                      ),
                      Text(
                        'THEME & SENSORY',
                        style: EtoleTypography.subheading(color: cream),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: studioTheme.dividerColor, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                children: [
                  // Section: Studio Themes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STUDIO THEMES',
                        style: EtoleTypography.labelCaps(color: muted),
                      ),
                      Text(
                        'INSTANT LIVE APPLIED',
                        style: EtoleTypography.labelCaps(
                          color: studioTheme.primaryAccent,
                        ).copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Tribal Orange
                  _buildThemeCard(
                    themeData: StudioThemeData.tribalOrange,
                    isSelected:
                        themeSettings.themeId == StudioThemeId.tribalOrange,
                    currentTheme: studioTheme,
                    onTap: () {
                      ref
                          .read(studioThemeSettingsProvider.notifier)
                          .setThemeId(StudioThemeId.tribalOrange);
                      EtoleHaptics.selection();
                    },
                  ),
                  const SizedBox(height: 12),

                  // 2. Night Warrior
                  _buildThemeCard(
                    themeData: StudioThemeData.nightWarrior,
                    isSelected:
                        themeSettings.themeId == StudioThemeId.nightWarrior,
                    currentTheme: studioTheme,
                    onTap: () {
                      ref
                          .read(studioThemeSettingsProvider.notifier)
                          .setThemeId(StudioThemeId.nightWarrior);
                      EtoleHaptics.selection();
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. Savannah Light
                  _buildThemeCard(
                    themeData: StudioThemeData.savannahLight,
                    isSelected:
                        themeSettings.themeId == StudioThemeId.savannahLight,
                    currentTheme: studioTheme,
                    onTap: () {
                      ref
                          .read(studioThemeSettingsProvider.notifier)
                          .setThemeId(StudioThemeId.savannahLight);
                      EtoleHaptics.selection();
                    },
                  ),
                  const SizedBox(height: 12),

                  // 4. Nairobi Neon
                  _buildThemeCard(
                    themeData: StudioThemeData.nairobiNeon,
                    isSelected:
                        themeSettings.themeId == StudioThemeId.nairobiNeon,
                    currentTheme: studioTheme,
                    onTap: () {
                      ref
                          .read(studioThemeSettingsProvider.notifier)
                          .setThemeId(StudioThemeId.nairobiNeon);
                      EtoleHaptics.selection();
                    },
                  ),

                  const SizedBox(height: 24),
                  Divider(color: studioTheme.dividerColor, height: 1),
                  const SizedBox(height: 20),

                  // Section: Dark Mode Automation
                  Text(
                    'SYSTEM INTEGRATION',
                    style: EtoleTypography.labelCaps(color: muted),
                  ),
                  const SizedBox(height: 14),

                  // Follow phone dark mode toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: studioTheme.surfaceCardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: studioTheme.dividerColor,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Follow phone dark mode',
                                style: EtoleTypography.bodyLarge(color: cream),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Automatically uses Savannah Light in daytime and your selected dark theme at night.',
                                style: EtoleTypography.bodySmall(color: muted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: themeSettings.followSystemDark,
                          activeThumbColor: studioTheme.primaryAccent,
                          activeTrackColor: studioTheme.primaryAccent
                              .withValues(alpha: 0.35),
                          onChanged: (val) {
                            ref
                                .read(studioThemeSettingsProvider.notifier)
                                .setFollowSystemDark(val);
                            EtoleHaptics.light();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Match card to theme toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: studioTheme.surfaceCardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: studioTheme.dividerColor,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Match card to theme',
                                style: EtoleTypography.bodyLarge(color: cream),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'When off, the digital card keeps its signature orange tribal look. When on, it adapts to the active theme.',
                                style: EtoleTypography.bodySmall(color: muted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: themeSettings.matchCardToTheme,
                          activeThumbColor: studioTheme.primaryAccent,
                          activeTrackColor: studioTheme.primaryAccent
                              .withValues(alpha: 0.35),
                          onChanged: (val) {
                            ref
                                .read(studioThemeSettingsProvider.notifier)
                                .setMatchCardToTheme(val);
                            EtoleHaptics.light();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: studioTheme.dividerColor, height: 1),
                  const SizedBox(height: 20),

                  // Section: Motion & Sensor
                  Text(
                    'MOTION & SENSORS',
                    style: EtoleTypography.labelCaps(color: muted),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reduce Motion',
                              style: EtoleTypography.bodyLarge(color: cream),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Disables 3D card tilt parallax, gyro foil sheen, and shard floating sine waves',
                              style: EtoleTypography.bodySmall(color: muted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: reduceMotion,
                        activeThumbColor: studioTheme.primaryAccent,
                        activeTrackColor: studioTheme.primaryAccent.withValues(
                          alpha: 0.35,
                        ),
                        onChanged: (val) {
                          ref.read(reduceMotionProvider.notifier).state = val;
                          EtoleHaptics.light();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Divider(color: studioTheme.dividerColor, height: 1),
                  const SizedBox(height: 20),

                  // Section: Audio & Sound
                  Text(
                    'SOUND & HAPTICS',
                    style: EtoleTypography.labelCaps(color: muted),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subtle Ambient Sound',
                              style: EtoleTypography.bodyLarge(color: cream),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Faint glass chime upon entering worlds and soft paper sounds in Docs (off by default)',
                              style: EtoleTypography.bodySmall(color: muted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: soundEnabled,
                        activeThumbColor: studioTheme.primaryAccent,
                        activeTrackColor: studioTheme.primaryAccent.withValues(
                          alpha: 0.35,
                        ),
                        onChanged: (val) {
                          ref.read(soundEnabledProvider.notifier).state = val;
                          EtoleHaptics.light();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Divider(color: studioTheme.dividerColor, height: 1),
                  const SizedBox(height: 20),

                  // Section: Open App To Target
                  Text(
                    'STARTUP LAUNCH TARGET',
                    style: EtoleTypography.labelCaps(color: muted),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open App To',
                              style: EtoleTypography.bodyLarge(color: cream),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              openAppTo == OpenAppToTarget.hub
                                  ? 'The Hub (Living Shards Navigation)'
                                  : 'Digital Card (Instant Presentation)',
                              style: EtoleTypography.bodySmall(color: muted),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<OpenAppToTarget>(
                        value: openAppTo,
                        underline: const SizedBox.shrink(),
                        dropdownColor: studioTheme.surfaceCardColor,
                        items: [
                          DropdownMenuItem(
                            value: OpenAppToTarget.hub,
                            child: Text(
                              'The Hub',
                              style: TextStyle(
                                color: cream,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: OpenAppToTarget.card,
                            child: Text(
                              'Digital Card',
                              style: TextStyle(
                                color: cream,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(openAppToProvider.notifier).state = val;
                            EtoleHaptics.selection();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required StudioThemeData themeData,
    required bool isSelected,
    required StudioThemeData currentTheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? themeData.primaryAccent.withValues(alpha: 0.12)
              : currentTheme.surfaceCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? themeData.primaryAccent
                : currentTheme.dividerColor,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeData.primaryAccent.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Color Swatches Cluster Preview
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: themeData.backgroundBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeData.glassBorderColor,
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(5),
              child: Stack(
                children: [
                  // Background base half
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: themeData.backgroundGradient,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Primary Accent dot
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeData.primaryAccent,
                        boxShadow: [
                          BoxShadow(
                            color: themeData.primaryAccent.withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Secondary Accent dot
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeData.secondaryAccent,
                      ),
                    ),
                  ),
                  // Glass glint strip
                  Positioned(
                    left: 4,
                    right: 4,
                    top: 18,
                    bottom: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeData.glassBorderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Theme Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        themeData.name,
                        style:
                            EtoleTypography.bodyLarge(
                              color: currentTheme.textPrimary,
                            ).copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                      ),
                      if (themeData.id == StudioThemeId.tribalOrange) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: themeData.primaryAccent.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: TextStyle(
                              color: themeData.primaryAccent,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    themeData.subtitle,
                    style: EtoleTypography.bodySmall(
                      color: currentTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: themeData.primaryAccent,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: currentTheme.textMuted.withValues(alpha: 0.4),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
