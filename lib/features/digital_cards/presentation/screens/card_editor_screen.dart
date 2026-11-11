import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../widgets/business_card_3d_flipper.dart';
import '../widgets/card_designs.dart';

class CardEditorScreen extends ConsumerStatefulWidget {
  final BusinessCard card;

  const CardEditorScreen({super.key, required this.card});

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _companyController;
  late TextEditingController _taglineController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _reelController;
  late TextEditingController _portfolioController;
  late TextEditingController _bookingController;
  late TextEditingController _customQrUrlController;
  late TextEditingController _customQrLabelController;
  late TextEditingController _whatsappTemplateController;
  late TextEditingController _hostedLogoUrlController;

  late String _designStyle;
  late String _defaultQrMode;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _titleController = TextEditingController(text: c.cardTitle);
    _nameController = TextEditingController(text: c.personName);
    _roleController = TextEditingController(text: c.personRole ?? '');
    _companyController = TextEditingController(text: c.companyName ?? '');
    _taglineController = TextEditingController(text: c.tagline ?? '');
    _phoneController = TextEditingController(text: c.primaryPhone ?? '');
    _whatsappController = TextEditingController(text: c.whatsappNumber ?? '');
    _emailController = TextEditingController(text: c.email ?? '');
    _websiteController = TextEditingController(text: c.website ?? '');
    _addressController = TextEditingController(text: c.address ?? '');
    _reelController = TextEditingController(text: c.showreelUrl ?? '');
    _portfolioController = TextEditingController(text: c.portfolioUrl ?? '');
    _bookingController = TextEditingController(text: c.bookingUrl ?? '');
    _customQrUrlController = TextEditingController(text: c.customQrUrl ?? '');
    _customQrLabelController = TextEditingController(
      text: c.customQrLabel ?? '',
    );
    _whatsappTemplateController = TextEditingController(
      text: c.whatsappTemplate ?? '',
    );
    _hostedLogoUrlController = TextEditingController(
      text: c.hostedLogoUrl ?? '',
    );

