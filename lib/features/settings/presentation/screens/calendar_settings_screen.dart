import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calendar/calendar_models.dart';
import '../../../../core/calendar/calendar_sync_service.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/studio_theme_provider.dart';

class CalendarSettingsScreen extends ConsumerStatefulWidget {
  const CalendarSettingsScreen({super.key});

  @override
  ConsumerState<CalendarSettingsScreen> createState() =>
      _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState
    extends ConsumerState<CalendarSettingsScreen> {
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _directSyncEnabled = false;
  DeviceCalendar? _selectedCalendar;
  List<DeviceCalendar> _availableCalendars = [];

  @override
  void initState() {
    super.initState();
    _loadCalendarSettings();
  }

  Future<void> _loadCalendarSettings() async {
    setState(() => _isLoading = true);
    final hasPerm = await CalendarSyncService.checkPermission();
    final directEnabled = await CalendarSyncService.isDirectSyncEnabled();
    final selectedCal = await CalendarSyncService.getSelectedCalendar();

    List<DeviceCalendar> calendars = [];
    if (hasPerm) {
      calendars = await CalendarSyncService.getAvailableCalendars();
    }

    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
        _directSyncEnabled = directEnabled;
        _availableCalendars = calendars;
        _selectedCalendar =
            selectedCal ??
            (calendars.isNotEmpty
                ? (calendars.where((c) => c.isPrimary).firstOrNull ??
                      calendars.first)
                : null);
        _isLoading = false;
      });

      if (selectedCal == null && _selectedCalendar != null) {
        await CalendarSyncService.setSelectedCalendar(_selectedCalendar!);
      }
    }
  }

  Future<void> _requestAccess() async {
    EtoleHaptics.selection();
    final granted = await CalendarSyncService.requestPermission();
    if (granted) {
      await _loadCalendarSettings();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E2328),
            content: const Text(
              'Calendar access denied. App will continue using quick calendar launches.',
              style: TextStyle(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleDirectSync(bool enabled) async {
    EtoleHaptics.selection();
    if (enabled && !_hasPermission) {
      final granted = await CalendarSyncService.requestPermission();
      if (!granted) {
        return;
      }
      _hasPermission = true;
      _availableCalendars = await CalendarSyncService.getAvailableCalendars();
      if (_selectedCalendar == null && _availableCalendars.isNotEmpty) {
        _selectedCalendar =
            _availableCalendars.where((c) => c.isPrimary).firstOrNull ??
            _availableCalendars.first;
        await CalendarSyncService.setSelectedCalendar(_selectedCalendar!);
      }
    }

    await CalendarSyncService.setDirectSyncEnabled(enabled);
    setState(() => _directSyncEnabled = enabled);
  }

  Future<void> _selectCalendar(DeviceCalendar cal) async {
    EtoleHaptics.selection();
    await CalendarSyncService.setSelectedCalendar(cal);
    setState(() => _selectedCalendar = cal);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E2328),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF38B6DB), width: 0.8),
          ),
          content: Text(
            'Syncing directly with: ${cal.name}',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final accent = studioTheme.accentColor;

    return Scaffold(
      backgroundColor: studioTheme.scaffoldBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      EtoleHaptics.selection();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CALENDAR & RADAR',
                          style: EtoleTypography.h2.copyWith(
                            color: EtoleColors.cream,
                            letterSpacing: 2.0,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Direct synchronization & schedule radar',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF38B6DB)),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    // Overview Glass Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: studioTheme.surfaceCardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.28),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Direct Device Calendar Sync',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _hasPermission
                                      ? 'Connected to phone calendar. Reminders sync without leaving the app.'
                                      : 'Grant permission to create & manage events directly in your calendar.',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Permission & Toggle Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14181D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Direct Sync (No App Launch)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Write reminders silently into your calendar and sync updates',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _directSyncEnabled,
                                activeColor: accent,
                                onChanged: _toggleDirectSync,
                              ),
                            ],
                          ),
                          if (!_hasPermission) ...[
                            const Divider(height: 24, color: Colors.white10),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Calendar permission is required for background sync & 7-day radar strip.',
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _requestAccess,
                                  child: const Text(
                                    'Allow Access',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section: Available Calendars
                    const Text(
                      'SELECT SYNC DESTINATION',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (!_hasPermission)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14181D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Allow calendar access above to select your target calendar (Personal, Work, iCloud, Google).',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else if (_availableCalendars.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14181D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'No calendars found on this device.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._availableCalendars.map((cal) {
                        final isSelected = _selectedCalendar?.id == cal.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14181D),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cal.displayColor,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  cal.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13.5,
                                  ),
                                ),
                                if (cal.isPrimary) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'PRIMARY',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              cal.accountName.isNotEmpty
                                  ? cal.accountName
                                  : 'Local Calendar',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: accent,
                                    size: 20,
                                  )
                                : const Icon(
                                    Icons.circle_outlined,
                                    color: Colors.white24,
                                    size: 20,
                                  ),
                            onTap: () => _selectCalendar(cal),
                          ),
                        );
                      }),

                    const SizedBox(height: 20),

                    // Fallback notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2026),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF38B6DB)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFF38B6DB),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'When Direct Sync is off or permission is not granted, Etole Studio seamlessly opens your phone calendar with all event details pre-filled.',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
