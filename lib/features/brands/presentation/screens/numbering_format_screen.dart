import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/utils/number_generator.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';

final brandSequencesStreamProvider =
    StreamProvider.autoDispose<List<NumberingSequence>>((ref) {
      final db = ref.watch(databaseProvider);
      final brandId = ref.watch(activeBrandIdProvider);
      return (db.select(
        db.numberingSequences,
      )..where((t) => t.brandId.equals(brandId))).watch();
    });

class NumberingFormatScreen extends ConsumerWidget {
  const NumberingFormatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(activeBrandProvider);
    final sequencesAsync = ref.watch(brandSequencesStreamProvider);
    final accent = ref.watch(activeAccentColorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Numbering: ${activeBrand?.name ?? "Brand"}')),
      body: sequencesAsync.when(
        data: (sequences) {
          if (sequences.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.tag_rounded,
              title: 'No Numbering Sequences',
              description:
                  'Sequences will generate automatically for your brand.',
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spacingM,
              vertical: AppDesignTokens.spacingM,
            ),
            children: [
              AppCard(
                variant: AppCardVariant.low,
                padding: const EdgeInsets.all(AppDesignTokens.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: accent,
                          size: 20,
                        ),
                        const SizedBox(width: AppDesignTokens.spacingS),
                        Text(
                          'Numbering Sequences Rules',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Each document type has its own independent numbering sequence per brand. Numbers auto-increment and deleting a document never reuses numbers.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingM),
              ...sequences
                  .where((s) {
                    final c = s.docType.toLowerCase();
                    return c == 'quotation' ||
                        c == 'invoice' ||
                        c == 'receipt' ||
                        c == 'rate_card' ||
                        c == 'ratecard' ||
                        c == 'contract';
                  })
                  .map((seq) {
                    final docType = DocTypeExtension.fromCode(seq.docType);
                    final previewNumber = NumberGenerator.formatNumber(
                      pattern: seq.formatPattern,
                      brandName: activeBrand?.name ?? 'Brand',
                      docPrefix: seq.prefix,
                      number: seq.currentNumber + 1,
                      padding: seq.numberPadding,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDesignTokens.spacingS,
                      ),
                      child: AppCard(
                        variant: AppCardVariant.surface,
                        padding: const EdgeInsets.all(AppDesignTokens.spacingM),
                        onTap: () => _editSequenceDialog(
                          context,
                          ref,
                          seq,
                          activeBrand?.name ?? 'Brand',
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusM,
                                ),
                              ),
                              child: Icon(
                                docType.icon,
                                color: accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppDesignTokens.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        docType.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Next: $previewNumber',
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Prefix: "${seq.prefix}" | Pattern: ${seq.formatPattern} (Count: ${seq.currentNumber})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit_outlined, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppDesignTokens.spacingM),
          child: SkeletonListPlaceholder(count: 6),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _editSequenceDialog(
    BuildContext context,
    WidgetRef ref,
    NumberingSequence seq,
    String brandName,
  ) {
    final prefixCtrl = TextEditingController(text: seq.prefix);
    final patternCtrl = TextEditingController(text: seq.formatPattern);
    int padding = seq.numberPadding;
    int currentNum = seq.currentNumber;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final nextPreview = NumberGenerator.formatNumber(
            pattern: patternCtrl.text,
            brandName: brandName,
            docPrefix: prefixCtrl.text,
            number: currentNum + 1,
            padding: padding,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusL),
            ),
            title: Text(
              'Edit ${DocTypeExtension.fromCode(seq.docType).displayName} Numbering',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDesignTokens.spacingM),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        AppDesignTokens.radiusM,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Document Number Preview:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextPreview,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: prefixCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Document Prefix (e.g. QT, INV, CS)',
                    ),
                    onChanged: (_) => setDlgState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: patternCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Format Pattern',
                      helperText:
                          'Tokens: {PREFIX}, {NUM}, {YEAR}, {BRAND}, {TYPE}',
                      helperMaxLines: 2,
                    ),
                    onChanged: (_) => setDlgState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text(
                          '{PREFIX}-{YEAR}-{NUM}',
                          style: TextStyle(fontSize: 10.5),
                        ),
                        onPressed: () {
                          patternCtrl.text = '{PREFIX}-{YEAR}-{NUM}';
                          setDlgState(() {});
                        },
                      ),
                      ActionChip(
                        label: const Text(
                          '{PREFIX}-{NUM}',
                          style: TextStyle(fontSize: 10.5),
                        ),
                        onPressed: () {
                          patternCtrl.text = '{PREFIX}-{NUM}';
                          setDlgState(() {});
                        },
                      ),
                      ActionChip(
                        label: const Text(
                          '{BRAND}-{TYPE}-{YEAR}-{NUMBER}',
                          style: TextStyle(fontSize: 10.5),
                        ),
                        onPressed: () {
                          patternCtrl.text = '{BRAND}-{TYPE}-{YEAR}-{NUMBER}';
                          setDlgState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Number Padding (Digits): '),
                      const Spacer(),
                      DropdownButton<int>(
                        value: padding,
                        items: [2, 3, 4, 5]
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '$p (e.g. ${1.toString().padLeft(p, '0')})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => padding = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await (db.update(
                    db.numberingSequences,
                  )..where((t) => t.id.equals(seq.id))).write(
                    NumberingSequencesCompanion(
                      prefix: drift.Value(prefixCtrl.text.trim().toUpperCase()),
                      formatPattern: drift.Value(patternCtrl.text.trim()),
                      numberPadding: drift.Value(padding),
                      updatedAt: drift.Value(DateTime.now()),
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Format'),
              ),
            ],
          );
        },
      ),
    );
  }
}
