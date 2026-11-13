import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../digital_cards/presentation/widgets/osm_map_view.dart';
import '../../domain/sanctuary_models.dart';
import '../../domain/sanctuary_storage_service.dart';

class AtlasPinItem {
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String tag;
  final bool isSecretSpot;
  final String? audioMemoPath;
  final DateTime createdAt;

  AtlasPinItem({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.tag,
    this.isSecretSpot = false,
    this.audioMemoPath,
    required this.createdAt,
  });
}

class PersonalAtlasScreen extends ConsumerStatefulWidget {
  const PersonalAtlasScreen({super.key});

  @override
  ConsumerState<PersonalAtlasScreen> createState() => _PersonalAtlasScreenState();
}

class _PersonalAtlasScreenState extends ConsumerState<PersonalAtlasScreen> {
  List<AtlasPinItem> _pins = [];
  bool _isLoading = true;
  double _centerLat = -1.286389; // Default Nairobi center
  double _centerLon = 36.817223;
  AtlasPinItem? _selectedPin;
  bool _showJourneyThread = false;
  AudioPlayer? _atlasAudioPlayer;
  String? _playingAudioPath;

  @override
  void initState() {
    super.initState();
    _loadAtlasData();
  }

  @override
  void dispose() {
    _atlasAudioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String path) async {
    _atlasAudioPlayer ??= AudioPlayer();
    if (_playingAudioPath == path) {
      await _atlasAudioPlayer!.stop();
      if (mounted) setState(() => _playingAudioPath = null);
    } else {
      await _atlasAudioPlayer!.stop();
      _atlasAudioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingAudioPath = null);
      });
      await _atlasAudioPlayer!.play(DeviceFileSource(path));
      if (mounted) setState(() => _playingAudioPath = path);
    }
  }

  Future<void> _loadAtlasData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final events = await (db.select(db.networkingEvents)).get();
    final spots = await SanctuaryStorageService.loadSecretSpots();

    final List<AtlasPinItem> items = [];

    // Add Events with coordinates
    for (final ev in events) {
      if (ev.latitude != null && ev.longitude != null) {
        items.add(
          AtlasPinItem(
            title: ev.name,
            subtitle: ev.location ?? 'Event Location',
            latitude: ev.latitude!,
            longitude: ev.longitude!,
            tag: 'Event / Meetup',
            isSecretSpot: false,
            createdAt: ev.startDate,
          ),
        );
      }
    }

    // Add Secret Spots with coordinates
    for (final s in spots) {
      if (s.latitude != null && s.longitude != null) {
        items.add(
          AtlasPinItem(
            title: s.name,
            subtitle: '${s.vibe.emoji} ${s.city} • ${s.address}',
            latitude: s.latitude!,
            longitude: s.longitude!,
            tag: s.vibe.label,
            isSecretSpot: true,
            audioMemoPath: s.audioMemoPath,
            createdAt: s.createdAt,
          ),
        );
      }
    }

    if (items.isNotEmpty) {
      _centerLat = items.first.latitude;
      _centerLon = items.first.longitude;
      _selectedPin = items.first;
    }

    setState(() {
      _pins = items;
      _isLoading = false;
    });
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
          'PERSONAL ATLAS',
          style: EtoleTypography.labelCaps(color: accent).copyWith(
            fontSize: 12,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.route_rounded,
              color: _showJourneyThread ? accent : Colors.white54,
              size: 22,
            ),
            tooltip: _showJourneyThread ? 'Show Normal View' : 'Thread of My Journey',
            onPressed: () {
              setState(() {
                _showJourneyThread = !_showJourneyThread;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Stat Ribbon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        _buildStatCard('Total Pins', '${_pins.length}', accent),
                        const SizedBox(width: 8),
                        _buildStatCard('Secret Spots', '${_pins.where((p) => p.isSecretSpot).length}', EtoleColors.cyan),
                        const SizedBox(width: 8),
                        _buildStatCard('Meetups', '${_pins.where((p) => !p.isSecretSpot).length}', const Color(0xFFFF7A00)),
                      ],
                    ),
                  ),

                  // OpenStreetMap Visualizer
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: OsmMapView(
                        key: ValueKey('$_centerLat-$_centerLon'),
                        initialLatitude: _centerLat,
                        initialLongitude: _centerLon,
                        initialZoom: 13,
                        height: double.infinity,
                        isInteractive: true,
                      ),
                    ),
                  ),

                  // Selected Pin Dossier Card
                  if (_selectedPin != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13171E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_selectedPin!.isSecretSpot ? EtoleColors.cyan : accent)
                                  .withValues(alpha: 0.16),
                            ),
                            child: Icon(
                              _selectedPin!.isSecretSpot ? Icons.star_rounded : Icons.place_rounded,
                              color: _selectedPin!.isSecretSpot ? EtoleColors.cyan : accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPin!.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedPin!.subtitle,
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedPin!.audioMemoPath != null) ...[
                            IconButton(
                              icon: Icon(
                                _playingAudioPath == _selectedPin!.audioMemoPath
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: const Color(0xFF67E8F9),
                                size: 28,
                              ),
                              tooltip: 'Listen to ambient spot sound',
                              onPressed: () => _toggleAudio(_selectedPin!.audioMemoPath!),
                            ),
                          ],
                        ],
                      ),
                    ),

                  if (_showJourneyThread)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timeline_rounded, color: accent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Thread of My Journey • Chronological Timeline',
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Pin Quick Selection Chips
                  Builder(
                    builder: (context) {
                      final displayPins = _showJourneyThread
                          ? ([..._pins]..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
                          : _pins;
                      return Expanded(
                        flex: 3,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          physics: const BouncingScrollPhysics(),
                          itemCount: displayPins.length,
                          itemBuilder: (ctx, idx) {
                            final pin = displayPins[idx];
                            final isSelected = _selectedPin == pin;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPin = pin;
                                  _centerLat = pin.latitude;
                                  _centerLon = pin.longitude;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accent.withValues(alpha: 0.12)
                                      : const Color(0xFF10141A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? accent : Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (_showJourneyThread) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '#${idx + 1}',
                                          style: TextStyle(
                                            color: accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Icon(
                                      pin.isSecretSpot ? Icons.star_border_rounded : Icons.location_on_outlined,
                                      size: 16,
                                      color: pin.isSecretSpot ? EtoleColors.cyan : accent,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        pin.title,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                          fontSize: 12.5,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      pin.tag,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF12161D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}
