import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/widgets/app_card.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _emptyAllTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'This will permanently delete all items currently in the trash. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await (db.delete(
        db.documents,
      )..where((t) => t.isDeleted.equals(true))).go();
      await (db.delete(
        db.clients,
      )..where((t) => t.isDeleted.equals(true))).go();
      await (db.delete(
        db.itemsLibrary,
      )..where((t) => t.isDeleted.equals(true))).go();
      await (db.delete(
        db.networkingEvents,
      )..where((t) => t.isDeleted.equals(true))).go();
      await (db.delete(
        db.networkingLeads,
      )..where((t) => t.isDeleted.equals(true))).go();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trash emptied successfully')),
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash & Recovery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Empty Trash',
            onPressed: _emptyAllTrash,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Documents'),
            Tab(text: 'People & Contacts'),
            Tab(text: 'Places & Events'),
            Tab(text: 'Services & Rates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentsTrash(db),
          _buildClientsTrash(db),
          _buildEventsTrash(db),
          _buildItemsTrash(db),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String itemType) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No deleted $itemType in trash',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Deleted items remain here for 30 days before permanent deletion, with instant restore.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTrash(AppDatabase db) {
    return StreamBuilder<List<Document>>(
      stream: (db.select(
        db.documents,
      )..where((t) => t.isDeleted.equals(true))).watch(),
      builder: (context, snapshot) {
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) return _buildEmptyState('documents');

        return ListView.separated(
          padding: const EdgeInsets.all(AppDesignTokens.space16),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDesignTokens.space8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.description_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  doc.docNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${doc.docType.toUpperCase()} • Deleted: ${_formatDate(doc.deletedAt)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.restore_rounded,
                        color: Colors.teal,
                      ),
                      tooltip: 'Restore Document',
                      onPressed: () async {
                        await (db.update(
                          db.documents,
                        )..where((t) => t.id.equals(doc.id))).write(
                          const DocumentsCompanion(
                            isDeleted: drift.Value(false),
                            deletedAt: drift.Value(null),
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Restored document ${doc.docNumber}',
                              ),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await (db.update(
                                    db.documents,
                                  )..where((t) => t.id.equals(doc.id))).write(
                                    DocumentsCompanion(
                                      isDeleted: const drift.Value(true),
                                      deletedAt: drift.Value(DateTime.now()),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Delete Permanently',
                      onPressed: () => _confirmPermanentDelete(
                        title: 'Delete Document Permanently',
                        message:
                            'Permanently remove ${doc.docNumber}? This cannot be undone.',
                        onDelete: () => (db.delete(
                          db.documents,
                        )..where((t) => t.id.equals(doc.id))).go(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClientsTrash(AppDatabase db) {
    return StreamBuilder<List<Client>>(
      stream: (db.select(
        db.clients,
      )..where((t) => t.isDeleted.equals(true))).watch(),
      builder: (context, clientSnap) {
        return StreamBuilder<List<NetworkingLead>>(
          stream: (db.select(
            db.networkingLeads,
          )..where((t) => t.isDeleted.equals(true))).watch(),
          builder: (context, leadSnap) {
            final clients = clientSnap.data ?? [];
            final leads = leadSnap.data ?? [];
            if (clients.isEmpty && leads.isEmpty)
              return _buildEmptyState('people & contacts');

            return ListView(
              padding: const EdgeInsets.all(AppDesignTokens.space16),
              children: [
                if (clients.isNotEmpty) ...[
                  ...clients.map(
                    (client) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDesignTokens.space8,
                      ),
                      child: AppCard(
                        variant: AppCardVariant.surface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            client.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${client.organization ?? 'Client'} • Deleted: ${_formatDate(client.deletedAt)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.restore_rounded,
                                  color: Colors.teal,
                                ),
                                tooltip: 'Restore Person',
                                onPressed: () async {
                                  await (db.update(db.clients)
                                        ..where((t) => t.id.equals(client.id)))
                                      .write(
                                        const ClientsCompanion(
                                          isDeleted: drift.Value(false),
                                          deletedAt: drift.Value(null),
                                        ),
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Restored ${client.name}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever_rounded,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Delete Permanently',
                                onPressed: () => _confirmPermanentDelete(
                                  title: 'Delete Person Permanently',
                                  message:
                                      'Permanently remove ${client.name}? Documents already issued will retain client snapshot.',
                                  onDelete: () => (db.delete(
                                    db.clients,
                                  )..where((t) => t.id.equals(client.id))).go(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (leads.isNotEmpty) ...[
                  ...leads.map(
                    (lead) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDesignTokens.space8,
                      ),
                      child: AppCard(
                        variant: AppCardVariant.surface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber.withValues(
                              alpha: 0.15,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                lead.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Network',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${lead.organization ?? lead.title ?? 'Contact'} • Deleted: ${_formatDate(lead.deletedAt)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.restore_rounded,
                                  color: Colors.teal,
                                ),
                                tooltip: 'Restore Contact',
                                onPressed: () async {
                                  await (db.update(
                                    db.networkingLeads,
                                  )..where((t) => t.id.equals(lead.id))).write(
                                    const NetworkingLeadsCompanion(
                                      isDeleted: drift.Value(false),
                                      deletedAt: drift.Value(null),
                                    ),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Restored ${lead.name} to Network',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever_rounded,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Delete Permanently',
                                onPressed: () => _confirmPermanentDelete(
                                  title: 'Delete Contact Permanently',
                                  message:
                                      'Permanently remove ${lead.name} from Network? This cannot be undone.',
                                  onDelete: () => (db.delete(
                                    db.networkingLeads,
                                  )..where((t) => t.id.equals(lead.id))).go(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEventsTrash(AppDatabase db) {
    return StreamBuilder<List<NetworkingEvent>>(
      stream: (db.select(
        db.networkingEvents,
      )..where((t) => t.isDeleted.equals(true))).watch(),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) return _buildEmptyState('places & events');

        return ListView.separated(
          padding: const EdgeInsets.all(AppDesignTokens.space16),
          itemCount: events.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDesignTokens.space8),
          itemBuilder: (context, index) {
            final ev = events[index];
            return AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.place_outlined,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                title: Text(
                  ev.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${ev.eventType.toUpperCase()} • Deleted: ${_formatDate(ev.deletedAt)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.restore_rounded,
                        color: Colors.teal,
                      ),
                      tooltip: 'Restore Place/Event',
                      onPressed: () async {
                        await (db.update(
                          db.networkingEvents,
                        )..where((t) => t.id.equals(ev.id))).write(
                          const NetworkingEventsCompanion(
                            isDeleted: drift.Value(false),
                            deletedAt: drift.Value(null),
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Restored ${ev.name}')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Delete Permanently',
                      onPressed: () => _confirmPermanentDelete(
                        title: 'Delete Place/Event Permanently',
                        message:
                            'Permanently remove "${ev.name}"? This cannot be undone.',
                        onDelete: () => (db.delete(
                          db.networkingEvents,
                        )..where((t) => t.id.equals(ev.id))).go(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemsTrash(AppDatabase db) {
    return StreamBuilder<List<ItemsLibraryData>>(
      stream: (db.select(
        db.itemsLibrary,
      )..where((t) => t.isDeleted.equals(true))).watch(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) return _buildEmptyState('rates & services');

        return ListView.separated(
          padding: const EdgeInsets.all(AppDesignTokens.space16),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDesignTokens.space8),
          itemBuilder: (context, index) {
            final item = items[index];
            return AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${item.category} • KES ${item.unitPrice.toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.restore_rounded,
                        color: Colors.teal,
                      ),
                      tooltip: 'Restore Item',
                      onPressed: () async {
                        await (db.update(
                          db.itemsLibrary,
                        )..where((t) => t.id.equals(item.id))).write(
                          const ItemsLibraryCompanion(
                            isDeleted: drift.Value(false),
                            deletedAt: drift.Value(null),
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Restored ${item.title}'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await (db.update(
                                    db.itemsLibrary,
                                  )..where((t) => t.id.equals(item.id))).write(
                                    ItemsLibraryCompanion(
                                      isDeleted: const drift.Value(true),
                                      deletedAt: drift.Value(DateTime.now()),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Delete Permanently',
                      onPressed: () => _confirmPermanentDelete(
                        title: 'Delete Item Permanently',
                        message:
                            'Permanently remove ${item.title}? Existing documents will not be affected.',
                        onDelete: () => (db.delete(
                          db.itemsLibrary,
                        )..where((t) => t.id.equals(item.id))).go(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmPermanentDelete({
    required String title,
    required String message,
    required Future<void> Function() onDelete,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onDelete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted permanently.')),
        );
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}
