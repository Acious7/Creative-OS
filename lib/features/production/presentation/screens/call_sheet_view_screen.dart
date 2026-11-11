import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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

class CallSheetViewScreen extends ConsumerStatefulWidget {
  final int callSheetId;

  const CallSheetViewScreen({super.key, required this.callSheetId});

  @override
  ConsumerState<CallSheetViewScreen> createState() =>
      _CallSheetViewScreenState();
}

class _CallSheetViewScreenState extends ConsumerState<CallSheetViewScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOled = ref.watch(isOledModeProvider);
    final cream = isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary;
    final muted = isDark ? EtoleColors.muted : EtoleColors.lightTextMuted;

    return StreamBuilder<CallSheet>(
      stream: (db.select(
        db.callSheets,
      )..where((t) => t.id.equals(widget.callSheetId))).watchSingle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: isDark
                ? EtoleColors.darkBase
                : EtoleColors.lightBase,
            body: const Center(
              child: CircularProgressIndicator(color: EtoleColors.cyan),
            ),
          );
        }

        final cs = snapshot.data!;

        // Parse Crew
        List<CrewMember> crewList = [];
        if (cs.crewJson != null && cs.crewJson!.isNotEmpty) {
          try {
            final list = jsonDecode(cs.crewJson!) as List<dynamic>;
            crewList = list
                .map((e) => CrewMember.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {}
        }

        // Parse Schedule
        List<ScheduleScene> scheduleList = [];
        if (cs.scheduleJson != null && cs.scheduleJson!.isNotEmpty) {
          try {
            final list = jsonDecode(cs.scheduleJson!) as List<dynamic>;
            scheduleList = list
                .map((e) => ScheduleScene.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {}
        }

        return Scaffold(
          backgroundColor: isDark
              ? (isOled ? EtoleColors.pitchBlack : EtoleColors.obsidian)
              : EtoleColors.warmWhite,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_rounded, color: cream),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRODUCTION CALL SHEET',
                                style: EtoleTypography.labelCaps(
                                  color: EtoleColors.cyan,
                                ),
                              ),
                              Text(
                                'DAY 1 DETAILS',
                                style: EtoleTypography.subheading(color: cream),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: Colors.tealAccent,
                            ),
                            tooltip: 'Export PDF',
                            onPressed: () => _exportPdf(cs),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.share_outlined,
                              color: EtoleColors.cyan,
                            ),
                            tooltip: 'Share via WhatsApp',
                            onPressed: () =>
                                _shareCallSheetWhatsApp(cs, crewList),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.amberAccent,
                            ),
                            tooltip: 'Edit Call Sheet',
                            onPressed: () =>
                                _showEditCallSheetModal(context, cs),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                            ),
                            tooltip: 'Delete Call Sheet',
                            onPressed: () =>
                                _confirmDeleteCallSheet(context, cs),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const EtoleHairline(),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    children: [
                      // Shoot Title Banner
                      Text(
                        DateFormat('EEEE, d MMMM yyyy')
                            .format(cs.shootDate)
                            .toUpperCase(),
                        style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cs.title,
                        style: EtoleTypography.pageTitle(color: cream)
                            .copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 16),

                      // Signature Call Time Card (Quotation Centerpiece Style)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: EtoleColors.cyan,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: EtoleColors.cyan.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GENERAL CREW CALL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'On Set & Ready',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              cs.callTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Location & Hospital Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? EtoleColors.darkSurfaceElevated
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? EtoleColors.darkHairline
                                : EtoleColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: EtoleColors.cyan,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cs.locationName,
                                        style: TextStyle(
                                          color: cream,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (cs.locationAddress != null)
                                        Text(
                                          cs.locationAddress!,
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (cs.locationGps != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.directions_rounded,
                                      color: Colors.tealAccent,
                                    ),
                                    onPressed: () async {
                                      final url = Uri.parse(
                                        'https://maps.google.com/?q=${cs.locationGps}',
                                      );
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                  ),
                              ],
                            ),
                            if (cs.nearestHospital != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.local_hospital_rounded,
                                      color: Colors.redAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Hospital: ${cs.nearestHospital!}',
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Sun & Weather Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoTile(
                              icon: Icons.wb_sunny_rounded,
                              iconColor: Colors.amberAccent,
                              title: 'SUNRISE / GOLDEN',
                              value: cs.sunriseTime ?? '06:18 AM',
                              cream: cream,
                              muted: muted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInfoTile(
                              icon: Icons.wb_twilight_rounded,
                              iconColor: EtoleColors.gold,
                              title: 'SUNSET / BLUE',
                              value: cs.sunsetTime ?? '18:34 PM',
                              cream: cream,
                              muted: muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Shooting Schedule
                      if (scheduleList.isNotEmpty) ...[
                        Text(
                          'SHOOTING SCHEDULE (${scheduleList.length} SCENES)',
                          style: EtoleTypography.labelCaps(color: muted),
                        ),
                        const SizedBox(height: 10),
                        ...scheduleList.map(
                          (s) => _buildScheduleItem(s, cream, muted),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Crew Roster
                      if (crewList.isNotEmpty) ...[
                        Text(
                          'CREW ROSTER (${crewList.length} MEMBERS)',
                          style: EtoleTypography.labelCaps(color: muted),
                        ),
                        const SizedBox(height: 10),
                        ...crewList.map((c) => _buildCrewItem(c, cream, muted)),
                        const SizedBox(height: 24),
                      ],

                      // General Notes
                      if (cs.generalNotes != null &&
                          cs.generalNotes!.isNotEmpty) ...[
                        Text(
                          'DIRECTOR & SAFETY NOTES',
                          style: EtoleTypography.labelCaps(color: muted),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Text(
                            cs.generalNotes!,
                            style: TextStyle(
                              color: cream,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Bottom Export Action Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EtoleColors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 20,
                        ),
                        label: const Text(
                          'PRINT / EXPORT CALL SHEET PDF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        onPressed: () => _exportPdf(cs),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color cream,
    required Color muted,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EtoleColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: cream,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(ScheduleScene scene, Color cream, Color muted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EtoleColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: EtoleColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: EtoleColors.cyan.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              scene.time,
              style: const TextStyle(
                color: EtoleColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.scene,
                  style: TextStyle(
                    color: cream,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                if (scene.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    scene.description,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 12,
                      color: Colors.tealAccent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      scene.location,
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewItem(CrewMember crew, Color cream, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? EtoleColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? EtoleColors.darkHairline : EtoleColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EtoleColors.cyan.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: EtoleColors.cyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crew.role,
                  style: const TextStyle(
                    color: EtoleColors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.7,
                  ),
                ),
                Text(
                  crew.name,
                  style: TextStyle(
                    color: cream,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  'Call: ${crew.callTime}',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (crew.phone.isNotEmpty) ...[
            IconButton(
              icon: const Icon(
                Icons.call_outlined,
                color: Colors.greenAccent,
                size: 20,
              ),
              onPressed: () async {
                final url = Uri.parse('tel:${crew.phone}');
                await launchUrl(url);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.tealAccent,
                size: 20,
              ),
              onPressed: () async {
                final phone = crew.phone.replaceAll(RegExp(r'[^0-9]'), '');
                final url = Uri.parse('https://wa.me/$phone');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _exportPdf(CallSheet cs) async {
    final db = ref.read(databaseProvider);
    final brands = await db.select(db.brands).get();
    final brand = brands.firstWhere(
      (b) => b.id == cs.brandId,
      orElse: () => brands.first,
    );
    final pdfBytes = await CallSheetPdfBuilder.buildCallSheetPdf(
      cs: cs,
      brand: brand,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'CallSheet_${cs.title.replaceAll(' ', '_')}.pdf',
    );
  }

  void _shareCallSheetWhatsApp(CallSheet cs, List<CrewMember> crew) async {
    final buffer = StringBuffer();
    buffer.writeln('📋 *CALL SHEET: ${cs.title.toUpperCase()}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '📅 *Date:* ${DateFormat('EEEE, d MMM yyyy').format(cs.shootDate)}',
    );
    buffer.writeln('⏰ *General Crew Call:* ${cs.callTime}');
    buffer.writeln('📍 *Location:* ${cs.locationName}');
    if (cs.locationGps != null)
      buffer.writeln('🗺️ *GPS:* https://maps.google.com/?q=${cs.locationGps}');
    buffer.writeln('🌅 *Sunrise:* ${cs.sunriseTime ?? '06:18 AM'}');
    buffer.writeln('🌇 *Sunset:* ${cs.sunsetTime ?? '18:34 PM'}');
    if (cs.nearestHospital != null)
      buffer.writeln('🏥 *Nearest Hospital:* ${cs.nearestHospital}');
    if (cs.generalNotes != null) {
      buffer.writeln('');
      buffer.writeln('📝 *Notes:* ${cs.generalNotes}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('See attached PDF for full schedule & crew call details.');

    final text = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/?text=$text');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDeleteCallSheet(
    BuildContext context,
    CallSheet cs,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171B),
        title: const Text(
          'Delete Call Sheet?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "${cs.title}"? This will move it to the trash archive.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await (db.update(db.callSheets)..where((t) => t.id.equals(cs.id))).write(
        const CallSheetsCompanion(isDeleted: drift.Value(true)),
      );

      if (mounted) {
        Navigator.pop(context); // Go back to call sheets list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call sheet "${cs.title}" moved to trash.'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: EtoleColors.cyan,
              onPressed: () async {
                await (db.update(
                  db.callSheets,
                )..where((t) => t.id.equals(cs.id))).write(
                  const CallSheetsCompanion(isDeleted: drift.Value(false)),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _showEditCallSheetModal(BuildContext context, CallSheet cs) {
    EtoleHaptics.selection();
    final titleCtrl = TextEditingController(text: cs.title);
    final callTimeCtrl = TextEditingController(text: cs.callTime);
    final locNameCtrl = TextEditingController(text: cs.locationName);
    final locAddressCtrl = TextEditingController(
      text: cs.locationAddress ?? '',
    );
    final hospitalCtrl = TextEditingController(text: cs.nearestHospital ?? '');
    final notesCtrl = TextEditingController(text: cs.generalNotes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: const Color(0xFA121518),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
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
                const SizedBox(height: 14),
                Text(
                  'Edit Call Sheet Details',
                  style: EtoleTypography.h2.copyWith(
                    color: EtoleColors.cream,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Shoot Day / Call Sheet Title',
                    labelStyle: TextStyle(color: EtoleColors.cyan),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: callTimeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'General Crew Call Time',
                          labelStyle: TextStyle(color: EtoleColors.cyan),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: locNameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Location Name',
                          labelStyle: TextStyle(color: EtoleColors.cyan),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locAddressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Location Address / Directions',
                    labelStyle: TextStyle(color: EtoleColors.cyan),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hospitalCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nearest Hospital & Emergency Contact',
                    labelStyle: TextStyle(color: EtoleColors.cyan),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'General Production Notes',
                    labelStyle: TextStyle(color: EtoleColors.cyan),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final db = ref.read(databaseProvider);
                    await (db.update(
                      db.callSheets,
                    )..where((t) => t.id.equals(cs.id))).write(
                      CallSheetsCompanion(
                        title: drift.Value(titleCtrl.text.trim()),
                        callTime: drift.Value(callTimeCtrl.text.trim()),
                        locationName: drift.Value(locNameCtrl.text.trim()),
                        locationAddress: drift.Value(
                          locAddressCtrl.text.trim().isNotEmpty
                              ? locAddressCtrl.text.trim()
                              : null,
                        ),
                        nearestHospital: drift.Value(
                          hospitalCtrl.text.trim().isNotEmpty
                              ? hospitalCtrl.text.trim()
                              : null,
                        ),
                        generalNotes: drift.Value(
                          notesCtrl.text.trim().isNotEmpty
                              ? notesCtrl.text.trim()
                              : null,
                        ),
                      ),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
