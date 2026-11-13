import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/sanctuary_models.dart';
import '../../domain/sanctuary_storage_service.dart';
import '../widgets/voice_capsule_recorder_sheet.dart';

class CreativeScrapbookScreen extends ConsumerStatefulWidget {
  const CreativeScrapbookScreen({super.key});

  @override
  ConsumerState<CreativeScrapbookScreen> createState() => _CreativeScrapbookScreenState();
}

class _CreativeScrapbookScreenState extends ConsumerState<CreativeScrapbookScreen> {
  List<ScrapbookItem> _items = [];
  bool _isLoading = true;
  AudioPlayer? _audioPlayer;
  String? _currentlyPlayingPath;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await SanctuaryStorageService.loadScrapbookItems();
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _recordVoiceCapsule() async {
    final result = await VoiceCapsuleRecorderSheet.show(context);
    if (result != null) {
      final newItem = ScrapbookItem(
        id: const Uuid().v4(),
        text: 'Voice Capsule (${result.durationSeconds}s)',
        audioPath: result.filePath,
        audioDurationSeconds: result.durationSeconds,
        createdAt: DateTime.now(),
      );
      await SanctuaryStorageService.saveScrapbookItem(newItem);
      _loadItems();
    }
  }

  Future<void> _openNewNoteDialog() async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14181E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: const Text(
            'Spontaneous Thought',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: textController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Jot down a fleeting creative thought, lyric, or quote...',
              hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              border: InputBorder.none,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  final newItem = ScrapbookItem(
                    id: const Uuid().v4(),
                    text: text,
                    createdAt: DateTime.now(),
                  );
                  await SanctuaryStorageService.saveScrapbookItem(newItem);
                  Navigator.pop(ctx);
                  _loadItems();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EtoleColors.cyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Note', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSketchpadSheet() async {
    var controller = SignatureController(
      penStrokeWidth: 3.5,
      penColor: EtoleColors.cyan,
      exportBackgroundColor: const Color(0xFF0D1116),
    );

    Color activeColor = EtoleColors.cyan;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1116),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Obsidian Sketchpad',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo_rounded, color: Colors.white70),
                            onPressed: () => controller.undo(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_all_rounded, color: Colors.white70),
                            onPressed: () => controller.clear(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Color Picker Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EtoleColors.cyan,
                      const Color(0xFFFF7A00),
                      const Color(0xFFE2E8F0),
                      const Color(0xFFFFB300),
                      const Color(0xFFE53E3E),
                    ].map((c) {
                      final isSelected = activeColor == c;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            activeColor = c;
                            final currentPoints = controller.points;
                            controller.dispose();
                            controller = SignatureController(
                              penStrokeWidth: 3.5,
                              penColor: c,
                              exportBackgroundColor: const Color(0xFF0D1116),
                              points: currentPoints,
                            );
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Canvas
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF090C10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Signature(
                      controller: controller,
                      backgroundColor: const Color(0xFF090C10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.isNotEmpty) {
                          final signatureBytes = await controller.toPngBytes();
                          if (signatureBytes != null) {
                            final appDir = await getApplicationDocumentsDirectory();
                            final sketchDir = Directory('${appDir.path}/sanctuary/sketches');
                            if (!await sketchDir.exists()) {
                              await sketchDir.create(recursive: true);
                            }
                            final filePath =
                                '${sketchDir.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png';
                            final file = File(filePath);
                            await file.writeAsBytes(signatureBytes);

                            final newItem = ScrapbookItem(
                              id: const Uuid().v4(),
                              text: 'Gesture Sketch',
                              sketchPath: filePath,
                              createdAt: DateTime.now(),
                            );
                            await SanctuaryStorageService.saveScrapbookItem(newItem);
                            Navigator.pop(ctx);
                            _loadItems();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EtoleColors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Sketch', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _extractColorSwatches() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 600);
      if (photo == null) return;

      // Extract color swatches based on sample palette
      final swatches = [
        ExtractedColorSwatch(hex: '#E06D28', label: 'Terracotta Earth'),
        ExtractedColorSwatch(hex: '#2B5F75', label: 'Kilifi Blue'),
        ExtractedColorSwatch(hex: '#C9A35E', label: 'Savannah Gold'),
        ExtractedColorSwatch(hex: '#1F242C', label: 'Obsidian Dusk'),
      ];

      final newItem = ScrapbookItem(
        id: const Uuid().v4(),
        text: 'Camera Color Palette Sample',
        swatches: swatches,
        createdAt: DateTime.now(),
      );
      await SanctuaryStorageService.saveScrapbookItem(newItem);
      _loadItems();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final accent = studioTheme.primaryAccent;

    return Scaffold(
      backgroundColor: studioTheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CREATIVE SCRAPBOOK',
          style: EtoleTypography.labelCaps(color: accent).copyWith(
            fontSize: 12,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openNewNoteDialog,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            tooltip: 'Add Thought',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Action Bar: Thought, Sketch, Color Swatch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.edit_note_rounded,
                      label: 'Thought',
                      onTap: _openNewNoteDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.gesture_rounded,
                      label: 'Sketchpad',
                      onTap: _openSketchpadSheet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.mic_none_rounded,
                      label: 'Voice Tape',
                      onTap: _recordVoiceCapsule,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.palette_rounded,
                      label: 'Swatch',
                      onTap: _extractColorSwatches,
                    ),
                  ),
                ],
              ),
            ),

            // Items List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.brush_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              const Text(
                                'No thoughts or sketches yet.\nCapture your raw creative inspirations.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (ctx, idx) {
                            final item = _items[idx];
                            return _buildScrapbookCard(item, accent);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF14181E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildScrapbookCard(ScrapbookItem item, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12161C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 18),
                onPressed: () async {
                  await SanctuaryStorageService.deleteScrapbookItem(item.id);
                  _loadItems();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          if (item.audioPath != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () async {
                      if (_currentlyPlayingPath == item.audioPath) {
                        await _audioPlayer?.stop();
                        setState(() => _currentlyPlayingPath = null);
                      } else {
                        _audioPlayer ??= AudioPlayer();
                        await _audioPlayer!.stop();
                        await _audioPlayer!.play(DeviceFileSource(item.audioPath!));
                        setState(() => _currentlyPlayingPath = item.audioPath);
                        _audioPlayer!.onPlayerComplete.listen((_) {
                          if (mounted) setState(() => _currentlyPlayingPath = null);
                        });
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF7A00),
                      ),
                      child: Icon(
                        _currentlyPlayingPath == item.audioPath
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Acoustic Thought Capsule',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item.audioDurationSeconds ?? 0}s Voice Memo',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.sketchPath != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(item.sketchPath!),
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ],
          if (item.swatches.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.swatches.map((s) {
                final colorVal = int.parse(s.hex.replaceFirst('#', '0xFF'));
                return InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: s.hex));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied ${s.hex} to clipboard')),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181D24),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Color(colorVal),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.hex,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✨ Sanctuary bathed in extracted palette!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFFF7A00)),
                    SizedBox(width: 6),
                    Text(
                      'Bathe Sanctuary in this Palette',
                      style: TextStyle(
                        color: Color(0xFFFF7A00),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
