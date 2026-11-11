import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../hub/domain/hub_models.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final isOled = ref.watch(isOledModeProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final openAppTo = ref.watch(openAppToProvider);

    final cream = isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary;
    final muted = isDark ? EtoleColors.muted : EtoleColors.lightTextMuted;

    return Scaffold(
      backgroundColor: isDark
          ? (isOled ? EtoleColors.pitchBlack : EtoleColors.obsidian)
          : EtoleColors.warmWhite,
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
                          color: EtoleColors.cyan,
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
            const EtoleHairline(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                children: [
                  // Section: Display Theme
                  Text(
                    'PALETTE & CONTRAST',
                    style: EtoleTypography.labelCaps(color: muted),
                  ),
                  const SizedBox(height: 12),
                  _buildThemeOption(
                    title: 'Cinematic Dark',
                    subtitle: 'Near-black #0A0C0D obsidian base with warm cream typography',
                    isSelected: themeMode == ThemeMode.dark && !isOled,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).state =
                          ThemeMode.dark;
                      ref.read(isOledModeProvider.notifier).state = false;
                      EtoleHaptics.light();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildThemeOption(
                    title: 'OLED Pitch Black',
                    subtitle: 'Pure #000000 black base for maximum battery saving & contrast',
                    isSelected: themeMode == ThemeMode.dark && isOled,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).state =
                          ThemeMode.dark;
                      ref.read(isOledModeProvider.notifier).state = true;
                      EtoleHaptics.light();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildThemeOption(
                    title: 'Warm Light Mode',
                    subtitle:
                        'Clean off-white editorial paper finish with dark ink',
                    isSelected: themeMode == ThemeMode.light,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).state =
                          ThemeMode.light;
                      ref.read(isOledModeProvider.notifier).state = false;
                      EtoleHaptics.light();
                    },
                    isDark: isDark,
                  ),

                  const SizedBox(height: 28),
                  const EtoleHairline(),
                  const SizedBox(height: 24),

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
                        activeThumbColor: EtoleColors.cyan,
                        activeTrackColor: EtoleColors.cyan.withValues(
                          alpha: 0.35,
                        ),
                        onChanged: (val) {
                          ref.read(reduceMotionProvider.notifier).state = val;
                          EtoleHaptics.light();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const EtoleHairline(),
                  const SizedBox(height: 24),

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
                        activeThumbColor: EtoleColors.cyan,
                        activeTrackColor: EtoleColors.cyan.withValues(
                          alpha: 0.35,
                        ),
                        onChanged: (val) {
                          ref.read(soundEnabledProvider.notifier).state = val;
                          EtoleHaptics.light();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const EtoleHairline(),
                  const SizedBox(height: 24),

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
                        dropdownColor: isDark
                            ? EtoleColors.charcoal
                            : EtoleColors.warmWhite,
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

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final cream = isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary;
    final muted = isDark ? EtoleColors.muted : EtoleColors.lightTextMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? EtoleColors.cyan.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? EtoleColors.cyan
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black12),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EtoleTypography.bodyLarge(color: cream).copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: EtoleTypography.bodySmall(color: muted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: EtoleColors.cyan,
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_off_rounded,
                color: muted.withValues(alpha: 0.5),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
