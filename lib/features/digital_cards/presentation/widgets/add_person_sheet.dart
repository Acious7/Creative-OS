import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/business_card_ocr_service.dart';
import '../providers/cards_providers.dart';
import '../screens/card_ocr_verification_screen.dart';

class AddPersonSheet extends ConsumerStatefulWidget {
  final int? eventId;
  final String? eventName;
  final VoidCallback? onPersonAdded;

  const AddPersonSheet({
    super.key,
    this.eventId,
    this.eventName,
    this.onPersonAdded,
  });

  static Future<void> show(
    BuildContext context, {
    int? eventId,
    String? eventName,
    VoidCallback? onPersonAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPersonSheet(
        eventId: eventId,
        eventName: eventName,
        onPersonAdded: onPersonAdded,
      ),
    );
  }

  @override
  ConsumerState<AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends ConsumerState<AddPersonSheet> {
  // Check for duplicates in database
  Future<NetworkingLead?> _findDuplicate({
    String? phone,
    String? email,
    String? name,
  }) async {
    final db = ref.read(databaseProvider);
    final activeBrand = ref.read(activeBrandProvider);
    if (activeBrand == null) return null;

    final allLeads =
        await (db.select(db.networkingLeads)..where(
              (t) =>
                  t.brandId.equals(activeBrand.id) & t.isDeleted.equals(false),
            ))
            .get();

    final cleanPhone = phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    final cleanEmail = email?.trim().toLowerCase() ?? '';
    final cleanName = name?.trim().toLowerCase() ?? '';

    for (final lead in allLeads) {
      if (cleanPhone.length >= 7 &&
          (lead.phone != null || lead.whatsapp != null)) {
        final p1 = (lead.phone ?? '').replaceAll(RegExp(r'\D'), '');
        final p2 = (lead.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
        if ((p1.isNotEmpty && p1.endsWith(cleanPhone)) ||
            (p2.isNotEmpty && p2.endsWith(cleanPhone))) {
          return lead;
        }
      }
      if (cleanEmail.isNotEmpty &&
          lead.email != null &&
          lead.email!.trim().toLowerCase() == cleanEmail) {
        return lead;
      }
      if (cleanName.length > 2 && lead.name.trim().toLowerCase() == cleanName) {
        return lead;
      }
    }
    return null;
  }

  Future<bool> _handleDuplicateDialog(NetworkingLead existing) async {
    final db = ref.read(databaseProvider);
    final events = await (db.select(
      db.networkingEvents,
    )..where((t) => t.id.equals(existing.eventId ?? -1))).get();
    final prevEventName = events.isNotEmpty
        ? events.first.name
        : 'a previous encounter';

    if (!mounted) return false;

    final targetName = widget.eventName ?? 'your Network';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF141719),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: EtoleColors.cyan.withOpacity(0.3)),
          ),
          title: Text(
            'Already in your Network',
            style: EtoleTypography.h3.copyWith(color: EtoleColors.cream),
          ),
          content: Text(
            'You met ${existing.name} before at $prevEventName.\n\nAdd "$targetName" to their record instead of creating a duplicate?',
            style: EtoleTypography.bodySmall(color: EtoleColors.creamSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Create New Anyway',
                style: TextStyle(color: EtoleColors.creamMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EtoleColors.cyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Add to Record',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // Append event to existing lead if applicable
      List<int> eventIds = [];
      if (existing.eventIdsJson != null && existing.eventIdsJson!.isNotEmpty) {
        try {
          eventIds = List<int>.from(jsonDecode(existing.eventIdsJson!));
        } catch (_) {}
      }
      if (existing.eventId != null && !eventIds.contains(existing.eventId)) {
        eventIds.add(existing.eventId!);
      }
      if (widget.eventId != null && !eventIds.contains(widget.eventId)) {
        eventIds.add(widget.eventId!);
      }

      await (db.update(
        db.networkingLeads,
      )..where((t) => t.id.equals(existing.id))).write(
        NetworkingLeadsCompanion(
          eventIdsJson: drift.Value(
            eventIds.isNotEmpty ? jsonEncode(eventIds) : null,
          ),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated record for ${existing.name}',
              style: const TextStyle(color: EtoleColors.cream),
            ),
            backgroundColor: const Color(0xFF141719),
          ),
        );
        Navigator.pop(context);
        widget.onPersonAdded?.call();
      }
      return true;
    }

