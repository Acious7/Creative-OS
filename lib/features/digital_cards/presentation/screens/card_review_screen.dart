import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/business_card_ocr_service.dart';

class CardReviewScreen extends ConsumerStatefulWidget {
  final ParsedCardData parsedData;
  final int locationId;
  final String locationName;

  const CardReviewScreen({
    super.key,
    required this.parsedData,
    required this.locationId,
    required this.locationName,
  });

  static Future<int?> show(
    BuildContext context, {
    required ParsedCardData parsedData,
    required int locationId,
    required String locationName,
  }) {
    EtoleHaptics.selection();
    return Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => CardReviewScreen(
          parsedData: parsedData,
          locationId: locationId,
          locationName: locationName,
        ),
      ),
    );
  }

  @override
  ConsumerState<CardReviewScreen> createState() => _CardReviewScreenState();
}

class _CardReviewScreenState extends ConsumerState<CardReviewScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _orgCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;

  bool _saveToPhoneContacts = false; // Off by default
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.parsedData;
    _nameCtrl = TextEditingController(text: d.name);
    _titleCtrl = TextEditingController(text: d.title);
    _orgCtrl = TextEditingController(text: d.organization);
    _phoneCtrl = TextEditingController(text: d.phone);
    _emailCtrl = TextEditingController(text: d.email);
    _websiteCtrl = TextEditingController(text: d.website);
    _addressCtrl = TextEditingController(text: d.address);
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _orgCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _cleanDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// Check whether email or phone already exists in networking leads
  Future<NetworkingLead?> _findDuplicate(String email, String phone) async {
    final db = ref.read(databaseProvider);
    final allLeads = await (db.select(
      db.networkingLeads,
    )..where((t) => t.isDeleted.equals(false))).get();

    final cleanPhone = _cleanDigits(phone);
    final cleanEmail = email.trim().toLowerCase();

    for (final lead in allLeads) {
      if (cleanEmail.isNotEmpty &&
          lead.email != null &&
          lead.email!.trim().toLowerCase() == cleanEmail) {
        return lead;
      }

      if (cleanPhone.length >= 9 && lead.phone != null) {
        final existingClean = _cleanDigits(lead.phone!);
        if (existingClean.length >= 9 &&
            (existingClean.endsWith(cleanPhone) ||
                cleanPhone.endsWith(existingClean))) {
          return lead;
        }
      }
    }
    return null;
  }

  /// Copies card photo to permanent local storage on phone
  Future<String?> _persistCardPhotoLocally() async {
    try {
      final src = File(widget.parsedData.imagePath);
      if (!await src.exists()) return null;

      final appDocDir = await getApplicationDocumentsDirectory();
      final cardsDir = Directory('${appDocDir.path}/business_cards');
      if (!await cardsDir.exists()) {
        await cardsDir.create(recursive: true);
      }

      final destPath =
          '${cardsDir.path}/card_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await src.copy(destPath);
      return destPath;
    } catch (_) {
      return widget.parsedData.imagePath;
    }
  }

  /// Save to device address book if requested
  Future<void> _exportToPhoneContacts({
    required String name,
    required String phone,
    required String email,
    required String org,
    required String title,
    required String website,
    required String address,
  }) async {
    try {
      if (await FlutterContacts.requestPermission(readonly: false)) {
        final nameParts = name.trim().split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : name;
        final lastName = nameParts.length > 1
            ? nameParts.sublist(1).join(' ')
            : '';

        final newContact = Contact(
          name: Name(first: firstName, last: lastName),
          phones: phone.isNotEmpty ? [Phone(phone)] : [],
          emails: email.isNotEmpty ? [Email(email)] : [],
          organizations: (org.isNotEmpty || title.isNotEmpty)
              ? [Organization(company: org, title: title)]
              : [],
          websites: website.isNotEmpty ? [Website(website)] : [],
          addresses: address.isNotEmpty ? [Address(address)] : [],
          notes: [Note('Met at ${widget.locationName} (Etole Studio)')],
        );

        await newContact.insert();
      }
    } catch (e) {
      debugPrint('Error saving to phone contacts: $e');
    }
  }

  Future<void> _onConfirmSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for this contact.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    // Check for duplicates (Rule: "If the email or phone already exists, ask: merge or add new")
    final duplicate = await _findDuplicate(email, phone);

    if (duplicate != null && mounted) {
      setState(() => _isSaving = false);
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF14181D),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                'Contact Already Exists',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A contact matching this phone or email already exists in your network:',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2129),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      duplicate.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (duplicate.title != null ||
                        duplicate.organization != null)
                      Text(
                        [
                          duplicate.title,
                          duplicate.organization,
                        ].whereType<String>().join(' • '),
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 12,
                        ),
                      ),
                    if (duplicate.phone != null)
                      Text(
                        'Phone: ${duplicate.phone}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    if (duplicate.email != null)
                      Text(
                        'Email: ${duplicate.email}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Would you like to merge the new card details into the existing contact or create a separate new entry?',
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF59E0B)),
              ),
              onPressed: () => Navigator.pop(ctx, 'add_new'),
              child: const Text(
                'Add as New',
                style: TextStyle(color: Color(0xFFF59E0B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx, 'merge'),
              child: const Text('Merge Details'),
            ),
          ],
        ),
      );

      if (action == null || action == 'cancel') return;
      setState(() => _isSaving = true);

      if (action == 'merge') {
        await _mergeIntoExisting(duplicate);
        return;
      }
    }

    // Insert as new person
    await _insertNewPerson();
  }

  Future<void> _mergeIntoExisting(NetworkingLead existing) async {
    final db = ref.read(databaseProvider);
    final savedPhoto = await _persistCardPhotoLocally();

    final role = _titleCtrl.text.trim();
    final org = _orgCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final website = _websiteCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final note = _notesCtrl.text.trim();

    final mergedNotes = [
      if (existing.notes != null && existing.notes!.isNotEmpty) existing.notes!,
      if (note.isNotEmpty) note,
      'Card scanned at ${widget.locationName}',
    ].join('\n');

    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(existing.id))).write(
      NetworkingLeadsCompanion(
        title: drift.Value(role.isNotEmpty ? role : existing.title),
        organization: drift.Value(org.isNotEmpty ? org : existing.organization),
        phone: drift.Value(phone.isNotEmpty ? phone : existing.phone),
        whatsapp: drift.Value(phone.isNotEmpty ? phone : existing.whatsapp),
        email: drift.Value(email.isNotEmpty ? email : existing.email),
        website: drift.Value(website.isNotEmpty ? website : existing.website),
        physicalAddress: drift.Value(
          address.isNotEmpty ? address : existing.physicalAddress,
        ),
        cardPhotoPath: drift.Value(savedPhoto ?? existing.cardPhotoPath),
        notes: drift.Value(mergedNotes),
      ),
    );

    if (_saveToPhoneContacts) {
      await _exportToPhoneContacts(
        name: existing.name,
        phone: phone.isNotEmpty ? phone : (existing.phone ?? ''),
        email: email.isNotEmpty ? email : (existing.email ?? ''),
        org: org.isNotEmpty ? org : (existing.organization ?? ''),
        title: role.isNotEmpty ? role : (existing.title ?? ''),
        website: website.isNotEmpty ? website : (existing.website ?? ''),
        address: address.isNotEmpty
            ? address
            : (existing.physicalAddress ?? ''),
      );
    }

    EtoleHaptics.success();
    if (mounted) {
      Navigator.pop(context, existing.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Merged card details into ${existing.name}.'),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
    }
  }

  Future<void> _insertNewPerson() async {
    final db = ref.read(databaseProvider);
    final brand = await db.select(db.brands).getSingleOrNull();
    final brandId = brand?.id ?? 1;

    final savedPhoto = await _persistCardPhotoLocally();

    final name = _nameCtrl.text.trim();
    final role = _titleCtrl.text.trim();
    final org = _orgCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final website = _websiteCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final note = _notesCtrl.text.trim();

    final personId = await db
        .into(db.networkingLeads)
        .insert(
          NetworkingLeadsCompanion(
            brandId: drift.Value(brandId),
            eventId: drift.Value(widget.locationId),
            name: drift.Value(name),
            title: drift.Value(role.isNotEmpty ? role : null),
            organization: drift.Value(org.isNotEmpty ? org : null),
            phone: drift.Value(phone.isNotEmpty ? phone : null),
            whatsapp: drift.Value(phone.isNotEmpty ? phone : null),
            email: drift.Value(email.isNotEmpty ? email : null),
            website: drift.Value(website.isNotEmpty ? website : null),
            physicalAddress: drift.Value(address.isNotEmpty ? address : null),
            cardPhotoPath: drift.Value(savedPhoto),
            notes: drift.Value(note.isNotEmpty ? note : null),
            locationMet: drift.Value(widget.locationName),
            dateMet: drift.Value(DateTime.now()),
            isArchived: const drift.Value(false),
            isDeleted: const drift.Value(false),
          ),
        );

    if (_saveToPhoneContacts) {
      await _exportToPhoneContacts(
        name: name,
        phone: phone,
        email: email,
        org: org,
        title: role,
        website: website,
        address: address,
      );
    }

    EtoleHaptics.success();
    if (mounted) {
      Navigator.pop(context, personId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $name to ${widget.locationName}.'),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        widget.parsedData.imagePath.isNotEmpty &&
        File(widget.parsedData.imagePath).existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F141A),
        elevation: 0,
        title: const Text(
          'Review Business Card',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // 1. Card Photo on Top (Rule: "card photo on top, editable fields below")
                  if (hasPhoto) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141920),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(widget.parsedData.imagePath),
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 11,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Kept on phone only',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 2. Location Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14181D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Met at: ${widget.locationName}',
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Editable Fields (Rule: "editable fields below")
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Full Name *',
                    hint: 'e.g. Alex Morgan',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 10),

                  _buildTextField(
                    controller: _titleCtrl,
                    label: 'Job Title / Role',
                    hint: 'e.g. Managing Director, Cinematographer',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 10),

                  _buildTextField(
                    controller: _orgCtrl,
                    label: 'Company / Organization',
                    hint: 'e.g. Etole Creative Studios Ltd',
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 10),

                  _buildTextField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    hint: 'e.g. +254 712 345 678, 0712...',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),

                  _buildTextField(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    hint: 'e.g. hello@brianetole.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),

                  _buildTextField(
                    controller: _websiteCtrl,
                    label: 'Website',
                    hint: 'e.g. www.brianetole.com',
                    icon: Icons.language_rounded,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 10),

                  _buildTextField(
                    controller: _addressCtrl,
                    label: 'Physical Address',
                    hint: 'e.g. Lenana Road, Kilimani, Nairobi',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 10),

                  _buildTextField(
                    controller: _notesCtrl,
                    label: 'Meeting Notes / Next Steps',
                    hint: 'e.g. Discussed TV commercial co-production for Q3',
                    icon: Icons.note_alt_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),

                  // 4. "Save to phone contacts" toggle (Rule: "Add a 'Save to phone contacts' toggle, off by default")
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141920),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _saveToPhoneContacts
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                            : Colors.white10,
                      ),
                    ),
                    child: SwitchListTile(
                      value: _saveToPhoneContacts,
                      activeColor: const Color(0xFFF59E0B),
                      title: const Text(
                        'Save to Phone Contacts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Exports this card directly into your phonebook',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _saveToPhoneContacts = val),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Confirm Save Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF090D12),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _onConfirmSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Confirm & Save Contact',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFFF59E0B), size: 18),
        filled: true,
        fillColor: const Color(0xFF141920),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
    );
  }
}
