import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/widgets/signature_capture_sheet.dart';
import '../../domain/brand_social_links.dart';

class BrandEditorScreen extends ConsumerStatefulWidget {
  final Brand? brand;

  const BrandEditorScreen({super.key, this.brand});

  @override
  ConsumerState<BrandEditorScreen> createState() => _BrandEditorScreenState();
}

class _BrandEditorScreenState extends ConsumerState<BrandEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _kraPinCtrl;
  late TextEditingController _vatNumberCtrl;
  late TextEditingController _mpesaCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _footerCtrl;

  late TextEditingController _instagramCtrl;
  late TextEditingController _linkedinCtrl;
  late TextEditingController _whatsappCtrl;

  late String _accentColorHex;
  late String _defaultPdfTemplate;
  String? _logoPath;
  String? _stampPath;
  String? _signaturePath;

  bool _isSaving = false;

  final List<String> _colorPresets = [
    '#38B6DB', // Brian Etole Quotation Cyan
    '#F5A623', // Warm Marigold Gold
    '#007A3D', // Maasai Forest Green
    '#4A90E2', // Slate Blue
    '#D32F2F', // Maasai Crimson
    '#0F766E', // Forest Teal
    '#1E3A8A', // Deep Navy
    '#7C3AED', // Royal Purple
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.brand;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _addressCtrl = TextEditingController(text: b?.address ?? '');
    _phoneCtrl = TextEditingController(text: b?.phone ?? '');
    _emailCtrl = TextEditingController(text: b?.email ?? '');
    _websiteCtrl = TextEditingController(text: b?.website ?? '');
    _kraPinCtrl = TextEditingController(text: b?.kraPin ?? '');
    _vatNumberCtrl = TextEditingController(text: b?.vatNumber ?? '');
    _mpesaCtrl = TextEditingController(text: b?.mpesaDetails ?? '');
    _bankCtrl = TextEditingController(text: b?.bankDetails ?? '');
    _footerCtrl = TextEditingController(text: b?.footerNote ?? '');

    _instagramCtrl = TextEditingController(
      text: BrandSocialLinks.defaultInstagram,
    );
    _linkedinCtrl = TextEditingController(
      text: BrandSocialLinks.defaultLinkedin,
    );
    _whatsappCtrl = TextEditingController(
      text: BrandSocialLinks.defaultWhatsapp,
    );
    _loadSocialLinks();

    _accentColorHex = b?.accentColorHex ?? '#800020';
    _defaultPdfTemplate = b?.defaultPdfTemplate ?? 'classic';
    _logoPath = b?.logoPath;
    _stampPath = b?.stampPath;
    _signaturePath = b?.signaturePath;
  }

  Future<void> _loadSocialLinks() async {
    final links = await BrandSocialLinksRepository.getSocialLinks();
    if (mounted) {
      setState(() {
        _instagramCtrl.text = links.instagram ?? '';
        _linkedinCtrl.text = links.linkedin ?? '';
        _whatsappCtrl.text = links.whatsapp ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _kraPinCtrl.dispose();
    _vatNumberCtrl.dispose();
    _mpesaCtrl.dispose();
    _bankCtrl.dispose();
    _footerCtrl.dispose();
    _instagramCtrl.dispose();
    _linkedinCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromFileManager(
    Function(String path) onPicked, {
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions:
            allowedExtensions ?? ['png', 'jpg', 'jpeg', 'svg', 'webp', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final originalFile = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final assetsDir = Directory('${appDir.path}/brand_assets');
        if (!await assetsDir.exists()) {
          await assetsDir.create(recursive: true);
        }
        final ext = originalFile.path.contains('.')
            ? originalFile.path.split('.').last
            : 'png';
        final targetPath =
            '${assetsDir.path}/brand_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final savedFile = await originalFile.copy(targetPath);
        onPicked(savedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _pickImage(
    ImageSource source,
    Function(String path) onPicked,
  ) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (file != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final assetsDir = Directory('${appDir.path}/brand_assets');
        if (!await assetsDir.exists()) {
          await assetsDir.create(recursive: true);
        }
        final ext = file.path.contains('.') ? file.path.split('.').last : 'png';
        final targetPath =
            '${assetsDir.path}/brand_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final savedFile = await File(file.path).copy(targetPath);
        onPicked(savedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _chooseImageSource(
    BuildContext context, {
    required String title,
    bool isLogo = false,
    required Function(String path) onPicked,
    List<String>? allowedExtensions,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (isLogo) ...[
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: EtoleColors.cyan, width: 1.5),
                      ),
                      child: Image.asset(
                        'assets/images/brian_etole_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: const Text(
                      'Etole Light Logo (Quotation Style)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Signature theme: Cerulean Cyan banner + multi-color etole typography.',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onPicked('assets/images/brian_etole_logo.png');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0C0D),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: EtoleColors.cyan, width: 1.5),
                      ),
                      child: Image.asset(
                        'assets/images/brian_etole_logo_dark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: const Text(
                      'Etole Dark Mode Logo (Obsidian & Cyan)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Night theme: Deep Obsidian background + Cerulean Cyan accent banner',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onPicked('assets/images/brian_etole_logo_dark.png');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: Image.asset(
                        'assets/images/brian_etole_logo_original.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: const Text(
                      'Original Crimson Logo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Uploaded version with classic red banner',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onPicked('assets/images/brian_etole_logo_original.png');
                    },
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EtoleColors.cyan.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: EtoleColors.cyan,
                    ),
                  ),
                  title: const Text(
                    'Browse Device File Manager',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Select custom image or SVG from storage',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromFileManager(
                      onPicked,
                      allowedExtensions: allowedExtensions,
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.teal,
                    ),
                  ),
                  title: const Text(
                    'Choose from Photos / Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery, onPicked);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.deepOrange,
                    ),
                  ),
                  title: const Text(
                    'Take Photo with Camera',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera, onPicked);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBrand() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final db = ref.read(databaseProvider);
      final isNew = widget.brand == null;

      if (isNew) {
        final newId = await db
            .into(db.brands)
            .insert(
              BrandsCompanion.insert(
                name: _nameCtrl.text.trim(),
                accentColorHex: drift.Value(_accentColorHex),
                address: _addressCtrl.text.trim().isNotEmpty
                    ? drift.Value(_addressCtrl.text.trim())
                    : const drift.Value.absent(),
                phone: _phoneCtrl.text.trim().isNotEmpty
                    ? drift.Value(_phoneCtrl.text.trim())
                    : const drift.Value.absent(),
                email: _emailCtrl.text.trim().isNotEmpty
                    ? drift.Value(_emailCtrl.text.trim())
                    : const drift.Value.absent(),
                website: _websiteCtrl.text.trim().isNotEmpty
                    ? drift.Value(_websiteCtrl.text.trim())
                    : const drift.Value.absent(),
                kraPin: _kraPinCtrl.text.trim().isNotEmpty
                    ? drift.Value(_kraPinCtrl.text.trim())
                    : const drift.Value.absent(),
                vatNumber: _vatNumberCtrl.text.trim().isNotEmpty
                    ? drift.Value(_vatNumberCtrl.text.trim())
                    : const drift.Value.absent(),
                mpesaDetails: _mpesaCtrl.text.trim().isNotEmpty
                    ? drift.Value(_mpesaCtrl.text.trim())
                    : const drift.Value.absent(),
                bankDetails: _bankCtrl.text.trim().isNotEmpty
                    ? drift.Value(_bankCtrl.text.trim())
                    : const drift.Value.absent(),
                footerNote: _footerCtrl.text.trim().isNotEmpty
                    ? drift.Value(_footerCtrl.text.trim())
                    : const drift.Value.absent(),
                defaultPdfTemplate: drift.Value(_defaultPdfTemplate),
                logoPath: _logoPath != null
                    ? drift.Value(_logoPath)
                    : const drift.Value.absent(),
                stampPath: _stampPath != null
                    ? drift.Value(_stampPath)
                    : const drift.Value.absent(),
                signaturePath: _signaturePath != null
                    ? drift.Value(_signaturePath)
                    : const drift.Value.absent(),
              ),
            );

        // Seed numbering sequences for new brand
        for (final docType in DocType.values) {
          await db
              .into(db.numberingSequences)
              .insert(
                NumberingSequencesCompanion.insert(
                  brandId: newId,
                  docType: docType.code,
                  prefix: docType.defaultPrefix,
                  currentNumber: const drift.Value(0),
                  numberPadding: const drift.Value(3),
                  formatPattern: const drift.Value(
                    '{BRAND}-{TYPE}-{YEAR}-{NUMBER}',
                  ),
                ),
              );
        }
      } else {
        await (db.update(
          db.brands,
        )..where((t) => t.id.equals(widget.brand!.id))).write(
          BrandsCompanion(
            name: drift.Value(_nameCtrl.text.trim()),
            accentColorHex: drift.Value(_accentColorHex),
            address: drift.Value(
              _addressCtrl.text.trim().isNotEmpty
                  ? _addressCtrl.text.trim()
                  : null,
            ),
            phone: drift.Value(
              _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
            ),
            email: drift.Value(
              _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
            ),
            website: drift.Value(
              _websiteCtrl.text.trim().isNotEmpty
                  ? _websiteCtrl.text.trim()
                  : null,
            ),
            kraPin: drift.Value(
              _kraPinCtrl.text.trim().isNotEmpty
                  ? _kraPinCtrl.text.trim()
                  : null,
            ),
            vatNumber: drift.Value(
              _vatNumberCtrl.text.trim().isNotEmpty
                  ? _vatNumberCtrl.text.trim()
                  : null,
            ),
            mpesaDetails: drift.Value(
              _mpesaCtrl.text.trim().isNotEmpty ? _mpesaCtrl.text.trim() : null,
            ),
            bankDetails: drift.Value(
              _bankCtrl.text.trim().isNotEmpty ? _bankCtrl.text.trim() : null,
            ),
            footerNote: drift.Value(
              _footerCtrl.text.trim().isNotEmpty
                  ? _footerCtrl.text.trim()
                  : null,
            ),
            defaultPdfTemplate: drift.Value(_defaultPdfTemplate),
            logoPath: drift.Value(_logoPath),
            stampPath: drift.Value(_stampPath),
            signaturePath: drift.Value(_signaturePath),
          ),
        );
      }

      await BrandSocialLinksRepository.saveSocialLinks(
        BrandSocialLinks(
          instagram: _instagramCtrl.text.trim(),
          linkedin: _linkedinCtrl.text.trim(),
          whatsapp: _whatsappCtrl.text.trim(),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Branding profile "${_nameCtrl.text.trim()}" saved'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving brand: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool _hasLogo(String? path) {
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('assets/')) return true;
    return File(path).existsSync();
  }

  Widget _buildLogoWidget(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.contain);
    }
    return Image.file(File(path), fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final previewAccent = AppColors.parseHex(_accentColorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.brand == null ? 'Branding Profile' : 'Branding & Details',
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            onPressed: _isSaving ? null : _saveBrand,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Brand Logo & Accent preview card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _chooseImageSource(
                        context,
                        title: 'Select Company Logo',
                        isLogo: true,
                        onPicked: (p) => setState(() => _logoPath = p),
                        allowedExtensions: [
                          'png',
                          'jpg',
                          'jpeg',
                          'svg',
                          'webp',
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: previewAccent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: previewAccent.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _hasLogo(_logoPath)
                            ? Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: _buildLogoWidget(_logoPath!),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: previewAccent,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Upload Logo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: previewAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameCtrl.text.isNotEmpty
                                ? _nameCtrl.text
                                : 'Brand Name',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasLogo(_logoPath)
                                ? 'Custom logo active (used in emails & docs)'
                                : 'No custom logo uploaded (emails display clean text wordmark)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                          if (_hasLogo(_logoPath)) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _chooseImageSource(
                                    context,
                                    title: 'Change Company Logo',
                                    isLogo: true,
                                    onPicked: (p) =>
                                        setState(() => _logoPath = p),
                                    allowedExtensions: [
                                      'png',
                                      'jpg',
                                      'jpeg',
                                      'svg',
                                      'webp',
                                    ],
                                  ),
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: EtoleColors.cyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                InkWell(
                                  onTap: () => setState(() => _logoPath = null),
                                  child: const Text(
                                    'Remove Logo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFEF5350),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Accent Color Picker
            _buildSectionTitle(
              'Brand Accent Color (Themes the App & Documents)',
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorPresets.map((hex) {
                final c = AppColors.parseHex(hex);
                final isSelected =
                    _accentColorHex.toUpperCase() == hex.toUpperCase();
                return InkWell(
                  onTap: () => setState(() => _accentColorHex = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: isSelected ? 3 : 0,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: c.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Basic Info
            _buildSectionTitle('Company / Business Details'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Brand / Business Name *',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Brand name is required'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Business Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number (e.g. +254 718 013 579)',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteCtrl,
              decoration: const InputDecoration(
                labelText: 'Website / Portfolio Link',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Physical Address / Box Number',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Social Media Links (Included in Outgoing Emails)
            _buildSectionTitle('Social Links (Included in Outgoing Emails)'),
            TextFormField(
              controller: _instagramCtrl,
              decoration: const InputDecoration(
                labelText: 'Instagram Link',
                hintText: 'instagram.com/brianetole',
                prefixIcon: Icon(Icons.camera_alt_outlined),
                helperText: 'Leave empty to hide from outgoing emails',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkedinCtrl,
              decoration: const InputDecoration(
                labelText: 'LinkedIn Link',
                hintText: 'linkedin.com/in/brianetole',
                prefixIcon: Icon(Icons.business_center_outlined),
                helperText: 'Leave empty to hide from outgoing emails',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _whatsappCtrl,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number',
                hintText: '+254 718 013 579',
                prefixIcon: Icon(Icons.chat_bubble_outline),
                helperText: 'Leave empty to hide from outgoing emails',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Tax Details
            _buildSectionTitle('Tax Details (Kenya / Global)'),
            TextFormField(
              controller: _kraPinCtrl,
              decoration: const InputDecoration(
                labelText: 'KRA / Tax PIN (e.g. P051234567Z)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vatNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'VAT Number (Optional)',
              ),
            ),
            const SizedBox(height: 24),

            // Payment Instructions
            _buildSectionTitle(
              'Payment Instructions (Printed on Invoices & Proformas)',
            ),
            TextFormField(
              controller: _mpesaCtrl,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Details (Paybill, Till, or Send Money)',
                hintText: 'Paybill: 247247 | Acc: 0700123456\nTill: 567890',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankCtrl,
              decoration: const InputDecoration(
                labelText: 'Bank Account Details',
                hintText: 'Bank: Stanbic Bank\nAcc Name: Creative Studio Media\nAcc No: 010023456789',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Signatures & Stamp
            _buildSectionTitle('Digital Signature & Stamp'),
            Row(
              children: [
                // Signature card
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => SignatureCaptureSheet(
                            title: '${_nameCtrl.text} Signature',
                            onSignatureSaved: (p) =>
                                setState(() => _signaturePath = p),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Container(
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  _signaturePath != null &&
                                      File(_signaturePath!).existsSync()
                                  ? Image.file(
                                      File(_signaturePath!),
                                      fit: BoxFit.contain,
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.draw_outlined,
                                        color: previewAccent,
                                        size: 28,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _signaturePath != null
                                  ? 'Change Signature'
                                  : 'Draw Signature',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: previewAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Stamp card
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () => _chooseImageSource(
                        context,
                        title: 'Select Official Company Stamp',
                        onPicked: (p) => setState(() => _stampPath = p),
                        allowedExtensions: [
                          'png',
                          'jpg',
                          'jpeg',
                          'svg',
                          'webp',
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Container(
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  _stampPath != null &&
                                      File(_stampPath!).existsSync()
                                  ? Image.file(
                                      File(_stampPath!),
                                      fit: BoxFit.contain,
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.approval_outlined,
                                        color: previewAccent,
                                        size: 28,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _stampPath != null
                                  ? 'Change Stamp'
                                  : 'Pick Stamp Image',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: previewAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // PDF Defaults
            _buildSectionTitle('Default PDF Layout & Footer'),
            DropdownButtonFormField<String>(
              initialValue: _defaultPdfTemplate,
              decoration: const InputDecoration(
                labelText: 'Default PDF Template',
              ),
              items: DocumentConstants.pdfTemplates
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _defaultPdfTemplate = val);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _footerCtrl,
              decoration: const InputDecoration(
                labelText: 'Default Document Footer Note',
                hintText: 'Thank you for your business...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveBrand,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.brand == null
                          ? 'Create Brand Profile'
                          : 'Save Changes',
                    ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextSecondary,
        ),
      ),
    );
  }
}
