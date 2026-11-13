import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/calendar/calendar_intent_service.dart';
import '../../../../core/calendar/calendar_sync_service.dart';
import '../widgets/calendar_seven_day_radar_strip.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../../documents/presentation/screens/document_editor_screen.dart';
import '../../domain/freelance_crm_models.dart';
import '../../domain/location_task_model.dart';
import '../providers/cards_providers.dart';
import '../widgets/add_location_sheet.dart';
import '../widgets/add_person_sheet.dart';
import '../widgets/edit_deal_sheet.dart';
import '../widgets/smart_pitch_sheet.dart';
import 'card_presentation_screen.dart';
import 'location_detail_screen.dart';
import 'person_profile_screen.dart';

class NetworkHubScreen extends ConsumerStatefulWidget {
  const NetworkHubScreen({super.key});

  @override
  ConsumerState<NetworkHubScreen> createState() => _NetworkHubScreenState();
}

class _NetworkHubScreenState extends ConsumerState<NetworkHubScreen> {
  // Master Tabs: 0: Places & Locations, 1: Deals & Pipeline, 2: VIP Rolodex, 3: Follow-Up Radar
  int _selectedTab = 0;

  // Sub-tab for Locations (0: Active Places, 1: Upcoming Meetups, 2: Archive)
  int _locationSubTab = 0;

  // Search
  bool _isSearchExpanded = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Pipeline Filter (null = All)
  DealStage? _pipelineFilter;

  // Rolodex Filter ('all', 'vip', 'client', 'agency')
  String _rolodexFilter = 'all';

