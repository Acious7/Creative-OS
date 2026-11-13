import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/security/biometrics_service.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/sanctuary_models.dart';
import '../../domain/sanctuary_storage_service.dart';

class BlackBoxJournalScreen extends ConsumerStatefulWidget {
  const BlackBoxJournalScreen({super.key});

  @override
  ConsumerState<BlackBoxJournalScreen> createState() => _BlackBoxJournalScreenState();
}

class _BlackBoxJournalScreenState extends ConsumerState<BlackBoxJournalScreen> {
  bool _isUnlocked = false;
  bool _isAuthenticating = false;
  List<BlackBoxJournalEntry> _entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _promptUnlock();
  }

  Future<void> _promptUnlock() async {
    setState(() => _isAuthenticating = true);
    final bio = ref.read(biometricsServiceProvider);
    final isSupported = await bio.isDeviceSupported();

    if (!isSupported) {
      // If biometrics unsupported, open directly
      setState(() {
        _isUnlocked = true;
        _isAuthenticating = false;
      });
      _loadEntries();
      return;
    }

    final success = await bio.authenticate(
      reason: 'Unlock your private Black Box journal',
    );

    setState(() {
      _isUnlocked = success;
      _isAuthenticating = false;
    });

    if (success) {
      _loadEntries();
    }
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await SanctuaryStorageService.loadJournalEntries();
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _openNewEntryDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final g1Ctrl = TextEditingController();
    final g2Ctrl = TextEditingController();
    final g3Ctrl = TextEditingController();
    String selectedEmoji = '✨';
    int modeIndex = 0; // 0: Reflection, 1: Gratitude Constellation, 2: Letter to Future
    DateTime selectedUnlockDate = DateTime.now().add(const Duration(days: 30));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Soulful Vault Ritual',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Mode Selector Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildModeChip('Honest Thought', 0, modeIndex, (idx) {
                            setSheetState(() => modeIndex = idx);
                          }),
                          const SizedBox(width: 8),
                          _buildModeChip('✨ Gratitude Stars', 1, modeIndex, (idx) {
                            setSheetState(() => modeIndex = idx);
                          }),
                          const SizedBox(width: 8),
                          _buildModeChip('🔒 Letter to Future', 2, modeIndex, (idx) {
                            setSheetState(() => modeIndex = idx);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mood Emojis
                    Wrap(
                      spacing: 10,
                      children: ['✨', '🔥', '🌿', '🌧️', '☕', '🌌', '⚡'].map((emoji) {
                        final isSel = selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF38B6DB).withValues(alpha: 0.25)
                                  : const Color(0xFF181D24),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? const Color(0xFF38B6DB) : Colors.transparent,
                              ),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 18)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: modeIndex == 1
                            ? 'Evening Gratitude Constellation'
                            : (modeIndex == 2 ? 'Letter to Future Self' : 'Entry Title'),
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF181D24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (modeIndex == 1) ...[
                      // 3-Point Gratitude Constellation
                      const Text(
                        '⭐ 3 Daily Stars of Gratitude',
                        style: TextStyle(color: Color(0xFFFDE047), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: g1Ctrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '1. What brought peace today?',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF181D24),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: g2Ctrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '2. Who moved my spirit or offered kindness?',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF181D24),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: g3Ctrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '3. What am I grateful to have survived or created?',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF181D24),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (modeIndex == 2) ...[
                      // Time-lock date picker
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1528),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Capsule Unlock Date', style: TextStyle(color: Color(0xFFD8B4FE), fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '${selectedUnlockDate.day}/${selectedUnlockDate.month}/${selectedUnlockDate.year}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedUnlockDate,
                                  firstDate: DateTime.now().add(const Duration(days: 1)),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                );
                                if (picked != null) {
                                  setSheetState(() => selectedUnlockDate = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFA855F7)),
                              label: const Text('Change Date', style: TextStyle(color: Color(0xFFA855F7))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    TextField(
                      controller: contentCtrl,
                      maxLines: modeIndex == 1 ? 3 : 5,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      decoration: InputDecoration(
                        labelText: modeIndex == 1 ? 'Additional Reflections (optional)' : 'Private honest thoughts...',
                        alignLabelWithHint: true,
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF181D24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Burn After Writing (Ephemeral Catharsis)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              HapticFeedback.heavyImpact();
                              await Future.delayed(const Duration(milliseconds: 150));
                              HapticFeedback.heavyImpact();
                              Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🔥 Dissolved into ashes. Stored nowhere on Earth.'),
                                    backgroundColor: Color(0xFFE11D48),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF43F5E), size: 18),
                            label: const Text('Burn', style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF43F5E)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Save into Black Box Vault
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              final content = contentCtrl.text.trim();
                              final gPoints = [
                                g1Ctrl.text.trim(),
                                g2Ctrl.text.trim(),
                                g3Ctrl.text.trim(),
                              ].where((p) => p.isNotEmpty).toList();

                              if (title.isNotEmpty || content.isNotEmpty || gPoints.isNotEmpty) {
                                final entry = BlackBoxJournalEntry(
                                  id: const Uuid().v4(),
                                  title: title.isEmpty
                                      ? (modeIndex == 1
                                          ? 'Gratitude Constellation'
                                          : (modeIndex == 2 ? 'Letter to Future Self' : 'Untitled Reflection'))
                                      : title,
                                  content: content,
                                  moodEmoji: selectedEmoji,
                                  isGratitude: modeIndex == 1,
                                  gratitudePoints: gPoints,
                                  isTimeLocked: modeIndex == 2,
                                  unlockDate: modeIndex == 2 ? selectedUnlockDate : null,
                                  timestamp: DateTime.now(),
                                );
                                await SanctuaryStorageService.saveJournalEntry(entry);
                                Navigator.pop(ctx);
                                _loadEntries();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38B6DB),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Save to Vault', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeChip(String label, int index, int current, ValueChanged<int> onSelect) {
    final isSelected = index == current;
    return GestureDetector(
      onTap: () => onSelect(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38B6DB).withValues(alpha: 0.2) : const Color(0xFF181D24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF38B6DB) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _exportArchive() async {
    try {
      final path = await SanctuaryStorageService.exportSanctuaryArchive();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archive exported to: $path'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export archive')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final accent = studioTheme.primaryAccent;

    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: const Color(0xFF07090C),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Icon(Icons.lock_rounded, color: accent, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                'BLACK BOX VAULT',
                style: EtoleTypography.labelCaps(color: Colors.white).copyWith(
                  fontSize: 14,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Biometrically encrypted private diary\n100% on-device, zero telemetry.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isAuthenticating ? null : _promptUnlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.fingerprint_rounded, color: Colors.black),
                label: const Text('Unlock with Biometrics', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: studioTheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'BLACK BOX JOURNAL',
          style: EtoleTypography.labelCaps(color: accent).copyWith(
            fontSize: 12,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _exportArchive,
            icon: const Icon(Icons.save_alt_rounded, color: Colors.white70),
            tooltip: 'Export Archive (Data Sovereignty)',
          ),
          IconButton(
            onPressed: _openNewEntryDialog,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            tooltip: 'Add Entry',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        const Text(
                          'Your vault is pristine.\nRecord your private reflections and ideas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _entries.length,
                    itemBuilder: (ctx, idx) {
                      final entry = _entries[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF11151B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(entry.moodEmoji, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(
                                      entry.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 18),
                                  onPressed: () async {
                                    await SanctuaryStorageService.deleteJournalEntry(entry.id);
                                    _loadEntries();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year} • ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            ),
                            if (entry.isLockedNow) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1528),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_clock_rounded, color: Color(0xFFA855F7), size: 24),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Letter to the Future\nUnlocks on ${entry.unlockDate!.day}/${entry.unlockDate!.month}/${entry.unlockDate!.year} (${entry.unlockDate!.difference(DateTime.now()).inDays + 1} days remaining)',
                                        style: const TextStyle(color: Color(0xFFD8B4FE), fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              if (entry.isGratitude && entry.gratitudePoints.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF231E12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.auto_awesome_rounded, color: Color(0xFFFDE047), size: 14),
                                          SizedBox(width: 6),
                                          Text(
                                            'Gratitude Constellation',
                                            style: TextStyle(
                                              color: Color(0xFFFDE047),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ...entry.gratitudePoints.map(
                                        (point) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('⭐ ', style: TextStyle(fontSize: 11)),
                                              Expanded(
                                                child: Text(
                                                  point,
                                                  style: const TextStyle(color: Color(0xFFFEF08A), fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (entry.content.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  entry.content,
                                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13.5, height: 1.45),
                                ),
                              ],
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
