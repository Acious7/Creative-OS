import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/business_card_ocr_service.dart';
import '../providers/cards_providers.dart';
import 'card_ocr_verification_screen.dart';

class LeadEditorScreen extends ConsumerStatefulWidget {
  final NetworkingLead? lead;
  final BusinessCard? sharedCard;
  final ParsedCardData? initialOcrData;

  const LeadEditorScreen({
    super.key,
    this.lead,
    this.sharedCard,
    this.initialOcrData,
  });

  @override
  ConsumerState<LeadEditorScreen> createState() => _LeadEditorScreenState();
}

class _LeadEditorScreenState extends ConsumerState<LeadEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _orgController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _tagsController;

  int? _selectedEventId;
  String? _cardPhotoPath;
  DateTime _dateMet = DateTime.now();
  DateTime? _followUpDate;
  String _status = 'new';

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    final ocr = widget.initialOcrData;

    _nameController = TextEditingController(text: l?.name ?? ocr?.name ?? '');
    _titleController = TextEditingController(
      text: l?.title ?? ocr?.title ?? '',
    );
    _orgController = TextEditingController(
      text: l?.organization ?? ocr?.organization ?? '',
    );
    _phoneController = TextEditingController(
      text: l?.phone ?? ocr?.phone ?? '',
    );
    _whatsappController = TextEditingController(
      text: l?.whatsapp ?? ocr?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: l?.email ?? ocr?.email ?? '',
    );
    _websiteController = TextEditingController(
      text: l?.website ?? ocr?.website ?? '',
    );
    _locationController = TextEditingController(text: l?.locationMet ?? '');
    _notesController = TextEditingController(text: l?.notes ?? '');
    _tagsController = TextEditingController(text: l?.interestTagsJson ?? '');

    _selectedEventId = l?.eventId;
    _cardPhotoPath = l?.cardPhotoPath ?? ocr?.imagePath;
    _dateMet = l?.dateMet ?? DateTime.now();
    _followUpDate =
        l?.followUpDate ?? DateTime.now().add(const Duration(days: 1));
    _status = l?.status ?? 'new';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _orgController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(networkingEventsProvider);
    final activeEvent = ref.watch(activeEventModeProvider).value;
    final accent = ref.watch(activeAccentColorProvider);

    // Auto-select active event if creating new lead and Event Mode is ON
    if (widget.lead == null &&
        _selectedEventId == null &&
        activeEvent != null) {
      _selectedEventId = activeEvent.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lead == null ? 'Save Who I Met' : 'Edit Lead Details',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Lead',
            onPressed: () => _saveLead(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDesignTokens.space16),
          children: [
            // Fast Import Shortcuts Card
            AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.all(AppDesignTokens.space12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanPhysicalBusinessCard,
                      icon: const Icon(
                        Icons.document_scanner_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Scan Card',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _importFromPhonebook,
                      icon: const Icon(Icons.contacts_outlined, size: 18),
                      label: const Text(
                        'Import Contact',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Image Preview (if scanned)
            if (_cardPhotoPath != null && File(_cardPhotoPath!).existsSync())
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDesignTokens.radiusMd,
                      ),
                      child: Image.file(
                        File(_cardPhotoPath!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _cardPhotoPath = null),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Contact Info Input Card
            AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.all(AppDesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title / Role (e.g. Head of Marketing)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _orgController,
                    decoration: const InputDecoration(
                      labelText: 'Organization / Company',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Number',
                      prefixIcon: Icon(Icons.chat_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Context & Meeting Details Card
            AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.all(AppDesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meeting & Event Context',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (eventsAsync.value != null)
                    DropdownButtonFormField<int?>(
                      value: _selectedEventId,
                      decoration: const InputDecoration(
                        labelText: 'Event Met At',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('None / Casual Meeting'),
                        ),
                        ...eventsAsync.value!.map(
                          (e) => DropdownMenuItem<int?>(
                            value: e.id,
                            child: Text(e.name),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedEventId = val),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location / Venue Met At',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes & Needs',
                      hintText:
                          'e.g. Needs a documentary in March for donor report.',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Interest Tags (comma separated)',
                      hintText: 'e.g. documentary, commercial, photo',
                      prefixIcon: Icon(Icons.label_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Follow-up Reminder & Status Card
            AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.all(AppDesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Follow-up & Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Lead Status',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'new', child: Text('New Lead')),
                      DropdownMenuItem(
                        value: 'contacted',
                        child: Text('Contacted'),
                      ),
                      DropdownMenuItem(
                        value: 'in_discussion',
                        child: Text('In Discussion'),
                      ),
                      DropdownMenuItem(
                        value: 'converted',
                        child: Text('Converted to Client'),
                      ),
                      DropdownMenuItem(
                        value: 'not_now',
                        child: Text('Not Now / Cold'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.alarm, color: accent),
                    title: const Text('Follow-up Reminder Date'),
                    subtitle: Text(
                      _followUpDate == null
                          ? 'No reminder set'
                          : '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _followUpDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null)
                          setState(() => _followUpDate = picked);
                      },
                      child: const Text('Change Date'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _saveLead(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusMd,
                    ),
                  ),
                ),
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                label: const Text(
                  'Save Lead Record',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _scanPhysicalBusinessCard() async {
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Reading card details with on-device OCR...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        final parsed = await BusinessCardOcrService.scanAndParseCard(picPath);
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CardOcrVerificationScreen(initialData: parsed),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Scanning failed: $e')));
      }
    }
  }

  Future<void> _importFromPhonebook() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final full = await FlutterContacts.getContact(contact.id);
          if (full != null) {
            setState(() {
              _nameController.text = full.displayName;
              if (full.phones.isNotEmpty) {
                _phoneController.text = full.phones.first.number;
                _whatsappController.text = full.phones.first.number;
              }
              if (full.emails.isNotEmpty) {
                _emailController.text = full.emails.first.address;
              }
              if (full.organizations.isNotEmpty) {
                _orgController.text = full.organizations.first.company;
                _titleController.text = full.organizations.first.title;
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLead(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter lead name.')));
      return;
    }

    final db = ref.read(databaseProvider);
    final activeBrand = ref.read(activeBrandProvider);

    if (widget.lead == null) {
      // Create new lead
      await db
          .into(db.networkingLeads)
          .insert(
            NetworkingLeadsCompanion.insert(
              brandId: activeBrand!.id,
              cardId: drift.Value(widget.sharedCard?.id),
              eventId: drift.Value(_selectedEventId),
              name: name,
              title: drift.Value(_titleController.text.trim()),
              organization: drift.Value(_orgController.text.trim()),
              phone: drift.Value(_phoneController.text.trim()),
              whatsapp: drift.Value(_whatsappController.text.trim()),
              email: drift.Value(_emailController.text.trim()),
              website: drift.Value(_websiteController.text.trim()),
              locationMet: drift.Value(_locationController.text.trim()),
              notes: drift.Value(_notesController.text.trim()),
              interestTagsJson: drift.Value(_tagsController.text.trim()),
              cardPhotoPath: drift.Value(_cardPhotoPath),
              dateMet: drift.Value(_dateMet),
              followUpDate: drift.Value(_followUpDate),
              status: drift.Value(_status),
            ),
          );
    } else {
      // Update existing lead
      await (db.update(
        db.networkingLeads,
      )..where((t) => t.id.equals(widget.lead!.id))).write(
        NetworkingLeadsCompanion(
          eventId: drift.Value(_selectedEventId),
          name: drift.Value(name),
          title: drift.Value(_titleController.text.trim()),
          organization: drift.Value(_orgController.text.trim()),
          phone: drift.Value(_phoneController.text.trim()),
          whatsapp: drift.Value(_whatsappController.text.trim()),
          email: drift.Value(_emailController.text.trim()),
          website: drift.Value(_websiteController.text.trim()),
          locationMet: drift.Value(_locationController.text.trim()),
          notes: drift.Value(_notesController.text.trim()),
          interestTagsJson: drift.Value(_tagsController.text.trim()),
          cardPhotoPath: drift.Value(_cardPhotoPath),
          followUpDate: drift.Value(_followUpDate),
          status: drift.Value(_status),
        ),
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lead saved successfully!')));
      Navigator.pop(context);
    }
  }
}
