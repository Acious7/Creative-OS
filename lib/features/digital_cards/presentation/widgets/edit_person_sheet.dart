import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../providers/cards_providers.dart';

class EditPersonSheet extends ConsumerStatefulWidget {
  final NetworkingLead person;
  final ValueChanged<NetworkingLead>? onPersonUpdated;

  const EditPersonSheet({
    super.key,
    required this.person,
    this.onPersonUpdated,
  });

  static Future<NetworkingLead?> show(
    BuildContext context, {
    required NetworkingLead person,
    ValueChanged<NetworkingLead>? onPersonUpdated,
  }) {
    return showModalBottomSheet<NetworkingLead>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          EditPersonSheet(person: person, onPersonUpdated: onPersonUpdated),
    );
  }

  @override
  ConsumerState<EditPersonSheet> createState() => _EditPersonSheetState();
}

class _EditPersonSheetState extends ConsumerState<EditPersonSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _orgCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _introducedCtrl;
  late TextEditingController _notesCtrl;

  int? _selectedEventId;
  bool _isClient = false;
  String? _avatarPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _nameCtrl = TextEditingController(text: p.name);
    _titleCtrl = TextEditingController(text: p.title ?? '');
    _orgCtrl = TextEditingController(text: p.organization ?? '');
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _whatsappCtrl = TextEditingController(text: p.whatsapp ?? p.phone ?? '');
    _emailCtrl = TextEditingController(text: p.email ?? '');
    _websiteCtrl = TextEditingController(text: p.website ?? '');
    _locationCtrl = TextEditingController(text: p.locationMet ?? '');
    _introducedCtrl = TextEditingController(text: p.whoIntroduced ?? '');
    _notesCtrl = TextEditingController(text: p.notes ?? '');
    _selectedEventId = p.eventId;
    _isClient = p.isClient;
    _avatarPath = p.avatarPhotoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _orgCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _locationCtrl.dispose();
    _introducedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarPath = picked.path);
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    // Preserve eventIdsJson
    List<int> eventIds = [];
    if (widget.person.eventIdsJson != null &&
        widget.person.eventIdsJson!.isNotEmpty) {
      try {
        eventIds = List<int>.from(jsonDecode(widget.person.eventIdsJson!));
      } catch (_) {}
    }
    if (_selectedEventId != null && !eventIds.contains(_selectedEventId)) {
      eventIds.add(_selectedEventId!);
    }

    // Sync client status if toggled to client
    int? clientId = widget.person.convertedClientId;
    if (_isClient && clientId == null) {
      clientId = await db
          .into(db.clients)
          .insert(
            ClientsCompanion(
              name: drift.Value(name),
              organization: drift.Value(_orgCtrl.text.trim()),
              phone: drift.Value(_phoneCtrl.text.trim()),
              email: drift.Value(_emailCtrl.text.trim()),
              notes: drift.Value(_notesCtrl.text.trim()),
            ),
          );
    }

    final companion = NetworkingLeadsCompanion(
      name: drift.Value(name),
      title: drift.Value(_titleCtrl.text.trim()),
      organization: drift.Value(_orgCtrl.text.trim()),
      phone: drift.Value(_phoneCtrl.text.trim()),
      whatsapp: drift.Value(_whatsappCtrl.text.trim()),
      email: drift.Value(_emailCtrl.text.trim()),
      website: drift.Value(_websiteCtrl.text.trim()),
      locationMet: drift.Value(_locationCtrl.text.trim()),
      whoIntroduced: drift.Value(_introducedCtrl.text.trim()),
      notes: drift.Value(_notesCtrl.text.trim()),
      avatarPhotoPath: drift.Value(_avatarPath),
      eventId: drift.Value(_selectedEventId),
      eventIdsJson: drift.Value(
        eventIds.isNotEmpty ? jsonEncode(eventIds) : null,
      ),
      isClient: drift.Value(_isClient),
      convertedClientId: drift.Value(clientId),
      updatedAt: drift.Value(now),
    );

    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(widget.person.id))).write(companion);

    final updated = widget.person.copyWith(
      name: name,
      title: drift.Value(_titleCtrl.text.trim()),
      organization: drift.Value(_orgCtrl.text.trim()),
      phone: drift.Value(_phoneCtrl.text.trim()),
      whatsapp: drift.Value(_whatsappCtrl.text.trim()),
      email: drift.Value(_emailCtrl.text.trim()),
      website: drift.Value(_websiteCtrl.text.trim()),
      locationMet: drift.Value(_locationCtrl.text.trim()),
      whoIntroduced: drift.Value(_introducedCtrl.text.trim()),
      notes: drift.Value(_notesCtrl.text.trim()),
      avatarPhotoPath: drift.Value(_avatarPath),
      eventId: drift.Value(_selectedEventId),
      eventIdsJson: drift.Value(
        eventIds.isNotEmpty ? jsonEncode(eventIds) : null,
      ),
      isClient: _isClient,
      convertedClientId: drift.Value(clientId),
      updatedAt: now,
    );

    EtoleHaptics.medium();

    if (mounted) {
      widget.onPersonUpdated?.call(updated);
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
    final allEvents = ref.watch(networkingEventsProvider).value ?? [];

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
                      'Edit Contact Details',
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

                // Avatar and Name Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF1E2226),
                            backgroundImage:
                                (_avatarPath != null &&
                                    File(_avatarPath!).existsSync())
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child:
                                (_avatarPath == null ||
                                    !File(_avatarPath!).existsSync())
                                ? const Icon(
                                    Icons.person,
                                    color: EtoleColors.cyan,
                                    size: 30,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: EtoleColors.cyan,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: EtoleColors.cream),
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          labelStyle: TextStyle(
                            color: EtoleColors.creamSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: EtoleColors.cyan,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Role & Organisation
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleCtrl,
                        style: const TextStyle(
                          color: EtoleColors.cream,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Role / Title',
                          labelStyle: TextStyle(
                            color: EtoleColors.creamSecondary,
                          ),
                          hintText: 'e.g. Producer',
                          hintStyle: TextStyle(
                            color: EtoleColors.creamMuted,
                            fontSize: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: EtoleColors.creamMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _orgCtrl,
                        style: const TextStyle(
                          color: EtoleColors.cream,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Organisation',
                          labelStyle: TextStyle(
                            color: EtoleColors.creamSecondary,
                          ),
                          hintText: 'e.g. Docubox',
                          hintStyle: TextStyle(
                            color: EtoleColors.creamMuted,
                            fontSize: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.business_outlined,
                            color: EtoleColors.creamMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Phone & WhatsApp
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          color: EtoleColors.cream,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          labelStyle: TextStyle(
                            color: EtoleColors.creamSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: EtoleColors.cyan,
                            size: 18,
                          ),
                        ),
                        onChanged: (v) {
                          if (_whatsappCtrl.text.isEmpty) {
                            _whatsappCtrl.text = v;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _whatsappCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          color: EtoleColors.cream,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp',
                          labelStyle: TextStyle(
                            color: EtoleColors.creamSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.chat_outlined,
                            color: EtoleColors.creamMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Email & Website
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: EtoleColors.cream,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: EtoleColors.creamMuted,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _websiteCtrl,
                  style: const TextStyle(
                    color: EtoleColors.cream,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Website / Portfolio / Profile',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    hintText: 'https://...',
                    prefixIcon: Icon(
                      Icons.link_outlined,
                      color: EtoleColors.creamMuted,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Associated Place / Event Selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2226),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedEventId,
                      dropdownColor: const Color(0xFF1E2226),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: EtoleColors.cyan,
                      ),
                      hint: const Text(
                        'Select Associated Place / Event',
                        style: TextStyle(
                          color: EtoleColors.creamMuted,
                          fontSize: 13,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'No Specific Event / General',
                            style: TextStyle(
                              color: EtoleColors.creamMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        ...allEvents.map(
                          (ev) => DropdownMenuItem<int?>(
                            value: ev.id,
                            child: Text(
                              ev.name,
                              style: const TextStyle(
                                color: EtoleColors.cream,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedEventId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Who introduced & Location met
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _introducedCtrl,
                        style: const TextStyle(
                          color: EtoleColors.cream,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Who Introduced Us',
                          labelStyle: TextStyle(
                            color: EtoleColors.creamSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.handshake_outlined,
                            color: EtoleColors.creamMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _locationCtrl,
                        style: const TextStyle(
                          color: EtoleColors.cream,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Location Met',
                          labelStyle: TextStyle(
                            color: EtoleColors.creamSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.place_outlined,
                            color: EtoleColors.creamMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Notes (What we talked about)
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                    color: EtoleColors.cream,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Notes / Conversation Takeaways',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    hintText: 'What you talked about, mutual connections, impressions...',
                    hintStyle: TextStyle(
                      color: EtoleColors.creamMuted,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.notes_outlined,
                      color: EtoleColors.creamMuted,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Client Status Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Mark as Client (visible in Docs)',
                    style: TextStyle(color: EtoleColors.cream, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Syncs with Client list for quoting and invoicing',
                    style: TextStyle(
                      color: EtoleColors.creamMuted,
                      fontSize: 11,
                    ),
                  ),
                  value: _isClient,
                  activeColor: EtoleColors.cyan,
                  onChanged: (v) => setState(() => _isClient = v),
                ),
                const SizedBox(height: 16),

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
                  onPressed: _saveChanges,
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