    _designStyle = c.designStyle;
    _defaultQrMode = c.defaultQrMode;
    _photoPath = c.photoPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    _companyController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _reelController.dispose();
    _portfolioController.dispose();
    _bookingController.dispose();
    _customQrUrlController.dispose();
    _customQrLabelController.dispose();
    _whatsappTemplateController.dispose();
    _hostedLogoUrlController.dispose();
    super.dispose();
  }

  BusinessCard _getDraftCard() {
    return widget.card.copyWith(
      cardTitle: _titleController.text.trim().isEmpty
          ? 'Untitled Card'
          : _titleController.text.trim(),
      personName: _nameController.text.trim().isEmpty
          ? 'Your Name'
          : _nameController.text.trim(),
      personRole: drift.Value(_roleController.text.trim()),
      companyName: drift.Value(_companyController.text.trim()),
      tagline: drift.Value(_taglineController.text.trim()),
      photoPath: drift.Value(_photoPath),
      primaryPhone: drift.Value(_phoneController.text.trim()),
      whatsappNumber: drift.Value(_whatsappController.text.trim()),
      email: drift.Value(_emailController.text.trim()),
      website: drift.Value(_websiteController.text.trim()),
      address: drift.Value(_addressController.text.trim()),
      showreelUrl: drift.Value(_reelController.text.trim()),
      portfolioUrl: drift.Value(_portfolioController.text.trim()),
      bookingUrl: drift.Value(_bookingController.text.trim()),
      customQrUrl: drift.Value(_customQrUrlController.text.trim()),
      customQrLabel: drift.Value(_customQrLabelController.text.trim()),
      whatsappTemplate: drift.Value(_whatsappTemplateController.text.trim()),
      hostedLogoUrl: drift.Value(_hostedLogoUrlController.text.trim()),
      designStyle: _designStyle,
      defaultQrMode: _defaultQrMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBrand = ref.watch(activeBrandProvider);
    final accent = ref.watch(activeAccentColorProvider);
    final draftCard = _getDraftCard();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Card Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Card',
            onPressed: () => _saveCard(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDesignTokens.space16),
          children: [
            // Live Preview Card Section
            const Text(
              'LIVE PREVIEW (TAP TO FLIP)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            BusinessCard3DFlipper(
              front: BusinessCardFrontView(
                card: draftCard,
                brand: activeBrand!,
              ),
              back: BusinessCardBackView(
                card: draftCard,
                brand: activeBrand,
                mode: QrDisplayMode.vCard,
              ),
            ),
            const SizedBox(height: 24),

            // Card Title & Style Section
            AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.all(AppDesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Card Preset & Design Style',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText:
                          'Card Title / Identifier (e.g. Director & DOP)',
                      prefixIcon: Icon(Icons.label_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Design Layout Theme:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStyleOption(
                        'minimal',
                        'Minimal',
                        Icons.crop_portrait_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildStyleOption(
                        'bold',
                        'Bold Accent',
                        Icons.format_color_fill_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildStyleOption(
                        'photo_led',
                        'Photo-led',
                        Icons.portrait_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Personal & Role Info Section
            AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.all(AppDesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal & Role Info',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _roleController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText:
                          'Title / Role (e.g. Cinematographer & Director)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _companyController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Company / Studio Name',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taglineController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Tagline / Short Motto',
                      prefixIcon: Icon(Icons.short_text_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Photo picker
                  Row(
                    children: [
                      if (_photoPath != null && File(_photoPath!).existsSync())
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_photoPath!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person, color: accent),
                        ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          _photoPath != null
                              ? 'Change Photo'
                              : 'Upload Card Photo',
                        ),
                      ),
                      if (_photoPath != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _photoPath = null),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact & Web Links Section
            AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.all(AppDesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact & Portfolio Links',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Primary Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _whatsappController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Number',
                      prefixIcon: Icon(Icons.chat_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _websiteController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Website URL',
                      prefixIcon: Icon(Icons.language_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Location / City',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reelController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Showreel Link (Vimeo/YouTube)',
                      prefixIcon: Icon(Icons.movie_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portfolioController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Portfolio Link (Behance/Site)',
                      prefixIcon: Icon(Icons.grid_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bookingController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Booking Calendar Link',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QR Code & Message Configuration
            AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.all(AppDesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR Code & Signature Options',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _defaultQrMode,
                    decoration: const InputDecoration(
                      labelText: 'Default QR Code Mode',
                      prefixIcon: Icon(Icons.qr_code_2_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'vcard',
                        child: Text('Save Contact (vCard 3.0)'),
                      ),
                      DropdownMenuItem(
                        value: 'whatsapp',
                        child: Text('WhatsApp Direct Chat'),
                      ),
                      DropdownMenuItem(
                        value: 'reel',
                        child: Text('Watch Showreel Link'),
                      ),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('Custom Web URL'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _defaultQrMode = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _whatsappTemplateController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Chat Greeting Message',
                      hintText: 'e.g. Hi Brian, nice meeting you!',
                      prefixIcon: Icon(Icons.message_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customQrUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Custom QR URL (Optional)',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hostedLogoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Hosted Logo Image URL (For Gmail/Outlook HTML Signature)',
                      hintText: 'https://brianetole.com/logo.png',
                      prefixIcon: Icon(Icons.image_search_rounded),
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
                onPressed: () => _saveCard(context),
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
                  'Save Business Card',
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

  Widget _buildStyleOption(String value, String label, IconData icon) {
    final isSelected = _designStyle == value;
    final accent = ref.watch(activeAccentColorProvider);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _designStyle = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.15)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accent : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? accent : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? accent
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _photoPath = picked.path;
      });
    }
  }

  Future<void> _saveCard(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final draft = _getDraftCard();

    await (db.update(
      db.businessCards,
    )..where((t) => t.id.equals(widget.card.id))).write(
      BusinessCardsCompanion(
        cardTitle: drift.Value(draft.cardTitle),
        personName: drift.Value(draft.personName),
        personRole: drift.Value(draft.personRole),
        companyName: drift.Value(draft.companyName),
        tagline: drift.Value(draft.tagline),
        photoPath: drift.Value(draft.photoPath),
        primaryPhone: drift.Value(draft.primaryPhone),
        whatsappNumber: drift.Value(draft.whatsappNumber),
        email: drift.Value(draft.email),
        website: drift.Value(draft.website),
        address: drift.Value(draft.address),
        showreelUrl: drift.Value(draft.showreelUrl),
        portfolioUrl: drift.Value(draft.portfolioUrl),
        bookingUrl: drift.Value(draft.bookingUrl),
        customQrUrl: drift.Value(draft.customQrUrl),
        customQrLabel: drift.Value(draft.customQrLabel),
        whatsappTemplate: drift.Value(draft.whatsappTemplate),
        hostedLogoUrl: drift.Value(draft.hostedLogoUrl),
        designStyle: drift.Value(draft.designStyle),
        defaultQrMode: drift.Value(draft.defaultQrMode),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card updated successfully!')),
      );
      Navigator.pop(context);
    }
  }
}
