import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../digital_cards/presentation/screens/card_presentation_screen.dart';
import '../../../../core/assistant/executive_chief_of_staff_sheet.dart';
import '../../../../core/assistant/executive_morning_radar_sheet.dart';
import '../../../help/presentation/screens/studio_academy_screen.dart';
import '../../../sanctuary/presentation/screens/sanctuary_hub_screen.dart';
import '../../domain/hub_models.dart';
import '../widgets/living_background.dart';
import '../widgets/world_transition_overlay.dart';

class HubScreen extends ConsumerStatefulWidget {
  final Function(EtoleWorld world) onWorldSelected;

  const HubScreen({super.key, required this.onWorldSelected});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen>
    with SingleTickerProviderStateMixin {
  EtoleWorld? _transitioningWorld;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onWorldChosen(EtoleWorld world) {
    EtoleHaptics.selection();
    widget.onWorldSelected(world);
  }

  void _onBrianLongPressed() {
    EtoleHaptics.selection();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CardPresentationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(reduceMotionProvider);
    final upcomingProductionAsync = ref.watch(upcomingProductionProvider);
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final isDark = studioTheme.isDark;

    return Scaffold(
      backgroundColor: studioTheme.backgroundBase,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Living Ambient Parallax Background with organic warm embers
          LivingBackground(
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 2. Executive Studio Header with Official Logo & Live Slate
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Studio Status Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Blinking REC Indicator
                              Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.redAccent,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.redAccent
                                                  .withValues(
                                                    alpha:
                                                        _pulseAnimation.value,
                                                  ),
                                              blurRadius:
                                                  7 * _pulseAnimation.value,
                                              spreadRadius:
                                                  1.5 * _pulseAnimation.value,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'STUDIO ACTIVE • REC',
                                    style:
                                        EtoleTypography.labelCaps(
                                          color: isDark
                                              ? EtoleColors.creamSecondary
                                              : EtoleColors.lightTextMuted,
                                        ).copyWith(
                                          fontSize: 9.5,
                                          letterSpacing: 1.8,
                                        ),
                                  ),
                                ],
                              ),

                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // The Sanctuary Portal (Life, Focus, Memory, Vault)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEC4899)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFEC4899)
                                            .withValues(alpha: 0.45),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          EtoleHaptics.selection();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SanctuaryHubScreen(),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.spa_rounded,
                                                size: 12,
                                                color: Color(0xFFEC4899),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'SANCTUARY',
                                                style:
                                                    EtoleTypography.labelCaps(
                                                      color: const Color(
                                                        0xFFEC4899,
                                                      ),
                                                    ).copyWith(fontSize: 8.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Studio Academy / Help Manual Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB300)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFFB300)
                                            .withValues(alpha: 0.45),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          EtoleHaptics.selection();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const StudioAcademyScreen(),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.school_rounded,
                                                size: 12,
                                                color: Color(0xFFFFB300),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'ACADEMY',
                                                style:
                                                    EtoleTypography.labelCaps(
                                                      color: const Color(
                                                        0xFFFFB300,
                                                      ),
                                                    ).copyWith(fontSize: 8.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Quick Identity presentation button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: EtoleColors.cyan.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: EtoleColors.cyan.withValues(
                                          alpha: 0.35,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: _onBrianLongPressed,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.nfc_rounded,
                                                size: 12,
                                                color: EtoleColors.cyan,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'PRESENT CARD',
                                                style:
                                                    EtoleTypography.labelCaps(
                                                      color: EtoleColors.cyan,
                                                    ).copyWith(fontSize: 8.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Official Creative OS Logo & Bauhaus Cluster Emblem
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22.0),
                                topRight: Radius.circular(14.0),
                                bottomLeft: Radius.circular(14.0),
                                bottomRight: Radius.circular(14.0),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  studioTheme.surfaceElevatedColor,
                                  studioTheme.surfaceCardColor,
                                ],
                              ),
                              border: Border.all(
                                color: studioTheme.primaryAccent.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: studioTheme.primaryAccent.withValues(
                                    alpha: studioTheme.isDark ? 0.12 : 0.08,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    EtoleBrandLogo(
                                      fontSize: 26,
                                      showSubtitle: true,
                                      tColor: Colors.white,
                                      subtitleColor: const Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'VISUAL STORYTELLER',
                                          style:
                                              EtoleTypography.labelCaps(
                                                color: EtoleColors.cyan,
                                              ).copyWith(
                                                fontSize: 9.5,
                                                letterSpacing: 1.8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'NAIROBI, KENYA',
                                          style: TextStyle(
                                            fontFamily:
                                                EtoleTypography.bodyFontFamily,
                                            fontSize: 9.5,
                                            color: isDark
                                                ? EtoleColors.muted
                                                : EtoleColors.lightTextMuted,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    const EtoleBauhausCluster(size: 38),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 2.5. Pocket Chief of Staff & Executive Morning Radar Capsule
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          // AI Voice Chief of Staff
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                EtoleHaptics.selection();
                                ExecutiveChiefOfStaffSheet.show(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14181D),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF38B6DB)
                                        .withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38B6DB)
                                          .withValues(alpha: 0.08),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF38B6DB)
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.mic_rounded,
                                        color: Color(0xFF38B6DB),
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'CHIEF OF STAFF',
                                            style:
                                                EtoleTypography.labelCaps(
                                                  color: const Color(
                                                    0xFF38B6DB,
                                                  ),
                                                ).copyWith(
                                                  fontSize: 9,
                                                  letterSpacing: 1.2,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const Text(
                                            'Dictate Note',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // CEO Morning Radar & Cashflow
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                EtoleHaptics.selection();
                                ExecutiveMorningRadarSheet.show(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14181D),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.08),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.wb_sunny_rounded,
                                        color: Color(0xFFF59E0B),
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'MORNING RADAR',
                                            style:
                                                EtoleTypography.labelCaps(
                                                  color: const Color(
                                                    0xFFF59E0B,
                                                  ),
                                                ).copyWith(
                                                  fontSize: 9,
                                                  letterSpacing: 1.2,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const Text(
                                            'Cashflow & Tax',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 3. Current Live Production Status Slate (Dynamic Hero Banner)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: upcomingProductionAsync.when(
                        data: (project) {
                          if (project == null) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1A222B),
                                    Color(0xFF10151D),
                                  ],
                                ),
                                border: Border.all(
                                  color: EtoleColors.cyan.withValues(
                                    alpha: 0.40,
                                  ),
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: EtoleColors.cyan.withValues(
                                      alpha: 0.10,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () =>
                                      _onWorldChosen(EtoleWorld.production),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: EtoleColors.cyan.withValues(
                                              alpha: isDark ? 0.25 : 0.18,
                                            ),
                                            border: Border.all(
                                              color: EtoleColors.cyan
                                                  .withValues(alpha: 0.35),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add_rounded,
                                            color: EtoleColors.cyan,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'PRODUCTION SLATE READY',
                                                style:
                                                    EtoleTypography.labelCaps(
                                                      color: EtoleColors.cyan,
                                                    ).copyWith(
                                                      fontSize: 9.5,
                                                      letterSpacing: 1.6,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'No active shoot in progress · Tap to set up a new project or call sheet',
                                                style: TextStyle(
                                                  fontFamily: EtoleTypography
                                                      .bodyFontFamily,
                                                  fontSize: 10.5,
                                                  color: isDark
                                                      ? EtoleColors.muted
                                                      : const Color(0xFF4A5568),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: EtoleColors.cyan,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  EtoleColors.cyan.withValues(alpha: 0.16),
                                  const Color(0xFF141719)
                                      .withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: EtoleColors.cyan.withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: EtoleColors.cyan.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () =>
                                    _onWorldChosen(EtoleWorld.production),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.movie_creation_outlined,
                                                color: EtoleColors.cyan,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'CURRENT PRODUCTION SLATE',
                                                style:
                                                    EtoleTypography.labelCaps(
                                                      color: EtoleColors.cyan,
                                                    ).copyWith(
                                                      fontSize: 10,
                                                      letterSpacing: 1.6,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: EtoleColors.gold
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              project.stage
                                                  .toUpperCase()
                                                  .replaceAll('_', ' '),
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: EtoleColors.gold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        project.title.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily:
                                              EtoleTypography.displayFontFamily,
                                          fontSize: 20,
                                          color: isDark
                                              ? EtoleColors.cream
                                              : EtoleColors.lightTextPrimary,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${project.clientName} • ${project.notes ?? 'Scene breakdown & deliverables in progress'}',
                                        style: TextStyle(
                                          fontFamily:
                                              EtoleTypography.bodyFontFamily,
                                          fontSize: 12,
                                          color: isDark
                                              ? EtoleColors.muted
                                              : EtoleColors.lightTextMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'OPEN PRODUCTION SET',
                                            style: TextStyle(
                                              fontFamily: EtoleTypography
                                                  .bodyFontFamily,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: EtoleColors.cyan,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 14,
                                            color: EtoleColors.cyan,
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
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  // 4. Executive Studio Modules (2x3 Artistic Cockpit - 6 Doorways)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                      children: [
                        // Doorway 1: PRODUCTION SET & TOOLKIT (BOLD OCEANIC TEAL / CYAN)
                        _buildStudioModuleCard(
                          title: 'SET & TOOLKIT',
                          subtitle: 'Call Sheets, Gear & Milestones',
                          tag: 'PRODUCTION',
                          highlight: 'Call Sheets & Gear',
                          icon: Icons.movie_filter_outlined,
                          watermarkIcon: Icons.videocam_outlined,
                          gradientStart: const Color(0xFF00838F),
                          gradientEnd: const Color(0xFF004D40),
                          accentHighlight: const Color(0xFF80DEEA),
                          onTap: () => _onWorldChosen(EtoleWorld.production),
                        ),

                        // Doorway 2: NETWORK & CLIENT CRM (BOLD GOLDEN AMBER)
                        _buildStudioModuleCard(
                          title: 'NETWORK & CRM',
                          subtitle: 'Occasions, Leads & 1-Tap Pitch',
                          tag: 'RELATIONS',
                          highlight: 'VIP Rolodex & CRM',
                          icon: Icons.hub_outlined,
                          watermarkIcon: Icons.share_rounded,
                          gradientStart: const Color(0xFFF59E0B),
                          gradientEnd: const Color(0xFFB45309),
                          accentHighlight: const Color(0xFFFDE68A),
                          onTap: () => _onWorldChosen(EtoleWorld.network),
                        ),

                        // Doorway 3: DOCUMENTS & COMMERCIAL FINANCE (BOLD FOREST GREEN)
                        _buildStudioModuleCard(
                          title: 'DOCS & FINANCE',
                          subtitle: 'Quotes, Invoices & Contracts',
                          tag: 'BILLING',
                          highlight: 'Quotes & Invoices (KES)',
                          icon: Icons.receipt_long_outlined,
                          watermarkIcon: Icons.account_balance_wallet_outlined,
                          gradientStart: const Color(0xFF007A3D),
                          gradientEnd: const Color(0xFF024C26),
                          accentHighlight: const Color(0xFFA7F3D0),
                          onTap: () => _onWorldChosen(EtoleWorld.docs),
                        ),

                        // Doorway 4: MEETINGS & MEMORY (BOLD ROYAL SAPPHIRE BLUE)
                        _buildStudioModuleCard(
                          title: 'MEETINGS',
                          subtitle: 'Agendas, Audio & Action Items',
                          tag: 'MEMORY',
                          highlight: 'Briefs & Audio Notes',
                          icon: Icons.forum_outlined,
                          watermarkIcon: Icons.graphic_eq_rounded,
                          gradientStart: const Color(0xFF2563EB),
                          gradientEnd: const Color(0xFF1E3A8A),
                          accentHighlight: const Color(0xFFBFDBFE),
                          onTap: () => _onWorldChosen(EtoleWorld.meetings),
                        ),

                        // Doorway 5: DIGITAL STAGE & IDENTITY (BOLD CRIMSON RED)
                        _buildStudioModuleCard(
                          title: 'STAGE & CARD',
                          subtitle: 'NFC, QR & Showreel Showcase',
                          tag: 'IDENTITY',
                          highlight: 'NFC Tap & Showreel',
                          icon: Icons.badge_outlined,
                          watermarkIcon: Icons.contactless_rounded,
                          gradientStart: const Color(0xFFDC2626),
                          gradientEnd: const Color(0xFF7F1D1D),
                          accentHighlight: const Color(0xFFFECACA),
                          onTap: () => _onWorldChosen(EtoleWorld.brian),
                        ),

                        // Doorway 6: SETTINGS & VAULT (BOLD ELECTRIC INDIGO / PURPLE)
                        _buildStudioModuleCard(
                          title: 'SETTINGS',
                          subtitle: 'Offline Vault & Preferences',
                          tag: 'SYSTEM',
                          highlight: 'AES-256 Vault Secured',
                          icon: Icons.tune_rounded,
                          watermarkIcon: Icons.shield_outlined,
                          gradientStart: const Color(0xFF4F46E5),
                          gradientEnd: const Color(0xFF312E81),
                          accentHighlight: const Color(0xFFDDD6FE),
                          onTap: () => _onWorldChosen(EtoleWorld.settings),
                        ),
                      ],
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
          ),

          // 6. Interactive World Transition Overlay
          if (_transitioningWorld != null)
            WorldTransitionOverlay(
              world: _transitioningWorld!,
              reduceMotion: reduceMotion,
              onCompleted: () {
                final target = _transitioningWorld!;
                setState(() => _transitioningWorld = null);
                widget.onWorldSelected(target);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStudioModuleCard({
    required String title,
    required String subtitle,
    required String tag,
    required String highlight,
    required IconData icon,
    required IconData watermarkIcon,
    required Color gradientStart,
    required Color gradientEnd,
    required Color accentHighlight,
    required VoidCallback onTap,
  }) {
    const cardRadius = BorderRadius.only(
      topLeft: Radius.circular(22),
      topRight: Radius.circular(14),
      bottomLeft: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: Stack(
          children: [
            // Watermark graphic in bottom-right corner for visual richness
            Positioned(
              right: -10,
              bottom: -4,
              child: IgnorePointer(
                child: Icon(
                  watermarkIcon,
                  size: 82,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),

            // Top-edge accent illumination glow bar
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: Container(
                  height: 2.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.65),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main Card Interactive Surface
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: cardRadius,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Icon container + Tag badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(icon, color: Colors.white, size: 19),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.40),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontFamily: EtoleTypography.bodyFontFamily,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Middle: Live Studio Highlight Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentHighlight,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                highlight,
                                style: const TextStyle(
                                  fontFamily: EtoleTypography.bodyFontFamily,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom: Title, Subtitle & Interactive Arrow Cue
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: EtoleTypography.displayFontFamily,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontFamily: EtoleTypography.bodyFontFamily,
                                    fontSize: 10.0,
                                    color: Colors.white.withValues(alpha: 0.88),
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.25),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    width: 0.7,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 11,
                                  color: Colors.white,
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
          ],
        ),
      ),
    );
  }
}
