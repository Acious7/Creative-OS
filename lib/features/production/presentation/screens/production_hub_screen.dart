import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/production_models.dart';
import '../../domain/call_sheet_pdf_builder.dart';
import 'project_detail_screen.dart';
import 'call_sheet_view_screen.dart';
import '../widgets/crew_roster_tab.dart';

class ProductionHubScreen extends ConsumerStatefulWidget {
  const ProductionHubScreen({super.key});

  @override
  ConsumerState<ProductionHubScreen> createState() =>
      _ProductionHubScreenState();
}

class _ProductionHubScreenState extends ConsumerState<ProductionHubScreen> {
  int _selectedTab = 0; // 0: Projects, 1: Call Sheets, 2: Gear Locker
  String _gearCategoryFilter = 'All';

  final List<String> _gearCategories = [
    'All',
    'Camera',
    'Lens',
    'Drone',
    'Lighting',
    'Audio',
    'Support',
    'Media',
    'Power',
  ];

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOled = ref.watch(isOledModeProvider);
    final cream = isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary;
    final muted = isDark ? EtoleColors.muted : EtoleColors.lightTextMuted;

    return Scaffold(
      backgroundColor: const Color(0xFF080B0F),
      body: SafeArea(
        child: Column(
          children: [
            // Studio Header
            _buildHeader(context, cream, muted),
            const EtoleHairline(),

            // Segmented Switcher
            _buildTabSelector(cream, muted),
            const SizedBox(height: 8),

            // Tab View Body
            Expanded(
              child: StreamBuilder<List<ProductionProject>>(
                stream:
                    (db.select(db.productionProjects)
                          ..where((t) => t.isDeleted.equals(false))
                          ..orderBy([
                            (t) => drift.OrderingTerm.desc(t.createdAt),
                          ]))
                        .watch(),
                builder: (context, projectSnap) {
                  return StreamBuilder<List<CallSheet>>(
                    stream:
                        (db.select(db.callSheets)
                              ..where((t) => t.isDeleted.equals(false))
                              ..orderBy([
                                (t) => drift.OrderingTerm.desc(t.shootDate),
                              ]))
                            .watch(),
                    builder: (context, callSheetSnap) {
                      return StreamBuilder<List<GearItem>>(
                        stream:
                            (db.select(db.gearItems)
                                  ..where((t) => t.isDeleted.equals(false))
                                  ..orderBy([
                                    (t) => drift.OrderingTerm.asc(t.category),
                                  ]))
                                .watch(),
                        builder: (context, gearSnap) {
                          final projects = projectSnap.data ?? [];
                          final callSheets = callSheetSnap.data ?? [];
                          final gearList = gearSnap.data ?? [];

                          if (_selectedTab == 0) {
                            return _buildProjectsTab(projects, cream, muted);
                          } else if (_selectedTab == 1) {
                            return _buildCallSheetsTab(
                              callSheets,
                              cream,
                              muted,
                            );
                          } else if (_selectedTab == 2) {
                            return const CrewRosterTab();
                          } else {
                            return _buildGearLockerTab(gearList, cream, muted);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          _selectedTab == 0
              ? 'NEW PROJECT'
              : (_selectedTab == 1 ? 'NEW CALL SHEET' : 'ADD GEAR'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        onPressed: () => _handleFabAction(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color cream, Color muted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Reserve clearance for WorldContainer's floating < HUB pill
              const SizedBox(width: 82),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRODUCTION SLATE',
                    style: EtoleTypography.h2.copyWith(
                      color: EtoleColors.cream,
                      letterSpacing: 2.2,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Projects, Call Sheets & Gear Locker',
                    style: TextStyle(
                      color: Color(0xFF00838F),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00838F).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00838F).withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.videocam_rounded,
                  color: Color(0xFF26C6DA),
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  '4K CINEMA',
                  style: TextStyle(
                    color: Color(0xFF26C6DA),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(Color cream, Color muted) {
    final tabs = ['Projects', 'Call Sheets', 'Crew Roster', 'Gear Locker'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _selectedTab == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                EtoleHaptics.selection();
                setState(() => _selectedTab = idx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? EtoleColors.cyan : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    tabs[idx].toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : muted,
                      fontSize: 11.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- TAB 1: PROJECTS & MILESTONES ---
  Widget _buildProjectsTab(
    List<ProductionProject> projects,
    Color cream,
    Color muted,
  ) {
    if (projects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.movie_outlined,
        title: 'No Active Productions',
        subtitle: 'Tap "+ NEW PROJECT" below to track client commissions, shoot milestones, and delivery handover.',
        cream: cream,
        muted: muted,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final stage = ProductionStage.fromCode(project.stage);

        // Milestones count
        int doneCount = 0;
        int totalMilestones = 0;
        if (project.milestonesJson != null &&
            project.milestonesJson!.isNotEmpty) {
          try {
            final list = jsonDecode(project.milestonesJson!) as List<dynamic>;
            totalMilestones = list.length;
            doneCount = list.where((e) => e['isDone'] == true).length;
          } catch (_) {}
        }

        // Delivery Links count
        int deliveryCount = 0;
        if (project.deliveryLinksJson != null &&
            project.deliveryLinksJson!.isNotEmpty) {
          try {
            deliveryCount = (jsonDecode(
              project.deliveryLinksJson!,
            ) as List<dynamic>).length;
          } catch (_) {}
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: EtoleColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: stage == ProductionStage.production
                  ? EtoleColors.cyan.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: stage == ProductionStage.production ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (stage == ProductionStage.production)
                BoxShadow(
                  color: EtoleColors.cyan.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                EtoleHaptics.light();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(projectId: project.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stage Pill & Budget
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: stage.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: stage.color.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(stage.icon, size: 13, color: stage.color),
                              const SizedBox(width: 5),
                              Text(
                                stage.label.toUpperCase(),
                                style: TextStyle(
                                  color: stage.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (project.budgetAmount > 0)
                          Text(
                            'KES ${NumberFormat('#,##0').format(project.budgetAmount)}',
                            style: const TextStyle(
                              color: EtoleColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title & Client
                    Text(
                      project.title,
                      style: EtoleTypography.sectionTitle(color: cream)
                          .copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Client: ${project.clientName} · ${project.projectType}',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    // Shoot Date & Delivery Due
                    Row(
                      children: [
                        if (project.shootDate != null) ...[
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Shoot: ${DateFormat('d MMM').format(project.shootDate!)}',
                            style: TextStyle(
                              color: cream,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        if (project.deliveryDueDate != null) ...[
                          Icon(
                            Icons.flag_rounded,
                            size: 13,
                            color: Colors.tealAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${DateFormat('d MMM').format(project.deliveryDueDate!)}',
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Milestone Progress Bar
                    if (totalMilestones > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MILESTONES',
                            style: EtoleTypography.labelCaps(color: muted)
                                .copyWith(fontSize: 9),
                          ),
                          Text(
                            '$doneCount of $totalMilestones complete',
                            style: TextStyle(color: muted, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalMilestones > 0
                              ? (doneCount / totalMilestones)
                              : 0,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            doneCount == totalMilestones
                                ? Colors.greenAccent
                                : EtoleColors.cyan,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],

                    // Handover Deliverable Links pill
                    if (deliveryCount > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_done_outlined,
                              size: 14,
                              color: Colors.tealAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$deliveryCount Handover Links (Frame.io / Drive)',
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: CALL SHEETS ---
  Widget _buildCallSheetsTab(
    List<CallSheet> callSheets,
    Color cream,
    Color muted,
  ) {
    if (callSheets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No Call Sheets Created',
        subtitle: 'Tap "+ NEW CALL SHEET" below to compose digital and printable Call Sheets with crew call times, sunrise/sunset, and GPS locations.',
        cream: cream,
        muted: muted,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: callSheets.length,
      itemBuilder: (context, index) {
        final cs = callSheets[index];

        int crewCount = 0;
        if (cs.crewJson != null && cs.crewJson!.isNotEmpty) {
          try {
            crewCount = (jsonDecode(cs.crewJson!) as List<dynamic>).length;
          } catch (_) {}
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: EtoleColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                EtoleHaptics.light();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CallSheetViewScreen(callSheetId: cs.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Shoot Date & Big Call Time Banner
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEE, d MMMM yyyy')
                                  .format(cs.shootDate)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: muted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cs.title,
                              style: EtoleTypography.sectionTitle(color: cream)
                                  .copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: EtoleColors.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'CALL',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                cs.callTime,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: EtoleColors.cyan,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cs.locationName,
                            style: TextStyle(
                              color: cream,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Weather & Crew count badges
                    Row(
                      children: [
                        if (cs.weatherForecast != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.wb_sunny_outlined,
                                  size: 12,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cs.weatherForecast!,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                size: 12,
                                color: Colors.tealAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$crewCount Crew Members',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.tealAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 16,
                          ),
                          label: const Text(
                            'Export PDF',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final db = ref.read(databaseProvider);
                            final brands = await db.select(db.brands).get();
                            final brand = brands.firstWhere(
                              (b) => b.id == cs.brandId,
                              orElse: () => brands.first,
                            );
                            final pdfBytes =
                                await CallSheetPdfBuilder.buildCallSheetPdf(
                                  cs: cs,
                                  brand: brand,
                                );
                            await Printing.sharePdf(
                              bytes: pdfBytes,
                              filename:
                                  'CallSheet_${cs.title.replaceAll(' ', '_')}.pdf',
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EtoleColors.cyan.withValues(
                              alpha: 0.15,
                            ),
                            foregroundColor: EtoleColors.cyan,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: EtoleColors.cyan.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.remove_red_eye_outlined,
                            size: 15,
                          ),
                          label: const Text(
                            'View Sheet',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CallSheetViewScreen(callSheetId: cs.id),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 3: GEAR LOCKER ---
  Widget _buildGearLockerTab(
    List<GearItem> gearList,
    Color cream,
    Color muted,
  ) {
    final filtered = _gearCategoryFilter == 'All'
        ? gearList
        : gearList
              .where(
                (g) =>
                    g.category.toLowerCase() ==
                    _gearCategoryFilter.toLowerCase(),
              )
              .toList();

    final packedCount = gearList.where((g) => g.isPacked).length;

    return Column(
      children: [
        // Category Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: _gearCategories.map((cat) {
              final isSel = _gearCategoryFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSel,
                  selectedColor: EtoleColors.cyan,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : cream,
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSel
                          ? EtoleColors.cyan
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  onSelected: (val) {
                    setState(() => _gearCategoryFilter = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Quick Stats & Reset Pack Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PACKED FOR SET: $packedCount / ${gearList.length}',
                style: const TextStyle(
                  color: EtoleColors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
              if (packedCount > 0)
                GestureDetector(
                  onTap: () async {
                    final db = ref.read(databaseProvider);
                    await (db.update(
                      db.gearItems,
                    )..where((t) => t.isPacked.equals(true))).write(
                      const GearItemsCompanion(isPacked: drift.Value(false)),
                    );
                    EtoleHaptics.medium();
                  },
                  child: const Text(
                    'Reset Pack',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Gear Items List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(
                  icon: Icons.camera_alt_outlined,
                  title: 'No Gear in this Category',
                  subtitle: 'Tap "+ ADD GEAR" to add your cinema lenses, bodies, drones, and lighting packages.',
                  cream: cream,
                  muted: muted,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final gear = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: gear.isPacked
                            ? EtoleColors.cyan.withValues(alpha: 0.08)
                            : EtoleColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: gear.isPacked
                              ? EtoleColors.cyan.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: gear.isPacked
                                ? EtoleColors.cyan
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoryIcon(gear.category),
                            size: 18,
                            color: gear.isPacked ? Colors.white : cream,
                          ),
                        ),
                        title: Text(
                          gear.name,
                          style: TextStyle(
                            color: cream,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            decoration: gear.isPacked
                                ? TextDecoration.none
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${gear.category}${gear.serialNumber != null ? ' · S/N: ${gear.serialNumber}' : ''}',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                        trailing: Checkbox(
                          value: gear.isPacked,
                          activeColor: EtoleColors.cyan,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) async {
                            EtoleHaptics.selection();
                            final db = ref.read(databaseProvider);
                            await (db.update(
                              db.gearItems,
                            )..where((t) => t.id.equals(gear.id))).write(
                              GearItemsCompanion(
                                isPacked: drift.Value(val ?? false),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'camera':
        return Icons.videocam_rounded;
      case 'lens':
        return Icons.camera_rounded;
      case 'drone':
        return Icons.flight_takeoff_rounded;
      case 'lighting':
        return Icons.lightbulb_outline_rounded;
      case 'audio':
        return Icons.mic_rounded;
      case 'support':
        return Icons.camera_alt_outlined;
      case 'media':
        return Icons.sd_card_outlined;
      case 'power':
        return Icons.battery_charging_full_rounded;
      default:
        return Icons.build_outlined;
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cream,
    required Color muted,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: muted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              title,
              style: EtoleTypography.sectionTitle(color: cream)
                  .copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFabAction(BuildContext context) {
    if (_selectedTab == 0) {
      _showCreateProjectSheet(context);
    } else if (_selectedTab == 1) {
      _showCreateCallSheetModal(context);
    } else {
      _showAddGearSheet(context);
    }
  }

  void _showCreateProjectSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String projectType = 'Commercial';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EtoleColors.darkSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CREATE PRODUCTION PROJECT',
                style: TextStyle(
                  color: EtoleColors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'Project Title (e.g. Safaricom Commercial)',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clientCtrl,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'Client or Brand Name',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'Budget (KES)',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'Primary Location',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final db = ref.read(databaseProvider);
                    final brands = await db.select(db.brands).get();
                    final brandId = brands.first.id;

                    await db
                        .into(db.productionProjects)
                        .insert(
                          ProductionProjectsCompanion.insert(
                            brandId: brandId,
                            title: titleCtrl.text.trim(),
                            clientName: clientCtrl.text.trim().isNotEmpty
                                ? clientCtrl.text.trim()
                                : 'Private Client',
                            projectType: drift.Value(projectType),
                            budgetAmount: drift.Value(
                              double.tryParse(budgetCtrl.text.trim()) ?? 0.0,
                            ),
                            location: drift.Value(
                              locationCtrl.text.trim().isNotEmpty
                                  ? locationCtrl.text.trim()
                                  : null,
                            ),
                            milestonesJson: drift.Value(
                              jsonEncode([
                                {
                                  'id': 'm1',
                                  'title': 'Pre-Production & Tech Scout',
                                  'isDone': false,
                                },
                                {
                                  'id': 'm2',
                                  'title': 'Principal Photography (Shoot Day)',
                                  'isDone': false,
                                },
                                {
                                  'id': 'm3',
                                  'title': 'Rough Cut & Assembly',
                                  'isDone': false,
                                },
                                {
                                  'id': 'm4',
                                  'title': 'DaVinci Color Grade & Sound Mix',
                                  'isDone': false,
                                },
                                {
                                  'id': 'm5',
                                  'title': 'Final 4K Master Handover',
                                  'isDone': false,
                                },
                              ]),
                            ),
                          ),
                        );

                    if (ctx.mounted) Navigator.pop(ctx);
                    EtoleHaptics.success();
                  },
                  child: const Text(
                    'CREATE PROJECT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCallSheetModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final callTimeCtrl = TextEditingController(text: '06:00 AM');
    final locCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EtoleColors.darkSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NEW CINEMA CALL SHEET',
              style: TextStyle(
                color: EtoleColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: EtoleColors.cream),
              decoration: const InputDecoration(
                labelText: 'Shoot Title (e.g. Day 1: Commercial Shoot)',
                labelStyle: TextStyle(color: EtoleColors.creamMuted),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: callTimeCtrl,
              style: const TextStyle(color: EtoleColors.cream),
              decoration: const InputDecoration(
                labelText: 'Crew Call Time (e.g. 06:00 AM)',
                labelStyle: TextStyle(color: EtoleColors.creamMuted),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locCtrl,
              style: const TextStyle(color: EtoleColors.cream),
              decoration: const InputDecoration(
                labelText: 'Set Location Name (e.g. Nairobi National Park)',
                labelStyle: TextStyle(color: EtoleColors.creamMuted),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EtoleColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty ||
                      locCtrl.text.trim().isEmpty)
                    return;
                  final db = ref.read(databaseProvider);
                  final brands = await db.select(db.brands).get();
                  final brandId = brands.first.id;

                  await db
                      .into(db.callSheets)
                      .insert(
                        CallSheetsCompanion.insert(
                          brandId: brandId,
                          title: titleCtrl.text.trim(),
                          callTime: drift.Value(callTimeCtrl.text.trim()),
                          locationName: locCtrl.text.trim(),
                          shootDate: drift.Value(
                            DateTime.now().add(const Duration(days: 1)),
                          ),
                          crewJson: drift.Value(
                            jsonEncode([
                              {
                                'role': 'Director / DP',
                                'name': 'Brian Etole',
                                'phone': '+254 718 013 579',
                                'callTime': callTimeCtrl.text.trim(),
                              },
                            ]),
                          ),
                        ),
                      );

                  if (ctx.mounted) Navigator.pop(ctx);
                  EtoleHaptics.success();
                },
                child: const Text(
                  'GENERATE CALL SHEET',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGearSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final snCtrl = TextEditingController();
    String category = 'Camera';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EtoleColors.darkSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADD GEAR TO LOCKER',
                style: TextStyle(
                  color: EtoleColors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'Gear Name (e.g. Sony FX6 Cinema Body)',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: EtoleColors.darkSurfaceElevated,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
                items:
                    [
                      'Camera',
                      'Lens',
                      'Drone',
                      'Lighting',
                      'Audio',
                      'Support',
                      'Media',
                      'Power',
                    ].map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                onChanged: (v) => setModalState(() => category = v ?? 'Camera'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: snCtrl,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'Serial Number / Asset Tag (Optional)',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final db = ref.read(databaseProvider);
                    final brands = await db.select(db.brands).get();
                    final brandId = brands.first.id;

                    await db
                        .into(db.gearItems)
                        .insert(
                          GearItemsCompanion.insert(
                            brandId: brandId,
                            name: nameCtrl.text.trim(),
                            category: drift.Value(category),
                            serialNumber: drift.Value(
                              snCtrl.text.trim().isNotEmpty
                                  ? snCtrl.text.trim()
                                  : null,
                            ),
                          ),
                        );

                    if (ctx.mounted) Navigator.pop(ctx);
                    EtoleHaptics.success();
                  },
                  child: const Text(
                    'ADD TO LOCKER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
