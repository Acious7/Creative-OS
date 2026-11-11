import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../items_library/presentation/screens/items_library_screen.dart';

class LibraryItemPickerSheet extends ConsumerStatefulWidget {
  final Function(ItemsLibraryData selectedItem) onItemSelected;

  const LibraryItemPickerSheet({super.key, required this.onItemSelected});

  @override
  ConsumerState<LibraryItemPickerSheet> createState() =>
      _LibraryItemPickerSheetState();
}

class _LibraryItemPickerSheetState
    extends ConsumerState<LibraryItemPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(activeAccentColorProvider);
    final itemsAsync = ref.watch(allItemsLibraryStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Item from Library',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search saved services and rates...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                  onChanged: (val) =>
                      setState(() => _search = val.toLowerCase()),
                ),
              ),
              const Divider(),
              Expanded(
                child: itemsAsync.when(
                  data: (items) {
                    final filtered = items.where((item) {
                      if (_search.isEmpty) return true;
                      return item.title.toLowerCase().contains(_search) ||
                          (item.description?.toLowerCase().contains(_search) ??
                              false);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No matching items found',
                          style: TextStyle(color: AppColors.darkTextSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: item.description != null
                                ? Text(
                                    item.description!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  )
                                : null,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(item.unitPrice),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '/ ${item.unit}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.darkTextMuted,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              widget.onItemSelected(item);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
