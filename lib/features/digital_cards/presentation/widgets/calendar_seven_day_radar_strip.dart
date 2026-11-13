import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/calendar/calendar_models.dart';
import '../../../../core/calendar/calendar_sync_service.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/theme/studio_theme_provider.dart';
import '../../../settings/presentation/screens/calendar_settings_screen.dart';

class CalendarSevenDayRadarStrip extends ConsumerStatefulWidget {
  const CalendarSevenDayRadarStrip({super.key});

  @override
  ConsumerState<CalendarSevenDayRadarStrip> createState() =>
      _CalendarSevenDayRadarStripState();
}

class _CalendarSevenDayRadarStripState
    extends ConsumerState<CalendarSevenDayRadarStrip> {
  bool _isLoading = true;
  bool _hasPermission = false;
  List<DeviceCalendarEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final hasPerm = await CalendarSyncService.checkPermission();
    if (!hasPerm) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
      return;
    }

    final evs = await CalendarSyncService.getUpcomingEvents(days: 7);
    if (mounted) {
      setState(() {
        _hasPermission = true;
        _events = evs;
        _isLoading = false;
      });
    }
  }

  void _showDayEventsSheet(DateTime day, List<DeviceCalendarEvent> dayEvents) {
    EtoleHaptics.selection();
    final timeFmt = DateFormat('h:mm a');
    final dayFmt = DateFormat('EEEE, MMMM d');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14181D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayFmt.format(day).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF38B6DB),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Device Calendar Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: dayEvents.isEmpty
                          ? const Color(0xFF007A3D).withValues(alpha: 0.2)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dayEvents.isEmpty
                          ? 'FREE / OPEN'
                          : '${dayEvents.length} BOOKED',
                      style: TextStyle(
                        color: dayEvents.isEmpty
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (dayEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        color: Color(0xFF10B981),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No conflicting events on this day',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Perfect slot to schedule meetings & film shoots.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...dayEvents.map(
                  (ev) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2026),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF38B6DB).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF38B6DB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    ev.allDay
                                        ? 'All Day'
                                        : '${timeFmt.format(ev.startTime)} - ${timeFmt.format(ev.endTime)}',
                                    style: const TextStyle(
                                      color: Color(0xFF38B6DB),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (ev.location.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ev.location,
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final accent = studioTheme.accentColor;

    if (_isLoading) {
      return Container(
        height: 100,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF38B6DB),
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF14181D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF38B6DB).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF38B6DB).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF38B6DB),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7-DAY SCHEDULE RADAR',
                    style: TextStyle(
                      color: Color(0xFF38B6DB),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Connect calendar to preview your next 7 days and avoid double-booking.',
                    style: TextStyle(color: Colors.white, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                EtoleHaptics.selection();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CalendarSettingsScreen(),
                  ),
                ).then((_) => _loadEvents());
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF38B6DB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.add(Duration(days: i)));
    final timeFmt = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.radar_rounded,
                    size: 14,
                    color: Color(0xFF38B6DB),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '7-DAY CALENDAR RADAR (READ-ONLY)',
                    style: TextStyle(
                      color: Color(0xFF38B6DB),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _loadEvents,
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = days[index];
                final isToday = index == 0;
                final dayEvents = _events.where((ev) {
                  final evDate = DateTime(
                    ev.startTime.year,
                    ev.startTime.month,
                    ev.startTime.day,
                  );
                  return evDate.isAtSameMomentAs(day);
                }).toList();

                final hasEvents = dayEvents.isNotEmpty;

                return InkWell(
                  onTap: () => _showDayEventsSheet(day, dayEvents),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF1A222C)
                          : const Color(0xFF14181D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? const Color(0xFF38B6DB).withValues(alpha: 0.6)
                            : (hasEvents
                                  ? const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.08)),
                        width: isToday ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isToday
                                  ? 'TODAY'
                                  : DateFormat('E').format(day).toUpperCase(),
                              style: TextStyle(
                                color: isToday
                                    ? const Color(0xFF38B6DB)
                                    : const Color(0xFF94A3B8),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasEvents
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d MMM').format(day),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (!hasEvents)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007A3D)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Free / Open',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dayEvents.length} booked',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dayEvents.first.allDay
                                    ? dayEvents.first.title
                                    : '${timeFmt.format(dayEvents.first.startTime)} ${dayEvents.first.title}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
