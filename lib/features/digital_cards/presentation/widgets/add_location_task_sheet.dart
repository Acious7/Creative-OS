import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../domain/location_task_model.dart';

class AddLocationTaskSheet extends ConsumerStatefulWidget {
  final int locationId;
  final String locationName;
  final List<NetworkingLead> people;
  final int? preselectedPersonId;

  const AddLocationTaskSheet({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.people,
    this.preselectedPersonId,
  });

  static Future<LocationTaskItem?> show(
    BuildContext context, {
    required int locationId,
    required String locationName,
    required List<NetworkingLead> people,
    int? preselectedPersonId,
  }) {
    EtoleHaptics.selection();
    return showModalBottomSheet<LocationTaskItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddLocationTaskSheet(
        locationId: locationId,
        locationName: locationName,
        people: people,
        preselectedPersonId: preselectedPersonId,
      ),
    );
  }

  @override
  ConsumerState<AddLocationTaskSheet> createState() =>
      _AddLocationTaskSheetState();
}

class _AddLocationTaskSheetState extends ConsumerState<AddLocationTaskSheet> {
  final _titleCtrl = TextEditingController();
  int? _selectedPersonId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _dueTime = const TimeOfDay(hour: 10, minute: 0);
  bool _setReminder = true;

  @override
  void initState() {
    super.initState();
    _selectedPersonId = widget.preselectedPersonId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    EtoleHaptics.selection();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF59E0B),
            onPrimary: Colors.black,
            surface: Color(0xFF191D22),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    EtoleHaptics.selection();
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF59E0B),
            onPrimary: Colors.black,
            surface: Color(0xFF191D22),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    EtoleHaptics.success();
    final dueDateTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    String? personName;
    if (_selectedPersonId != null) {
      final match = widget.people
          .where((p) => p.id == _selectedPersonId)
          .firstOrNull;
      personName = match?.name;
    }

    final taskId = DateTime.now().millisecondsSinceEpoch;
    final task = LocationTaskItem(
      id: taskId.toString(),
      title: title,
      isDone: false,
      dueDate: dueDateTime,
      personId: _selectedPersonId,
      personName: personName,
      hasReminder: _setReminder,
    );

    if (_setReminder && dueDateTime.isAfter(DateTime.now())) {
      await LocalNotificationService.scheduleNetworkTaskReminder(
        taskId: taskId,
        title: 'Task Reminder: $title',
        subtitle: personName != null
            ? 'For $personName · ${widget.locationName}'
            : 'At ${widget.locationName}',
        reminderTime: dueDateTime,
      );
    }

    if (mounted) {
      Navigator.pop(context, task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(_dueDate);
    final timeStr = _dueTime.format(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: const Color(0xFA121518),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: EtoleColors.creamMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_task_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TASK & REMINDER',
                              style: EtoleTypography.labelCaps(
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            Text(
                              'Add Action Item',
                              style: EtoleTypography.h3.copyWith(
                                color: EtoleColors.cream,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
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

                // Task Target: Whole location or specific person
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15191E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedPersonId,
                      dropdownColor: const Color(0xFF1E242B),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            '📍 Whole Location: ${widget.locationName}',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...widget.people.map(
                          (p) => DropdownMenuItem<int?>(
                            value: p.id,
                            child: Text(
                              '👤 For: ${p.name}${p.organization != null ? ' (${p.organization})' : ''}',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedPersonId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Task Description
                TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Task Description *',
                    hintText: _selectedPersonId != null
                        ? 'e.g. Send rate card to Amina'
                        : 'e.g. Send meeting minutes recap',
                    labelStyle: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 13,
                    ),
                    hintStyle: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF15191E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Due Date & Time Picker Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15191E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_rounded,
                                size: 16,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15191E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.alarm_rounded,
                                size: 16,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  timeStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                CheckboxListTile(
                  value: _setReminder,
                  activeColor: const Color(0xFFF59E0B),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Set Phone Notification Reminder',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Fires native Android notification at the selected date & time',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  onChanged: (val) =>
                      setState(() => _setReminder = val ?? true),
                ),
                const SizedBox(height: 14),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _save,
                  child: const Text(
                    'Save Task & Set Reminder',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
