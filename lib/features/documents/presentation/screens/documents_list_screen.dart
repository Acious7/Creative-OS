import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/document_constants.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/document_thumbnail_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/document_repository.dart';
import '../providers/document_providers.dart';
import '../widgets/new_document_sheet.dart';
import '../../../trash/presentation/screens/trash_screen.dart';

class DocumentsListScreen extends ConsumerStatefulWidget {
  final Function(int docId)? onOpenDocument;
  final Function(DocType docType)? onNewDocument;

  const DocumentsListScreen({
    super.key,
    this.onOpenDocument,
    this.onNewDocument,
  });

  @override
  ConsumerState<DocumentsListScreen> createState() =>
      _DocumentsListScreenState();
}

class _DocumentsListScreenState extends ConsumerState<DocumentsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'all';

  final Set<int> _selectedDocIds = {};
  bool _isSelectionMode = false;

  final List<String> _categories = [
    'All',
    'Quotation',
    'Invoice',
    'Receipt',
    'Rate Card',
    'Contract',
  ];

  final List<(String, String)> _statusFilters = [
    ('all', 'All Statuses'),
    ('draft', 'Draft'),
    ('sent', 'Sent'),
    ('paid', 'Paid'),
    ('accepted', 'Accepted'),
    ('overdue', 'Overdue'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedDocIds.contains(id)) {
        _selectedDocIds.remove(id);
        if (_selectedDocIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedDocIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedDocIds.length;
    final repo = ref.read(documentRepositoryProvider);

    for (final id in _selectedDocIds) {
      await repo.deleteDocument(id);
    }

    setState(() {
      _selectedDocIds.clear();
      _isSelectionMode = false;
    });

    ref.invalidate(recentDocumentsProvider);
    ref.invalidate(brandMetricsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count document(s) moved to Trash'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Note: Items can be restored via Trash screen
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ref.watch(activeAccentColorProvider);
    final recentDocsAsync = ref.watch(recentDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedDocIds.length} Selected')
            : const Text('Documents'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete Selected',
              onPressed: _deleteSelected,
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel Selection',
              onPressed: () {
                setState(() {
                  _selectedDocIds.clear();
                  _isSelectionMode = false;
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Create New Document',
              onPressed: () {
                if (widget.onNewDocument != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => NewDocumentSheet(
                      onSelectDocType: widget.onNewDocument!,
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(recentDocumentsProvider);
                ref.invalidate(brandMetricsProvider);
              },
            ),
          ],
        ],
      ),
      floatingActionButton: !_isSelectionMode && widget.onNewDocument != null
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) =>
                      NewDocumentSheet(onSelectDocType: widget.onNewDocument!),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Document'),
            )
          : null,
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppSearchBar(
              controller: _searchCtrl,
              hintText: 'Search number, client, or items...',
              hasActiveFilters:
                  _selectedCategory != 'All' || _selectedStatus != 'all',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              onFilterTap: () => _showFilterBottomSheet(context),
            ),
          ),

          // Category Filter Chips Carousel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: accent.withValues(alpha: 0.18),
                    checkmarkColor: accent,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? accent : theme.colorScheme.onSurface,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Document List
          Expanded(
            child: recentDocsAsync.when(
              data: (docs) {
                final filtered = docs.where((docWithClient) {
                  final doc = docWithClient.document;
                  final client = docWithClient.client;
                  final docType = DocTypeExtension.fromCode(doc.docType);

                  // Type filter
                  if (_selectedCategory == 'Quotation' &&
                      docType != DocType.quotation)
                    return false;
                  if (_selectedCategory == 'Invoice' &&
                      docType != DocType.invoice)
                    return false;
                  if (_selectedCategory == 'Receipt' &&
                      docType != DocType.receipt)
                    return false;
                  if (_selectedCategory == 'Rate Card' &&
                      docType != DocType.rateCard)
                    return false;
                  if (_selectedCategory == 'Contract' &&
                      docType != DocType.contract)
                    return false;

                  // Status filter
                  if (_selectedStatus != 'all' &&
                      doc.status.toLowerCase() != _selectedStatus)
                    return false;

                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    final matchNum = doc.docNumber.toLowerCase().contains(
                      _searchQuery,
                    );
                    final matchClient =
                        client?.name.toLowerCase().contains(_searchQuery) ??
                        false;
                    final matchOrg =
                        client?.organization?.toLowerCase().contains(
                          _searchQuery,
                        ) ??
                        false;
                    if (!matchNum && !matchClient && !matchOrg) return false;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'No Matching Documents',
                    description:
                        'Try adjusting your search terms or filter categories.',
                    actionLabel: 'Reset Filters',
                    onAction: () {
                      setState(() {
                        _searchCtrl.clear();
                        _searchQuery = '';
                        _selectedCategory = 'All';
                        _selectedStatus = 'all';
                      });
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final doc = item.document;
                    final client = item.client;
                    final docType = DocTypeExtension.fromCode(doc.docType);
                    final isSelected = _selectedDocIds.contains(doc.id);

                    return Dismissible(
                      key: ValueKey('doc_${doc.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppDesignTokens.statusOverdue,
                          borderRadius: BorderRadius.circular(
                            AppDesignTokens.radiusLg,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        final repo = ref.read(documentRepositoryProvider);
                        await repo.deleteDocument(doc.id);
                        ref.invalidate(recentDocumentsProvider);
                        ref.invalidate(brandMetricsProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${doc.docNumber} moved to Trash'),
                              action: SnackBarAction(
                                label: 'View Trash',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TrashScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        return true;
                      },
                      child: DocumentThumbnailCard(
                        docNumber: doc.docNumber,
                        docType: docType.displayName,
                        clientName:
                            client?.name ??
                            client?.organization ??
                            'Walk-in Client',
                        issueDate: doc.issueDate,
                        totalAmount: doc.totalAmount,
                        currency: doc.currencyCode,
                        status: doc.status,
                        isSelected: isSelected,
                        onLongPress: () => _toggleSelection(doc.id),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(doc.id);
                          } else if (widget.onOpenDocument != null) {
                            widget.onOpenDocument!(doc.id);
                          }
                        },
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Status',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = 'all';
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statusFilters.map((s) {
                    final isSel = _selectedStatus == s.$1;
                    return ChoiceChip(
                      label: Text(s.$2),
                      selected: isSel,
                      onSelected: (val) {
                        setState(() {
                          _selectedStatus = s.$1;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
