import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import 'design_system_gallery_screen.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  int _tapCount = 0;

  void _onVersionTap() {
    _tapCount++;
    if (_tapCount == 5) {
      _tapCount = 0;
      EtoleHaptics.success();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const DesignSystemGalleryScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Design System Gallery Unlocked!'),
          backgroundColor: EtoleColors.cyan,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      EtoleHaptics.light();
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
                        '11 · ABOUT',
                        style: EtoleTypography.labelCaps(
                          color: EtoleColors.cyan,
                        ),
                      ),
                      Text(
                        'CREATIVE OS',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          color: cream,
                        ),
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
                  horizontal: 24,
                  vertical: 24,
                ),
                children: [
                  // Signature Quotation Visual Identity Card
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? EtoleColors.darkSurfaceElevated
                            : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                        border: Border.all(
                          color: isDark
                              ? EtoleColors.darkHairline
                              : EtoleColors.lightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.4 : 0.06,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EtoleBrandLogo(size: 32, showSubtitle: true),
                              SizedBox(width: 24),
                              EtoleBauhausCluster(size: 52),
                            ],
                          ),
                          SizedBox(height: 16),
                          EtoleMaasaiAccent(height: 28),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      'PERSONAL CREATIVE BUSINESS SUITE',
                      style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
                    ),
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _onVersionTap,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black12,
                          ),
                        ),
                        child: Text(
                          'VERSION 2.2.0',
                          style: EtoleTypography.labelCaps(color: muted),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const EtoleHairline(),
                  const SizedBox(height: 24),

                  Text(
                    'ARCHITECT & CREATOR',
                    style: EtoleTypography.labelCaps(color: muted),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Designed, engineered, and architected by Brian Etole — Director, Cinematographer & Creative Technologist based in Nairobi, Kenya. Creative OS is built as a sovereign, offline-first personal operating system to empower creative entrepreneurs, directors, and studios to manage commercial productions, high-ticket proposals, legal contracts, client relationships, and business intelligence without cloud subscriptions, vendor lock-in, or third-party tracking.',
                    style: EtoleTypography.bodySmall(color: cream)
                        .copyWith(height: 1.6),
                  ),

                  const SizedBox(height: 24),
                  const EtoleHairline(),
                  const SizedBox(height: 24),

                  Text(
                    'CONTACT & STUDIO CHANNELS',
                    style: EtoleTypography.labelCaps(color: muted),
                  ),
                  const SizedBox(height: 14),
                  _buildContactItem(
                    Icons.phone_rounded,
                    '+254 718 013 579',
                    cream,
                  ),
                  _buildContactItem(
                    Icons.mail_outline_rounded,
                    'hello@brianetole.com',
                    cream,
                  ),
                  _buildContactItem(
                    Icons.language_rounded,
                    'www.brianetole.com',
                    cream,
                  ),
                  _buildContactItem(
                    Icons.location_on_outlined,
                    'Nairobi, Kenya',
                    cream,
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, Color cream) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: EtoleColors.cyan, size: 18),
          const SizedBox(width: 14),
          Text(
            text,
            style: EtoleTypography.body(color: cream)
                .copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
