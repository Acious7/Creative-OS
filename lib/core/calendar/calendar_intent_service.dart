import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/etole_components.dart';

class CalendarIntentService {
  static const MethodChannel _channel = MethodChannel(
    'com.brianetole.etole/location',
  );

  /// Opens the phone calendar application pre-filled with:
  /// - title
  /// - date and time
  /// - the place as location
  /// - notes with the person's name
  /// - a 30-minute alert
  /// Requires ZERO permissions as it delegates to the user's preferred calendar app.
  static Future<bool> openAddToCalendar({
    BuildContext? context,
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String location = '',
    String notes = '',
    int alertMinutesBefore = 30,
  }) async {
    EtoleHaptics.selection();
    try {
      final beginMs = startTime.millisecondsSinceEpoch;
      final endMs = (endTime ?? startTime.add(const Duration(hours: 1)))
          .millisecondsSinceEpoch;

      final res = await _channel.invokeMethod<bool>('openCalendarIntent', {
        'title': title,
        'beginTime': beginMs,
        'endTime': endMs,
        'location': location,
        'description': notes,
        'minutesBefore': alertMinutesBefore,
      });

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E2328),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFF59E0B), width: 0.8),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Opening calendar for "$title"...',
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

      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
