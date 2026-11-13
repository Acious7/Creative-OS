import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../domain/osm_location_service.dart';
import '../../domain/place_search_service.dart';
import 'osm_map_view.dart';
import 'real_location_picker_sheet.dart';

class AddLocationSheet extends ConsumerStatefulWidget {
  final bool isUpcoming;
  final NetworkingEvent? existingEvent;

  const AddLocationSheet({
    super.key,
    this.isUpcoming = false,
    this.existingEvent,
  });

  static Future<int?> show(
    BuildContext context, {
    bool isUpcoming = false,
    NetworkingEvent? existingEvent,
  }) {
    EtoleHaptics.selection();
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddLocationSheet(
        isUpcoming: isUpcoming,
        existingEvent: existingEvent,
      ),
    );
  }

  @override
  ConsumerState<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends ConsumerState<AddLocationSheet> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isUpcoming;
  bool _setReminder = true;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  List<OsmPlaceDetail> _quickVenues = [];

  @override
  void initState() {
    super.initState();
    final ev = widget.existingEvent;
    if (ev != null) {
      _nameCtrl.text = ev.name;
      _addressCtrl.text = ev.location ?? '';
      _descCtrl.text = ev.description ?? '';
      _selectedDate = ev.startDate;
      _selectedTime = TimeOfDay.fromDateTime(ev.startDate);
      _isUpcoming = ev.occasionType == 'upcoming';
      _latitude = ev.latitude;
      _longitude = ev.longitude;
    } else {
      _isUpcoming = widget.isUpcoming;
      final now = DateTime.now();
      if (_isUpcoming) {
        _selectedDate = now.add(const Duration(days: 1));
        _selectedTime = const TimeOfDay(hour: 10, minute: 0);
      } else {
        _selectedDate = now;
        _selectedTime = TimeOfDay.fromDateTime(now);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    EtoleHaptics.selection();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    EtoleHaptics.selection();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = picked);
    }
  }

  /// Direct "Use My Location" GPS action
  Future<void> _useMyLocation() async {
    EtoleHaptics.selection();
    setState(() => _isLocating = true);

    final coords = await OsmLocationService.getCurrentCoordinates();
    if (coords != null && mounted) {
      final lat = coords['latitude']!;
      final lon = coords['longitude']!;

      final place = await OsmLocationService.reverseGeocode(lat, lon);
      final nearby = await OsmLocationService.getNearbyVenues(
        lat,
        lon,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _isLocating = false;
          _latitude = lat;
          _longitude = lon;
          _quickVenues = nearby;

          if (place != null) {
            _nameCtrl.text = place.name;
            _addressCtrl.text = place.address;
          } else if (nearby.isNotEmpty) {
            _nameCtrl.text = nearby.first.name;
            _addressCtrl.text = nearby.first.address;
          }
        });

        EtoleHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location found: ${_nameCtrl.text.isNotEmpty ? _nameCtrl.text : "Coordinates acquired"}',
            ),
            backgroundColor: const Color(0xFFF59E0B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (mounted) {
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not acquire GPS position. You can pick from map or type manually.',
          ),
          backgroundColor: Color(0xFFE57B22),
        ),
      );
    }
  }

  Future<void> _pickRealLocation() async {
    EtoleHaptics.selection();
    final place = await showModalBottomSheet<PlaceSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RealLocationPickerSheet(
        initialQuery: _nameCtrl.text.isNotEmpty
            ? _nameCtrl.text
            : _addressCtrl.text,
        initialLatitude: _latitude,
        initialLongitude: _longitude,
      ),
    );

    if (place != null) {
      setState(() {
        _nameCtrl.text = place.name;
        _addressCtrl.text = place.address;
        _latitude = place.latitude;
        _longitude = place.longitude;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    EtoleHaptics.success();
    final db = ref.read(databaseProvider);
    final brand = await db.select(db.brands).getSingleOrNull();
    final brandId = brand?.id ?? 1;

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    int eventId;

    if (widget.existingEvent != null) {
      // Edit existing location
      eventId = widget.existingEvent!.id;
      await (db.update(
        db.networkingEvents,
      )..where((t) => t.id.equals(eventId))).write(
        NetworkingEventsCompanion(
          name: drift.Value(name),
          startDate: drift.Value(combinedDateTime),
          location: drift.Value(
            _addressCtrl.text.trim().isNotEmpty
                ? _addressCtrl.text.trim()
                : null,
          ),
          description: drift.Value(
            _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
          ),
          latitude: drift.Value(_latitude),
          longitude: drift.Value(_longitude),
        ),
      );
    } else {
      // Add new location
      eventId = await db
          .into(db.networkingEvents)
          .insert(
            NetworkingEventsCompanion(
              brandId: drift.Value(brandId),
              name: drift.Value(name),
              startDate: drift.Value(combinedDateTime),
              location: drift.Value(
                _addressCtrl.text.trim().isNotEmpty
                    ? _addressCtrl.text.trim()
                    : null,
              ),
              description: drift.Value(
                _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
              ),
              occasionType: drift.Value(_isUpcoming ? 'upcoming' : 'location'),
              latitude: drift.Value(_latitude),
              longitude: drift.Value(_longitude),
              isArchived: const drift.Value(false),
              isDeleted: const drift.Value(false),
            ),
          );
    }

    // Schedule reminder notification if future event
    if (_isUpcoming &&
        _setReminder &&
        combinedDateTime.isAfter(DateTime.now())) {
      final reminderTime = combinedDateTime.subtract(const Duration(hours: 2));
      await LocalNotificationService.scheduleOccasionReminder(
        occasionId: eventId,
        occasionName: name,
        location: _addressCtrl.text.trim(),
        reminderTime: reminderTime.isAfter(DateTime.now())
            ? reminderTime
            : combinedDateTime,
      );
    }

    if (mounted) {
      Navigator.pop(context, eventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(_selectedDate);
    final timeStr = _selectedTime.format(context);
    final isEditing = widget.existingEvent != null;

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
                          child: Icon(
                            isEditing
                                ? Icons.edit_location_alt_rounded
                                : (_isUpcoming
                                      ? Icons.event_available_rounded
                                      : Icons.place_rounded),
                            color: const Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? 'EDIT LOCATION'
                                  : (_isUpcoming
                                        ? 'FUTURE MEETUP / EVENT'
                                        : 'NEW MEETING LOCATION'),
                              style: EtoleTypography.labelCaps(
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            Text(
                              isEditing
                                  ? 'Update Location Details'
                                  : (_isUpcoming
                                        ? 'Plan Upcoming Occasion'
                                        : 'Where Did You Meet?'),
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

                // Toggle between Recent Meetup vs Future Event (only for new)
                if (!isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191D22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isUpcoming = false),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isUpcoming
                                    ? const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.25)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: !_isUpcoming
                                    ? Border.all(
                                        color: const Color(0xFFF59E0B),
                                        width: 1.1,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '📍 Place I Met People',
                                style: TextStyle(
                                  color: !_isUpcoming
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isUpcoming = true),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isUpcoming
                                    ? const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.25)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: _isUpcoming
                                    ? Border.all(
                                        color: const Color(0xFFF59E0B),
                                        width: 1.1,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '📅 Upcoming Event',
                                style: TextStyle(
                                  color: _isUpcoming
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // "Use My Location" + "Open Map Picker" Action Bar
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _isLocating ? null : _useMyLocation,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLocating)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFF59E0B),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.my_location_rounded,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                              const SizedBox(width: 6),
                              Text(
                                _isLocating ? 'Locating...' : 'Use My Location',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
                        onTap: _pickRealLocation,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15191E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_rounded,
                                size: 16,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Open Map (OSM)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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

                // 5 Nearest Venues Tap Strip (if populated)
                if (_quickVenues.isNotEmpty) ...[
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickVenues.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final v = _quickVenues[index];
                        final isSelected =
                            _nameCtrl.text.trim().toLowerCase() ==
                            v.name.toLowerCase();

                        return ActionChip(
                          avatar: const Icon(
                            Icons.place_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          label: Text(
                            v.name,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFFF59E0B)
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          backgroundColor: isSelected
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                              : const Color(0xFF191E25),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFF59E0B)
                                : Colors.white12,
                          ),
                          onPressed: () {
                            setState(() {
                              _nameCtrl.text = v.name;
                              _addressCtrl.text = v.address;
                              _latitude = v.latitude;
                              _longitude = v.longitude;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Small OSM Map Preview if coordinates exist
                if (_latitude != null && _longitude != null) ...[
                  OsmMapView(
                    initialLatitude: _latitude!,
                    initialLongitude: _longitude!,
                    height: 140,
                    onCoordinatesChanged: (c) {
                      setState(() {
                        _latitude = c.latitude;
                        _longitude = c.longitude;
                      });
                    },
                    onUseMyLocation: _useMyLocation,
                  ),
                  const SizedBox(height: 10),
                ],

                // Location / Event Name (manual entry always works)
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: _isUpcoming
                        ? 'Event or Meetup Name'
                        : 'Location or Meeting Name',
                    hintText: _isUpcoming
                        ? 'e.g. Kenya Film Commission Forum'
                        : 'e.g. Java House Kilimani, Film Set Karura',
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

                // Date & Time Picker Row
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
                                Icons.calendar_today_rounded,
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
                                Icons.access_time_rounded,
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

                // Address / Area
                TextField(
                  controller: _addressCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Address or Area (Optional)',
                    hintText: 'e.g. Lenana Road, Westlands, Sarit Centre',
                    labelStyle: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
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

                // Short Description
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Short Description / Context',
                    hintText: _isUpcoming ? 'What is this event about?' : 'e.g. Afternoon coffee with prospective documentary partners',
                    labelStyle: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
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

                if (_isUpcoming) ...[
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: _setReminder,
                    activeColor: const Color(0xFFF59E0B),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Set Android Notification Reminder',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Alerts you 2 hours before the scheduled time',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                    onChanged: (val) =>
                        setState(() => _setReminder = val ?? true),
                  ),
                ],

                const SizedBox(height: 18),
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
                  child: Text(
                    isEditing
                        ? 'Save Changes'
                        : (_isUpcoming
                              ? 'Save Upcoming Meetup'
                              : 'Create Location & Log Meeting'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
