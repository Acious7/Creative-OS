import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/production_models.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOled = ref.watch(isOledModeProvider);
    final cream = isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary;
    final muted = isDark ? EtoleColors.muted : EtoleColors.lightTextMuted;

    return StreamBuilder<ProductionProject>(
      stream: (db.select(
        db.productionProjects,
      )..where((t) => t.id.equals(widget.projectId))).watchSingle(),
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

        final project = snapshot.data!;
        final currentStage = ProductionStage.fromCode(project.stage);

        // Milestones
        List<MilestoneItem> milestones = [];
        if (project.milestonesJson != null &&
            project.milestonesJson!.isNotEmpty) {
          try {
            final list = jsonDecode(project.milestonesJson!) as List<dynamic>;
            milestones = list
                .map((e) => MilestoneItem.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {}
        }

        // Delivery Links
        List<DeliveryLinkItem> deliveryLinks = [];
        if (project.deliveryLinksJson != null &&
            project.deliveryLinksJson!.isNotEmpty) {
          try {
            final list =
                jsonDecode(project.deliveryLinksJson!) as List<dynamic>;
            deliveryLinks = list
                .map(
                  (e) => DeliveryLinkItem.fromJson(e as Map<String, dynamic>),
                )
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
                // Top App Bar
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
                                'PRODUCTION MILESTONES',
                                style: EtoleTypography.labelCaps(
                                  color: EtoleColors.cyan,
                                ),
                              ),
                              Text(
                                'PROJECT TRACKER',
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
                              Icons.share_outlined,
                              color: EtoleColors.cyan,
                            ),
                            tooltip: 'Share Handover Note',
                            onPressed: () => _shareHandoverNote(
                              context,
                              project,
                              deliveryLinks,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.tealAccent,
                            ),
                            tooltip: 'Edit Project',
                            onPressed: () =>
                                _showEditProjectModal(context, project),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                            ),
                            tooltip: 'Delete Project',
                            onPressed: () =>
                                _confirmDeleteProject(context, project),
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
                      // Project Header Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? EtoleColors.darkSurfaceElevated
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  project.projectType.toUpperCase(),
                                  style: const TextStyle(
                                    color: EtoleColors.cyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if (project.budgetAmount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EtoleColors.gold.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: EtoleColors.gold.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'KES ${NumberFormat('#,##0').format(project.budgetAmount)}',
                                      style: const TextStyle(
                                        color: EtoleColors.gold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              project.title,
                              style: EtoleTypography.pageTitle(color: cream)
                                  .copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Client: ${project.clientName}',
                              style: TextStyle(
                                color: muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (project.location != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: EtoleColors.cyan,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      project.location!,
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Production Stage Stepper
                      Text(
                        'PIPELINE STAGE',
                        style: EtoleTypography.labelCaps(color: muted),
                      ),
                      const SizedBox(height: 10),
                      _buildStageSelector(context, project, currentStage),
                      const SizedBox(height: 28),

                      // Milestones Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PROJECT MILESTONES (${milestones.where((m) => m.isDone).length}/${milestones.length})',
                            style: EtoleTypography.labelCaps(color: muted),
                          ),
                          InkWell(
                            onTap: () => _showAddMilestoneDialog(
                              context,
                              project,
                              milestones,
                            ),
                            child: const Text(
                              '+ Add Milestone',
                              style: TextStyle(
                                color: EtoleColors.cyan,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (milestones.isEmpty)
                        Text(
                          'No milestones set yet.',
                          style: TextStyle(color: muted, fontSize: 12),
                        )
                      else
                        ...milestones.map(
                          (m) => _buildMilestoneRow(
                            m,
                            project,
                            milestones,
                            cream,
                            muted,
                          ),
                        ),

                      const SizedBox(height: 28),
                      const EtoleHairline(),
                      const SizedBox(height: 24),

                      // Delivery Handover Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DELIVERY & HANDOVER LINKS',
                            style: EtoleTypography.labelCaps(color: muted),
                          ),
                          InkWell(
                            onTap: () => _showAddDeliveryLinkDialog(
                              context,
                              project,
                              deliveryLinks,
                            ),
                            child: const Text(
                              '+ Add Link',
                              style: TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (deliveryLinks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'No review or master download links added yet. Tap "+ Add Link" to attach Frame.io, Drive, or Dropbox handover links.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        )
                      else
                        ...deliveryLinks.map(
                          (dl) => _buildDeliveryLinkCard(dl, cream, muted),
                        ),

                      const SizedBox(height: 24),
                      if (deliveryLinks.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text(
                            'DISPATCH HANDOVER TO CLIENT (WHATSAPP)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                          onPressed: () => _shareHandoverNote(
                            context,
                            project,
                            deliveryLinks,
                          ),
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

  Widget _buildStageSelector(
    BuildContext context,
    ProductionProject project,
    ProductionStage current,
  ) {
    final stages = [
      ProductionStage.preProduction,
      ProductionStage.production,
      ProductionStage.postProduction,
      ProductionStage.clientReview,
      ProductionStage.delivered,
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: stages.map((st) {
          final isCurrent = current == st;
          final isPast = stages.indexOf(st) < stages.indexOf(current);

          return GestureDetector(
            onTap: () async {
              EtoleHaptics.selection();
              final db = ref.read(databaseProvider);
              await (db.update(
                db.productionProjects,
              )..where((t) => t.id.equals(project.id))).write(
                ProductionProjectsCompanion(stage: drift.Value(st.code)),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? st.color.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent ? st.color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPast ? Icons.check_circle_rounded : st.icon,
                    size: 18,
                    color: isCurrent
                        ? st.color
                        : (isPast
                              ? Colors.greenAccent
                              : EtoleColors.creamMuted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      st.label,
                      style: TextStyle(
                        color: isCurrent
                            ? EtoleColors.cream
                            : EtoleColors.creamMuted,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: st.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMilestoneRow(
    MilestoneItem milestone,
    ProductionProject project,
    List<MilestoneItem> allMilestones,
    Color cream,
    Color muted,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: EtoleColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: milestone.isDone
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Checkbox(
          value: milestone.isDone,
          activeColor: Colors.greenAccent,
          checkColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (val) async {
            EtoleHaptics.selection();
            final updated = allMilestones.map((m) {
              if (m.id == milestone.id) {
                return MilestoneItem(
                  id: m.id,
                  title: m.title,
                  isDone: val ?? false,
                  dueDate: m.dueDate,
                );
              }
              return m;
            }).toList();

            final db = ref.read(databaseProvider);
            await (db.update(
              db.productionProjects,
            )..where((t) => t.id.equals(project.id))).write(
              ProductionProjectsCompanion(
                milestonesJson: drift.Value(
                  jsonEncode(updated.map((e) => e.toJson()).toList()),
                ),
              ),
            );
          },
        ),
        title: Text(
          milestone.title,
          style: TextStyle(
            color: cream,
            fontSize: 13,
            decoration: milestone.isDone ? TextDecoration.lineThrough : null,
            decorationColor: muted,
          ),
        ),
        subtitle: milestone.dueDate != null
            ? Text(
                'Due: ${milestone.dueDate}',
                style: TextStyle(color: muted, fontSize: 11),
              )
            : null,
      ),
    );
  }

  Widget _buildDeliveryLinkCard(DeliveryLinkItem dl, Color cream, Color muted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EtoleColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: Colors.tealAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dl.platform} · ${dl.label}',
                  style: TextStyle(
                    color: cream,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dl.url,
                  style: TextStyle(color: muted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: Colors.tealAccent,
              size: 18,
            ),
            onPressed: () async {
              final uri = Uri.tryParse(dl.url);
              if (uri != null)
                await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }

  void _showAddMilestoneDialog(
    BuildContext context,
    ProductionProject project,
    List<MilestoneItem> current,
  ) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EtoleColors.darkSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Milestone',
          style: TextStyle(color: EtoleColors.cream),
        ),
        content: TextField(
          controller: titleCtrl,
          style: const TextStyle(color: EtoleColors.cream),
          decoration: const InputDecoration(
            labelText: 'Milestone Title (e.g. Color Grade Lock)',
            labelStyle: TextStyle(color: EtoleColors.creamMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: EtoleColors.creamMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EtoleColors.cyan,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final newItem = MilestoneItem(
                id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                title: titleCtrl.text.trim(),
                isDone: false,
              );
              final updated = [...current, newItem];
              final db = ref.read(databaseProvider);
              await (db.update(
                db.productionProjects,
              )..where((t) => t.id.equals(project.id))).write(
                ProductionProjectsCompanion(
                  milestonesJson: drift.Value(
                    jsonEncode(updated.map((e) => e.toJson()).toList()),
                  ),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddDeliveryLinkDialog(
    BuildContext context,
    ProductionProject project,
    List<DeliveryLinkItem> current,
  ) {
    final urlCtrl = TextEditingController();
    final labelCtrl = TextEditingController(text: 'Review & Dailies');
    String platform = 'Frame.io';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: EtoleColors.darkSurfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Handover Link',
            style: TextStyle(color: EtoleColors.cream),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: platform,
                dropdownColor: EtoleColors.darkSurfaceElevated,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'Platform',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
                items:
                    [
                      'Frame.io',
                      'Google Drive',
                      'Dropbox',
                      'Vimeo',
                      'WeTransfer',
                    ].map((p) {
                      return DropdownMenuItem(value: p, child: Text(p));
                    }).toList(),
                onChanged: (v) => setDlgState(() => platform = v ?? 'Frame.io'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: labelCtrl,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'Link Label (e.g. 4K ProRes Masters)',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlCtrl,
                style: const TextStyle(color: EtoleColors.cream),
                decoration: const InputDecoration(
                  labelText: 'URL (https://...)',
                  labelStyle: TextStyle(color: EtoleColors.creamMuted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: EtoleColors.creamMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (urlCtrl.text.trim().isEmpty) return;
                final newItem = DeliveryLinkItem(
                  platform: platform,
                  label: labelCtrl.text.trim(),
                  url: urlCtrl.text.trim(),
                );
                final updated = [...current, newItem];
                final db = ref.read(databaseProvider);
                await (db.update(
                  db.productionProjects,
                )..where((t) => t.id.equals(project.id))).write(
                  ProductionProjectsCompanion(
                    deliveryLinksJson: drift.Value(
                      jsonEncode(updated.map((e) => e.toJson()).toList()),
                    ),
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Link'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareHandoverNote(
    BuildContext context,
    ProductionProject project,
    List<DeliveryLinkItem> links,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('🎬 *BRIAN ETOLE PRODUCTIONS · PROJECT HANDOVER*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('*Project:* ${project.title}');
    buffer.writeln('*Client:* ${project.clientName}');
    buffer.writeln('');
    buffer.writeln(
      'Dear ${project.clientName}, your project deliverables are ready:',
    );
    buffer.writeln('');
    if (links.isEmpty) {
      buffer.writeln('Please reach out for your direct download credentials.');
    } else {
      for (final l in links) {
        buffer.writeln('• *${l.platform}* (${l.label}):');
        buffer.writeln('  ${l.url}');
      }
    }
    buffer.writeln('');
    buffer.writeln('Thank you for creating with us!');
    buffer.writeln('Creative Studio · Production & Direction');
    buffer.writeln('brianetole.com');

    final text = Uri.encodeComponent(buffer.toString());
    final whatsappUrl = Uri.parse('https://wa.me/?text=$text');
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    ProductionProject project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171B),
        title: const Text(
          'Delete Project?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "${project.title}"? This will move it to the trash archive.',
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
      await (db.update(
        db.productionProjects,
      )..where((t) => t.id.equals(project.id))).write(
        const ProductionProjectsCompanion(isDeleted: drift.Value(true)),
      );

      if (mounted) {
        Navigator.pop(context); // Go back to projects list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${project.title}" moved to trash.'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: EtoleColors.cyan,
              onPressed: () async {
                await (db.update(
                  db.productionProjects,
                )..where((t) => t.id.equals(project.id))).write(
                  const ProductionProjectsCompanion(
                    isDeleted: drift.Value(false),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _showEditProjectModal(BuildContext context, ProductionProject project) {
    EtoleHaptics.selection();
    final titleCtrl = TextEditingController(text: project.title);
    final clientCtrl = TextEditingController(text: project.clientName);
    final budgetCtrl = TextEditingController(
      text: project.budgetAmount.toInt().toString(),
    );
    final locationCtrl = TextEditingController(text: project.location ?? '');
    final notesCtrl = TextEditingController(text: project.notes ?? '');
    String stage = project.stage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => ClipRRect(
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
                    'Edit Project Details',
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
                      labelText: 'Project Title',
                      labelStyle: TextStyle(color: EtoleColors.cyan),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: clientCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      labelStyle: TextStyle(color: EtoleColors.cyan),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: stage,
                          dropdownColor: const Color(0xFF1E242B),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Stage',
                            labelStyle: TextStyle(color: EtoleColors.cyan),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'pre_production',
                              child: Text('Pre-Production'),
                            ),
                            DropdownMenuItem(
                              value: 'production',
                              child: Text('Production'),
                            ),
                            DropdownMenuItem(
                              value: 'post_production',
                              child: Text('Post-Production'),
                            ),
                            DropdownMenuItem(
                              value: 'client_review',
                              child: Text('Client Review'),
                            ),
                            DropdownMenuItem(
                              value: 'delivered',
                              child: Text('Delivered'),
                            ),
                            DropdownMenuItem(
                              value: 'archived',
                              child: Text('Archived'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => stage = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: budgetCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Budget (KES)',
                            labelStyle: TextStyle(color: EtoleColors.cyan),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Shoot Location Address',
                      labelStyle: TextStyle(color: EtoleColors.cyan),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Director Notes',
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
                      final budget =
                          double.tryParse(
                            budgetCtrl.text.replaceAll(RegExp(r'[^\d.]'), ''),
                          ) ??
                          0.0;
                      final db = ref.read(databaseProvider);
                      await (db.update(
                        db.productionProjects,
                      )..where((t) => t.id.equals(project.id))).write(
                        ProductionProjectsCompanion(
                          title: drift.Value(titleCtrl.text.trim()),
                          clientName: drift.Value(clientCtrl.text.trim()),
                          stage: drift.Value(stage),
                          budgetAmount: drift.Value(budget),
                          location: drift.Value(
                            locationCtrl.text.trim().isNotEmpty
                                ? locationCtrl.text.trim()
                                : null,
                          ),
                          notes: drift.Value(
                            notesCtrl.text.trim().isNotEmpty
                                ? notesCtrl.text.trim()
                                : null,
                          ),
                          updatedAt: drift.Value(DateTime.now()),
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
      ),
    );
  }
}
