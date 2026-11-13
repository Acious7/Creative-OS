import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/ambient_soundscape_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/sanctuary_models.dart';
import '../../domain/sanctuary_storage_service.dart';
import 'black_box_journal_screen.dart';
import 'creative_scrapbook_screen.dart';
import 'inner_circle_screen.dart';
import 'monk_mode_screen.dart';
import 'personal_atlas_screen.dart';
import 'secret_spots_screen.dart';

class SanctuaryHubScreen extends ConsumerStatefulWidget {
  const SanctuaryHubScreen({super.key});

  @override
  ConsumerState<SanctuaryHubScreen> createState() => _SanctuaryHubScreenState();
}

class _SanctuaryHubScreenState extends ConsumerState<SanctuaryHubScreen> {
  String? _onThisDayMemory;

  @override
  void initState() {
    super.initState();
    _checkOnThisDay();
  }

  Future<void> _checkOnThisDay() async {
    final now = DateTime.now();
    final spots = await SanctuaryStorageService.loadSecretSpots();
    for (final s in spots) {
      if (s.createdAt.month == now.month && s.createdAt.day == now.day) {
        setState(() {
          _onThisDayMemory = 'Discovered "${s.name}" (${s.city}) on this day.';
        });
        return;
      }
    }

    final db = ref.read(databaseProvider);
    final events = await (db.select(db.networkingEvents)).get();
    for (final ev in events) {
      if (ev.startDate.month == now.month && ev.startDate.day == now.day) {
        setState(() {
          _onThisDayMemory = 'Met at "${ev.name}" in ${ev.location ?? "Nairobi"} on this day.';
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final soundState = ref.watch(ambientSoundscapeProvider);
    final accent = studioTheme.primaryAccent;

    return Scaffold(
      backgroundColor: studioTheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'THE SANCTUARY',
          style: EtoleTypography.labelCaps(color: accent).copyWith(
            fontSize: 13,
            letterSpacing: 2.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Ambient Soundscape Quick Toggle
          IconButton(
            icon: Icon(
              soundState.isPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: soundState.isPlaying ? accent : Colors.white54,
            ),
            tooltip: 'Ambient Soundscape',
            onPressed: () {
              ref.read(ambientSoundscapeProvider.notifier).togglePlayPause();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Subtitle
              Center(
                child: Text(
                  'LIFE • CREATIVITY • MEMORY • SANCTUARY',
                  style: TextStyle(
                    color: studioTheme.isDark ? const Color(0xFF94A3B8) : EtoleColors.lightTextMuted,
                    fontSize: 10,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // "On This Day" Serendipity Card
              if (_onThisDayMemory != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141922),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFB300), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ON THIS DAY',
                              style: EtoleTypography.labelCaps(color: const Color(0xFFFFB300))
                                  .copyWith(fontSize: 9.5, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _onThisDayMemory!,
                              style: const TextStyle(color: Colors.white, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Hero Monk Mode Card (Deep Work & Solitude)
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MonkModeScreen()));
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.22),
                        const Color(0xFF10141A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.2),
                          border: Border.all(color: accent, width: 1.2),
                        ),
                        child: Icon(Icons.self_improvement_rounded, color: accent, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OBSIDIAN FOCUS',
                              style: EtoleTypography.labelCaps(color: accent).copyWith(
                                fontSize: 10,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Monk Mode Sanctuary',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              soundState.isPlaying
                                  ? 'Active: ${soundState.activeType.title}'
                                  : 'Ember-particle breathing clock & ambient soundscape',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Grid of 4 Sanctuary Portals
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  // 1. Personal Atlas
                  _buildPortalCard(
                    title: 'Personal Atlas',
                    subtitle: 'Life cartography & travel map',
                    icon: Icons.map_rounded,
                    accentColor: EtoleColors.cyan,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PersonalAtlasScreen()),
                    ),
                  ),

                  // 2. Secret Spots
                  _buildPortalCard(
                    title: 'Secret Spots',
                    subtitle: 'Quiet cafes, viewpoints & hideouts',
                    icon: Icons.local_cafe_rounded,
                    accentColor: const Color(0xFFFF7A00),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SecretSpotsScreen()),
                    ),
                  ),

                  // 3. Creative Scrapbook
                  _buildPortalCard(
                    title: 'Scrapbook',
                    subtitle: 'Finger sketchpad & color swatches',
                    icon: Icons.brush_rounded,
                    accentColor: const Color(0xFFFFB300),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreativeScrapbookScreen()),
                    ),
                  ),

                  // 4. Inner Circle
                  _buildPortalCard(
                    title: 'Inner Circle',
                    subtitle: 'Friendship warmth & gift diary',
                    icon: Icons.favorite_rounded,
                    accentColor: const Color(0xFFEC4899),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InnerCircleScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Black Box Journal Vault Portal
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlackBoxJournalScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101318),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: Colors.white70, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Black Box Private Vault',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Biometrically locked encrypted diary • 100% on-device',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF11151B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
