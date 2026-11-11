import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';

class AddPersonToLocationSheet extends ConsumerStatefulWidget {
  final int locationId;
  final String locationName;

  const AddPersonToLocationSheet({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  static Future<int?> show(
    BuildContext context, {
    required int locationId,
    required String locationName,
  }) {
    EtoleHaptics.selection();
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPersonToLocationSheet(
        locationId: locationId,
        locationName: locationName,
      ),
    );
  }

  @override
  ConsumerState<AddPersonToLocationSheet> createState() =>
      _AddPersonToLocationSheetState();
}

class _AddPersonToLocationSheetState
    extends ConsumerState<AddPersonToLocationSheet> {
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _orgCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromPhonebook() async {
    try {
      EtoleHaptics.selection();
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final full = await FlutterContacts.getContact(contact.id) ?? contact;
          setState(() {
            _nameCtrl.text = full.displayName;
            if (full.phones.isNotEmpty) {
              _phoneCtrl.text = full.phones.first.number;
            }
            if (full.emails.isNotEmpty) {
              _emailCtrl.text = full.emails.first.address;
            }
            if (full.organizations.isNotEmpty) {
              _orgCtrl.text = full.organizations.first.company;
              _roleCtrl.text = full.organizations.first.title;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking contact: $e');
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    EtoleHaptics.success();
    final db = ref.read(databaseProvider);
    final brand = await db.select(db.brands).getSingleOrNull();
    final brandId = brand?.id ?? 1;

    final personId = await db
        .into(db.networkingLeads)
        .insert(
          NetworkingLeadsCompanion(
            brandId: drift.Value(brandId),
            eventId: drift.Value(widget.locationId),
            name: drift.Value(name),
            title: drift.Value(
              _roleCtrl.text.trim().isNotEmpty ? _roleCtrl.text.trim() : null,
            ),
            organization: drift.Value(
              _orgCtrl.text.trim().isNotEmpty ? _orgCtrl.text.trim() : null,
            ),
            phone: drift.Value(
              _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
            ),
            whatsapp: drift.Value(
              _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
            ),
            email: drift.Value(
              _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
            ),
            notes: drift.Value(
              _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
            ),
            locationMet: drift.Value(widget.locationName),
            dateMet: drift.Value(DateTime.now()),
            isArchived: const drift.Value(false),
            isDeleted: const drift.Value(false),
          ),
        );

    if (mounted) {
      Navigator.pop(context, personId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PERSON I MET HERE',
                                  style: EtoleTypography.labelCaps(
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                                Text(
                                  widget.locationName,
                                  style: EtoleTypography.h3.copyWith(
                                    color: EtoleColors.cream,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
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
                const SizedBox(height: 12),

                // Quick Import from Phonebook banner
                InkWell(
                  onTap: _pickFromPhonebook,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2026),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contacts_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Import from Phone Contacts (1-Tap)',
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Full Name
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Amina Hassan',
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

                // Role and Company Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _roleCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Role / Title',
                          hintText: 'e.g. Head of Brand',
                          labelStyle: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                          ),
                          hintStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _orgCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Company / Org',
                          hintText: 'e.g. Safaricom',
                          labelStyle: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                          ),
                          hintStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
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
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Phone and Email Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Phone / WhatsApp',
                          hintText: '+2547...',
                          labelStyle: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                          ),
                          hintStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'name@org.com',
                          labelStyle: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                          ),
                          hintStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
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
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Note on who they are
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Short Note on Who They Are',
                    hintText: 'e.g. Planning a corporate commercial in Q2. Looking for high-end cinematic director. Wants showreel sample.',
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
                  child: const Text(
                    'Save Person to Location',
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
