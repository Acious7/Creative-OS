import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/card_pdf_builder.dart';

class CardPrintScreen extends ConsumerStatefulWidget {
  final BusinessCard card;

  const CardPrintScreen({super.key, required this.card});

  @override
  ConsumerState<CardPrintScreen> createState() => _CardPrintScreenState();
}

class _CardPrintScreenState extends ConsumerState<CardPrintScreen> {
  CardPrintSize _printSize = CardPrintSize.standardEu;
  bool _includeBleed = true;
  bool _includeCropMarks = true;
  bool _includeSafeAreaGuides = true;
  bool _isGangSheet = false;

  @override
  Widget build(BuildContext context) {
    final activeBrand = ref.watch(activeBrandProvider);
    final accent = ref.watch(activeAccentColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Print-Ready Cards PDF')),
      body: SafeArea(
        child: Column(
          children: [
            // Print Configuration Controls
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.space12),
              color: Theme.of(context).cardTheme.color,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<CardPrintSize>(
                          value: _printSize,
                          decoration: const InputDecoration(
                            labelText: 'Card Dimensions',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: CardPrintSize.standardEu,
                              child: Text('85 × 55 mm (Kenya / EU Standard)'),
                            ),
                            DropdownMenuItem(
                              value: CardPrintSize.standardUs,
                              child: Text('3.5 × 2.0 in (US Standard)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _printSize = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        selected: _includeBleed,
                        label: const Text('3mm Bleed'),
                        onSelected: (val) =>
                            setState(() => _includeBleed = val),
                      ),
                      FilterChip(
                        selected: _includeCropMarks,
                        label: const Text('Crop Marks'),
                        onSelected: (val) =>
                            setState(() => _includeCropMarks = val),
                      ),
                      FilterChip(
                        selected: _includeSafeAreaGuides,
                        label: const Text('Safe Area Guide'),
                        onSelected: (val) =>
                            setState(() => _includeSafeAreaGuides = val),
                      ),
                      FilterChip(
                        selected: _isGangSheet,
                        label: const Text('A4 Sheet (10 Cards)'),
                        selectedColor: accent,
                        labelStyle: TextStyle(
                          color: _isGangSheet ? Colors.white : null,
                        ),
                        onSelected: (val) => setState(() => _isGangSheet = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Live Vector PDF Preview
            Expanded(
              child: PdfPreview(
                build: (format) => CardPdfBuilder.buildPrintPdf(
                  card: widget.card,
                  brand: activeBrand!,
                  printSize: _printSize,
                  includeBleed: _includeBleed,
                  includeCropMarks: _includeCropMarks,
                  includeSafeAreaGuides: _includeSafeAreaGuides,
                  isGangSheet: _isGangSheet,
                ),
                canChangeOrientation: false,
                canChangePageFormat: false,
                allowPrinting: true,
                allowSharing: true,
                maxPageWidth: 400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
