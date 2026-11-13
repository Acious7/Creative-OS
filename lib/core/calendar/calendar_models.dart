import 'package:flutter/material.dart';

class DeviceCalendar {
  final String id;
  final String name;
  final String accountName;
  final int colorValue;
  final bool isPrimary;

  const DeviceCalendar({
    required this.id,
    required this.name,
    required this.accountName,
    this.colorValue = 0,
    this.isPrimary = false,
  });

  Color get displayColor {
    if (colorValue != 0) {
      return Color(colorValue | 0xFF000000);
    }
    return const Color(0xFFF59E0B);
  }

  factory DeviceCalendar.fromMap(Map<dynamic, dynamic> map) {
    return DeviceCalendar(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed Calendar',
      accountName: map['accountName']?.toString() ?? '',
      colorValue: (map['color'] as num?)?.toInt() ?? 0,
      isPrimary: map['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'accountName': accountName,
      'color': colorValue,
      'isPrimary': isPrimary,
    };
  }
}

class DeviceCalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final bool allDay;

  const DeviceCalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.allDay = false,
  });

  factory DeviceCalendarEvent.fromMap(Map<dynamic, dynamic> map) {
    final startMs = (map['startTime'] as num?)?.toInt() ?? 0;
    final endMs = (map['endTime'] as num?)?.toInt() ?? 0;
    return DeviceCalendarEvent(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Event',
      startTime: DateTime.fromMillisecondsSinceEpoch(startMs),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        endMs > 0 ? endMs : startMs + 3600000,
      ),
      location: map['location']?.toString() ?? '',
      allDay: map['allDay'] == true,
    );
  }
}
