import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/business_card_ocr_service.dart';
import 'lead_editor_screen.dart';

class CardOcrVerificationScreen extends ConsumerStatefulWidget {
  final ParsedCardData initialData;

  const CardOcrVerificationScreen({super.key, required this.initialData});

  @override
  ConsumerState<CardOcrVerificationScreen> createState() =>
      _CardOcrVerificationScreenState();
}

class _CardOcrVerificationScreenState
    extends ConsumerState<CardOcrVerificationScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _orgController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameController = TextEditingController(text: d.name);
    _titleController = TextEditingController(text: d.title);
    _orgController = TextEditingController(text: d.organization);
    _phoneController = TextEditingController(text: d.phone);
    _emailController = TextEditingController(text: d.email);
    _websiteController = TextEditingController(text: d.website);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _orgController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _proceedToSave() {
    final updatedData = widget.initialData.copyWith(
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      organization: _orgController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LeadEditorScreen(initialOcrData: updatedData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ref.watch(activeAccentColorProvider);
    final hasImage =
        widget.initialData.imagePath.isNotEmpty &&
        File(widget.initialData.imagePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Scanned Card'),
        actions: [
          TextButton(
            onPressed: _proceedToSave,
            child: Text(
              'USE DETAILS',
              style: TextStyle(color: accent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDesignTokens.space16),
          children: [
            // Scanned Card Image Preview
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.black26,
                  child: InteractiveViewer(
                    maxScale: 3.0,
                    child: Image.file(
                      File(widget.initialData.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Pinch or drag image to zoom & inspect card',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'On-device OCR extracted the following fields. Verify or tap detected text snippets below to adjust.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form Fields
            _buildField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _titleController,
              label: 'Role / Job Title',
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _orgController,
              label: 'Company / Studio / Agency',
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _websiteController,
              label: 'Website / Portfolio',
              icon: Icons.language_outlined,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),

            // Detected raw snippets chip group for fast assignment
            if (widget.initialData.unassignedLines.isNotEmpty) ...[
              AppCard(
                variant: AppCardVariant.surface,
                padding: const EdgeInsets.all(AppDesignTokens.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Text Detected on Card:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.initialData.unassignedLines.map((
                        snippet,
                      ) {
                        return ActionChip(
                          label: Text(
                            snippet,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () => _showSnippetAssignSheet(snippet),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _proceedToSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusMd,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
                label: const Text(
                  'Confirm & Save Lead',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  void _showSnippetAssignSheet(String text) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Assign "$text" to field:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: const Text('Set as Name'),
                onTap: () {
                  setState(() => _nameController.text = text);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Set as Job Title'),
                onTap: () {
                  setState(() => _titleController.text = text);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Set as Company'),
                onTap: () {
                  setState(() => _orgController.text = text);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Set as Phone'),
                onTap: () {
                  setState(() => _phoneController.text = text);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Set as Website'),
                onTap: () {
                  setState(() => _websiteController.text = text);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
