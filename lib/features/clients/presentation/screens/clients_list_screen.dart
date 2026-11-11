import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import 'client_detail_screen.dart';

final allClientsStreamProvider = StreamProvider<List<Client>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.clients)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
      .watch();
});

class ClientsListScreen extends ConsumerStatefulWidget {
  final Function(int docId)? onOpenDocument;

  const ClientsListScreen({super.key, this.onOpenDocument});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _importFromContacts(BuildContext context) async {
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts permission is required to import from phonebook.'),
          ),
        );
        return;
      }

      final picked = await FlutterContacts.openExternalPick();
      if (picked == null) return;

      final fullContact = await FlutterContacts.getContact(picked.id) ?? picked;

      final name = fullContact.displayName.isNotEmpty
          ? fullContact.displayName
          : '${fullContact.name.first} ${fullContact.name.last}'.trim();
      final phone = fullContact.phones.isNotEmpty ? fullContact.phones.first.number : '';
      final email = fullContact.emails.isNotEmpty ? fullContact.emails.first.address : '';
      final org = fullContact.organizations.isNotEmpty ? fullContact.organizations.first.company : '';
      final address = fullContact.addresses.isNotEmpty ? fullContact.addresses.first.address : '';

      if (!context.mounted) return;
      _showAddEditContactDialog(
        context,
        initialName: name,
        initialOrg: org,
        initialPhone: phone,
        initialEmail: email,
        initialAddress: address,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load contact: $e')),
      );
    }
  }

  Future<void> _pickFromNetwork(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final leads = await (db.select(db.networkingLeads)
          ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
        .get();

    if (!context.mounted) return;

    if (leads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts found in your Network yet.')),
      );
      return;
    }

    final selectedLead = await showModalBottomSheet<NetworkingLead>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14171A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = leads.where((l) {
              final q = query.toLowerCase();
              return l.name.toLowerCase().contains(q) ||
                  (l.organization?.toLowerCase().contains(q) ?? false) ||
                  (l.title?.toLowerCase().contains(q) ?? false);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FROM MY NETWORK',
                          style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: EtoleColors.creamSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2228),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        onChanged: (v) => setModalState(() => query = v.trim()),
                        style: GoogleFonts.inter(color: EtoleColors.cream, fontSize: 13),
                        cursorColor: EtoleColors.cyan,
                        decoration: const InputDecoration(
                          hintText: 'Search people met in Network...',
                          hintStyle: TextStyle(color: EtoleColors.creamSecondary, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                      ),
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  'No matching people from Network',
                                  style: TextStyle(color: EtoleColors.creamSecondary),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: Color(0x18F3EAD9),
                                height: 1,
                              ),
                              itemBuilder: (ctx, idx) {
                                final l = filtered[idx];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF262C34),
                                      border: Border.all(
                                        color: EtoleColors.cyan.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      l.name.isNotEmpty ? l.name.substring(0, 1).toUpperCase() : 'N',
                                      style: GoogleFonts.inter(
                                        color: EtoleColors.cream,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    l.name,
                                    style: GoogleFonts.inter(
                                      color: EtoleColors.cream,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    l.organization ?? l.title ?? l.phone ?? 'Lead',
                                    style: GoogleFonts.inter(
                                      color: EtoleColors.creamSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(ctx, l),
                                );
                              },
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

    if (selectedLead != null && mounted) {
      _showAddEditContactDialog(
        context,
        initialName: selectedLead.name,
        initialOrg: selectedLead.organization ?? selectedLead.title ?? '',
        initialPhone: selectedLead.phone ?? selectedLead.whatsapp ?? '',
        initialEmail: selectedLead.email ?? '',
        initialAddress: selectedLead.physicalAddress ?? '',
        initialNotes: selectedLead.notes ?? '',
        linkedLeadId: selectedLead.id,
      );
    }
  }

  void _showAddEditContactDialog(
    BuildContext context, {
    Client? client,
    String? initialName,
    String? initialOrg,
    String? initialPhone,
    String? initialEmail,
    String? initialKra,
    String? initialAddress,
    String? initialNotes,
    int? linkedLeadId,
  }) {
    final isEdit = client != null;
    final nameCtrl = TextEditingController(text: initialName ?? client?.name ?? '');
    final orgCtrl = TextEditingController(text: initialOrg ?? client?.organization ?? '');
    final phoneCtrl = TextEditingController(text: initialPhone ?? client?.phone ?? '');
    final emailCtrl = TextEditingController(text: initialEmail ?? client?.email ?? '');
    final kraCtrl = TextEditingController(text: initialKra ?? client?.kraPin ?? '');
    final addressCtrl = TextEditingController(text: initialAddress ?? client?.address ?? '');
    final notesCtrl = TextEditingController(text: initialNotes ?? client?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14171A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'EDIT CONTACT' : 'ADD NEW CONTACT',
                    style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: EtoleColors.creamSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Import Actions at top of form
              if (!isEdit) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EtoleColors.cream,
                          side: const BorderSide(color: Color(0x33F3EAD9)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _importFromContacts(context);
                        },
                        icon: const Icon(Icons.contacts_rounded, size: 16, color: EtoleColors.cyan),
                        label: Text(
                          'Phone Contacts',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EtoleColors.cream,
                          side: const BorderSide(color: Color(0x33F3EAD9)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _pickFromNetwork(context);
                        },
                        icon: const Icon(Icons.hub_rounded, size: 16, color: EtoleColors.cyan),
                        label: Text(
                          'From Network',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0x18F3EAD9), height: 1),
                const SizedBox(height: 16),
              ],

              // Form fields
              _buildField('Full Name *', nameCtrl, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 10),
              _buildField('Organisation / Company', orgCtrl, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 10),
              _buildField('Phone Number', phoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _buildField('Email Address', emailCtrl, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _buildField('KRA / Tax PIN (e.g. A012345678Z)', kraCtrl, textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 10),
              _buildField('Physical / Billing Address', addressCtrl),
              const SizedBox(height: 10),
              _buildField('Notes / Requirements', notesCtrl, maxLines: 2),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final db = ref.read(databaseProvider);
                    if (isEdit) {
                      await (db.update(db.clients)..where((t) => t.id.equals(client.id))).write(
                        ClientsCompanion(
                          name: drift.Value(name),
                          organization: drift.Value(orgCtrl.text.trim().isNotEmpty ? orgCtrl.text.trim() : null),
                          phone: drift.Value(phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null),
                          email: drift.Value(emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null),
                          kraPin: drift.Value(kraCtrl.text.trim().isNotEmpty ? kraCtrl.text.trim() : null),
                          address: drift.Value(addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null),
                          notes: drift.Value(notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null),
                        ),
                      );
                    } else {
                      await db.into(db.clients).insert(
                            ClientsCompanion.insert(
                              name: name,
                              organization: drift.Value(orgCtrl.text.trim().isNotEmpty ? orgCtrl.text.trim() : null),
                              phone: drift.Value(phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null),
                              email: drift.Value(emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null),
                              kraPin: drift.Value(kraCtrl.text.trim().isNotEmpty ? kraCtrl.text.trim() : null),
                              address: drift.Value(addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null),
                              notes: drift.Value(notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null),
                            ),
                          );

                      // If linked to a lead, mark lead as client
                      if (linkedLeadId != null) {
                        await (db.update(db.networkingLeads)..where((t) => t.id.equals(linkedLeadId))).write(
                          const NetworkingLeadsCompanion(isClient: drift.Value(true)),
                        );
                      }
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(
                    isEdit ? 'Save Changes' : 'Add Contact',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: EtoleColors.creamSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2228),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x22F3EAD9), width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            style: GoogleFonts.inter(color: EtoleColors.cream, fontSize: 13.5),
            cursorColor: EtoleColors.cyan,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteClient(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Contact?', style: GoogleFonts.inter(color: EtoleColors.cream)),
        content: Text(
          'Move "${client.name}" to Trash? You can undo this action immediately.',
          style: const TextStyle(color: EtoleColors.creamSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: EtoleColors.creamSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE54D2E),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await (db.update(db.clients)..where((t) => t.id.equals(client.id))).write(
                const ClientsCompanion(isDeleted: drift.Value(true)),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                     content: Text('Contact "${client.name}" moved to Trash'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: EtoleColors.gold,
                      onPressed: () async {
                        await (db.update(db.clients)..where((t) => t.id.equals(client.id))).write(
                          const ClientsCompanion(isDeleted: drift.Value(false)),
                        );
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allClientsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0C0E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: EtoleColors.cream, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CONTACTS',
          style: EtoleTypography.h2.copyWith(
            color: EtoleColors.cream,
            letterSpacing: 2.0,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: EtoleColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: () => _showAddEditContactDialog(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Add new',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF14171A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _search.isNotEmpty ? EtoleColors.cyan : const Color(0x33F3EAD9),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: EtoleColors.creamSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _search = val.toLowerCase().trim()),
                      style: GoogleFonts.inter(color: EtoleColors.cream, fontSize: 13.5),
                      cursorColor: EtoleColors.cyan,
                      decoration: InputDecoration(
                        hintText: 'Search contacts by name, org, or PIN...',
                        hintStyle: GoogleFonts.inter(
                          color: EtoleColors.creamSecondary.withValues(alpha: 0.6),
                          fontSize: 12.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_search.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                      child: const Icon(Icons.close_rounded, color: EtoleColors.creamSecondary, size: 16),
                    ),
                ],
              ),
            ),
          ),

          // Alphabetical list of contacts
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                final filtered = clients.where((c) {
                  if (_search.isEmpty) return true;
                  final nameMatch = c.name.toLowerCase().contains(_search);
                  final orgMatch = c.organization?.toLowerCase().contains(_search) ?? false;
                  final pinMatch = c.kraPin?.toLowerCase().contains(_search) ?? false;
                  return nameMatch || orgMatch || pinMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded, color: EtoleColors.creamSecondary, size: 44),
                          const SizedBox(height: 14),
                          Text(
                            _search.isEmpty ? 'No contacts yet' : 'No contacts match "$_search"',
                            style: GoogleFonts.inter(
                              color: EtoleColors.cream,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _search.isEmpty
                                ? 'Add clients manually, import from phonebook, or select people from your Network.'
                                : 'Try searching for a different name or organization.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: EtoleColors.creamSecondary, fontSize: 12.5),
                          ),
                          if (_search.isEmpty) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EtoleColors.cyan,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () => _showAddEditContactDialog(context),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Add your first contact',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Color(0x18F3EAD9),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final client = filtered[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E2228),
                          border: Border.all(
                            color: EtoleColors.cyan.withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          client.name.isNotEmpty ? client.name.substring(0, 1).toUpperCase() : 'C',
                          style: GoogleFonts.inter(
                            color: EtoleColors.cream,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      title: Text(
                        client.name,
                        style: GoogleFonts.inter(
                          color: EtoleColors.cream,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: Text(
                        client.organization ?? client.phone ?? client.email ?? 'Direct Client',
                        style: GoogleFonts.inter(
                          color: EtoleColors.creamSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (client.kraPin != null && client.kraPin!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0x18F3EAD9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                client.kraPin!,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  color: EtoleColors.creamSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: EtoleColors.creamSecondary,
                          ),
                        ],
                      ),
                      onTap: () {
                        EtoleHaptics.light();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientDetailScreen(
                              client: client,
                              onOpenDocument: widget.onOpenDocument,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: EtoleColors.cyan),
              ),
              error: (err, _) => Center(
                child: Text('Error: $err', style: const TextStyle(color: EtoleColors.creamSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
