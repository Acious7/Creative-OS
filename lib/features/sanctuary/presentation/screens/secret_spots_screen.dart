import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/sanctuary_models.dart';
import '../../domain/sanctuary_storage_service.dart';
import '../widgets/voice_capsule_recorder_sheet.dart';

class SecretSpotsScreen extends ConsumerStatefulWidget {
  const SecretSpotsScreen({super.key});

  @override
  ConsumerState<SecretSpotsScreen> createState() => _SecretSpotsScreenState();
}

class _SecretSpotsScreenState extends ConsumerState<SecretSpotsScreen> {
  List<SecretSpot> _spots = [];
  SpotVibe? _selectedFilter;
  bool _isLoading = true;
  AudioPlayer? _spotAudioPlayer;
  String? _playingAudioPath;

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  @override
  void dispose() {
    _spotAudioPlayer?.dispose();
    super.dispose();
  }

  void _shareSpot(SecretSpot spot) {
    final text = '✨ Secret Spot Field Guide: ${spot.name} (${spot.city})\n'
        'Atmosphere: ${spot.vibe.emoji} ${spot.vibe.label}\n'
        'Address: ${spot.address}\n'
        'Personal Notes: "${spot.personalNotes}"\n\n'
        'Curated via Etole Studio Sanctuary';
    Share.share(text, subject: 'Secret Spot: ${spot.name}');
  }

  Future<void> _togglePlayAudio(String path) async {
    _spotAudioPlayer ??= AudioPlayer();
    if (_playingAudioPath == path) {
      await _spotAudioPlayer!.stop();
      if (mounted) setState(() => _playingAudioPath = null);
    } else {
      await _spotAudioPlayer!.stop();
      _spotAudioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingAudioPath = null);
      });
      await _spotAudioPlayer!.play(DeviceFileSource(path));
      if (mounted) setState(() => _playingAudioPath = path);
    }
  }

  Future<void> _loadSpots() async {
    setState(() => _isLoading = true);
    final spots = await SanctuaryStorageService.loadSecretSpots();
    setState(() {
      _spots = spots;
      _isLoading = false;
    });
  }

  Future<void> _openAddSpotSheet() async {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Nairobi');
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    SpotVibe chosenVibe = SpotVibe.quietCafe;
    int rating = 5;
    double? lat;
    double? lon;

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
                          'Add Secret Spot',
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
                    const SizedBox(height: 12),

                    // Name
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Spot Name',
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

                    // City & Address
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: cityCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'City / Region',
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFF181D24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: addressCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Neighborhood / Address',
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFF181D24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Vibe Selector
                    const Text('Vibe & Atmosphere', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SpotVibe.values.map((vibe) {
                        final isSelected = chosenVibe == vibe;
                        return ChoiceChip(
                          label: Text('${vibe.emoji} ${vibe.label}'),
                          selected: isSelected,
                          onSelected: (_) => setSheetState(() => chosenVibe = vibe),
                          selectedColor: const Color(0xFF38B6DB).withValues(alpha: 0.25),
                          backgroundColor: const Color(0xFF181D24),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF38B6DB) : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Personal Reflections / Why you love it',
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

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isNotEmpty) {
                            final spot = SecretSpot(
                              id: const Uuid().v4(),
                              name: name,
                              city: cityCtrl.text.trim(),
                              address: addressCtrl.text.trim(),
                              vibe: chosenVibe,
                              rating: rating,
                              personalNotes: notesCtrl.text.trim(),
                              latitude: lat ?? -1.286389,
                              longitude: lon ?? 36.817223,
                              createdAt: DateTime.now(),
                            );
                            await SanctuaryStorageService.saveSecretSpot(spot);
                            Navigator.pop(ctx);
                            _loadSpots();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38B6DB),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Secret Spot', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final accent = studioTheme.primaryAccent;

    final filteredSpots = _selectedFilter == null
        ? _spots
        : _spots.where((s) => s.vibe == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: studioTheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SECRET SPOTS',
          style: EtoleTypography.labelCaps(color: accent).copyWith(
            fontSize: 12,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openAddSpotSheet,
            icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
            tooltip: 'Add Spot',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Vibe Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Vibe Spots'),
                    selected: _selectedFilter == null,
                    onSelected: (_) => setState(() => _selectedFilter = null),
                    selectedColor: accent.withValues(alpha: 0.25),
                    backgroundColor: const Color(0xFF14181E),
                    labelStyle: TextStyle(
                      color: _selectedFilter == null ? accent : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: _selectedFilter == null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...SpotVibe.values.map((vibe) {
                    final isSelected = _selectedFilter == vibe;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('${vibe.emoji} ${vibe.label}'),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedFilter = vibe),
                        selectedColor: accent.withValues(alpha: 0.25),
                        backgroundColor: const Color(0xFF14181E),
                        labelStyle: TextStyle(
                          color: isSelected ? accent : const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Spot Cards
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSpots.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.place_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              const Text(
                                'No secret spots saved yet.\nBookmark your favorite cafes, hideouts & view spots.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredSpots.length,
                          itemBuilder: (ctx, idx) {
                            final spot = filteredSpots[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF13171D),
                                borderRadius: BorderRadius.circular(18),
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
                                          Text(spot.vibe.emoji, style: const TextStyle(fontSize: 20)),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                spot.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${spot.city} • ${spot.address}',
                                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (spot.audioMemoPath != null) ...[
                                            IconButton(
                                              icon: Icon(
                                                _playingAudioPath == spot.audioMemoPath
                                                    ? Icons.pause_circle_filled_rounded
                                                    : Icons.play_circle_fill_rounded,
                                                color: const Color(0xFF67E8F9),
                                                size: 22,
                                              ),
                                              tooltip: 'Play Ambient Sound',
                                              onPressed: () => _togglePlayAudio(spot.audioMemoPath!),
                                            ),
                                          ] else ...[
                                            IconButton(
                                              icon: const Icon(Icons.mic_none_rounded, color: Colors.white38, size: 20),
                                              tooltip: 'Record Ambient Sound',
                                              onPressed: () async {
                                                final recordedResult = await showModalBottomSheet<VoiceCapsuleResult>(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor: Colors.transparent,
                                                  builder: (_) => VoiceCapsuleRecorderSheet(
                                                    recordingPrefix: 'spot_${spot.id.substring(0, spot.id.length > 8 ? 8 : spot.id.length)}',
                                                  ),
                                                );
                                                if (recordedResult != null) {
                                                  final updated = spot.copyWith(audioMemoPath: recordedResult.filePath);
                                                  await SanctuaryStorageService.saveSecretSpot(updated);
                                                  _loadSpots();
                                                }
                                              },
                                            ),
                                          ],
                                          IconButton(
                                            icon: const Icon(Icons.share_outlined, color: Colors.white60, size: 20),
                                            tooltip: 'Share Field Guide',
                                            onPressed: () => _shareSpot(spot),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 20),
                                            tooltip: 'Remove Spot',
                                            onPressed: () async {
                                              await SanctuaryStorageService.deleteSecretSpot(spot.id);
                                              _loadSpots();
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (spot.personalNotes.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      '"${spot.personalNotes}"',
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 12.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
