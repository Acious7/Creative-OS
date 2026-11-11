import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/editable_line_item.dart';

class ItemsEditorCard extends ConsumerWidget {
  final int index;
  final EditableLineItem item;
  final String currencyCode;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const ItemsEditorCard({
    super.key,
    required this.index,
    required this.item,
    required this.currencyCode,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Header: Item # and Delete/Save actions
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.15),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.description.isNotEmpty
                        ? item.description
                        : 'Line Item #${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                  label: const Text(
                    'Save to Library',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () => _saveToLibrary(context, ref),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.statusOverdue,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Item Title & Description
            TextFormField(
              initialValue: item.description,
              decoration: const InputDecoration(
                labelText: 'Item / Service Name *',
                isDense: true,
              ),
              onChanged: (val) {
                item.description = val;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.details,
              decoration: const InputDecoration(
                labelText: 'Details / Scope / Specifications (Optional)',
                isDense: true,
              ),
              maxLines: 2,
              onChanged: (val) {
                item.details = val;
                onChanged();
              },
            ),
            const SizedBox(height: 10),

            // Qty, Unit, Rate, Discount
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.quantity.toString().replaceAll(
                      RegExp(r'\.0$'),
                      '',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      item.quantity = double.tryParse(val) ?? 1.0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: DocumentConstants.units.contains(item.unit)
                        ? item.unit
                        : 'item',
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      isDense: true,
                    ),
                    items: DocumentConstants.units
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              u,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        item.unit = val;
                        onChanged();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: item.unitPrice > 0
                        ? item.unitPrice.toStringAsFixed(0)
                        : '',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Rate ($currencyCode)',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      item.unitPrice = double.tryParse(val) ?? 0.0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.discountPercent > 0
                        ? item.discountPercent.toStringAsFixed(0)
                        : '',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Disc %',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      item.discountPercent = double.tryParse(val) ?? 0.0;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Line Total Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkCardElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Line Total:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      item.total,
                      currencyCode: currencyCode,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveToLibrary(BuildContext context, WidgetRef ref) async {
    if (item.description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an item name before saving to library'),
        ),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    await db
        .into(db.itemsLibrary)
        .insert(
          ItemsLibraryCompanion.insert(
            title: item.description.trim(),
            description: item.details.trim().isNotEmpty
                ? drift.Value(item.details.trim())
                : const drift.Value.absent(),
            unit: drift.Value(item.unit),
            unitPrice: drift.Value(item.unitPrice),
            category: drift.Value(item.category),
          ),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.description}" saved to Items Library')),
      );
    }
  }
}
