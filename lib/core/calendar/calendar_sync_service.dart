import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../design_system/etole_components.dart';
import 'calendar_intent_service.dart';
import 'calendar_models.dart';

class CalendarSyncService {
  static const MethodChannel _channel = MethodChannel(
    'com.brianetole.etole/location',
  );
  static const _storage = FlutterSecureStorage();

  static const String _keySyncEnabled = 'cal_sync_enabled';
  static const String _keySelectedId = 'cal_selected_id';
  static const String _keySelectedName = 'cal_selected_name';
  static const String _keySelectedAccount = 'cal_selected_account';
  static const String _keySelectedColor = 'cal_selected_color';
  static const String _eventMapPrefix = 'cal_event_map_';

  /// Check whether READ_CALENDAR and WRITE_CALENDAR are granted.
  static Future<bool> checkPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkCalendarPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request runtime permission for Calendar.
  static Future<bool> requestPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>(
        'requestCalendarPermission',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if user has opted into Direct Calendar Sync.
  static Future<bool> isDirectSyncEnabled() async {
    final val = await _storage.read(key: _keySyncEnabled);
    return val == 'true';
  }

  /// Set user preference for Direct Calendar Sync.
  static Future<void> setDirectSyncEnabled(bool enabled) async {
    await _storage.write(key: _keySyncEnabled, value: enabled.toString());
  }

  /// Get currently selected DeviceCalendar, or null if none saved.
  static Future<DeviceCalendar?> getSelectedCalendar() async {
    final id = await _storage.read(key: _keySelectedId);
    if (id == null || id.isEmpty) return null;
    final name = await _storage.read(key: _keySelectedName) ?? 'Calendar $id';
    final account = await _storage.read(key: _keySelectedAccount) ?? '';
    final colorStr = await _storage.read(key: _keySelectedColor);
    final colorVal = int.tryParse(colorStr ?? '0') ?? 0;

    return DeviceCalendar(
      id: id,
      name: name,
      accountName: account,
      colorValue: colorVal,
    );
  }

  /// Save selected calendar for direct syncing.
  static Future<void> setSelectedCalendar(DeviceCalendar cal) async {
    await _storage.write(key: _keySelectedId, value: cal.id);
    await _storage.write(key: _keySelectedName, value: cal.name);
    await _storage.write(key: _keySelectedAccount, value: cal.accountName);
    await _storage.write(
      key: _keySelectedColor,
      value: cal.colorValue.toString(),
    );
  }

  /// Fetch all available calendars from device.
  static Future<List<DeviceCalendar>> getAvailableCalendars() async {
    try {
      final res = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'getCalendars',
      );
      if (res == null) return [];
      return res.map((m) => DeviceCalendar.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Synchronize or update an event directly in the user's selected calendar.
  /// If direct sync is disabled or permission denied, falls back seamlessly to Intent (Part 4A).
  static Future<bool> syncOrUpdateReminder({
    required String key,
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String location = '',
    String notes = '',
    int alertMinutesBefore = 30,
    BuildContext? context,
  }) async {
    EtoleHaptics.selection();

    final directEnabled = await isDirectSyncEnabled();
    final hasPerm = await checkPermission();
    final selectedCal = await getSelectedCalendar();

    // Fall back to Part 4A Intent if direct sync not active or permission missing
    if (!directEnabled || !hasPerm || selectedCal == null) {
      return CalendarIntentService.openAddToCalendar(
        context: context,
        title: title,
        startTime: startTime,
        endTime: endTime,
        location: location,
        notes: notes,
        alertMinutesBefore: alertMinutesBefore,
      );
    }

    try {
      final existingEventId = await _storage.read(key: '$_eventMapPrefix$key');
      final beginMs = startTime.millisecondsSinceEpoch;
      final endMs = (endTime ?? startTime.add(const Duration(hours: 1)))
          .millisecondsSinceEpoch;

      if (existingEventId != null && existingEventId.isNotEmpty) {
        // Attempt update of existing calendar event
        final updated = await _channel.invokeMethod<bool>('updateDirectEvent', {
          'eventId': existingEventId,
          'title': title,
          'beginTime': beginMs,
          'endTime': endMs,
          'location': location,
          'description': notes,
        });

        if (updated == true) {
          _showToast(context, 'Updated on calendar (${selectedCal.name})');
          return true;
        }
      }

      // Create new event in selected calendar
      final newEventId = await _channel.invokeMethod<String>(
        'createDirectEvent',
        {
          'calendarId': selectedCal.id,
          'title': title,
          'beginTime': beginMs,
          'endTime': endMs,
          'location': location,
          'description': notes,
          'minutesBefore': alertMinutesBefore,
        },
      );

      if (newEventId != null && newEventId.isNotEmpty) {
        await _storage.write(
          key: '$_eventMapPrefix$key',
          value: newEventId.toString(),
        );
        _showToast(context, 'Saved to calendar (${selectedCal.name})');
        return true;
      }

      return false;
    } catch (_) {
      // In case of any direct provider failure, fall back to Intent
      return CalendarIntentService.openAddToCalendar(
        context: context,
        title: title,
        startTime: startTime,
        endTime: endTime,
        location: location,
        notes: notes,
        alertMinutesBefore: alertMinutesBefore,
      );
    }
  }

  /// Remove calendar event when a reminder is deleted in the app.
  static Future<bool> deleteReminder({required String key}) async {
    try {
      final existingEventId = await _storage.read(key: '$_eventMapPrefix$key');
      if (existingEventId == null || existingEventId.isEmpty) return false;

      final deleted = await _channel.invokeMethod<bool>('deleteDirectEvent', {
        'eventId': existingEventId,
      });

      await _storage.delete(key: '$_eventMapPrefix$key');
      return deleted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve upcoming events for the next [days] days (default 7)
  static Future<List<DeviceCalendarEvent>> getUpcomingEvents({
    int days = 7,
  }) async {
    final hasPerm = await checkPermission();
    if (!hasPerm) return [];

    try {
      final res = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'getUpcomingCalendarEvents',
        {'days': days},
      );
      if (res == null) return [];
      return res.map((m) => DeviceCalendarEvent.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  static void _showToast(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E2328),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF38B6DB), width: 0.8),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF38B6DB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