  static final _dateFormat = DateFormat('MMM d, yyyy • h:mm a');
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  StudioThemeData _theme = StudioThemeData.tribalOrange;
  Color get _accent => _theme.primaryAccent;
  Color get _bg => _theme.backgroundBase;
  Color get _cardBg => _theme.surfaceCardColor;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddChoiceSheet() {
    EtoleHaptics.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFA121518),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: _accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: EtoleColors.creamMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Network & CRM Actions',
                      style: EtoleTypography.h2.copyWith(
                        color: EtoleColors.cream,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: EtoleColors.creamMuted,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAddOption(
                  icon: Icons.place_outlined,
                  color: _accent,
                  title: 'New Location or Meetup',
                  subtitle: 'Pick real venues (GPS / Places search), cafés, film sets, or upcoming events',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddLocation();
                  },
                ),
                const SizedBox(height: 10),
                _buildAddOption(
                  icon: Icons.person_add_outlined,
                  color: const Color(0xFF38B6DB),
                  title: 'New Lead or VIP Contact',
                  subtitle: 'Scan business card (AI OCR), scan QR, import phonebook, or manual entry',
                  onTap: () {
                    Navigator.pop(ctx);
                    AddPersonSheet.show(context);
                  },
                ),
                const SizedBox(height: 10),
                _buildAddOption(
                  icon: Icons.contactless_rounded,
                  color: const Color(0xFFEF4444),
                  title: 'Present Digital Card (NFC / QR)',
                  subtitle: 'Broadcast live showreel, rate sheet, and digital vCard to nearby phones',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CardPresentationScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          EtoleHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF16191D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: EtoleTypography.bodyMedium.copyWith(
                        color: EtoleColors.cream,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: EtoleTypography.labelSmall.copyWith(
                        color: EtoleColors.creamMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: EtoleColors.creamMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLocation({bool isUpcoming = false}) async {
    final eventId = await AddLocationSheet.show(
      context,
      isUpcoming: isUpcoming,
    );
    if (eventId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationDetailScreen(locationId: eventId),
        ),
      );
    }
  }

  Future<void> _toggleArchive(NetworkingEvent event) async {
    EtoleHaptics.selection();
    final db = ref.read(databaseProvider);
    final nextState = !event.isArchived;

    await (db.update(db.networkingEvents)..where((t) => t.id.equals(event.id)))
        .write(NetworkingEventsCompanion(isArchived: drift.Value(nextState)));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState
                ? '"${event.name}" moved to archive'
                : '"${event.name}" restored to active locations',
          ),
          backgroundColor: const Color(0xFF14181D),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteLocation(NetworkingEvent event) async {
    EtoleHaptics.warning();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14181D),
        title: const Text(
          'Delete Location?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete "${event.name}"? Note: Archiving keeps all people and notes preserved.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await (db.update(db.networkingEvents)
            ..where((t) => t.id.equals(event.id)))
          .write(const NetworkingEventsCompanion(isDeleted: drift.Value(true)));
      await CalendarSyncService.deleteReminder(key: 'location_${event.id}');
    }
  }

  Future<void> _advanceDealStage(NetworkingLead lead) async {
    EtoleHaptics.selection();
    final deal = FreelanceDealInfo.fromLead(lead);
    DealStage next;
    switch (deal.stage) {
      case DealStage.lead:
        next = DealStage.pitching;
        break;
      case DealStage.pitching:
        next = DealStage.negotiating;
        break;
      case DealStage.negotiating:
        next = DealStage.won;
        break;
      case DealStage.won:
        next = DealStage.won;
        break;
      case DealStage.lost:
        next = DealStage.lead;
        break;
    }

    final db = ref.read(databaseProvider);
    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(lead.id))).write(
      NetworkingLeadsCompanion(
        status: drift.Value(next.name),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${lead.name} moved to ${next.label}!'),
          backgroundColor: const Color(0xFF141719),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _draftQuoteForLead(NetworkingLead lead) async {
    EtoleHaptics.selection();
    final db = ref.read(databaseProvider);
    int? clientId = lead.convertedClientId;

    if (clientId == null) {
      clientId = await db
          .into(db.clients)
          .insert(
            ClientsCompanion(
              name: drift.Value(lead.name),
              organization: drift.Value(lead.organization),
              phone: drift.Value(lead.phone),
              email: drift.Value(lead.email),
              address: drift.Value(lead.physicalAddress),
              notes: drift.Value(lead.notes),
            ),
          );

      await (db.update(
        db.networkingLeads,
      )..where((t) => t.id.equals(lead.id))).write(
        NetworkingLeadsCompanion(
          isClient: const drift.Value(true),
          convertedClientId: drift.Value(clientId),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentEditorScreen(
            docType: DocType.quotation,
            initialClientId: clientId,
          ),
        ),
      );
    }
  }

  int _countTasks(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return 0;
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    _theme = ref.watch(currentStudioThemeProvider);
    final leadsAsync = ref.watch(networkingLeadsProvider);
    final eventsAsync = ref.watch(networkingEventsProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: eventsAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: _accent)),
          error: (err, _) => Center(
            child: Text(
              'Error loading network: $err',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          data: (allEvents) {
            return leadsAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: _accent)),
              error: (err, _) => Center(
                child: Text(
                  'Error loading leads: $err',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              data: (allLeads) {
                // Calculate metrics
                final activeEvents = allEvents
                    .where((e) => !e.isDeleted && !e.isArchived)
                    .toList();
                final pipelineDeals = allLeads
                    .where((l) => !l.isDeleted && !l.isArchived)
                    .toList();
                final totalPipelineVal = pipelineDeals.fold<double>(
                  0.0,
                  (sum, l) => sum + FreelanceDealInfo.fromLead(l).dealValue,
                );
                final vipCount = allLeads
                    .where((l) => FreelanceDealInfo.fromLead(l).isVip)
                    .length;

                return Column(
                  children: [
                    // 1. Header Bar
                    _buildHeader(
                      activeEvents.length,
                      totalPipelineVal,
                      vipCount,
                    ),

                    // 2. Expandable Search Bar
                    if (_isSearchExpanded) _buildSearchBar(),

                    // 3. Segmented 4-Tab Control
                    _buildTabBar(),

                    // 4. Tab Body
                    Expanded(
                      child: _buildSelectedTabContent(allEvents, allLeads),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChoiceSheet,
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        elevation: 6,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // --- HEADER & METRIC CHIPS ---
  Widget _buildHeader(int activeLocations, double pipelineValue, int vipCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NETWORK & CRM',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Locations, Deals & Rolodex',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isSearchExpanded
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      color: _isSearchExpanded ? _accent : Colors.white70,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearchExpanded = !_isSearchExpanded;
                        if (!_isSearchExpanded) {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.contactless_outlined,
                      color: Color(0xFF38B6DB),
                      size: 22,
                    ),
                    tooltip: 'Digital Business Card',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CardPresentationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Metric Badges
          Row(
            children: [
              _buildMetricChip(
                icon: Icons.place_rounded,
                label: '$activeLocations Places',
                color: _accent,
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                icon: Icons.monetization_on_rounded,
                label: 'KES ${_currencyFormat.format(pipelineValue)}',
                color: const Color(0xFF34D399),
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                icon: Icons.star_rounded,
                label: '$vipCount VIPs',
                color: const Color(0xFF38B6DB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14181D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        onChanged: (val) =>
            setState(() => _searchQuery = val.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search locations, people, deals, roles, notes...',
          hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: _accent, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.white60,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // --- 4 MASTER TABS ---
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF14181D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildTabButton(index: 0, title: '📍 Places'),
          _buildTabButton(index: 1, title: '💼 Deals'),
          _buildTabButton(index: 2, title: '👥 Rolodex'),
          _buildTabButton(index: 3, title: '📡 Radar'),
        ],
      ),
    );
  }

  Widget _buildTabButton({required int index, required String title}) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          EtoleHaptics.light();
          setState(() => _selectedTab = index);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? _accent.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: _accent, width: 1.1) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(
    List<NetworkingEvent> allEvents,
    List<NetworkingLead> allLeads,
  ) {
    switch (_selectedTab) {
      case 0:
        return _buildLocationsTab(allEvents, allLeads);
      case 1:
        return _buildDealsPipelineTab(allLeads, allEvents);
      case 2:
        return _buildRolodexTab(allLeads, allEvents);
      case 3:
        return _buildFollowUpRadarTab(allLeads, allEvents);
      default:
        return _buildLocationsTab(allEvents, allLeads);
    }
  }

  // ==========================================
  // TAB 0: 📍 LOCATIONS & PLACES (7-POINT ARCH)
  // ==========================================
  Widget _buildLocationsTab(
    List<NetworkingEvent> allEvents,
    List<NetworkingLead> allLeads,
  ) {
    final notDeleted = allEvents.where((e) => !e.isDeleted).toList();

    // Auto-rollover upcoming events whose date has passed
    final now = DateTime.now();
    for (final e in notDeleted) {
      if (e.occasionType == 'upcoming' && e.startDate.isBefore(now)) {
        final db = ref.read(databaseProvider);
        (db.update(db.networkingEvents)..where((t) => t.id.equals(e.id))).write(
          const NetworkingEventsCompanion(
            occasionType: drift.Value('location'),
          ),
        );
      }
    }

    final activeLocations = notDeleted
        .where((e) => !e.isArchived && e.occasionType != 'upcoming')
        .toList();
    final upcomingEvents = notDeleted
        .where((e) => !e.isArchived && e.occasionType == 'upcoming')
        .toList();
    final archivedLocations = notDeleted.where((e) => e.isArchived).toList();

    return Column(
      children: [
        // Sub-Tabs for Locations
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildLocationSubChip(0, '📍 Places (${activeLocations.length})'),
              const SizedBox(width: 6),
              _buildLocationSubChip(
                1,
                '📅 Upcoming (${upcomingEvents.length})',
              ),
              const SizedBox(width: 6),
              _buildLocationSubChip(
                2,
                '🗄️ Archive (${archivedLocations.length})',
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        Expanded(
          child: Builder(
            builder: (context) {
              List<NetworkingEvent> targetList;
              if (_locationSubTab == 0) {
                targetList = activeLocations;
              } else if (_locationSubTab == 1) {
                targetList = upcomingEvents;
              } else {
                targetList = archivedLocations;
              }

              // Apply Search Query
              if (_searchQuery.isNotEmpty) {
                targetList = targetList.where((event) {
                  final inName = event.name.toLowerCase().contains(
                    _searchQuery,
                  );
                  final inLoc = (event.location ?? '').toLowerCase().contains(
                    _searchQuery,
                  );
                  final inNotes = (event.notes ?? '').toLowerCase().contains(
                    _searchQuery,
                  );
                  final inDesc = (event.description ?? '')
                      .toLowerCase()
                      .contains(_searchQuery);

                  final eventLeads = allLeads
                      .where((l) => l.eventId == event.id && !l.isDeleted)
                      .toList();
                  final inPeople = eventLeads.any(
                    (p) =>
                        p.name.toLowerCase().contains(_searchQuery) ||
                        (p.organization ?? '').toLowerCase().contains(
                          _searchQuery,
                        ) ||
                        (p.title ?? '').toLowerCase().contains(_searchQuery),
                  );

                  return inName || inLoc || inNotes || inDesc || inPeople;
                }).toList();
              }

              // Sort by date descending
              targetList.sort((a, b) => b.startDate.compareTo(a.startDate));

              return Column(
                children: [
                  if (_locationSubTab == 1) const CalendarSevenDayRadarStrip(),
                  Expanded(
                    child: targetList.isEmpty
                        ? _buildEmptyLocationsState(_locationSubTab)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                            itemCount: targetList.length,
                            itemBuilder: (context, index) {
                              final event = targetList[index];
                              final peopleMet = allLeads
                                  .where(
                                    (l) =>
                                        l.eventId == event.id && !l.isDeleted,
                                  )
                                  .toList();
                              final taskCount = _countTasks(
                                event.ticketsPhotosJson,
                              );

                              return _buildLocationCard(
                                event,
                                peopleMet,
                                taskCount,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSubChip(int subIndex, String label) {
    final isSelected = _locationSubTab == subIndex;
    return Expanded(
      child: InkWell(
        onTap: () {
          EtoleHaptics.selection();
          setState(() => _locationSubTab = subIndex);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? _accent.withValues(alpha: 0.15)
                : const Color(0xFF14181D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? _accent
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? _accent : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    NetworkingEvent event,
    List<NetworkingLead> people,
    int taskCount,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14181D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.isArchived
              ? const Color(0xFF334155)
              : _accent.withValues(alpha: 0.28),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            EtoleHaptics.selection();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationDetailScreen(locationId: event.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Name + Popup Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            event.occasionType == 'upcoming'
                                ? Icons.calendar_today_rounded
                                : Icons.place_rounded,
                            size: 18,
                            color: _accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      color: const Color(0xFF1E2328),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') {
                          AddLocationSheet.show(context, existingEvent: event);
                        }
                        if (val == 'calendar') {
                          CalendarSyncService.syncOrUpdateReminder(
                            context: context,
                            key: 'location_${event.id}',
                            title: event.name,
                            startTime: event.startDate,
                            endTime: event.endDate,
                            location: [event.name, event.location]
                                .where((s) => s != null && s.isNotEmpty)
                                .toSet()
                                .join(' - '),
                            notes: event.notes ?? event.description ?? '',
                            alertMinutesBefore: 30,
                          );
                        }
                        if (val == 'archive') _toggleArchive(event);
                        if (val == 'delete') _confirmDeleteLocation(event);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_location_alt_outlined,
                                color: _accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Edit Location',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'calendar',
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: _accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Add to Calendar',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(
                                event.isArchived
                                    ? Icons.unarchive_outlined
                                    : Icons.archive_outlined,
                                color: _accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                event.isArchived ? 'Unarchive' : 'Archive',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Date & Time
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: _accent),
                    const SizedBox(width: 6),
                    Text(
                      _dateFormat.format(event.startDate),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    if (event.location != null &&
                        event.location!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Text(
                        '•',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.description!,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Bottom Badges: People Met + Tasks + Notes
                Row(
                  children: [
                    // People count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 13,
                            color: _accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${people.length} people',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (taskCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38B6DB)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 13,
                              color: Color(0xFF38B6DB),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$taskCount tasks',
                              style: const TextStyle(
                                color: Color(0xFF38B6DB),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (event.notes != null && event.notes!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Notes',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (event.occasionType == 'upcoming' ||
                        event.startDate.isAfter(DateTime.now())) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          CalendarSyncService.syncOrUpdateReminder(
                            context: context,
                            key: 'location_${event.id}',
                            title: event.name,
                            startTime: event.startDate,
                            endTime: event.endDate,
                            location: [event.name, event.location]
                                .where((s) => s != null && s.isNotEmpty)
                                .toSet()
                                .join(' - '),
                            notes: event.notes ?? event.description ?? '',
                            alertMinutesBefore: 30,
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: _accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Add to cal',
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLocationsState(int subTab) {
    final title = subTab == 0
        ? 'No Active Locations Yet'
        : subTab == 1
        ? 'No Upcoming Meetups'
        : 'Archive is Empty';
    final desc = subTab == 0
        ? 'Tap the button below or "+" to log a café, film set, or event where you met people.'
        : subTab == 1
        ? 'Plan upcoming meetups, conferences, and festivals with reminder alarms.'
        : 'Locations you archive will appear here safely. Nothing is permanently deleted.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                subTab == 1
                    ? Icons.event_available_rounded
                    : subTab == 2
                    ? Icons.archive_outlined
                    : Icons.place_outlined,
                size: 38,
                color: _accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
            ),
            if (subTab != 2) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _showAddLocation(isUpcoming: subTab == 1),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  subTab == 1 ? 'Add Upcoming Meetup' : 'Add Location / Café',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: 💼 DEALS & PIPELINE (CRM PIPELINE)
  // ==========================================
  Widget _buildDealsPipelineTab(
    List<NetworkingLead> leads,
    List<NetworkingEvent> events,
  ) {
    List<NetworkingLead> filtered = leads
        .where((l) => !l.isDeleted && !l.isArchived)
        .toList();

    if (_pipelineFilter != null) {
      filtered = filtered
          .where((l) => FreelanceDealInfo.fromLead(l).stage == _pipelineFilter)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((l) {
        final deal = FreelanceDealInfo.fromLead(l);
        return l.name.toLowerCase().contains(_searchQuery) ||
            (deal.dealTitle ?? '').toLowerCase().contains(_searchQuery) ||
            (l.organization ?? '').toLowerCase().contains(_searchQuery) ||
            (deal.serviceCategory).toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Pipeline Stage Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStageFilterChip(null, 'All Deals (${leads.length})'),
              ...DealStage.values.map((stage) {
                final count = leads
                    .where((l) => FreelanceDealInfo.fromLead(l).stage == stage)
                    .length;
                return _buildStageFilterChip(stage, '${stage.label} ($count)');
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF13171B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.monetization_on_outlined,
                  size: 42,
                  color: _accent.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Deals in ${_pipelineFilter?.label ?? 'Pipeline'}',
                  style: EtoleTypography.h3.copyWith(
                    color: EtoleColors.cream,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap any contact in your VIP Rolodex to attach an estimated deal value and pitch campaign.',
                  textAlign: TextAlign.center,
                  style: EtoleTypography.bodySmall(
                    color: EtoleColors.creamMuted,
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map((lead) => _buildDealCard(lead, events)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStageFilterChip(DealStage? stage, String label) {
    final isSelected = _pipelineFilter == stage;
    final color = stage?.color ?? _accent;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          EtoleHaptics.light();
          setState(() => _pipelineFilter = stage);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.22)
                : const Color(0xFF13171B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : EtoleColors.creamSecondary,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(NetworkingLead lead, List<NetworkingEvent> events) {
    final deal = FreelanceDealInfo.fromLead(lead);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14171B),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(
          color: deal.stage.color.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            EtoleHaptics.light();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PersonProfileScreen(person: lead),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Stage pill, Value pill, More menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: deal.stage.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: deal.stage.color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            deal.stage.icon,
                            size: 12,
                            color: deal.stage.color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            deal.stage.label.toUpperCase(),
                            style: TextStyle(
                              color: deal.stage.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        deal.dealValue > 0
                            ? deal.formattedValue
                            : 'PROPOSAL PENDING',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Deal Title & Contact Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: const Color(0xFF1E2328),
                      backgroundImage:
                          (lead.avatarPhotoPath != null &&
                              File(lead.avatarPhotoPath!).existsSync())
                          ? FileImage(File(lead.avatarPhotoPath!))
                          : null,
                      child:
                          (lead.avatarPhotoPath == null ||
                              !File(lead.avatarPhotoPath!).existsSync())
                          ? Text(
                              lead.name.isNotEmpty
                                  ? lead.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deal.dealTitle ?? lead.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lead.name}${lead.organization != null && lead.organization!.isNotEmpty ? ' • ${lead.organization}' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Offering: ${deal.serviceCategory}',
                            style: TextStyle(
                              color: EtoleColors.cyan.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (deal.isVip)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.star_rounded,
                          color: _accent,
                          size: 18,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: Color(0x1AFFFFFF), height: 1),
                const SizedBox(height: 10),

                // Mogul Quick Action Buttons on Deal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () => EditDealSheet.show(context, lead: lead),
                      icon: Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: _accent,
                      ),
                      label: Text(
                        'Edit Deal',
                        style: TextStyle(color: _accent, fontSize: 12),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 16,
                            color: Color(0xFF25D366),
                          ),
                          tooltip: 'Pitch via WhatsApp',
                          onPressed: () =>
                              SmartPitchSheet.show(context, lead: lead),
                        ),
                        if (deal.stage != DealStage.won)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: deal.stage.color.withValues(
                                alpha: 0.18,
                              ),
                              foregroundColor: deal.stage.color,
                              elevation: 0,
                              side: BorderSide(
                                color: deal.stage.color.withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _advanceDealStage(lead),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                            ),
                            label: const Text(
                              'Advance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007A3D)
                                  .withValues(alpha: 0.2),
                              foregroundColor: const Color(0xFF34D399),
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFF007A3D)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _draftQuoteForLead(lead),
                            icon: const Icon(
                              Icons.receipt_long_rounded,
                              size: 13,
                            ),
                            label: const Text(
                              'Bill / Quote',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: 👥 VIP ROLODEX (ALL CONTACTS)
  // ==========================================
  Widget _buildRolodexTab(
    List<NetworkingLead> leads,
    List<NetworkingEvent> events,
  ) {
    List<NetworkingLead> filtered = leads
        .where((l) => !l.isDeleted && !l.isArchived)
        .toList();

    if (_rolodexFilter == 'vip') {
      filtered = filtered
          .where((l) => FreelanceDealInfo.fromLead(l).isVip)
          .toList();
    } else if (_rolodexFilter == 'client') {
      filtered = filtered.where((l) => l.isClient).toList();
    } else if (_rolodexFilter == 'agency') {
      filtered = filtered
          .where((l) => (l.organization != null && l.organization!.isNotEmpty))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((l) {
        return l.name.toLowerCase().contains(_searchQuery) ||
            (l.organization ?? '').toLowerCase().contains(_searchQuery) ||
            (l.title ?? '').toLowerCase().contains(_searchQuery) ||
            (l.phone ?? '').toLowerCase().contains(_searchQuery) ||
            (l.notes ?? '').toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Rolodex Filter Pills
        Row(
          children: [
            _buildRolodexFilterChip('all', 'All (${leads.length})'),
            const SizedBox(width: 6),
            _buildRolodexFilterChip(
              'vip',
              '⭐ VIPs (${leads.where((l) => FreelanceDealInfo.fromLead(l).isVip).length})',
            ),
            const SizedBox(width: 6),
            _buildRolodexFilterChip(
              'client',
              '💼 Clients (${leads.where((l) => l.isClient).length})',
            ),
            const SizedBox(width: 6),
            _buildRolodexFilterChip('agency', '🏢 Agencies'),
          ],
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF13171B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 42,
                  color: EtoleColors.creamMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Contacts Found',
                  style: EtoleTypography.h3.copyWith(
                    color: EtoleColors.cream,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add high-profile contacts, scan business cards, or import from phonebook.',
                  textAlign: TextAlign.center,
                  style: EtoleTypography.bodySmall(
                    color: EtoleColors.creamMuted,
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map((lead) => _buildContactCard(lead, events)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildRolodexFilterChip(String filterKey, String label) {
    final isSelected = _rolodexFilter == filterKey;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        EtoleHaptics.light();
        setState(() => _rolodexFilter = filterKey);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF38B6DB).withValues(alpha: 0.22)
              : const Color(0xFF13171B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38B6DB)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : EtoleColors.creamSecondary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    NetworkingLead person,
    List<NetworkingEvent> events,
  ) {
    final deal = FreelanceDealInfo.fromLead(person);
    NetworkingEvent? linkedEvent;
    if (person.eventId != null) {
      linkedEvent = events.where((e) => e.id == person.eventId).firstOrNull;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14171A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: deal.isVip
              ? _accent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.07),
          width: deal.isVip ? 1.3 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            EtoleHaptics.light();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PersonProfileScreen(person: person),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1F2429),
                  backgroundImage:
                      (person.avatarPhotoPath != null &&
                          File(person.avatarPhotoPath!).existsSync())
                      ? FileImage(File(person.avatarPhotoPath!))
                      : null,
                  child:
                      (person.avatarPhotoPath == null ||
                          !File(person.avatarPhotoPath!).existsSync())
                      ? Text(
                          person.name.isNotEmpty
                              ? person.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: deal.isVip ? _accent : EtoleColors.cream,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              person.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (deal.isVip) ...[
                            const SizedBox(width: 5),
                            Icon(Icons.star_rounded, color: _accent, size: 16),
                          ],
                          if (person.isClient) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007A3D)
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CLIENT',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${person.title ?? 'Contact'}${person.organization != null && person.organization!.isNotEmpty ? ' • ${person.organization}' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (linkedEvent != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.place_rounded, size: 11, color: _accent),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                linkedEvent.name,
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Quick Contact Shortcuts
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (person.phone != null && person.phone!.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.call_outlined,
                          size: 18,
                          color: Color(0xFF38B6DB),
                        ),
                        onPressed: () {
                          final uri = Uri.parse('tel:${person.phone}');
                          launchUrl(uri);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: Color(0xFF25D366),
                        ),
                        onPressed: () {
                          final clean = person.phone!.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          final uri = Uri.parse('https://wa.me/$clean');
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: 📡 FOLLOW-UP RADAR & SMART PITCH
  // ==========================================
  Widget _buildFollowUpRadarTab(
    List<NetworkingLead> leads,
    List<NetworkingEvent> events,
  ) {
    final now = DateTime.now();

    final urgentFollowUps = leads.where((l) {
      if (l.isDeleted || l.isArchived) return false;
      if (l.followUpDate != null) {
        return l.followUpDate!.isBefore(now.add(const Duration(days: 2)));
      }
      return false;
    }).toList();

    final vipNurture = leads.where((l) {
      if (l.isDeleted || l.isArchived) return false;
      final deal = FreelanceDealInfo.fromLead(l);
      return deal.isVip && !urgentFollowUps.contains(l);
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Radar Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFDC2626).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MOGUL FOLLOW-UP RADAR',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${urgentFollowUps.length} contacts need follow-up or pitch alignment.',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (urgentFollowUps.isNotEmpty) ...[
          const Text(
            'URGENT ATTENTION',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...urgentFollowUps.map(
            (l) => _buildRadarCard(l, events, isUrgent: true),
          ),
          const SizedBox(height: 16),
        ],

        if (vipNurture.isNotEmpty) ...[
          Text(
            'VIP NURTURE & RELATIONSHIPS',
            style: TextStyle(
              color: _accent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...vipNurture.map((l) => _buildRadarCard(l, events, isUrgent: false)),
          const SizedBox(height: 16),
        ],

        if (urgentFollowUps.isEmpty && vipNurture.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF13171B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 42,
                  color: const Color(0xFF007A3D).withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'Radar All Clear!',
                  style: EtoleTypography.h3.copyWith(
                    color: EtoleColors.cream,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'All client follow-ups are up to date.',
                  textAlign: TextAlign.center,
                  style: EtoleTypography.bodySmall(
                    color: EtoleColors.creamMuted,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildRadarCard(
    NetworkingLead lead,
    List<NetworkingEvent> events, {
    required bool isUrgent,
  }) {
    final deal = FreelanceDealInfo.fromLead(lead);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF14171A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
              : _accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1E2328),
            child: Text(
              lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: isUrgent ? const Color(0xFFEF4444) : _accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  deal.dealTitle ?? lead.title ?? 'Key Relationship',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                if (lead.notes != null && lead.notes!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Promise: "${lead.notes}"',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today_rounded, size: 18, color: _accent),
            tooltip: 'Add follow-up to calendar',
            onPressed: () {
              final matchingEvent = events
                  .where((e) => e.id == lead.eventId)
                  .firstOrNull;
              CalendarSyncService.syncOrUpdateReminder(
                context: context,
                key: 'lead_${lead.id}',
                title: 'Follow-up: ${lead.name}',
                startTime:
                    lead.followUpDate ??
                    DateTime.now().add(const Duration(days: 1, hours: 10)),
                location: [
                  matchingEvent?.name,
                  matchingEvent?.location,
                ].where((s) => s != null && s.isNotEmpty).join(' - '),
                notes:
                    'Follow-up with ${lead.name} (${lead.title ?? ""}). Notes: ${lead.notes ?? ""}',
                alertMinutesBefore: 30,
              );
            },
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => SmartPitchSheet.show(context, lead: lead),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send_rounded, size: 12),
                SizedBox(width: 4),
                Text(
                  'Reach Out',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
