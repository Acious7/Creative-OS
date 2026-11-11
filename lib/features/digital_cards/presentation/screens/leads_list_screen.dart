import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../documents/presentation/screens/document_editor_screen.dart';
import '../../../documents/presentation/widgets/new_document_sheet.dart';
import '../providers/cards_providers.dart';
import 'events_list_screen.dart';
import 'lead_editor_screen.dart';

class LeadsListScreen extends ConsumerStatefulWidget {
  final bool isSubView;

  const LeadsListScreen({super.key, this.isSubView = false});

  @override
  ConsumerState<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends ConsumerState<LeadsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  int? _selectedEventFilterId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(networkingLeadsProvider);
    final eventsAsync = ref.watch(networkingEventsProvider);
    final activeEvent = ref.watch(activeEventModeProvider).value;
    final accent = ref.watch(activeAccentColorProvider);

    return Scaffold(
      appBar: widget.isSubView
          ? null
          : AppBar(
              title: const Text('Who I Met (Networking Leads)'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.event_available_outlined),
                  tooltip: 'Events & Event Mode',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EventsListScreen(),
                      ),
                    );
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'All Leads'),
                  Tab(text: 'New'),
                  Tab(text: 'Contacted'),
                  Tab(text: 'In Discussion'),
                  Tab(text: 'Converted'),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeadEditorScreen()),
          );
        },
        backgroundColor: accent,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text(
          'Add Lead',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Event Mode Active Indicator Banner
          if (activeEvent != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.deepOrange.shade700,
              child: Row(
                children: [
                  const Icon(
                    Icons.sensors_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'EVENT MODE ON: "${activeEvent.name}" — New leads auto-tagged',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final db = ref.read(databaseProvider);
                      await (db.update(
                        db.networkingEvents,
                      )..where((t) => t.id.equals(activeEvent.id))).write(
                        const NetworkingEventsCompanion(
                          isEventModeActive: drift.Value(false),
                        ),
                      );
                    },
                    child: const Text(
                      'TURN OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search & Event Filter Bar
          Padding(
            padding: const EdgeInsets.all(AppDesignTokens.space12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search leads, companies, notes...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                if (eventsAsync.value != null &&
                    eventsAsync.value!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  DropdownButton<int?>(
                    value: _selectedEventFilterId,
                    hint: const Text(
                      'Filter Event',
                      style: TextStyle(fontSize: 12),
                    ),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Events'),
                      ),
                      ...eventsAsync.value!.map(
                        (e) => DropdownMenuItem<int?>(
                          value: e.id,
                          child: Text(
                            e.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedEventFilterId = val),
                  ),
                ],
              ],
            ),
          ),

          if (widget.isSubView)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: accent,
              unselectedLabelColor: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
              indicatorColor: accent,
              tabs: const [
                Tab(text: 'All Leads'),
                Tab(text: 'New'),
                Tab(text: 'Contacted'),
                Tab(text: 'In Discussion'),
                Tab(text: 'Converted'),
              ],
            ),

          // Tab View for Leads List
          Expanded(
            child: leadsAsync.when(
              data: (leads) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFilteredLeadsList(leads, null),
                    _buildFilteredLeadsList(leads, 'new'),
                    _buildFilteredLeadsList(leads, 'contacted'),
                    _buildFilteredLeadsList(leads, 'in_discussion'),
                    _buildFilteredLeadsList(leads, 'converted'),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredLeadsList(
    List<NetworkingLead> allLeads,
    String? statusFilter,
  ) {
    final theme = Theme.of(context);
    final accent = ref.watch(activeAccentColorProvider);

    var filtered = allLeads.where((l) {
      if (statusFilter != null && l.status != statusFilter) return false;
      if (_selectedEventFilterId != null && l.eventId != _selectedEventFilterId)
        return false;
      if (_searchQuery.isNotEmpty) {
        final matchName = l.name.toLowerCase().contains(_searchQuery);
        final matchOrg = (l.organization ?? '').toLowerCase().contains(
          _searchQuery,
        );
        final matchNotes = (l.notes ?? '').toLowerCase().contains(_searchQuery);
        if (!matchName && !matchOrg && !matchNotes) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'No Leads Found',
        description:
            'Tap "Add Lead" to quickly record contacts you meet at events.',
        actionLabel: 'Add Lead',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeadEditorScreen()),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.space12,
        vertical: AppDesignTokens.space8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final lead = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDesignTokens.space10),
          child: AppCard(
            variant: AppCardVariant.surface,
            padding: const EdgeInsets.all(AppDesignTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (lead.title != null || lead.organization != null)
                            Text(
                              '${lead.title ?? ""} ${lead.organization != null ? "• ${lead.organization}" : ""}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusChip(lead.status),
                  ],
                ),
                if (lead.notes != null && lead.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    lead.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Met ${DateFormatter.format(lead.dateMet)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (lead.followUpDate != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.alarm, size: 12, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        'Follow-up: ${DateFormatter.format(lead.followUpDate!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (lead.whatsapp != null || lead.phone != null)
                          IconButton(
                            icon: const Icon(
                              Icons.chat_outlined,
                              color: Colors.green,
                              size: 20,
                            ),
                            tooltip: 'WhatsApp Chat',
                            onPressed: () => _launchWhatsApp(lead),
                          ),
                        if (lead.email != null)
                          IconButton(
                            icon: Icon(
                              Icons.email_outlined,
                              color: accent,
                              size: 20,
                            ),
                            tooltip: 'Email Lead',
                            onPressed: () => _launchEmail(lead),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        if (lead.status != 'converted')
                          ElevatedButton.icon(
                            onPressed: () =>
                                _convertToClient(context, ref, lead),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                            ),
                            icon: const Icon(
                              Icons.person_add_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Convert to Client',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LeadEditorScreen(lead: lead),
                                ),
                              );
                            } else if (val == 'delete') {
                              _deleteLead(ref, lead);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Lead'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Move to Trash',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = Colors.grey;
    String label = status;
    if (status == 'new') {
      bg = EtoleColors.cyan;
      label = 'New';
    } else if (status == 'contacted') {
      bg = Colors.orange;
      label = 'Contacted';
    } else if (status == 'in_discussion') {
      bg = Colors.purple;
      label = 'In Discussion';
    } else if (status == 'converted') {
      bg = Colors.green;
      label = 'Converted Client';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Future<void> _launchWhatsApp(NetworkingLead lead) async {
    final rawPhone = (lead.whatsapp ?? lead.phone ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    final uri = Uri.parse(
      'https://wa.me/$rawPhone?text=${Uri.encodeComponent("Hi ${lead.name}, nice connecting with you!")}',
    );
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchEmail(NetworkingLead lead) async {
    final uri = Uri.parse(
      'mailto:${lead.email}?subject=${Uri.encodeComponent("Connecting from our recent meeting")}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _convertToClient(
    BuildContext context,
    WidgetRef ref,
    NetworkingLead lead,
  ) async {
    final db = ref.read(databaseProvider);

    // 1. Create new Client from Lead
    final clientId = await db
        .into(db.clients)
        .insert(
          ClientsCompanion.insert(
            name: lead.name,
            organization: drift.Value(lead.organization),
            email: drift.Value(lead.email),
            phone: drift.Value(lead.phone ?? lead.whatsapp),
            notes: drift.Value(lead.notes),
            cardPhotoPath: drift.Value(lead.cardPhotoPath),
          ),
        );

    // 2. Mark Lead as Converted
    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(lead.id))).write(
      NetworkingLeadsCompanion(
        status: const drift.Value('converted'),
        convertedClientId: drift.Value(clientId),
      ),
    );

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lead Converted to Client!'),
          content: Text(
            '${lead.name} is now saved in your Clients directory. Would you like to create a Quotation or Job now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => NewDocumentSheet(
                    onSelectDocType: (docType) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentEditorScreen(
                            docType: docType,
                            initialClientId: clientId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              child: const Text('Create Quotation / Doc'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteLead(WidgetRef ref, NetworkingLead lead) async {
    final db = ref.read(databaseProvider);
    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(lead.id))).write(
      NetworkingLeadsCompanion(
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(DateTime.now()),
      ),
    );
  }
}
