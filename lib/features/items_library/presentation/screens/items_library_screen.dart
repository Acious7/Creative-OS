import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../contracts/presentation/screens/clause_library_screen.dart';

final allItemsLibraryStreamProvider = StreamProvider<List<ItemsLibraryData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.itemsLibrary)..orderBy([(t) => drift.OrderingTerm.asc(t.title)])).watch();
});

class ItemsLibraryScreen extends ConsumerStatefulWidget {
  const ItemsLibraryScreen({super.key});

  @override
  ConsumerState<ItemsLibraryScreen> createState() => _ItemsLibraryScreenState();
}

class _ItemsLibraryScreenState extends ConsumerState<ItemsLibraryScreen> {
  String _search = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Production',
    'Post-production',
    'Photography',
    'Pre-production',
    'Equipment',
    'Crew',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(activeAccentColorProvider);
    final itemsAsync = ref.watch(allItemsLibraryStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library & Assets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.gavel_outlined),
            tooltip: 'Clause Library',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ClauseLibraryScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Item'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDesignTokens.space16, AppDesignTokens.space12, AppDesignTokens.space16, AppDesignTokens.space8),
            child: AppSearchBar(
              hintText: 'Search services, rates, equipment...',
              onChanged: (val) {
                setState(() {
                  _search = val.toLowerCase();
                });
              },
            ),
          ),

          // Category Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: AppDesignTokens.space8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat),
                    selectedColor: accent.withValues(alpha: 0.15),
                    checkmarkColor: accent,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected ? accent : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusFull),
                      side: BorderSide(
                        color: isSelected ? accent.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppDesignTokens.space8),

          // Items List
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final filtered = items.where((item) {
                  if (_selectedCategory != 'All' && item.category != _selectedCategory) {
                    return false;
                  }
                  if (_search.isEmpty) return true;
                  final matchTitle = item.title.toLowerCase().contains(_search);
                  final matchDesc = item.description?.toLowerCase().contains(_search) ?? false;
                  final matchCat = item.category.toLowerCase().contains(_search);
                  return matchTitle || matchDesc || matchCat;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No Items Found',
                    description: _search.isNotEmpty
                        ? 'No catalog items match "$_search"'
                        : 'Save services, rates, and equipment for 1-tap reuse.',
                    actionLabel: 'Add First Item',
                    onAction: () => _showItemDialog(context),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space16, vertical: AppDesignTokens.space8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDesignTokens.space8),
                      child: AppCard(
                        variant: AppCardVariant.low,
                        onTap: () => _showItemDialog(context, item: item),
                        padding: const EdgeInsets.all(AppDesignTokens.space14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                              ),
                              child: Icon(Icons.handyman_outlined, color: accent, size: 18),
                            ),
                            const SizedBox(width: AppDesignTokens.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (item.description != null && item.description!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.description!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (item.category.isNotEmpty) ...[
                                    const SizedBox(height: AppDesignTokens.space6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusXs),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDesignTokens.space12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(item.unitPrice),
                                  style: AppDesignTokens.tabular(
                                    theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ),
                                Text(
                                  '/ ${item.unit}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const SkeletonListPlaceholder(count: 5),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDialog(BuildContext context, {ItemsLibraryData? item}) {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final priceCtrl = TextEditingController(text: item != null ? item.unitPrice.toStringAsFixed(0) : '');
    String selectedUnit = item?.unit ?? 'day';
    String selectedCat = item?.category ?? 'Production';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg)),
          title: Text(item == null ? 'Add Service / Item' : 'Edit Service / Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Item / Service Title *')),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Details'),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Unit Rate (KES) *'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: DocumentConstants.units
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Production', 'Post-production', 'Photography', 'Pre-production', 'Equipment', 'Crew', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedCat = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (item != null)
              TextButton(
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await (db.delete(db.itemsLibrary)..where((t) => t.id.equals(item.id))).go();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Delete', style: TextStyle(color: AppDesignTokens.statusOverdue)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final db = ref.read(databaseProvider);

                if (item == null) {
                  await db.into(db.itemsLibrary).insert(
                        ItemsLibraryCompanion.insert(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isNotEmpty
                              ? drift.Value(descCtrl.text.trim())
                              : const drift.Value.absent(),
                          unit: drift.Value(selectedUnit),
                          unitPrice: drift.Value(price),
                          category: drift.Value(selectedCat),
                        ),
                      );
                } else {
                  await (db.update(db.itemsLibrary)..where((t) => t.id.equals(item.id))).write(
                    ItemsLibraryCompanion(
                      title: drift.Value(titleCtrl.text.trim()),
                      description: drift.Value(descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null),
                      unit: drift.Value(selectedUnit),
                      unitPrice: drift.Value(price),
                      category: drift.Value(selectedCat),
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Item'),
            ),
          ],
        ),
      ),
    );
  }
}
