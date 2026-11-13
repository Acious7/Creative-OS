import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/calendar/calendar_intent_service.dart';
import '../../../../core/calendar/calendar_sync_service.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../documents/presentation/screens/document_editor_screen.dart';
import '../../domain/location_task_model.dart';
import '../widgets/add_location_sheet.dart';
import '../widgets/add_location_task_sheet.dart';
import '../widgets/add_person_to_location_sheet.dart';
import '../widgets/osm_map_view.dart';
import '../widgets/scan_business_card_sheet.dart';

class LocationDetailScreen extends ConsumerStatefulWidget {
  final int locationId;

  const LocationDetailScreen({super.key, required this.locationId});

  @override
  ConsumerState<LocationDetailScreen> createState() =>
      _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  static final _dateFormat = DateFormat('EEEE, MMM d, yyyy • h:mm a');

  void _editLocation(NetworkingEvent event) {
    EtoleHaptics.selection();
    AddLocationSheet.show(context, existingEvent: event);
  }

  Future<void> _archiveToggle(NetworkingEvent event) async {
    EtoleHaptics.selection();
    final db = ref.read(databaseProvider);
    final nextState = !event.isArchived;

    await (db.update(db.networkingEvents)..where((t) => t.id.equals(event.id)))
        .write(NetworkingEventsCompanion(isArchived: drift.Value(nextState)));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState
                ? 'Location moved to Archive.'
                : 'Location restored to Active.',
          ),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
    }
  }

  Future<void> _deleteLocation(NetworkingEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171B),
        title: const Text(
          'Delete Location?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "${event.name}" and all records from your locations?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await (db.update(db.networkingEvents)
            ..where((t) => t.id.equals(event.id)))
          .write(const NetworkingEventsCompanion(isDeleted: drift.Value(true)));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${event.name} deleted.')));
      }
    }
  }

  void _showEditMeetingNotesModal(NetworkingEvent event) {
    EtoleHaptics.selection();
    final notesCtrl = TextEditingController(text: event.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: const Color(0xFA121518),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
              Text(
                'Meeting Notes · ${event.name}',
                style: EtoleTypography.h2.copyWith(
                  color: EtoleColors.cream,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 6,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Write down key discussion points, ideas, agreements, or takeaways from this meeting...',
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
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await (db.update(
                    db.networkingEvents,
                  )..where((t) => t.id.equals(event.id))).write(
                    NetworkingEventsCompanion(
                      notes: drift.Value(notesCtrl.text.trim()),
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text(
                  'Save Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPersonNotesModal(NetworkingLead person) {
    EtoleHaptics.selection();
    final notesCtrl = TextEditingController(text: person.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: const Color(0xFA121518),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
              Text(
                'Personal Note for ${person.name}',
                style: EtoleTypography.h2.copyWith(
                  color: EtoleColors.cream,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 4,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'e.g. Prefers WhatsApp communication. Wants to review budget next week...',
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
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await (db.update(
                    db.networkingLeads,
                  )..where((t) => t.id.equals(person.id))).write(
                    NetworkingLeadsCompanion(
                      notes: drift.Value(notesCtrl.text.trim()),
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text(
                  'Save Note',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LocationTaskItem> _parseTasks(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => LocationTaskItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveTasks(
    NetworkingEvent event,
    List<LocationTaskItem> tasks,
  ) async {
    final db = ref.read(databaseProvider);
    final jsonStr = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await (db.update(
      db.networkingEvents,
    )..where((t) => t.id.equals(event.id))).write(
      NetworkingEventsCompanion(ticketsPhotosJson: drift.Value(jsonStr)),
    );
  }

  Future<void> _launchWhatsApp(String phone, String text) async {
    EtoleHaptics.selection();
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
      'https://wa.me/$clean?text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message copied to clipboard!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return StreamBuilder<NetworkingEvent>(
      stream: (db.select(
        db.networkingEvents,
      )..where((t) => t.id.equals(widget.locationId))).watchSingle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF080B0F),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
            ),
          );
        }

        final event = snapshot.data!;
        final tasks = _parseTasks(event.ticketsPhotosJson);

        return Scaffold(
          backgroundColor: const Color(0xFF080B0F),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Top Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCATION & MEETING',
                                style: EtoleTypography.labelCaps(
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              Text(
                                event.name,
                                style: EtoleTypography.subheading(
                                  color: Colors.white,
                                ).copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_location_alt_outlined,
                              color: Color(0xFFF59E0B),
                            ),
                            tooltip: 'Edit Location',
                            onPressed: () => _editLocation(event),
                          ),
                          IconButton(
                            icon: Icon(
                              event.isArchived
                                  ? Icons.unarchive_rounded
                                  : Icons.archive_outlined,
                              color: const Color(0xFFF59E0B),
                            ),
                            tooltip: event.isArchived ? 'Unarchive' : 'Archive',
                            onPressed: () => _archiveToggle(event),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                            ),
                            tooltip: 'Delete Location',
                            onPressed: () => _deleteLocation(event),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const EtoleHairline(),

                // 2. Main Scrollable Content
                Expanded(
                  child: StreamBuilder<List<NetworkingLead>>(
                    stream:
                        (db.select(db.networkingLeads)..where(
                              (t) =>
                                  t.eventId.equals(event.id) &
                                  t.isDeleted.equals(false),
                            ))
                            .watch(),
                    builder: (context, peopleSnapshot) {
                      final people = peopleSnapshot.data ?? [];

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                        children: [
                          // Location Summary Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14181D),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.35),
                                width: 1.1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (event.isArchived)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF64748B)
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'ARCHIVED',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _dateFormat.format(event.startDate),
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (event.location != null &&
                                    event.location!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.place_outlined,
                                        size: 14,
                                        color: Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          event.location!,
                                          style: const TextStyle(
                                            color: Color(0xFFCBD5E1),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Small OSM Map on Location Page (Rule: "On the location page show a small map and an 'Open in Google Maps' button")
                                  if (event.latitude != null &&
                                      event.longitude != null) ...[
                                    const SizedBox(height: 10),
                                    OsmMapView(
                                      initialLatitude: event.latitude!,
                                      initialLongitude: event.longitude!,
                                      height: 155,
                                      isInteractive: false,
                                    ),
                                    const SizedBox(height: 8),
                                  ] else ...[
                                    const SizedBox(height: 8),
                                  ],
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          final url =
                                              (event.latitude != null &&
                                                  event.longitude != null)
                                              ? Uri.parse(
                                                  'https://www.google.com/maps/search/?api=1&query=${event.latitude},${event.longitude}',
                                                )
                                              : Uri.parse(
                                                  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("${event.name}, ${event.location ?? ''}")}',
                                                );
                                          launchUrl(
                                            url,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFF59E0B)
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.map_rounded,
                                                size: 14,
                                                color: Color(0xFFF59E0B),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Open in Google Maps',
                                                style: TextStyle(
                                                  color: Color(0xFFF59E0B),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (event.latitude == null ||
                                          event.longitude == null)
                                        InkWell(
                                          onTap: () => _editLocation(event),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E252F),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.white12,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .add_location_alt_rounded,
                                                  size: 13,
                                                  color: Colors.white70,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Pin on Map',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      InkWell(
                                        onTap: () {
                                          CalendarSyncService.syncOrUpdateReminder(
                                            context: context,
                                            key: 'location_${event.id}',
                                            title: event.name,
                                            startTime: event.startDate,
                                            endTime: event.endDate,
                                            location:
                                                [event.name, event.location]
                                                    .where(
                                                      (s) =>
                                                          s != null &&
                                                          s.isNotEmpty,
                                                    )
                                                    .toSet()
                                                    .join(' - '),
                                            notes: [
                                              if (event.notes != null &&
                                                  event.notes!.isNotEmpty)
                                                event.notes,
                                              if (event.description != null &&
                                                  event.description!.isNotEmpty)
                                                event.description,
                                            ].join("\n\n"),
                                            alertMinutesBefore: 30,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF38B6DB)
                                                .withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF38B6DB)
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 13,
                                                color: Color(0xFF38B6DB),
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                'Add to Calendar',
                                                style: TextStyle(
                                                  color: Color(0xFF38B6DB),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (event.description != null &&
                                    event.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    event.description!,
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Section 1: Whole Meeting Notes
                          _buildSectionHeader(
                            title: 'MEETING NOTES',
                            actionLabel:
                                event.notes != null && event.notes!.isNotEmpty
                                ? 'Edit'
                                : '+ Write Notes',
                            onAction: () => _showEditMeetingNotesModal(event),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14181D),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child:
                                event.notes != null && event.notes!.isNotEmpty
                                ? SelectableText(
                                    event.notes!,
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  )
                                : InkWell(
                                    onTap: () =>
                                        _showEditMeetingNotesModal(event),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.edit_note_rounded,
                                          color: Color(0xFFF59E0B),
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Tap to jot down notes for this meeting...',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),

                          // Section 2: People I Met Here
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PEOPLE I MET HERE (${people.length})',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Row(
                                children: [
                                  // Rule: In a Network location, add "Scan card" next to "Add person"
                                  InkWell(
                                    onTap: () => ScanBusinessCardSheet.show(
                                      context,
                                      locationId: event.id,
                                      locationName: event.name,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.document_scanner_rounded,
                                            size: 13,
                                            color: Color(0xFFF59E0B),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Scan card',
                                            style: TextStyle(
                                              color: Color(0xFFF59E0B),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => AddPersonToLocationSheet.show(
                                      context,
                                      locationId: event.id,
                                      locationName: event.name,
                                    ),
                                    child: const Text(
                                      '+ Add person',
                                      style: TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (people.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14181D),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.people_outline_rounded,
                                      size: 32,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'No people added yet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Log who you connected with at this location.',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFF59E0B,
                                            ),
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () =>
                                              ScanBusinessCardSheet.show(
                                                context,
                                                locationId: event.id,
                                                locationName: event.name,
                                              ),
                                          icon: const Icon(
                                            Icons.document_scanner_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Scan Card',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            side: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () =>
                                              AddPersonToLocationSheet.show(
                                                context,
                                                locationId: event.id,
                                                locationName: event.name,
                                              ),
                                          icon: const Icon(
                                            Icons.add_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Manual Entry',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...people.map(
                              (person) =>
                                  _buildPersonCard(person, event, people),
                            ),
                          const SizedBox(height: 20),

                          // Section 3: Tasks and Reminders
                          _buildSectionHeader(
                            title:
                                'TASKS & REMINDERS (${tasks.where((t) => !t.isDone).length} OPEN)',
                            actionLabel: '+ Add Task',
                            onAction: () async {
                              final newTask = await AddLocationTaskSheet.show(
                                context,
                                locationId: event.id,
                                locationName: event.name,
                                people: people,
                              );
                              if (newTask != null) {
                                final updated = [...tasks, newTask];
                                await _saveTasks(event, updated);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          if (tasks.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14181D),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  final newTask =
                                      await AddLocationTaskSheet.show(
                                        context,
                                        locationId: event.id,
                                        locationName: event.name,
                                        people: people,
                                      );
                                  if (newTask != null) {
                                    final updated = [...tasks, newTask];
                                    await _saveTasks(event, updated);
                                  }
                                },
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add_task_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add a task or reminder (e.g. "Send rate card to Amina")...',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...tasks.map(
                              (task) => _buildTaskTile(task, event, tasks),
                            ),
                          const SizedBox(height: 20),

                          // Section 4: Smart Follow-Up Suggestions
                          if (people.isNotEmpty) ...[
                            _buildSectionHeader(
                              title: 'SUGGESTED FOLLOW-UP STEPS',
                              actionLabel: '',
                              onAction: () {},
                            ),
                            const SizedBox(height: 8),
                            _buildSmartFollowUpSuggestions(event, people),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        if (actionLabel.isNotEmpty)
          InkWell(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonCard(
    NetworkingLead person,
    NetworkingEvent event,
    List<NetworkingLead> allPeople,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14181D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                child: Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (person.title != null ||
                        person.organization != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          person.title,
                          person.organization,
                        ].where((e) => e != null && e.isNotEmpty).join(' • '),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Communication Quick Actions
              if (person.phone != null && person.phone!.isNotEmpty) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF25D366),
                    size: 18,
                  ),
                  tooltip: 'WhatsApp',
                  onPressed: () => _launchWhatsApp(
                    person.phone!,
                    'Hi ${person.name}! Great meeting you at ${event.name}. Following up from our creative studio.',
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF60A5FA),
                    size: 18,
                  ),
                  tooltip: 'Call',
                  onPressed: () => launchUrl(Uri.parse('tel:${person.phone}')),
                ),
              ],
              if (person.email != null && person.email!.isNotEmpty)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFFFBBF24),
                    size: 18,
                  ),
                  tooltip: 'Email',
                  onPressed: () =>
                      launchUrl(Uri.parse('mailto:${person.email}')),
                ),
            ],
          ),

          if (person.cardPhotoPath != null &&
              File(person.cardPhotoPath!).existsSync()) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.black,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.file(
                              File(person.cardPhotoPath!),
                              fit: BoxFit.contain,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${person.name}\'s Business Card',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 13,
                      color: Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'View Scanned Card',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Person's Individual Notes
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2026),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    person.notes != null && person.notes!.isNotEmpty
                        ? person.notes!
                        : 'No personal note added yet.',
                    style: TextStyle(
                      color: person.notes != null && person.notes!.isNotEmpty
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  tooltip: 'Edit Note',
                  onPressed: () => _showEditPersonNotesModal(person),
                ),
              ],
            ),
          ),

          // Quick Action: Add task for this person
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 26),
              ),
              onPressed: () async {
                final tasks = _parseTasks(event.ticketsPhotosJson);
                final newTask = await AddLocationTaskSheet.show(
                  context,
                  locationId: event.id,
                  locationName: event.name,
                  people: allPeople,
                  preselectedPersonId: person.id,
                );
                if (newTask != null) {
                  final updated = [...tasks, newTask];
                  await _saveTasks(event, updated);
                }
              },
              icon: const Icon(Icons.add_task_rounded, size: 13),
              label: Text(
                'Task for ${person.name.split(' ').first}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(
    LocationTaskItem task,
    NetworkingEvent event,
    List<LocationTaskItem> allTasks,
  ) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF14181D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: CheckboxListTile(
        value: task.isDone,
        activeColor: const Color(0xFFF59E0B),
        title: Text(
          task.title,
          style: TextStyle(
            color: task.isDone ? const Color(0xFF64748B) : Colors.white,
            fontSize: 13,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (task.personName != null) ...[
              Text(
                '👤 ${task.personName!}',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (task.dueDate != null) ...[
              Icon(
                task.hasReminder ? Icons.alarm_on_rounded : Icons.event_rounded,
                size: 12,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(task.dueDate!),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
            const Spacer(),
            InkWell(
              onTap: () {
                CalendarSyncService.syncOrUpdateReminder(
                  context: context,
                  key: 'task_${task.id}',
                  title: task.title,
                  startTime:
                      task.dueDate ??
                      DateTime.now().add(const Duration(hours: 1)),
                  location: [
                    event.name,
                    event.location,
                  ].where((s) => s != null && s.isNotEmpty).toSet().join(' - '),
                  notes: task.personName != null
                      ? 'Task / reminder for ${task.personName} from ${event.name}'
                      : 'Task / reminder from ${event.name}',
                  alertMinutesBefore: 30,
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 10,
                      color: Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add to cal',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () async {
                EtoleHaptics.selection();
                final updated = allTasks.where((t) => t.id != task.id).toList();
                await _saveTasks(event, updated);
                await CalendarSyncService.deleteReminder(
                  key: 'task_${task.id}',
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 11,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
        onChanged: (val) async {
          EtoleHaptics.selection();
          final updated = allTasks.map((t) {
            if (t.id == task.id) {
              return t.copyWith(isDone: val ?? false);
            }
            return t;
          }).toList();
          await _saveTasks(event, updated);
        },
      ),
    );
  }

  Widget _buildSmartFollowUpSuggestions(
    NetworkingEvent event,
    List<NetworkingLead> people,
  ) {
    final primary = people.first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2026),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'NEXT BEST ACTIONS FOR ${primary.name.toUpperCase()}',
                style: const TextStyle(
                  color: Color(0xFFFDE68A),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Suggestion 1: Warm WhatsApp Thank-You Note
          _buildSuggestionTile(
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFF25D366),
            title: 'Send Warm Thank-You Note',
            subtitle:
                'Opens WhatsApp with a pre-written greeting referencing ${event.name}',
            onTap: () {
              final phone = primary.phone ?? '';
              final text =
                  'Hi ${primary.name}! It was great meeting you at ${event.name}. '
                  'Following up from our creative studio. Looking forward to staying in touch!';
              _launchWhatsApp(phone, text);
            },
          ),
          const SizedBox(height: 8),

          // Suggestion 2: Share Digital Card
          _buildSuggestionTile(
            icon: Icons.contactless_rounded,
            color: const Color(0xFF38B6DB),
            title: 'Share Digital Business Card & Showreel',
            subtitle: 'Shares your contact card, bio, and showreel link',
            onTap: () {
              Share.share(
                'Creative Studio · Production & Direction\n'
                'Portfolio: https://brianetole.com\n'
                'Contact: +254 718 013 579',
              );
            },
          ),
          const SizedBox(height: 8),

          // Suggestion 3: Send Quotation / Rate Card
          _buildSuggestionTile(
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Prepare Quotation / Rate Card',
            subtitle:
                'Launches quotation builder with ${primary.name} pre-filled',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DocumentEditorScreen(docType: DocType.quotation),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Suggestion 4: Schedule Follow-Up in Calendar
          _buildSuggestionTile(
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF38B6DB),
            title: 'Schedule Follow-Up in Calendar',
            subtitle:
                'Pre-fills title, ${event.name} venue, ${primary.name} in notes & 30-min alert',
            onTap: () {
              CalendarSyncService.syncOrUpdateReminder(
                context: context,
                key: 'followup_${primary.id}_${event.id}',
                title: 'Follow-up with ${primary.name}',
                startTime: DateTime.now().add(
                  const Duration(days: 2, hours: 10),
                ),
                location: [
                  event.name,
                  event.location,
                ].where((s) => s != null && s.isNotEmpty).toSet().join(' - '),
                notes:
                    'Follow-up meeting/touchpoint with ${primary.name} (${primary.title ?? ""}) met at ${event.name}.',
                alertMinutesBefore: 30,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        EtoleHaptics.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF14181D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF64748B),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