    return false;
  }

  // 1. Scan Business Card
  Future<void> _scanBusinessCard() async {
    Navigator.pop(context);
    try {
      final pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        final picPath = pictures.first;
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: EtoleColors.cyan,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Reading business card with OCR...',
                  style: TextStyle(color: EtoleColors.cream),
                ),
              ],
            ),
            backgroundColor: Color(0xFF141719),
            duration: Duration(seconds: 2),
          ),
        );

        final parsed = await BusinessCardOcrService.scanAndParseCard(picPath);
        if (!mounted) return;

        // Duplicate check
        final duplicate = await _findDuplicate(
          phone: parsed.phone,
          email: parsed.email,
          name: parsed.name,
        );
        if (duplicate != null) {
          final merged = await _handleDuplicateDialog(duplicate);
          if (merged) return;
        }

        if (!mounted) return;
        // Open verification or direct save
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CardOcrVerificationScreen(initialData: parsed),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Card scan failed: $e',
              style: const TextStyle(color: EtoleColors.cream),
            ),
          ),
        );
      }
    }
  }

  // 2. Scan QR
  Future<void> _scanQrCode() async {
    // Show QR Input dialog with QR payload or image scan
    final controller = TextEditingController();
    final result = await showDialog<String>(
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
            'Scan or Paste QR',
            style: EtoleTypography.h3.copyWith(color: EtoleColors.cream),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste their vCard text, website link, or WhatsApp URL from camera scan:',
                style: EtoleTypography.bodySmall(
                  color: EtoleColors.creamSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                style: const TextStyle(color: EtoleColors.cream, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'BEGIN:VCARD\nFN:John Doe\nTEL:+254...\nEND:VCARD\nor https://...',
                  hintStyle: const TextStyle(
                    color: EtoleColors.creamMuted,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: EtoleColors.cyan.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ],
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
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text(
                'Parse & Add',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      _parseQrAndSave(result);
    }
  }

  Future<void> _parseQrAndSave(String qrData) async {
    String name = '';
    String phone = '';
    String email = '';
    String org = '';
    String website = '';

    if (qrData.contains('BEGIN:VCARD')) {
      for (final line in qrData.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('FN:')) {
          name = trimmed.substring(3).trim();
        } else if (trimmed.startsWith('TEL')) {
          final parts = trimmed.split(':');
          if (parts.length > 1) phone = parts.last.trim();
        } else if (trimmed.startsWith('EMAIL')) {
          final parts = trimmed.split(':');
          if (parts.length > 1) email = parts.last.trim();
        } else if (trimmed.startsWith('ORG:')) {
          org = trimmed.substring(4).trim();
        } else if (trimmed.startsWith('URL:')) {
          website = trimmed.substring(4).trim();
        }
      }
    } else if (qrData.startsWith('http')) {
      website = qrData;
      name = 'Contact (${Uri.tryParse(qrData)?.host ?? 'Web'})';
    } else {
      name = qrData;
    }

    if (name.isEmpty && phone.isNotEmpty) name = phone;
    if (name.isEmpty) name = 'New Contact';

    await _savePersonToDb(
      name: name,
      phone: phone,
      email: email,
      org: org,
      website: website,
    );
  }

  // 3. Import from Phone Contacts
  Future<void> _importFromContacts() async {
    Navigator.pop(context);
    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final full = await FlutterContacts.getContact(contact.id);
          if (full != null) {
            final name = full.displayName;
            final phone = full.phones.isNotEmpty
                ? full.phones.first.number
                : '';
            final email = full.emails.isNotEmpty
                ? full.emails.first.address
                : '';
            final org = full.organizations.isNotEmpty
                ? full.organizations.first.company
                : '';
            final role = full.organizations.isNotEmpty
                ? full.organizations.first.title
                : '';

            // Duplicate check
            final duplicate = await _findDuplicate(
              phone: phone,
              email: email,
              name: name,
            );
            if (duplicate != null) {
              final merged = await _handleDuplicateDialog(duplicate);
              if (merged) return;
            }

            await _savePersonToDb(
              name: name,
              phone: phone,
              email: email,
              org: org,
              role: role,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission required to import.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Contacts import failed: $e')));
      }
    }
  }

  // 4. Type It (Clean Fast Dialog: Name + Phone)
  Future<void> _showTypeItDialog() async {
    Navigator.pop(context);
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF141719),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: EtoleColors.cyan.withOpacity(0.3)),
          ),
          title: Text(
            'Add Person',
            style: EtoleTypography.h3.copyWith(color: EtoleColors.cream),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(color: EtoleColors.cream),
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: EtoleColors.cyan,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: EtoleColors.cream),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: EtoleColors.cyan,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: roleCtrl,
                  style: const TextStyle(color: EtoleColors.cream),
                  decoration: const InputDecoration(
                    labelText: 'Role / Title (e.g. Producer)',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: EtoleColors.creamMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: orgCtrl,
                  style: const TextStyle(color: EtoleColors.cream),
                  decoration: const InputDecoration(
                    labelText: 'Organisation (e.g. Safaricom)',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    prefixIcon: Icon(
                      Icons.business_outlined,
                      color: EtoleColors.creamMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: EtoleColors.cream),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: EtoleColors.creamSecondary),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: EtoleColors.creamMuted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
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
                backgroundColor: EtoleColors.cyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text(
                'Save Person',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final duplicate = await _findDuplicate(
        phone: phoneCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        name: nameCtrl.text.trim(),
      );
      if (duplicate != null) {
        final merged = await _handleDuplicateDialog(duplicate);
        if (merged) return;
      }

      await _savePersonToDb(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        role: roleCtrl.text.trim(),
        org: orgCtrl.text.trim(),
        email: emailCtrl.text.trim(),
      );
    }
  }

  // 5. Name-only (Fast single input)
  Future<void> _showNameOnlyDialog() async {
    Navigator.pop(context);
    final ctrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF141719),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: EtoleColors.cyan.withOpacity(0.3)),
          ),
          title: Text(
            'Quick Name-Only',
            style: EtoleTypography.h3.copyWith(color: EtoleColors.cream),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Only caught their first name or description? Save it now and fill the details later.',
                style: EtoleTypography.bodySmall(
                  color: EtoleColors.creamSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: InputDecoration(
                  hintText:
                      'e.g. "Sarah (camera op)", "tall guy from Safaricom"',
                  hintStyle: const TextStyle(
                    color: EtoleColors.creamMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_add_outlined,
                    color: EtoleColors.cyan,
                  ),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: EtoleColors.cyan.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ],
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
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _savePersonToDb(name: result);
    }
  }

  Future<void> _savePersonToDb({
    required String name,
    String? phone,
    String? role,
    String? org,
    String? email,
    String? website,
    String? cardPhotoPath,
  }) async {
    final db = ref.read(databaseProvider);
    final activeBrand = ref.read(activeBrandProvider);
    if (activeBrand == null) return;

    final eventIdsList = widget.eventId != null ? [widget.eventId!] : <int>[];

    await db
        .into(db.networkingLeads)
        .insert(
          NetworkingLeadsCompanion.insert(
            brandId: activeBrand.id,
            eventId: drift.Value(widget.eventId),
            eventIdsJson: drift.Value(
              eventIdsList.isNotEmpty ? jsonEncode(eventIdsList) : null,
            ),
            name: name,
            title: drift.Value(role ?? ''),
            organization: drift.Value(org ?? ''),
            phone: drift.Value(phone ?? ''),
            whatsapp: drift.Value(phone ?? ''),
            email: drift.Value(email ?? ''),
            website: drift.Value(website ?? ''),
            cardPhotoPath: drift.Value(cardPhotoPath),
            dateMet: drift.Value(DateTime.now()),
          ),
        );

    EtoleHaptics.medium();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.eventName != null
                ? 'Added $name to ${widget.eventName}'
                : 'Added $name to Network',
            style: const TextStyle(color: EtoleColors.cream),
          ),
          backgroundColor: const Color(0xFF141719),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onPersonAdded?.call();
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
            color: const Color(0xEB141719),
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

              // Title
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: EtoleColors.cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      color: EtoleColors.cyan,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Person Met',
                          style: EtoleTypography.h3.copyWith(
                            color: EtoleColors.cream,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          widget.eventName ?? 'Network Contact',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: EtoleTypography.labelSmall.copyWith(
                            color: EtoleColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5 Options
              _OptionTile(
                icon: Icons.document_scanner_outlined,
                title: 'Scan business card',
                subtitle: 'Camera OCR auto-fills name, role, phone & email',
                onTap: _scanBusinessCard,
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.qr_code_scanner_outlined,
                title: 'Scan their QR',
                subtitle: 'Reads vCard, WhatsApp or portfolio link',
                onTap: _scanQrCode,
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.contacts_outlined,
                title: 'Import from phone contacts',
                subtitle: 'Pick someone saved in your device address book',
                onTap: _importFromContacts,
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.edit_note_outlined,
                title: 'Type it',
                subtitle: 'Fast entry with name, phone, organisation & role',
                onTap: _showTypeItDialog,
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.help_outline,
                title: 'Name-only / Quick note',
                subtitle: 'e.g. "tall guy from Safaricom", fill details later',
                onTap: _showNameOnlyDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          EtoleHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: EtoleColors.cyan.withOpacity(0.12),
        highlightColor: EtoleColors.cyan.withOpacity(0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D20).withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EtoleColors.cyan.withOpacity(0.2)),
                ),
                child: Icon(icon, color: EtoleColors.cyan, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: EtoleTypography.bodyMedium.copyWith(
                        color: EtoleColors.cream,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: EtoleTypography.labelSmall.copyWith(
                        color: EtoleColors.creamMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: EtoleColors.creamMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
