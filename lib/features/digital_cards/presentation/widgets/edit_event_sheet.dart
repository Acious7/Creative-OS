import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/notifications/local_notification_service.dart';

class EditEventSheet extends ConsumerStatefulWidget {
  final NetworkingEvent event;
  final ValueChanged<NetworkingEvent>? onEventUpdated;

  const EditEventSheet({super.key, required this.event, this.onEventUpdated});

  static Future<NetworkingEvent?> show(
    BuildContext context, {
    required NetworkingEvent event,
    ValueChanged<NetworkingEvent>? onEventUpdated,
  }) {
    return showModalBottomSheet<NetworkingEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          EditEventSheet(event: event, onEventUpdated: onEventUpdated),
    );
  }

  @override
  ConsumerState<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends ConsumerState<EditEventSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _placeCtrl;
  late TextEditingController _notesCtrl;
  late String _type;
  late DateTime _date;
  late TimeOfDay _time;
  String? _coverPath;
  final ImagePicker _picker = ImagePicker();

  final List<String> _types = [
    'Event',
    'Meeting',
    'Café',
    'On set',
    'Call',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    _nameCtrl = TextEditingController(text: ev.name);
    _placeCtrl = TextEditingController(text: ev.location ?? '');
    _notesCtrl = TextEditingController(text: ev.notes ?? '');
    _type = ev.eventType;
    if (!_types.contains(_type)) {
      _types.add(_type);
    }
    _date = ev.startDate;
    _time = TimeOfDay(hour: ev.startDate.hour, minute: ev.startDate.minute);
    _coverPath = ev.coverPhotoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: EtoleColors.cyan,
            onPrimary: Colors.black,
            surface: Color(0xFF141719),
            onSurface: EtoleColors.cream,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: EtoleColors.cyan,
            onPrimary: Colors.black,
            surface: Color(0xFF141719),
            onSurface: EtoleColors.cream,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _pickCoverPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _coverPath = picked.path);
    }
  }

  Future<void> _saveEvent() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    final db = ref.read(databaseProvider);
    final startDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    await (db.update(
      db.networkingEvents,
    )..where((t) => t.id.equals(widget.event.id))).write(
      NetworkingEventsCompanion(
        name: drift.Value(name),
        startDate: drift.Value(startDateTime),
        location: drift.Value(_placeCtrl.text.trim()),
        notes: drift.Value(_notesCtrl.text.trim()),
        eventType: drift.Value(_type),
        coverPhotoPath: drift.Value(_coverPath),
      ),
    );

    // Reschedule Reminders
    if (startDateTime.isAfter(DateTime.now())) {
      final oneDayBefore = startDateTime.subtract(const Duration(days: 1));
      final twoHoursBefore = startDateTime.subtract(const Duration(hours: 2));

      await LocalNotificationService.scheduleOccasionReminder(
        occasionId: widget.event.id,
        occasionName: name,
        location: _placeCtrl.text.trim(),
        reminderTime: oneDayBefore,
      );

      await LocalNotificationService.scheduleOccasionReminder(
        occasionId: widget.event.id + 50000,
        occasionName: name,
        location: _placeCtrl.text.trim(),
        reminderTime: twoHoursBefore,
      );
    }

    final updated = widget.event.copyWith(
      name: name,
      startDate: startDateTime,
      location: drift.Value(_placeCtrl.text.trim()),
      notes: drift.Value(_notesCtrl.text.trim()),
      eventType: _type,
      coverPhotoPath: drift.Value(_coverPath),
    );

    EtoleHaptics.medium();

    if (mounted) {
      widget.onEventUpdated?.call(updated);
      Navigator.pop(context, updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated "$name"',
            style: const TextStyle(color: EtoleColors.cream),
          ),
          backgroundColor: const Color(0xFF141719),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFA141719),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: EtoleColors.cyan.withOpacity(0.4),
                width: 1.5,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: EtoleColors.creamMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Place / Event',
                      style: EtoleTypography.h2.copyWith(
                        color: EtoleColors.cream,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: EtoleColors.creamMuted,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Name
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: EtoleColors.cream),
                  decoration: const InputDecoration(
                    labelText: 'Place / Event Name *',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    prefixIcon: Icon(
                      Icons.event_outlined,
                      color: EtoleColors.cyan,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Type selection pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((t) {
                    final isSel = _type == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: isSel,
                      onSelected: (_) => setState(() => _type = t),
                      selectedColor: EtoleColors.cyan,
                      backgroundColor: const Color(0xFF1E2226),
                      labelStyle: TextStyle(
                        color: isSel
                            ? Colors.black
                            : EtoleColors.creamSecondary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSel
                            ? EtoleColors.cyan
                            : Colors.white.withOpacity(0.1),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Date & Time pickers
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EtoleColors.cream,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _pickDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: EtoleColors.cyan,
                        ),
                        label: Text(
                          DateFormat('d MMM yyyy').format(_date),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EtoleColors.cream,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _pickTime,
                        icon: const Icon(
                          Icons.access_time_outlined,
                          size: 16,
                          color: EtoleColors.cyan,
                        ),
                        label: Text(
                          _time.format(context),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Place / Venue
                TextField(
                  controller: _placeCtrl,
                  style: const TextStyle(color: EtoleColors.cream),
                  decoration: const InputDecoration(
                    labelText: 'Location / Venue',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    hintText: 'e.g. Sarit Expo Centre, Westlands',
                    hintStyle: TextStyle(
                      color: EtoleColors.creamMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: EtoleColors.creamMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cover Photo option
                Row(
                  children: [
                    if (_coverPath != null && File(_coverPath!).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_coverPath!),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: EtoleColors.creamMuted,
                          size: 22,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EtoleColors.creamSecondary,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.15),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _pickCoverPhoto,
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 16,
                          color: EtoleColors.cyan,
                        ),
                        label: Text(
                          _coverPath == null
                              ? 'Add Cover Photo'
                              : 'Change Cover Photo',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (_coverPath != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        tooltip: 'Remove cover photo',
                        onPressed: () => setState(() => _coverPath = null),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: EtoleColors.cream),
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    hintText: 'Atmosphere, goals, booth number...',
                    hintStyle: TextStyle(
                      color: EtoleColors.creamMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.notes_outlined,
                      color: EtoleColors.creamMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveEvent,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
