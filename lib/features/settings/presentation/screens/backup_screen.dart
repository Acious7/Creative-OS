import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../data/backup_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  DatabaseStats? _stats;
  List<File> _localSnapshots = [];
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final backupService = BackupService(db);
    try {
      final stats = await backupService.getDatabaseStats();
      final snapshots = await backupService.listLocalBackups();
      if (mounted) {
        setState(() {
          _stats = stats;
          _localSnapshots = snapshots;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('d MMM yyyy • h:mm a').format(dt);
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    final db = ref.read(databaseProvider);
    final backupService = BackupService(db);

    try {
      EtoleHaptics.medium();
      await backupService.shareBackupFile();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Full offline archive exported successfully'),
            backgroundColor: EtoleColors.cyan,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleRestorePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      final lowerPath = path.toLowerCase();
      if (!lowerPath.endsWith('.etole') &&
          !lowerPath.endsWith('.zip') &&
          !lowerPath.endsWith('.json')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please select an .etole, .zip, or .json backup file',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final file = File(path);
      await _promptAndRestoreFile(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _promptAndRestoreFile(File file) async {
    final db = ref.read(databaseProvider);
    final backupService = BackupService(db);

    // Preview
    final summary = await backupService.previewBackupFile(file);
    if (!mounted) return;

    if (summary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to read backup file. Archive may be corrupted or invalid.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EtoleColors.darkSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: EtoleColors.gold.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: EtoleColors.gold,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Restore Backup?',
              style: TextStyle(color: EtoleColors.cream, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Archive created on ${_formatDateTime(summary.createdAt)}',
              style: const TextStyle(
                color: EtoleColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Contents to be restored:',
              style: TextStyle(color: EtoleColors.creamMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _dialogStatRow('Documents', '${summary.documentCount}'),
                  _dialogStatRow('Clients', '${summary.clientCount}'),
                  _dialogStatRow('Places & Events', '${summary.eventCount}'),
                  _dialogStatRow('Contacts / Leads', '${summary.leadCount}'),
                  _dialogStatRow('Catalog Items', '${summary.itemCount}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Restoring will replace your current data with this backup. We recommend exporting a backup of current data first.',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
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
              backgroundColor: EtoleColors.cyan,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Proceed & Restore',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final success = await backupService.restoreBackupFromFile(file);
      await _loadData();

      if (mounted) {
        if (success) {
          EtoleHaptics.success();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: EtoleColors.darkSurfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Restore Completed',
                    style: TextStyle(color: EtoleColors.cream),
                  ),
                ],
              ),
              content: const Text(
                'All database records, documents, networking contacts, and attachments have been successfully restored!',
                style: TextStyle(
                  color: EtoleColors.creamMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to restore backup. Please ensure file is valid.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Widget _dialogStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: EtoleColors.creamMuted, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: EtoleColors.cream,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteSnapshot(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EtoleColors.darkSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Local Snapshot?',
          style: TextStyle(color: EtoleColors.cream),
        ),
        content: Text(
          'Delete ${file.uri.pathSegments.last}? This action cannot be undone.',
          style: const TextStyle(color: EtoleColors.creamMuted, fontSize: 13),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      final backupService = BackupService(db);
      await backupService.deleteBackupFile(file);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOled = ref.watch(isOledModeProvider);
    final cream = isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary;
    final muted = isDark ? EtoleColors.muted : EtoleColors.lightTextMuted;

    return Scaffold(
      backgroundColor: isDark
          ? (isOled ? EtoleColors.pitchBlack : EtoleColors.obsidian)
          : EtoleColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: cream),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '09 · BACKUP & RECOVERY',
                        style: EtoleTypography.labelCaps(
                          color: EtoleColors.cyan,
                        ),
                      ),
                      Text(
                        'OFFLINE ARCHIVE & RESTORE',
                        style: EtoleTypography.subheading(color: cream),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const EtoleHairline(),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: EtoleColors.cyan),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      children: [
                        // Live Health Card
                        _buildHealthCard(cream, muted),
                        const SizedBox(height: 24),

                        // Action Buttons: Export & Restore
                        Text(
                          'ARCHIVE ACTIONS',
                          style: EtoleTypography.labelCaps(color: muted),
                        ),
                        const SizedBox(height: 12),

                        // Export Button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: EtoleColors.darkSurfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: EtoleColors.cyan.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.archive_outlined,
                                      color: EtoleColors.cyan,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Export Full Backup',
                                          style: TextStyle(
                                            color: cream,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Encrypted .etole archive with all data & media',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              EtoleButton.primary(
                                label: _isExporting
                                    ? 'PACKAGING ARCHIVE...'
                                    : 'EXPORT & SHARE BACKUP',
                                icon: Icons.share_rounded,
                                isFullWidth: true,
                                onPressed: (_isExporting || _isRestoring)
                                    ? null
                                    : _handleExport,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Restore from File Button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: EtoleColors.darkSurfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.tealAccent.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.restore_page_outlined,
                                      color: Colors.tealAccent,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Restore From File',
                                          style: TextStyle(
                                            color: cream,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Import from Google Drive, SD card, or Downloads',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.tealAccent.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  foregroundColor: Colors.tealAccent,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: _isRestoring
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.tealAccent,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.file_open_outlined,
                                        size: 18,
                                      ),
                                label: Text(
                                  _isRestoring
                                      ? 'RESTORING DATABASE...'
                                      : 'CHOOSE BACKUP FILE (.etole)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                onPressed: (_isExporting || _isRestoring)
                                    ? null
                                    : _handleRestorePicker,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        const EtoleHairline(),
                        const SizedBox(height: 24),

                        // Saved Local Snapshots List
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SAVED LOCAL SNAPSHOTS (${_localSnapshots.length}/7)',
                              style: EtoleTypography.labelCaps(color: muted),
                            ),
                            if (_localSnapshots.isNotEmpty)
                              Text(
                                'Auto-retains latest 7',
                                style: TextStyle(color: muted, fontSize: 10),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_localSnapshots.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: muted.withValues(alpha: 0.5),
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No local snapshots saved yet',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap "Export Full Backup" above to create one.',
                                    style: TextStyle(
                                      color: muted.withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._localSnapshots.map(
                            (f) => _buildSnapshotCard(f, cream, muted),
                          ),

                        const SizedBox(height: 32),
                        const EtoleHairline(),
                        const SizedBox(height: 24),

                        // Security Architecture Callout
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: EtoleColors.cyan.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: EtoleColors.cyan.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    color: EtoleColors.cyan,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    '100% OFFLINE-FIRST SOVEREIGNTY',
                                    style: TextStyle(
                                      color: EtoleColors.cyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'All records, client notes, PDF designs, and contract signatures remain entirely on this device. Backups are self-contained archives that you control—store them in Google Drive, personal cloud storage, or on a flash drive.',
                                style: EtoleTypography.bodySmall(color: cream)
                                    .copyWith(height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(Color cream, Color muted) {
    final stats = _stats;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EtoleColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DATABASE HEALTH',
                style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
              ),
              if (stats != null && stats.estimatedSizeBytes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatBytes(stats.estimatedSizeBytes),
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (stats == null)
            const Text(
              'Loading statistics...',
              style: TextStyle(color: EtoleColors.creamMuted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatPill('📄 ${stats.documentCount} Docs', cream),
                _buildStatPill('👥 ${stats.clientCount} Clients', cream),
                _buildStatPill('📍 ${stats.eventCount} Places', cream),
                _buildStatPill('📇 ${stats.leadCount} Contacts', cream),
                _buildStatPill('📦 ${stats.itemCount} Items', cream),
                _buildStatPill('🏷️ ${stats.brandCount} Brands', cream),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, Color cream) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cream,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSnapshotCard(File file, Color cream, Color muted) {
    final fileName = file.uri.pathSegments.last;
    final fileStat = file.statSync();
    final sizeFormatted = _formatBytes(fileStat.size);
    final dateFormatted = _formatDateTime(fileStat.modified);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: EtoleColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EtoleColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.folder_zip_outlined,
              color: EtoleColors.cyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: cream,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateFormatted • $sizeFormatted',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: muted, size: 20),
            color: EtoleColors.darkSurfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (val) {
              if (val == 'restore') {
                _promptAndRestoreFile(file);
              } else if (val == 'share') {
                final db = ref.read(databaseProvider);
                BackupService(db).shareBackupFile(file);
              } else if (val == 'delete') {
                _handleDeleteSnapshot(file);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(
                      Icons.restore_rounded,
                      color: Colors.tealAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Restore this Backup',
                      style: TextStyle(color: Colors.tealAccent, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(
                      Icons.share_outlined,
                      color: EtoleColors.cream,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Share / Export',
                      style: TextStyle(color: EtoleColors.cream, fontSize: 13),
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
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Delete Snapshot',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
