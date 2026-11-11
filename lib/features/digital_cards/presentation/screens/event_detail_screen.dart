import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/voice_memo_service.dart';
import '../providers/cards_providers.dart';
import '../widgets/add_person_sheet.dart';
import '../widgets/edit_event_sheet.dart';
import '../widgets/edit_person_sheet.dart';
import 'card_presentation_screen.dart';
import 'person_profile_screen.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isEditingNotes = false;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    VoiceMemoService.stop();
    super.dispose();
  }

  Future<void> _openMaps(String location) async {
    EtoleHaptics.light();
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _addEventPhoto(NetworkingEvent event, bool isTicket) async {
    EtoleHaptics.selection();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141719),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: EtoleColors.cyan.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: EtoleColors.cyan,
              ),
              title: Text(
                'Take Photo',
                style: EtoleTypography.bodyMedium.copyWith(
                  color: EtoleColors.cream,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: EtoleColors.cyan,
              ),
              title: Text(
                'Choose from Gallery',
                style: EtoleTypography.bodyMedium.copyWith(
                  color: EtoleColors.cream,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final db = ref.read(databaseProvider);
    if (isTicket) {
      List<String> tickets = [];
      if (event.ticketsPhotosJson != null &&
          event.ticketsPhotosJson!.isNotEmpty) {
        try {
          tickets = List<String>.from(jsonDecode(event.ticketsPhotosJson!));
        } catch (_) {}
      }
      tickets.add(picked.path);
      await (db.update(
        db.networkingEvents,
      )..where((t) => t.id.equals(event.id))).write(
        NetworkingEventsCompanion(
          ticketsPhotosJson: drift.Value(jsonEncode(tickets)),
        ),
      );
    } else {
      List<String> photos = [];
      if (event.eventPhotosJson != null && event.eventPhotosJson!.isNotEmpty) {
        try {
          photos = List<String>.from(jsonDecode(event.eventPhotosJson!));
        } catch (_) {}
      }
      photos.add(picked.path);
      await (db.update(
        db.networkingEvents,
      )..where((t) => t.id.equals(event.id))).write(
        NetworkingEventsCompanion(
          eventPhotosJson: drift.Value(jsonEncode(photos)),
        ),
      );
    }
  }

  Future<void> _saveEventNotes(NetworkingEvent event) async {
    final db = ref.read(databaseProvider);
    await (db.update(
      db.networkingEvents,
    )..where((t) => t.id.equals(event.id))).write(
      NetworkingEventsCompanion(
        notes: drift.Value(_notesController.text.trim()),
      ),
    );
    setState(() => _isEditingNotes = false);
    EtoleHaptics.light();
  }

  // Quick Action Handlers for People
  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    EtoleHaptics.selection();
    final url = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s+'), '')}');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    EtoleHaptics.selection();
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _sendEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    EtoleHaptics.selection();
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _saveToContacts(NetworkingLead lead) async {
    EtoleHaptics.selection();
    try {
      if (await FlutterContacts.requestPermission()) {
        final newContact = Contact()
          ..name.first = lead.name
          ..phones = [
            if (lead.phone != null && lead.phone!.isNotEmpty)
              Phone(lead.phone!),
          ]
          ..emails = [
            if (lead.email != null && lead.email!.isNotEmpty)
              Email(lead.email!),
          ]
          ..organizations = [
            if (lead.organization != null && lead.organization!.isNotEmpty)
              Organization(
                company: lead.organization!,
                title: lead.title ?? '',
              ),
          ];
        await newContact.insert();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saved ${lead.name} to phone contacts',
                style: const TextStyle(color: EtoleColors.cream),
              ),
              backgroundColor: const Color(0xFF141719),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save contact failed: $e')));
      }
    }
  }

  Future<void> _toggleClient(NetworkingLead lead) async {
    EtoleHaptics.selection();
    final db = ref.read(databaseProvider);
    final newStatus = !lead.isClient;

    int? clientId = lead.convertedClientId;
    if (newStatus && clientId == null) {
      clientId = await db
          .into(db.clients)
          .insert(
            ClientsCompanion(
              name: drift.Value(lead.name),
              organization: drift.Value(lead.organization),
              phone: drift.Value(lead.phone),
              email: drift.Value(lead.email),
              notes: drift.Value(lead.notes),
            ),
          );
    }

    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(lead.id))).write(
      NetworkingLeadsCompanion(
        isClient: drift.Value(newStatus),
        convertedClientId: drift.Value(clientId),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? '${lead.name} marked as Client (visible in Docs)'
                : '${lead.name} unmarked as Client',
            style: const TextStyle(color: EtoleColors.cream),
          ),
          backgroundColor: const Color(0xFF141719),
        ),
      );
    }
  }

  // Toggle promise done
  Future<void> _togglePromise(NetworkingLead lead, int index) async {
    EtoleHaptics.selection();
    List<Map<String, dynamic>> promises = [];
    if (lead.promisesJson != null && lead.promisesJson!.isNotEmpty) {
      try {
        promises = List<Map<String, dynamic>>.from(
          jsonDecode(lead.promisesJson!),
        );
      } catch (_) {}
    }
    if (index < promises.length) {
      promises[index]['isDone'] =
          !(promises[index]['isDone'] as bool? ?? false);
      final db = ref.read(databaseProvider);
      await (db.update(
        db.networkingLeads,
      )..where((t) => t.id.equals(lead.id))).write(
        NetworkingLeadsCompanion(
          promisesJson: drift.Value(jsonEncode(promises)),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  // Add promise
  Future<void> _addPromiseDialog(NetworkingLead lead) async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF141719),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: EtoleColors.cyan.withOpacity(0.3)),
          ),
          title: Text(
            'Add Promise',
            style: EtoleTypography.h3.copyWith(color: EtoleColors.cream),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(color: EtoleColors.cream),
            decoration: const InputDecoration(
              hintText: 'e.g. Send rate card by Tuesday',
              hintStyle: TextStyle(color: EtoleColors.creamMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: EtoleColors.creamMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EtoleColors.cyan,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (res != null && res.isNotEmpty) {
      List<Map<String, dynamic>> promises = [];
      if (lead.promisesJson != null && lead.promisesJson!.isNotEmpty) {
        try {
          promises = List<Map<String, dynamic>>.from(
            jsonDecode(lead.promisesJson!),
          );
        } catch (_) {}
      }
      promises.add({
        'text': res,
        'isDone': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      final db = ref.read(databaseProvider);
      await (db.update(
        db.networkingLeads,
      )..where((t) => t.id.equals(lead.id))).write(
        NetworkingLeadsCompanion(
          promisesJson: drift.Value(jsonEncode(promises)),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _deletePromise(NetworkingLead lead, int index) async {
    EtoleHaptics.selection();
    List<Map<String, dynamic>> promises = [];
    if (lead.promisesJson != null && lead.promisesJson!.isNotEmpty) {
      try {
        promises = List<Map<String, dynamic>>.from(
          jsonDecode(lead.promisesJson!),
        );
      } catch (_) {}
    }
    if (index < promises.length) {
      promises.removeAt(index);
      final db = ref.read(databaseProvider);
      await (db.update(
        db.networkingLeads,
      )..where((t) => t.id.equals(lead.id))).write(
        NetworkingLeadsCompanion(
          promisesJson: drift.Value(jsonEncode(promises)),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _confirmDeleteEvent(NetworkingEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF141719),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: EtoleColors.cyan.withOpacity(0.3)),
          ),
          title: Text(
            'Delete Place / Event?',
            style: EtoleTypography.h3.copyWith(color: EtoleColors.cream),
          ),
          content: Text(
            'Are you sure you want to delete "${event.name}"?\n\nPeople met at this event will remain in your Network, but will be unlinked from this event.',
            style: EtoleTypography.bodySmall(color: EtoleColors.creamSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: EtoleColors.creamMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete Event',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await (db.update(
        db.networkingEvents,
      )..where((t) => t.id.equals(event.id))).write(
        NetworkingEventsCompanion(
          isDeleted: const drift.Value(true),
          deletedAt: drift.Value(DateTime.now()),
        ),
      );

      EtoleHaptics.warning();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${event.name}"'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: EtoleColors.gold,
              onPressed: () async {
                await (db.update(
                  db.networkingEvents,
                )..where((t) => t.id.equals(event.id))).write(
                  const NetworkingEventsCompanion(
                    isDeleted: drift.Value(false),
                    deletedAt: drift.Value(null),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeletePerson(NetworkingLead lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF141719),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: EtoleColors.cyan.withOpacity(0.3)),
          ),
          title: Text(
            'Delete Contact?',
            style: EtoleTypography.h3.copyWith(color: EtoleColors.cream),
          ),
          content: Text(
            'Move "${lead.name}" to Trash?\nYou can restore them at any time.',
            style: EtoleTypography.bodySmall(color: EtoleColors.creamSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: EtoleColors.creamMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Move to Trash',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await (db.update(
        db.networkingLeads,
      )..where((t) => t.id.equals(lead.id))).write(
        NetworkingLeadsCompanion(
          isDeleted: const drift.Value(true),
          deletedAt: drift.Value(DateTime.now()),
        ),
      );

      EtoleHaptics.warning();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lead.name} moved to Trash'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: EtoleColors.gold,
              onPressed: () async {
                await (db.update(
                  db.networkingLeads,
                )..where((t) => t.id.equals(lead.id))).write(
                  const NetworkingLeadsCompanion(
                    isDeleted: drift.Value(false),
                    deletedAt: drift.Value(null),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _showPhotoPreviewDialog(
    String photoPath,
    VoidCallback onDelete,
  ) async {
    final file = File(photoPath);
    await showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: const Color(0xFF141719),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: EtoleColors.cyan.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: file.existsSync()
                      ? Image.file(file, height: 350, fit: BoxFit.contain)
                      : const Text(
                          'File not found',
                          style: TextStyle(color: EtoleColors.creamMuted),
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete Photo'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EtoleColors.cyan,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteGalleryPhoto(
    NetworkingEvent event,
    String photoPath,
    bool isTicket,
  ) async {
    final db = ref.read(databaseProvider);
    if (isTicket) {
      List<String> tickets = [];
      if (event.ticketsPhotosJson != null &&
          event.ticketsPhotosJson!.isNotEmpty) {
        try {
          tickets = List<String>.from(jsonDecode(event.ticketsPhotosJson!));
        } catch (_) {}
      }
      tickets.remove(photoPath);
      await (db.update(
        db.networkingEvents,
      )..where((t) => t.id.equals(event.id))).write(
        NetworkingEventsCompanion(
          ticketsPhotosJson: drift.Value(jsonEncode(tickets)),
        ),
      );
    } else {
      List<String> photos = [];
      if (event.eventPhotosJson != null && event.eventPhotosJson!.isNotEmpty) {
        try {
          photos = List<String>.from(jsonDecode(event.eventPhotosJson!));
        } catch (_) {}
      }
      photos.remove(photoPath);
      await (db.update(
        db.networkingEvents,
      )..where((t) => t.id.equals(event.id))).write(
        NetworkingEventsCompanion(
          eventPhotosJson: drift.Value(jsonEncode(photos)),
        ),
      );
    }
    EtoleHaptics.light();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo removed',
            style: TextStyle(color: EtoleColors.cream),
          ),
          backgroundColor: Color(0xFF141719),
        ),
      );
    }
  }

  Future<void> _managePersonPhotos(NetworkingLead lead, bool isFlyer) async {
    List<String> currentPhotos = [];
    final jsonStr = isFlyer ? lead.flyersPhotosJson : lead.photosWithPersonJson;
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        currentPhotos = List<String>.from(jsonDecode(jsonStr));
      } catch (_) {}
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFA141719),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: EtoleColors.cyan.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isFlyer ? 'Flyers & Cards' : 'Photos with ${lead.name}',
                        style: EtoleTypography.h3.copyWith(
                          color: EtoleColors.cream,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: EtoleColors.creamMuted,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (currentPhotos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No photos yet.',
                        textAlign: TextAlign.center,
                        style: EtoleTypography.bodySmall(
                          color: EtoleColors.creamMuted,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: currentPhotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (c, idx) {
                          final path = currentPhotos[idx];
                          final file = File(path);
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: file.existsSync()
                                    ? Image.file(
                                        file,
                                        width: 90,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 90,
                                        height: 100,
                                        color: Colors.white10,
                                      ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () async {
                                    currentPhotos.removeAt(idx);
                                    final db = ref.read(databaseProvider);
                                    if (isFlyer) {
                                      await (db.update(
                                            db.networkingLeads,
                                          )..where((t) => t.id.equals(lead.id)))
                                          .write(
                                            NetworkingLeadsCompanion(
                                              flyersPhotosJson: drift.Value(
                                                jsonEncode(currentPhotos),
                                              ),
                                              updatedAt: drift.Value(
                                                DateTime.now(),
                                              ),
                                            ),
                                          );
                                    } else {
                                      await (db.update(
                                            db.networkingLeads,
                                          )..where((t) => t.id.equals(lead.id)))
                                          .write(
                                            NetworkingLeadsCompanion(
                                              photosWithPersonJson: drift.Value(
                                                jsonEncode(currentPhotos),
                                              ),
                                              updatedAt: drift.Value(
                                                DateTime.now(),
                                              ),
                                            ),
                                          );
                                    }
                                    setSheetState(() {});
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black87,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EtoleColors.cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (isFlyer) {
                        _addFlyerPhoto(lead);
                      } else {
                        _takePhotoWithPerson(lead);
                      }
                    },
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text(
                      isFlyer
                          ? 'Add Flyer Photo'
                          : 'Take Photo with ${lead.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add Photo with Person
  Future<void> _takePhotoWithPerson(NetworkingLead lead) async {
    EtoleHaptics.selection();
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    List<String> photos = [];
    if (lead.photosWithPersonJson != null &&
        lead.photosWithPersonJson!.isNotEmpty) {
      try {
        photos = List<String>.from(jsonDecode(lead.photosWithPersonJson!));
      } catch (_) {}
    }
    photos.add(picked.path);

    final db = ref.read(databaseProvider);
    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(lead.id))).write(
      NetworkingLeadsCompanion(
        photosWithPersonJson: drift.Value(jsonEncode(photos)),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  // Voice note recording
  Future<void> _recordVoiceNote(NetworkingLead lead) async {
    if (VoiceMemoService.isRecording) {
      final memo = await VoiceMemoService.stopRecording();
      if (memo != null) {
        List<Map<String, dynamic>> memos = [];
        if (lead.voiceNotesJson != null && lead.voiceNotesJson!.isNotEmpty) {
          try {
            memos = List<Map<String, dynamic>>.from(
              jsonDecode(lead.voiceNotesJson!),
            );
          } catch (_) {}
        }
        memos.add(memo.toMap());
        final db = ref.read(databaseProvider);
        await (db.update(
          db.networkingLeads,
        )..where((t) => t.id.equals(lead.id))).write(
          NetworkingLeadsCompanion(
            voiceNotesJson: drift.Value(jsonEncode(memos)),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
        setState(() {});
      }
    } else {
      await VoiceMemoService.startRecording();
      setState(() {});
    }
  }

  // Add flyer photo
  Future<void> _addFlyerPhoto(NetworkingLead lead) async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    List<String> flyers = [];
    if (lead.flyersPhotosJson != null && lead.flyersPhotosJson!.isNotEmpty) {
      try {
        flyers = List<String>.from(jsonDecode(lead.flyersPhotosJson!));
      } catch (_) {}
    }
    flyers.add(picked.path);

    final db = ref.read(databaseProvider);
    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(lead.id))).write(
      NetworkingLeadsCompanion(
        flyersPhotosJson: drift.Value(jsonEncode(flyers)),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(singleEventProvider(widget.eventId));
    final peopleAsync = ref.watch(eventLeadsProvider(widget.eventId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0E),
      body: eventAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: EtoleColors.cyan),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: EtoleColors.cream),
          ),
        ),
        data: (event) {
          if (event == null) {
            return const Center(
              child: Text(
                'Event not found',
                style: TextStyle(color: EtoleColors.cream),
              ),
            );
          }

          if (!_isEditingNotes &&
              _notesController.text.isEmpty &&
              event.notes != null) {
            _notesController.text = event.notes!;
          }

          final people = peopleAsync.value ?? [];

          // Parse event photos
          List<String> eventPhotos = [];
          if (event.eventPhotosJson != null &&
              event.eventPhotosJson!.isNotEmpty) {
            try {
              eventPhotos = List<String>.from(
                jsonDecode(event.eventPhotosJson!),
              );
            } catch (_) {}
          }

          // Parse tickets photos
          List<String> ticketPhotos = [];
          if (event.ticketsPhotosJson != null &&
              event.ticketsPhotosJson!.isNotEmpty) {
            try {
              ticketPhotos = List<String>.from(
                jsonDecode(event.ticketsPhotosJson!),
              );
            } catch (_) {}
          }

          return CustomScrollView(
            slivers: [
              // Top App Bar
              SliverAppBar(
                backgroundColor: const Color(0xFF0A0C0E),
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: EtoleColors.cream),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Show My Card Button
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EtoleColors.cyan,
                        side: const BorderSide(color: EtoleColors.cyan),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        EtoleHaptics.medium();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CardPresentationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.nfc, size: 16),
                      label: const Text(
                        'Show my card',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: EtoleColors.cream),
                    color: const Color(0xFF1E2226),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (val) {
                      if (val == 'edit') {
                        EditEventSheet.show(context, event: event);
                      } else if (val == 'delete') {
                        _confirmDeleteEvent(event);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        height: 38,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: EtoleColors.cream,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Edit Event',
                              style: TextStyle(
                                color: EtoleColors.cream,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        height: 38,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Event',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Event Header & Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Type & Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: EtoleColors.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: EtoleColors.cyan.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              event.eventType.toUpperCase(),
                              style: EtoleTypography.labelSmall.copyWith(
                                color: EtoleColors.cyan,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEE, d MMM yyyy • h:mm a')
                                .format(event.startDate),
                            style: EtoleTypography.labelSmall.copyWith(
                              color: EtoleColors.creamMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Event Name
                      Text(
                        event.name,
                        style: EtoleTypography.h1.copyWith(
                          color: EtoleColors.cream,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Location & Open in Maps
                      if (event.location != null &&
                          event.location!.isNotEmpty) ...[
                        InkWell(
                          onTap: () => _openMaps(event.location!),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: EtoleColors.cyan,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location!,
                                  style: EtoleTypography.bodySmall(
                                    color: EtoleColors.creamSecondary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Open in Maps',
                                      style: TextStyle(
                                        color: EtoleColors.cream,
                                        fontSize: 11,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.open_in_new,
                                      size: 11,
                                      color: EtoleColors.creamMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Event Gallery & Tickets Section
                      _buildGalleryRow(
                        'Event Gallery',
                        eventPhotos,
                        () => _addEventPhoto(event, false),
                        event,
                        false,
                      ),
                      const SizedBox(height: 12),
                      _buildGalleryRow(
                        'Programme, Ticket & Badges',
                        ticketPhotos,
                        () => _addEventPhoto(event, true),
                        event,
                        true,
                      ),
                      const SizedBox(height: 16),

                      // Event Notes (Inline edit)
                      _buildNotesSection(event),
                      const SizedBox(height: 24),

                      // Hairline divider before People
                      const Divider(color: Color(0xFF22262A), height: 1),
                      const SizedBox(height: 16),

                      // Section Header: People Met
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'PEOPLE I MET HERE',
                                style: EtoleTypography.labelSmall.copyWith(
                                  color: EtoleColors.creamMuted,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: EtoleColors.cyan.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${people.length}',
                                  style: const TextStyle(
                                    color: EtoleColors.cyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: EtoleColors.cyan,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              AddPersonSheet.show(
                                context,
                                eventId: event.id,
                                eventName: event.name,
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Add person',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // People Met List
              if (people.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 40,
                            color: EtoleColors.creamMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No one recorded at this event yet',
                            style: EtoleTypography.bodySmall(
                              color: EtoleColors.creamMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: EtoleColors.cyan,
                              side: const BorderSide(color: EtoleColors.cyan),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              AddPersonSheet.show(
                                context,
                                eventId: event.id,
                                eventName: event.name,
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add first person met'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final person = people[index];
                    return _buildPersonBlock(person, event);
                  }, childCount: people.length),
                ),

              // Bottom Add Person Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141719),
                        foregroundColor: EtoleColors.cyan,
                        side: BorderSide(
                          color: EtoleColors.cyan.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        AddPersonSheet.show(
                          context,
                          eventId: event.id,
                          eventName: event.name,
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text(
                        'Add another person met here',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Gallery horizontal preview row
  Widget _buildGalleryRow(
    String title,
    List<String> photos,
    VoidCallback onAdd,
    NetworkingEvent event,
    bool isTicket,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: EtoleTypography.labelSmall.copyWith(
                color: EtoleColors.creamSecondary,
                fontSize: 12,
              ),
            ),
            InkWell(
              onTap: onAdd,
              child: const Row(
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 14,
                    color: EtoleColors.cyan,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(color: EtoleColors.cyan, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Center(
                child: Text(
                  'No photos added • Tap to add',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final path = photos[idx];
                final f = File(path);
                return GestureDetector(
                  onTap: () => _showPhotoPreviewDialog(
                    path,
                    () => _deleteGalleryPhoto(event, path, isTicket),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: f.existsSync()
                        ? Image.file(
                            f,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            color: Colors.white10,
                          ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Notes section
  Widget _buildNotesSection(NetworkingEvent event) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141719),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Event Notes',
                style: EtoleTypography.labelSmall.copyWith(
                  color: EtoleColors.creamSecondary,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isEditingNotes ? Icons.check : Icons.edit_outlined,
                  size: 16,
                  color: EtoleColors.cyan,
                ),
                onPressed: () {
                  if (_isEditingNotes) {
                    _saveEventNotes(event);
                  } else {
                    setState(() => _isEditingNotes = true);
                  }
                },
              ),
            ],
          ),
          if (_isEditingNotes)
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: EtoleColors.cream, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Notes about the event, atmosphere, key takeaways...',
                hintStyle: TextStyle(
                  color: EtoleColors.creamMuted,
                  fontSize: 12,
                ),
                border: InputBorder.none,
              ),
            )
          else
            Text(
              (event.notes != null && event.notes!.isNotEmpty)
                  ? event.notes!
                  : 'No notes written yet.',
              style: EtoleTypography.bodySmall(
                color: (event.notes != null && event.notes!.isNotEmpty)
                    ? EtoleColors.cream
                    : EtoleColors.creamMuted,
              ),
            ),
        ],
      ),
    );
  }

  // Each person met at this event
  Widget _buildPersonBlock(NetworkingLead person, NetworkingEvent event) {
    // Parse promises
    List<Map<String, dynamic>> promises = [];
    if (person.promisesJson != null && person.promisesJson!.isNotEmpty) {
      try {
        promises = List<Map<String, dynamic>>.from(
          jsonDecode(person.promisesJson!),
        );
      } catch (_) {}
    }

    // Parse links
    List<String> links = [];
    if (person.socialLinksJson != null && person.socialLinksJson!.isNotEmpty) {
      try {
        links = List<String>.from(jsonDecode(person.socialLinksJson!));
      } catch (_) {}
    }
    if (person.website != null &&
        person.website!.isNotEmpty &&
        !links.contains(person.website)) {
      links.add(person.website!);
    }

    // Parse photos with person
    List<String> photosWithPerson = [];
    if (person.photosWithPersonJson != null &&
        person.photosWithPersonJson!.isNotEmpty) {
      try {
        photosWithPerson = List<String>.from(
          jsonDecode(person.photosWithPersonJson!),
        );
      } catch (_) {}
    }

    // Parse voice notes
    List<Map<String, dynamic>> voiceNotes = [];
    if (person.voiceNotesJson != null && person.voiceNotesJson!.isNotEmpty) {
      try {
        voiceNotes = List<Map<String, dynamic>>.from(
          jsonDecode(person.voiceNotesJson!),
        );
      } catch (_) {}
    }

    // Parse flyers
    List<String> flyers = [];
    if (person.flyersPhotosJson != null &&
        person.flyersPhotosJson!.isNotEmpty) {
      try {
        flyers = List<String>.from(jsonDecode(person.flyersPhotosJson!));
      } catch (_) {}
    }

    final initials = person.name.isNotEmpty
        ? person.name
              .split(' ')
              .map((p) => p.isNotEmpty ? p[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E2226), width: 1)),
      ),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Org & tap to open full Profile + More actions
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    EtoleHaptics.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonProfileScreen(person: person),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF1E2226),
                        backgroundImage:
                            (person.avatarPhotoPath != null &&
                                File(person.avatarPhotoPath!).existsSync())
                            ? FileImage(File(person.avatarPhotoPath!))
                            : null,
                        child:
                            (person.avatarPhotoPath == null ||
                                !File(person.avatarPhotoPath!).existsSync())
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  color: EtoleColors.cyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    person.name,
                                    style: EtoleTypography.h3.copyWith(
                                      color: EtoleColors.cream,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (person.isClient)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EtoleColors.cyan.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: EtoleColors.cyan.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'CLIENT',
                                      style: TextStyle(
                                        color: EtoleColors.cyan,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if ((person.title != null &&
                                    person.title!.isNotEmpty) ||
                                (person.organization != null &&
                                    person.organization!.isNotEmpty))
                              Text(
                                [person.title, person.organization]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(' • '),
                                style: EtoleTypography.labelSmall.copyWith(
                                  color: EtoleColors.creamSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: EtoleColors.creamMuted,
                ),
                color: const Color(0xFF1E2226),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (val) {
                  if (val == 'edit') {
                    EditPersonSheet.show(context, person: person);
                  } else if (val == 'delete') {
                    _confirmDeletePerson(person);
                  } else if (val == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonProfileScreen(person: person),
                      ),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'profile',
                    height: 36,
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: EtoleColors.cream,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'View Profile',
                          style: TextStyle(
                            color: EtoleColors.cream,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    height: 36,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: EtoleColors.cream,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Edit Contact',
                          style: TextStyle(
                            color: EtoleColors.cream,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    height: 36,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete Contact',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Action Icons: Call, WhatsApp, Email, Save Contacts, Mark as Client
          Row(
            children: [
              _buildActionIcon(
                icon: Icons.phone_outlined,
                tooltip: 'Call',
                enabled: person.phone != null && person.phone!.isNotEmpty,
                onTap: () => _makeCall(person.phone),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                icon: Icons.chat_outlined,
                tooltip: 'WhatsApp',
                enabled: person.phone != null && person.phone!.isNotEmpty,
                onTap: () => _openWhatsApp(person.phone),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                icon: Icons.email_outlined,
                tooltip: 'Email',
                enabled: person.email != null && person.email!.isNotEmpty,
                onTap: () => _sendEmail(person.email),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                icon: Icons.person_add_outlined,
                tooltip: 'Save to Contacts',
                enabled: true,
                onTap: () => _saveToContacts(person),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                icon: person.isClient ? Icons.star : Icons.star_border,
                tooltip: person.isClient ? 'Client' : 'Mark as Client',
                color: person.isClient
                    ? EtoleColors.cyan
                    : EtoleColors.creamMuted,
                enabled: true,
                onTap: () => _toggleClient(person),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Who introduced us (optional)
          if (person.whoIntroduced != null &&
              person.whoIntroduced!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.link, size: 13, color: EtoleColors.creamMuted),
                const SizedBox(width: 6),
                Text(
                  'Introduced by: ',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
                Text(
                  person.whoIntroduced!,
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // What we talked about (Notes)
          if (person.notes != null && person.notes!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 14, color: EtoleColors.cyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      person.notes!,
                      style: EtoleTypography.bodySmall(
                        color: EtoleColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Promises (Tick-off checklist)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROMISES & FOLLOW-UPS',
                    style: EtoleTypography.labelSmall.copyWith(
                      color: EtoleColors.creamMuted,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  InkWell(
                    onTap: () => _addPromiseDialog(person),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 12, color: EtoleColors.cyan),
                        SizedBox(width: 2),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: EtoleColors.cyan,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (promises.isEmpty)
                Text(
                  'No promises recorded',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                    fontSize: 11,
                  ),
                )
              else
                ...promises.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final isDone = p['isDone'] as bool? ?? false;
                  final txt = p['text'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _togglePromise(person, idx),
                          child: Icon(
                            isDone
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 15,
                            color: isDone
                                ? EtoleColors.cyan
                                : EtoleColors.creamMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => _togglePromise(person, idx),
                            child: Text(
                              txt,
                              style: TextStyle(
                                color: isDone
                                    ? EtoleColors.creamMuted
                                    : EtoleColors.cream,
                                fontSize: 12,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 14,
                            color: EtoleColors.creamMuted,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Delete promise',
                          onPressed: () => _deletePromise(person, idx),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 10),

          // Tappable Links chips
          if (links.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: links.map((link) {
                return ActionChip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  backgroundColor: const Color(0xFF16191C),
                  side: BorderSide(color: EtoleColors.cyan.withOpacity(0.3)),
                  avatar: const Icon(
                    Icons.link,
                    size: 12,
                    color: EtoleColors.cyan,
                  ),
                  label: Text(
                    Uri.tryParse(link)?.host.replaceAll('www.', '') ?? link,
                    style: const TextStyle(
                      color: EtoleColors.cream,
                      fontSize: 11,
                    ),
                  ),
                  onPressed: () async {
                    EtoleHaptics.light();
                    final uri = Uri.tryParse(
                      link.startsWith('http') ? link : 'https://$link',
                    );
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Media Row: Photos with them (camera button) & Voice notes player/record & Card photo & Flyers
          Row(
            children: [
              // Photos with them
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: EtoleColors.cream,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _managePersonPhotos(person, false),
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  size: 14,
                  color: EtoleColors.cyan,
                ),
                label: Text(
                  photosWithPerson.isEmpty
                      ? 'Photo with them'
                      : '${photosWithPerson.length} photos',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),

              // Voice Notes
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: VoiceMemoService.isRecording
                      ? Colors.redAccent
                      : EtoleColors.cream,
                  side: BorderSide(
                    color: VoiceMemoService.isRecording
                        ? Colors.redAccent
                        : Colors.white.withOpacity(0.1),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _recordVoiceNote(person),
                icon: Icon(
                  VoiceMemoService.isRecording
                      ? Icons.stop
                      : Icons.mic_none_outlined,
                  size: 14,
                  color: VoiceMemoService.isRecording
                      ? Colors.redAccent
                      : EtoleColors.cyan,
                ),
                label: Text(
                  VoiceMemoService.isRecording
                      ? 'Recording...'
                      : (voiceNotes.isEmpty
                            ? 'Voice note'
                            : '${voiceNotes.length} notes'),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),

              // Flyers
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: EtoleColors.cream,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _managePersonPhotos(person, true),
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  size: 14,
                  color: EtoleColors.cyan,
                ),
                label: Text(
                  flyers.isEmpty ? 'Flyer' : '${flyers.length} flyers',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),

          // Business card thumbnail (if scanned)
          if (person.cardPhotoPath != null &&
              File(person.cardPhotoPath!).existsSync()) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(person.cardPhotoPath!),
                height: 80,
                width: 140,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF1A1D20) : const Color(0xFF141719),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Icon(
          icon,
          size: 16,
          color:
              color ??
              (enabled
                  ? EtoleColors.cream
                  : EtoleColors.creamMuted.withOpacity(0.4)),
        ),
      ),
    );
  }
}
