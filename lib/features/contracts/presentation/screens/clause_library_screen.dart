import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';

final clausesProvider = StreamProvider<List<ReusableClause>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.reusableClauses,
  )..orderBy([(t) => drift.OrderingTerm.asc(t.category)])).watch();
});

class ClauseLibraryScreen extends ConsumerWidget {
  const ClauseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clausesAsync = ref.watch(clausesProvider);
    final accent = ref.watch(activeAccentColorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Clause Library')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClauseEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Clause'),
      ),
      body: clausesAsync.when(
        data: (clauses) {
          if (clauses.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.gavel_outlined,
              title: 'Clause Library Empty',
              description: 'Store standard legal clauses for contracts, NDAs, releases & licences.',
              actionLabel: 'Add Standard Clause',
              onAction: () => _openClauseEditor(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.space16,
              vertical: AppDesignTokens.space12,
            ),
            itemCount: clauses.length,
            itemBuilder: (ctx, idx) {
              final c = clauses[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDesignTokens.space8),
                child: AppCard(
                  variant: AppCardVariant.low,
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: AppDesignTokens.space14,
                        vertical: AppDesignTokens.space4,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDesignTokens.radiusSm,
                          ),
                        ),
                        child: Icon(
                          Icons.gavel_outlined,
                          color: accent,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        c.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        c.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDesignTokens.space16,
                            0,
                            AppDesignTokens.space16,
                            AppDesignTokens.space14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.bodyText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => _openClauseEditor(
                                      context,
                                      ref,
                                      clause: c,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppDesignTokens.statusOverdue,
                                    ),
                                    onPressed: () => _deleteClause(ref, c.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const SkeletonListPlaceholder(count: 4),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _openClauseEditor(
    BuildContext context,
    WidgetRef ref, {
    ReusableClause? clause,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesignTokens.radiusXl),
        ),
      ),
      builder: (ctx) => _ClauseForm(clause: clause),
    );
  }

  Future<void> _deleteClause(WidgetRef ref, int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.reusableClauses)..where((t) => t.id.equals(id))).go();
  }
}

class _ClauseForm extends ConsumerStatefulWidget {
  final ReusableClause? clause;

  const _ClauseForm({this.clause});

  @override
  ConsumerState<_ClauseForm> createState() => _ClauseFormState();
}

class _ClauseFormState extends ConsumerState<_ClauseForm> {
  final _titleController = TextEditingController();
  final _catController = TextEditingController(text: 'General Terms');
  final _contentController = TextEditingController();

  final List<String> _categories = [
    'General Terms',
    'Scope & Deliverables',
    'Payment & Fees',
    'Intellectual Property / Copyright',
    'Confidentiality & Non-Disclosure',
    'Revisions & Change Orders',
    'Cancellation & Termination',
    'Limitation of Liability',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.clause != null) {
      _titleController.text = widget.clause!.title;
      _catController.text = widget.clause!.category;
      _contentController.text = widget.clause!.bodyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.clause == null ? 'Add Reusable Clause' : 'Edit Clause',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _categories.contains(_catController.text)
                  ? _catController.text
                  : _categories.first,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _catController.text = val);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Clause Title (e.g. Usage Rights)',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Clause Content',
                hintText: 'Use placeholders like {CLIENT_NAME}, {BRAND_NAME}, {FEE_AMOUNT}',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Clause'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty)
      return;
    final db = ref.read(databaseProvider);

    if (widget.clause == null) {
      await db
          .into(db.reusableClauses)
          .insert(
            ReusableClausesCompanion.insert(
              category: drift.Value(_catController.text.trim()),
              title: _titleController.text.trim(),
              bodyText: drift.Value(_contentController.text.trim()),
            ),
          );
    } else {
      await (db.update(
        db.reusableClauses,
      )..where((t) => t.id.equals(widget.clause!.id))).write(
        ReusableClausesCompanion(
          category: drift.Value(_catController.text.trim()),
          title: drift.Value(_titleController.text.trim()),
          bodyText: drift.Value(_contentController.text.trim()),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
