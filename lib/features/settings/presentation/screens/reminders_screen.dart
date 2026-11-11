import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOled = ref.watch(isOledModeProvider);
    final leadDays = ref.watch(remindersLeadDaysProvider);
    final reminderHour = ref.watch(remindersHourProvider);
    final overdueEnabled = ref.watch(overdueRemindersEnabledProvider);

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
                        '07 · REMINDERS',
                        style: EtoleTypography.labelCaps(
                          color: EtoleColors.cyan,
                        ),
                      ),
                      Text(
                        'OCCASIONS & ALERTS',
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
                  Text(
                    'OCCASION & EVENT REMINDERS',
                    style: EtoleTypography.labelCaps(color: muted),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upcoming shoots, exhibitions, festivals, and set dates trigger automatic local notifications.',
                    style: EtoleTypography.bodySmall(color: muted),
                  ),
                  const SizedBox(height: 16),

                  // Lead Time Selector
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advance Notice',
                              style: EtoleTypography.bodyLarge(color: cream),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'How many days before the event to notify you',
                              style: EtoleTypography.bodySmall(color: muted),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<int>(
                        value: leadDays,
                        underline: const SizedBox.shrink(),
                        dropdownColor: isDark
                            ? EtoleColors.charcoal
                            : EtoleColors.warmWhite,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Same day')),
                          DropdownMenuItem(
                            value: 1,
                            child: Text('1 day before (Default)'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('2 days before'),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('3 days before'),
                          ),
                          DropdownMenuItem(
                            value: 7,
                            child: Text('1 week before'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(remindersLeadDaysProvider.notifier).state =
                                val;
                            EtoleHaptics.selection();
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const EtoleHairline(),
                  const SizedBox(height: 16),

                  // Notification Time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alert Time',
                              style: EtoleTypography.bodyLarge(color: cream),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Morning delivery time for upcoming schedule reminders',
                              style: EtoleTypography.bodySmall(color: muted),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<int>(
                        value: reminderHour,
                        underline: const SizedBox.shrink(),
                        dropdownColor: isDark
                            ? EtoleColors.charcoal
                            : EtoleColors.warmWhite,
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('07:00 AM')),
                          DropdownMenuItem(value: 8, child: Text('08:00 AM')),
                          DropdownMenuItem(
                            value: 9,
                            child: Text('09:00 AM (Default)'),
                          ),
                          DropdownMenuItem(value: 10, child: Text('10:00 AM')),
                          DropdownMenuItem(value: 12, child: Text('12:00 PM')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(remindersHourProvider.notifier).state =
                                val;
                            EtoleHaptics.selection();
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const EtoleHairline(),
                  const SizedBox(height: 24),

                  // Section: Document Follow-ups
                  Text(
                    'DOCUMENT & PROMISE FOLLOW-UPS',
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
                              'Overdue Document Warnings',
                              style: EtoleTypography.bodyLarge(color: cream),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Displays a quiet pulsing cyan dot on the Docs window pane whenever an invoice or quotation passes its due date',
                              style: EtoleTypography.bodySmall(color: muted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: overdueEnabled,
                        activeThumbColor: EtoleColors.cyan,
                        activeTrackColor: EtoleColors.cyan.withValues(
                          alpha: 0.35,
                        ),
                        onChanged: (val) {
                          ref
                                  .read(
                                    overdueRemindersEnabledProvider.notifier,
                                  )
                                  .state =
                              val;
                          EtoleHaptics.light();
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
}
