import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../documents/presentation/screens/document_detail_screen.dart';
import '../../../documents/presentation/screens/document_editor_screen.dart';
import '../../../documents/presentation/widgets/new_document_sheet.dart';

final clientDocumentsStreamProvider = StreamProvider.family.autoDispose<List<Document>, int>((ref, clientId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.documents)
        ..where((t) => t.clientId.equals(clientId))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.issueDate)]))
      .watch();
});

final singleClientStreamProvider = StreamProvider.family.autoDispose<Client?, int>((ref, clientId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.clients)..where((t) => t.id.equals(clientId))).watchSingleOrNull();
});

class ClientDetailScreen extends ConsumerWidget {
  final Client client;
  final Function(int docId)? onOpenDocument;

  const ClientDetailScreen({
    super.key,
    required this.client,
    this.onOpenDocument,
  });

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(activeAccentColorProvider);
    final docsAsync = ref.watch(clientDocumentsStreamProvider(client.id));
    final liveClientAsync = ref.watch(singleClientStreamProvider(client.id));
    final currentClient = liveClientAsync.value ?? client;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentClient.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Client Details',
            onPressed: () => _showEditClientDialog(context, ref, currentClient),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppDesignTokens.statusDanger),
            tooltip: 'Delete Client',
            onPressed: () => _confirmDeleteClient(context, ref, currentClient),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space16, vertical: AppDesignTokens.space16),
        children: [
          // Client Profile Card
          AppCard(
            variant: AppCardVariant.surface,
            padding: const EdgeInsets.all(AppDesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          currentClient.name.isNotEmpty ? currentClient.name.substring(0, 1).toUpperCase() : 'C',
                          style: GoogleFonts.inter(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDesignTokens.space14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentClient.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          if (currentClient.organization != null && currentClient.organization!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              currentClient.organization!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (currentClient.kraPin != null && currentClient.kraPin!.isNotEmpty) ...[
                            const SizedBox(height: AppDesignTokens.space6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(AppDesignTokens.radiusXs),
                              ),
                              child: Text(
                                'PIN: ${currentClient.kraPin}',
                                style: AppDesignTokens.tabularStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.space16),
                Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                // Contact Details
                if (currentClient.phone != null && currentClient.phone!.isNotEmpty) ...[
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.phone_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    title: Text(currentClient.phone!, style: theme.textTheme.bodyMedium),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call_rounded, color: EtoleColors.cyan, size: 20),
                          onPressed: () => _launchUrl('tel:${currentClient.phone}'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: EtoleColors.cyan, size: 20),
                          onPressed: () => _launchUrl('https://wa.me/${currentClient.phone!.replaceAll(RegExp(r'\D'), '')}'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (currentClient.email != null && currentClient.email!.isNotEmpty) ...[
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.email_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    title: Text(currentClient.email!, style: theme.textTheme.bodyMedium),
                    trailing: IconButton(
                      icon: Icon(Icons.send_rounded, size: 18, color: accent),
                      onPressed: () => _launchUrl('mailto:${currentClient.email}'),
                    ),
                  ),
                ],
                if (currentClient.address != null && currentClient.address!.isNotEmpty) ...[
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.location_on_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    title: Text(currentClient.address!, style: theme.textTheme.bodyMedium),
                  ),
                ],
                if (currentClient.notes != null && currentClient.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.space8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDesignTokens.space12),
                    decoration: BoxDecoration(
                      color: AppDesignTokens.statusWarning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                      border: Border.all(color: AppDesignTokens.statusWarning.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.rule_folder_outlined, size: 16, color: AppDesignTokens.statusWarning),
                            SizedBox(width: 6),
                            Text(
                              'Client Requirements & Checklist:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppDesignTokens.statusWarning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(currentClient.notes!, style: theme.textTheme.bodySmall?.copyWith(height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.space16),

          // Statement of Account Card
          AppCard(
            variant: AppCardVariant.high,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Generating Statement of Account for ${currentClient.name}...')),
              );
            },
            padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space16, vertical: AppDesignTokens.space14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                  ),
                  child: Icon(Icons.account_balance_wallet_outlined, color: accent, size: 22),
                ),
                const SizedBox(width: AppDesignTokens.space14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Statement of Account',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Export statement of invoices and balances',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurfaceVariant, size: 16),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.space24),

          // Document History for this client
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Document History',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  docsAsync.maybeWhen(
                    data: (docs) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                      ),
                      child: Text(
                        '${docs.length}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => NewDocumentSheet(
                      onSelectDocType: (type) => _openNewDocForClient(context, type, currentClient.id),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Doc'),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.space8),

          docsAsync.when(
            data: (docs) {
              if (docs.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.description_outlined,
                  title: 'No Documents Yet',
                  description: 'No business documents have been issued to this client.',
                  actionLabel: 'Create Document for Client',
                  onAction: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => NewDocumentSheet(
                        onSelectDocType: (type) => _openNewDocForClient(context, type, currentClient.id),
                      ),
                    );
                  },
                );
              }

              return Column(
                children: docs.map((doc) {
                  final docType = DocTypeExtension.fromCode(doc.docType);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDesignTokens.space8),
                    child: AppCard(
                      variant: AppCardVariant.low,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentDetailScreen(documentId: doc.id),
                          ),
                        );
                      },
                      padding: const EdgeInsets.all(AppDesignTokens.space12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                            ),
                            child: Icon(docType.icon, color: accent, size: 20),
                          ),
                          const SizedBox(width: AppDesignTokens.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        doc.docNumber,
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    StatusBadge(status: doc.status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormatter.format(doc.issueDate),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(doc.totalAmount, currencyCode: doc.currencyCode),
                                      style: AppDesignTokens.tabularStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SkeletonListPlaceholder(count: 3),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          const SizedBox(height: AppDesignTokens.space32),
        ],
      ),
    );
  }

  void _confirmDeleteClient(BuildContext context, WidgetRef ref, Client c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg)),
        title: const Text('Delete Client?'),
        content: Text(
          'Are you sure you want to delete "${c.name}"?\n\nAll existing documents and historical transactions will retain full client snapshot information intact.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignTokens.statusDanger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await (db.update(db.clients)..where((t) => t.id.equals(c.id))).write(
                const ClientsCompanion(isDeleted: drift.Value(true)),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Contact "${c.name}" moved to Trash'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: EtoleColors.gold,
                      onPressed: () async {
                        await (db.update(db.clients)..where((t) => t.id.equals(c.id))).write(
                          const ClientsCompanion(isDeleted: drift.Value(false)),
                        );
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete Client'),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(BuildContext context, WidgetRef ref, Client c) {
    final nameCtrl = TextEditingController(text: c.name);
    final orgCtrl = TextEditingController(text: c.organization ?? '');
    final phoneCtrl = TextEditingController(text: c.phone ?? '');
    final emailCtrl = TextEditingController(text: c.email ?? '');
    final kraCtrl = TextEditingController(text: c.kraPin ?? '');
    final addressCtrl = TextEditingController(text: c.address ?? '');
    final notesCtrl = TextEditingController(text: c.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg)),
        title: const Text('Edit Client Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Client Name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: orgCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Company / Organization'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: kraCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'KRA / Tax PIN'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Address / Box'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes / Checklist'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final db = ref.read(databaseProvider);
              await (db.update(db.clients)..where((t) => t.id.equals(c.id))).write(
                ClientsCompanion(
                  name: drift.Value(nameCtrl.text.trim()),
                  organization: drift.Value(orgCtrl.text.trim().isNotEmpty ? orgCtrl.text.trim() : null),
                  phone: drift.Value(phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null),
                  email: drift.Value(emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null),
                  kraPin: drift.Value(kraCtrl.text.trim().isNotEmpty ? kraCtrl.text.trim().toUpperCase() : null),
                  address: drift.Value(addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null),
                  notes: drift.Value(notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null),
                ),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client details updated.')),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _openNewDocForClient(BuildContext context, DocType docType, int clientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DocumentEditorScreen(
          docType: docType,
          initialClientId: clientId,
        ),
      ),
    );
  }
}
