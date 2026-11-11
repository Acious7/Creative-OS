import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../documents/presentation/screens/document_editor_screen.dart';
import '../../domain/voice_memo_service.dart';
import '../../domain/freelance_crm_models.dart';
import '../providers/cards_providers.dart';
import '../widgets/edit_person_sheet.dart';
import '../widgets/edit_deal_sheet.dart';
import '../widgets/smart_pitch_sheet.dart';
import 'event_detail_screen.dart';

class PersonProfileScreen extends ConsumerStatefulWidget {
  final NetworkingLead person;

  const PersonProfileScreen({super.key, required this.person});

  @override
  ConsumerState<PersonProfileScreen> createState() =>
      _PersonProfileScreenState();
}

class _PersonProfileScreenState extends ConsumerState<PersonProfileScreen> {
  late NetworkingLead _person;
  String? _currentlyPlayingMemoId;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
  }

  Future<void> _toggleClientStatus() async {
    EtoleHaptics.selection();
    final db = ref.read(databaseProvider);
    final newClientStatus = !_person.isClient;

    int? clientId = _person.convertedClientId;
    if (newClientStatus && clientId == null) {
      // Add to Clients table so they appear in Docs
      clientId = await db
          .into(db.clients)
          .insert(
            ClientsCompanion(
              name: drift.Value(_person.name),
              organization: drift.Value(_person.organization),
              phone: drift.Value(_person.phone),
              email: drift.Value(_person.email),
              address: drift.Value(_person.physicalAddress),
              notes: drift.Value(_person.notes),
            ),
          );
    }

    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(_person.id))).write(
      NetworkingLeadsCompanion(
        isClient: drift.Value(newClientStatus),
        convertedClientId: drift.Value(clientId),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    setState(() {
      _person = _person.copyWith(
        isClient: newClientStatus,
        convertedClientId: drift.Value(clientId),
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newClientStatus
                ? '${_person.name} marked as Client (visible in Docs)'
                : '${_person.name} unmarked as Client',
            style: const TextStyle(color: EtoleColors.cream),
          ),
          backgroundColor: const Color(0xFF141719),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<int> _ensureClientId() async {
    if (_person.convertedClientId != null) {
      return _person.convertedClientId!;
    }
    final db = ref.read(databaseProvider);
    final clientId = await db
        .into(db.clients)
        .insert(
          ClientsCompanion(
            name: drift.Value(_person.name),
            organization: drift.Value(_person.organization),
            phone: drift.Value(_person.phone),
            email: drift.Value(_person.email),
            address: drift.Value(_person.physicalAddress),
            notes: drift.Value(_person.notes),
          ),
        );
    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(_person.id))).write(
      NetworkingLeadsCompanion(
        isClient: const drift.Value(true),
        convertedClientId: drift.Value(clientId),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
    setState(() {
      _person = _person.copyWith(
        isClient: true,
        convertedClientId: drift.Value(clientId),
      );
    });
    return clientId;
  }

  void _sendSmartWhatsAppFollowUp() async {
    final phone = _person.whatsapp ?? _person.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for WhatsApp follow-up'),
        ),
      );
      return;
    }
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final org =
        (_person.organization != null && _person.organization!.isNotEmpty)
        ? ' at ${_person.organization}'
        : '';
    final notes = (_person.notes != null && _person.notes!.isNotEmpty)
        ? '\nRegarding our discussion: "${_person.notes}"'
        : '';
    final text =
        'Hi ${_person.name}! Great connecting with you$org. Brian Etole here from Brian Etole Productions (Director & Hybrid Filmmaker).$notes\n\nLooking forward to collaborating on your upcoming visual projects. Let me know when is best for a quick alignment chat!';

    final uri = Uri.parse(
      'https://wa.me/$clean?text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _convertLeadToDocument(BuildContext context) async {
    EtoleHaptics.selection();
    final clientId = await _ensureClientId();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF141719),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: EtoleColors.cyan.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: EtoleColors.cyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'CONVERT TO DOCUMENT',
                  style: EtoleTypography.labelCaps(color: EtoleColors.cyan)
                      .copyWith(fontSize: 12, letterSpacing: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Draft an executive document pre-filled with ${_person.name}\'s profile:',
              style: EtoleTypography.bodySmall(
                color: EtoleColors.creamSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _buildDocOption(
              icon: Icons.request_quote_outlined,
              title: 'Quotation / Commercial Pitch',
              subtitle: 'Send estimated project scope & rate proposal',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentEditorScreen(
                      docType: DocType.quotation,
                      initialClientId: clientId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildDocOption(
              icon: Icons.receipt_long_outlined,
              title: 'Tax Invoice',
              subtitle:
                  'Bill client for services, shoot deposit, or production',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentEditorScreen(
                      docType: DocType.invoice,
                      initialClientId: clientId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildDocOption(
              icon: Icons.description_outlined,
              title: 'Production Contract',
              subtitle: 'Terms of service, deliverables, IP rights',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentEditorScreen(
                      docType: DocType.contract,
                      initialClientId: clientId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildDocOption(
              icon: Icons.bookmark_added_outlined,
              title: 'Payment Receipt',
              subtitle: 'Confirm received project payment with stamp',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentEditorScreen(
                      docType: DocType.receipt,
                      initialClientId: clientId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDocOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x35141719),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EtoleColors.cyan.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EtoleColors.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: EtoleColors.cyan, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: EtoleColors.cream,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: EtoleColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: EtoleColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePromiseDone(
    String eventKey,
    int index,
    List<Map<String, dynamic>> promises,
  ) async {
    EtoleHaptics.selection();
    promises[index]['isDone'] = !(promises[index]['isDone'] as bool? ?? false);
    final db = ref.read(databaseProvider);
    final jsonStr = jsonEncode(promises);

    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(_person.id))).write(
      NetworkingLeadsCompanion(
        promisesJson: drift.Value(jsonStr),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    setState(() {
      _person = _person.copyWith(promisesJson: drift.Value(jsonStr));
    });
  }

  Future<void> _saveToPhoneContacts() async {
    EtoleHaptics.medium();
    try {
      final permission = await FlutterContacts.requestPermission();
      if (!permission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission not granted')),
          );
        }
        return;
      }

      final names = _person.name.trim().split(' ');
      final first = names.isNotEmpty ? names.first : _person.name;
      final last = names.length > 1 ? names.sublist(1).join(' ') : '';

      final newContact = Contact(
        name: Name(first: first, last: last),
        phones: _person.phone != null ? [Phone(_person.phone!)] : [],
        emails: _person.email != null ? [Email(_person.email!)] : [],
        organizations: _person.organization != null
            ? [
                Organization(
                  company: _person.organization!,
                  title: _person.title ?? '',
                ),
              ]
            : [],
      );

      await newContact.insert();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${_person.name} to phone contacts')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save contact: $e')));
      }
    }
  }

  void _callPhone() async {
    final phone = _person.phone;
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  void _openWhatsApp() async {
    final phone = _person.whatsapp ?? _person.phone;
    if (phone != null && phone.isNotEmpty) {
      final clean = phone.replaceAll(RegExp(r'\D'), '');
      final uri = Uri.parse('https://wa.me/$clean');
      if (await canLaunchUrl(uri))
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _sendEmail() async {
    final email = _person.email;
    if (email != null && email.isNotEmpty) {
      final uri = Uri.parse('mailto:$email');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  Future<void> _editPerson() async {
    final updated = await EditPersonSheet.show(context, person: _person);
    if (updated != null && mounted) {
      setState(() => _person = updated);
    }
  }

  void _deletePerson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF141719),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: EtoleColors.cyan.withValues(alpha: 0.3)),
          ),
          title: Text(
            'Delete Contact?',
            style: EtoleTypography.h3.copyWith(color: EtoleColors.cream),
          ),
          content: Text(
            'Move "${_person.name}" to Trash?\nYou can restore them at any time.',
            style: EtoleTypography.bodySmall(color: EtoleColors.creamSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: EtoleColors.creamMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Move to Trash',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    EtoleHaptics.warning();
    final db = ref.read(databaseProvider);
    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(_person.id))).write(
      NetworkingLeadsCompanion(
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(DateTime.now()),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_person.name} moved to Trash'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: EtoleColors.gold,
            onPressed: () async {
              await (db.update(
                db.networkingLeads,
              )..where((t) => t.id.equals(_person.id))).write(
                const NetworkingLeadsCompanion(
                  isDeleted: drift.Value(false),
                  deletedAt: drift.Value(null),
                ),
              );
            },
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  List<Map<String, dynamic>> _parseJsonList(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    } catch (_) {}
    return [];
  }

  Map<String, dynamic> _parseJsonMap(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allEvents = ref.watch(networkingEventsProvider).value ?? [];

    // Find all events where Brian met this person
    final matchedEvents = allEvents.where((e) {
      if (e.id == _person.eventId) return true;
      if (_person.eventIdsJson != null &&
          _person.eventIdsJson!.contains(e.id.toString()))
        return true;
      return false;
    }).toList();

    final socialLinks = _parseJsonMap(_person.socialLinksJson);
    final promises = _parseJsonList(_person.promisesJson);
    final photosWithThem = _parseJsonList(_person.photosWithPersonJson);
    final voiceNotes = _parseJsonList(_person.voiceNotesJson);
    final flyers = _parseJsonList(_person.flyersPhotosJson);

    return Scaffold(
      backgroundColor: isDark ? EtoleColors.darkBase : EtoleColors.lightBase,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Minimal Header Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        EtoleHaptics.light();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0x35141719)
                              : const Color(0x20000000),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? EtoleColors.cream.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              size: 14,
                              color: EtoleColors.cyan,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'BACK',
                              style: EtoleTypography.labelCaps(
                                color: isDark
                                    ? EtoleColors.cream
                                    : EtoleColors.lightTextPrimary,
                              ).copyWith(fontSize: 10, letterSpacing: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _person.isClient
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: _person.isClient
                                ? EtoleColors.cyan
                                : EtoleColors.muted,
                            size: 22,
                          ),
                          tooltip: _person.isClient
                              ? 'Marked as Client'
                              : 'Mark as Client',
                          onPressed: _toggleClientStatus,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: EtoleColors.creamSecondary,
                            size: 20,
                          ),
                          tooltip: 'Edit Contact Details',
                          onPressed: _editPerson,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: EtoleColors.muted,
                            size: 20,
                          ),
                          tooltip: 'Delete to Trash',
                          onPressed: _deletePerson,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Profile Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar or Initials
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF141719),
                            border: Border.all(
                              color: EtoleColors.cyan.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _person.name.trim().isNotEmpty
                                  ? _person.name
                                        .trim()
                                        .split(' ')
                                        .map((w) => w[0])
                                        .take(2)
                                        .join()
                                        .toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontFamily: EtoleTypography.displayFontFamily,
                                fontSize: 24,
                                color: EtoleColors.cream,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _person.name.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: EtoleTypography.displayFontFamily,
                                  fontSize: 24,
                                  color: isDark
                                      ? EtoleColors.cream
                                      : EtoleColors.lightTextPrimary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              if (_person.title != null &&
                                  _person.title!.isNotEmpty)
                                Text(
                                  _person.title!.toUpperCase(),
                                  style: EtoleTypography.labelCaps(
                                    color: EtoleColors.cyan,
                                  ).copyWith(fontSize: 10),
                                ),
                              if (_person.organization != null &&
                                  _person.organization!.isNotEmpty)
                                Text(
                                  _person.organization!,
                                  style: TextStyle(
                                    fontFamily: EtoleTypography.bodyFontFamily,
                                    fontSize: 12,
                                    color: isDark
                                        ? EtoleColors.muted
                                        : EtoleColors.lightTextMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Quick Action Icons
                    Row(
                      children: [
                        _buildQuickAction(
                          Icons.call_outlined,
                          'Call',
                          _callPhone,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickAction(
                          Icons.chat_outlined,
                          'WhatsApp',
                          _openWhatsApp,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickAction(
                          Icons.mail_outline_rounded,
                          'Email',
                          _sendEmail,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickAction(
                          Icons.contacts_outlined,
                          'Save to Phone',
                          _saveToPhoneContacts,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickAction(
                          _person.isClient
                              ? Icons.check_circle_rounded
                              : Icons.star_border_rounded,
                          _person.isClient ? 'Client' : 'Make Client',
                          _toggleClientStatus,
                          isDark,
                          isActive: _person.isClient,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Contact Details
                    if (_person.phone != null && _person.phone!.isNotEmpty)
                      _buildDetailRow(
                        Icons.phone_android_rounded,
                        _person.phone!,
                        isDark,
                      ),
                    if (_person.email != null && _person.email!.isNotEmpty)
                      _buildDetailRow(
                        Icons.alternate_email_rounded,
                        _person.email!,
                        isDark,
                      ),
                    if (_person.physicalAddress != null &&
                        _person.physicalAddress!.isNotEmpty)
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        _person.physicalAddress!,
                        isDark,
                      ),

                    // Tappable Links Chips
                    if (socialLinks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: socialLinks.entries.map((entry) {
                          return GestureDetector(
                            onTap: () async {
                              final url = entry.value.toString();
                              final uri = Uri.tryParse(
                                url.startsWith('http') ? url : 'https://$url',
                              );
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0x35141719)
                                    : const Color(0x20000000),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: EtoleColors.cyan.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.link_rounded,
                                    size: 12,
                                    color: EtoleColors.cyan,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    entry.key.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily:
                                          EtoleTypography.bodyFontFamily,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? EtoleColors.cream
                                          : EtoleColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 18),

                    const SizedBox(height: 18),

                    // Mogul Commercial Deal & Pipeline Card
                    Builder(
                      builder: (context) {
                        final deal = FreelanceDealInfo.fromLead(_person);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14171B),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: deal.stage.color.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        deal.stage.icon,
                                        color: deal.stage.color,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'DEAL STAGE: ${deal.stage.label.toUpperCase()}',
                                        style: TextStyle(
                                          fontFamily:
                                              EtoleTypography.displayFontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: deal.stage.color,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      deal.dealValue > 0
                                          ? deal.formattedValue
                                          : 'VALUATION PENDING',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFFBBF24),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                deal.dealTitle ?? _person.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Offering: ${deal.serviceCategory}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: EtoleColors.cyan,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () =>
                                          _convertLeadToDocument(context),
                                      icon: const Icon(
                                        Icons.bolt_rounded,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        '1-TAP QUOTE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF25D366,
                                        ),
                                        side: BorderSide(
                                          color: const Color(0xFF25D366)
                                              .withValues(alpha: 0.4),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => SmartPitchSheet.show(
                                        context,
                                        lead: _person,
                                      ),
                                      icon: const Icon(
                                        Icons.send_rounded,
                                        size: 15,
                                        color: Color(0xFF25D366),
                                      ),
                                      label: const Text(
                                        'SMART PITCH',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E2226),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.edit_note_rounded,
                                      size: 18,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    tooltip: 'Edit Deal Details',
                                    onPressed: () {
                                      EditDealSheet.show(
                                        context,
                                        lead: _person,
                                        onSaved: () async {
                                          final db = ref.read(databaseProvider);
                                          final updated =
                                              await (db.select(
                                                    db.networkingLeads,
                                                  )..where(
                                                    (t) =>
                                                        t.id.equals(_person.id),
                                                  ))
                                                  .getSingleOrNull();
                                          if (updated != null && mounted) {
                                            setState(() => _person = updated);
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0x20FFFFFF), height: 1),
                  ],
                ),
              ),
            ),

            // "WHERE WE MET" Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHERE WE MET',
                      style: EtoleTypography.labelCaps(color: EtoleColors.cyan)
                          .copyWith(fontSize: 11, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 10),
                    if (matchedEvents.isEmpty)
                      Text(
                        'Direct contact (no event attached)',
                        style: TextStyle(
                          fontFamily: EtoleTypography.bodyFontFamily,
                          fontSize: 12,
                          color: isDark
                              ? EtoleColors.muted
                              : EtoleColors.lightTextMuted,
                        ),
                      )
                    else
                      ...matchedEvents.map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              EtoleHaptics.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EventDetailScreen(eventId: event.id),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0x35141719)
                                    : const Color(0x20000000),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? EtoleColors.cream.withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.event_outlined,
                                    size: 16,
                                    color: EtoleColors.cyan,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.name,
                                          style: TextStyle(
                                            fontFamily:
                                                EtoleTypography.bodyFontFamily,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? EtoleColors.cream
                                                : EtoleColors.lightTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${event.location ?? 'Nairobi'} • ${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                                          style: TextStyle(
                                            fontFamily:
                                                EtoleTypography.bodyFontFamily,
                                            fontSize: 10.5,
                                            color: isDark
                                                ? EtoleColors.muted
                                                : EtoleColors.lightTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: EtoleColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0x20FFFFFF), height: 1),
                  ],
                ),
              ),
            ),

            // NOTES & PROMISES GROUPED BY EVENT
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTES & WHAT WE TALKED ABOUT',
                      style: EtoleTypography.labelCaps(color: EtoleColors.cyan)
                          .copyWith(fontSize: 11, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x35141719)
                            : const Color(0x20000000),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? EtoleColors.cream.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        _person.notes?.isNotEmpty == true
                            ? _person.notes!
                            : 'No notes recorded yet.',
                        style: TextStyle(
                          fontFamily: EtoleTypography.bodyFontFamily,
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark
                              ? EtoleColors.cream
                              : EtoleColors.lightTextPrimary,
                        ),
                      ),
                    ),

                    if (_person.whoIntroduced != null &&
                        _person.whoIntroduced!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Introduced by: ${_person.whoIntroduced}',
                        style: TextStyle(
                          fontFamily: EtoleTypography.bodyFontFamily,
                          fontSize: 11.5,
                          color: isDark
                              ? EtoleColors.muted
                              : EtoleColors.lightTextMuted,
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // THINGS PROMISED (Simple tick-off lines)
                    Text(
                      'THINGS PROMISED',
                      style: EtoleTypography.labelCaps(color: EtoleColors.cyan)
                          .copyWith(fontSize: 11, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 8),
                    if (promises.isEmpty)
                      Text(
                        'No promises recorded.',
                        style: TextStyle(
                          fontFamily: EtoleTypography.bodyFontFamily,
                          fontSize: 12,
                          color: isDark
                              ? EtoleColors.muted
                              : EtoleColors.lightTextMuted,
                        ),
                      )
                    else
                      ...List.generate(promises.length, (idx) {
                        final p = promises[idx];
                        final isDone = p['isDone'] as bool? ?? false;
                        final title =
                            (p['text'] ?? p['title']) as String? ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: GestureDetector(
                            onTap: () =>
                                _togglePromiseDone('event', idx, promises),
                            child: Row(
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 18,
                                  color: isDone
                                      ? EtoleColors.cyan
                                      : EtoleColors.muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontFamily:
                                          EtoleTypography.bodyFontFamily,
                                      fontSize: 12.5,
                                      decoration: isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isDone
                                          ? EtoleColors.muted
                                          : (isDark
                                                ? EtoleColors.cream
                                                : EtoleColors.lightTextPrimary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0x20FFFFFF), height: 1),
                  ],
                ),
              ),
            ),

            // COLLECTED MEDIA (Photos with them, Business Cards, Voice Notes, Flyers)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos with them
                    Text(
                      'PHOTOS WITH THEM',
                      style: EtoleTypography.labelCaps(color: EtoleColors.cyan)
                          .copyWith(fontSize: 11, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 8),
                    if (photosWithThem.isEmpty)
                      Text(
                        'No photos yet.',
                        style: TextStyle(
                          fontFamily: EtoleTypography.bodyFontFamily,
                          fontSize: 11.5,
                          color: isDark
                              ? EtoleColors.muted
                              : EtoleColors.lightTextMuted,
                        ),
                      )
                    else
                      SizedBox(
                        height: 84,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: photosWithThem.length,
                          itemBuilder: (context, idx) {
                            final path =
                                photosWithThem[idx]['path'] as String? ?? '';
                            return Container(
                              width: 84,
                              height: 84,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: EtoleColors.cream.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                image: DecorationImage(
                                  image: FileImage(File(path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Voice Notes
                    Text(
                      'VOICE MEMOS',
                      style: EtoleTypography.labelCaps(color: EtoleColors.cyan)
                          .copyWith(fontSize: 11, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 8),
                    if (voiceNotes.isEmpty)
                      Text(
                        'No voice memos recorded.',
                        style: TextStyle(
                          fontFamily: EtoleTypography.bodyFontFamily,
                          fontSize: 11.5,
                          color: isDark
                              ? EtoleColors.muted
                              : EtoleColors.lightTextMuted,
                        ),
                      )
                    else
                      ...voiceNotes.map((memo) {
                        final path = memo['filePath'] as String? ?? '';
                        final duration = memo['durationSeconds'] as num? ?? 0;
                        final isPlaying = _currentlyPlayingMemoId == path;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0x35141719)
                                : const Color(0x20000000),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPlaying
                                  ? EtoleColors.cyan
                                  : EtoleColors.cream.withValues(alpha: 0.1),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (isPlaying) {
                                    VoiceMemoService.stop();
                                    setState(
                                      () => _currentlyPlayingMemoId = null,
                                    );
                                  } else {
                                    setState(
                                      () => _currentlyPlayingMemoId = path,
                                    );
                                    VoiceMemoService.play(
                                      path,
                                      onComplete: () => setState(
                                        () => _currentlyPlayingMemoId = null,
                                      ),
                                    );
                                  }
                                },
                                child: Icon(
                                  isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded,
                                  color: EtoleColors.cyan,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Voice Memo (${duration}s)',
                                  style: TextStyle(
                                    fontFamily: EtoleTypography.bodyFontFamily,
                                    fontSize: 12,
                                    color: isDark
                                        ? EtoleColors.cream
                                        : EtoleColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 18),

                    // Scanned Business Card
                    if (_person.cardPhotoPath != null &&
                        _person.cardPhotoPath!.isNotEmpty) ...[
                      Text(
                        'SCANNED BUSINESS CARD',
                        style: EtoleTypography.labelCaps(
                          color: EtoleColors.cyan,
                        ).copyWith(fontSize: 11, letterSpacing: 2.0),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 140,
                        width: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: EtoleColors.cream.withValues(alpha: 0.2),
                          ),
                          image: DecorationImage(
                            image: FileImage(File(_person.cardPhotoPath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Flyers / Brochures
                    if (flyers.isNotEmpty) ...[
                      Text(
                        'FLYERS & BROCHURES',
                        style: EtoleTypography.labelCaps(
                          color: EtoleColors.cyan,
                        ).copyWith(fontSize: 11, letterSpacing: 2.0),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: flyers.length,
                          itemBuilder: (context, idx) {
                            final path = flyers[idx]['path'] as String? ?? '';
                            return Container(
                              width: 70,
                              height: 90,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: EtoleColors.cream.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                image: DecorationImage(
                                  image: FileImage(File(path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDark, {
    bool isActive = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          EtoleHaptics.light();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? EtoleColors.cyan
                : (isDark ? const Color(0x35141719) : const Color(0x20000000)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? EtoleColors.cyan
                  : (isDark
                        ? EtoleColors.cream.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08)),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : EtoleColors.cyan,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: EtoleTypography.bodyFontFamily,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : (isDark
                            ? EtoleColors.cream
                            : EtoleColors.lightTextPrimary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: EtoleColors.cyan.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: EtoleTypography.bodyFontFamily,
                fontSize: 12,
                color: isDark
                    ? EtoleColors.cream
                    : EtoleColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
