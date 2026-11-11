import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_card.dart';

class TextDefaultsScreen extends ConsumerStatefulWidget {
  const TextDefaultsScreen({super.key});

  @override
  ConsumerState<TextDefaultsScreen> createState() => _TextDefaultsScreenState();
}

class _TextDefaultsScreenState extends ConsumerState<TextDefaultsScreen> {
  DocType _selectedDocType = DocType.quotation;
  final _headingController = TextEditingController();
  final _termsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    _headingController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final db = ref.read(databaseProvider);
    final brandId = ref.read(activeBrandIdProvider);

    final item = await (db.select(db.textDefaults)
          ..where((tbl) => tbl.brandId.equals(brandId) & tbl.docType.equals(_selectedDocType.code)))
        .getSingleOrNull();

    if (item != null) {
      _headingController.text = item.titleOverride ?? _selectedDocType.displayName;
      _termsController.text = item.termsConditions ?? '';
      _notesController.text = item.closingNotes ?? '';
    } else {
      _headingController.text = _selectedDocType.displayName;
      _termsController.text = 'Payment due upon receipt. Terms subject to agreement.';
      _notesController.text = 'Thank you for partnering with us.';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveDefaults() async {
    final db = ref.read(databaseProvider);
    final brandId = ref.read(activeBrandIdProvider);

    final existing = await (db.select(db.textDefaults)
          ..where((tbl) => tbl.brandId.equals(brandId) & tbl.docType.equals(_selectedDocType.code)))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.textDefaults)..where((tbl) => tbl.id.equals(existing.id))).write(
        TextDefaultsCompanion(
          titleOverride: drift.Value(_headingController.text.trim()),
          termsConditions: drift.Value(_termsController.text.trim()),
          closingNotes: drift.Value(_notesController.text.trim()),
        ),
      );
    } else {
      await db.into(db.textDefaults).insert(
        TextDefaultsCompanion.insert(
          brandId: brandId,
          docType: _selectedDocType.code,
          titleOverride: drift.Value(_headingController.text.trim()),
          termsConditions: drift.Value(_termsController.text.trim()),
          closingNotes: drift.Value(_notesController.text.trim()),
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Defaults saved for ${_selectedDocType.displayName}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(activeAccentColorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Text & Labels Defaults'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Defaults',
            onPressed: _saveDefaults,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDesignTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Document Type:',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingS),
                  DropdownButtonFormField<DocType>(
                    initialValue: _selectedDocType,
                    decoration: const InputDecoration(isDense: true),
                    items: DocType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(t.icon, size: 18, color: accent),
                            const SizedBox(width: 8),
                            Text(t.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDocType = val;
                          _isLoading = true;
                        });
                        _loadDefaults();
                      }
                    },
                  ),
                  const SizedBox(height: AppDesignTokens.spacingL),
                  AppCard(
                    variant: AppCardVariant.surface,
                    padding: const EdgeInsets.all(AppDesignTokens.spacingL),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _headingController,
                          decoration: const InputDecoration(
                            labelText: 'Default Document Heading',
                            hintText: 'e.g. TAX INVOICE or QUOTATION',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                        ),
                        const SizedBox(height: AppDesignTokens.spacingM),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Default Intro / Closing Notes',
                            hintText: 'e.g. Thank you for your business. We look forward to collaborating.',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppDesignTokens.spacingM),
                        TextFormField(
                          controller: _termsController,
                          decoration: const InputDecoration(
                            labelText: 'Default Terms & Conditions',
                            hintText: 'e.g. 50% deposit required upon confirmation, balance upon delivery.',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingL),
                  Container(
                    padding: const EdgeInsets.all(AppDesignTokens.spacingM),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusM),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Supported Placeholders:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          '• {CLIENT_NAME} - Client or company name\n• {DOC_NUMBER} - Sequential document number\n• {DUE_DATE} - Formatted payment due date\n• {BRAND_NAME} - Active brand name',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingL),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: Text('Save Defaults for ${_selectedDocType.displayName}'),
                      onPressed: _saveDefaults,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
