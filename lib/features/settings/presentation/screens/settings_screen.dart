import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../brands/presentation/screens/brand_editor_screen.dart';
import '../../../brands/presentation/screens/numbering_format_screen.dart';
import '../../../email/presentation/screens/google_email_settings_screen.dart';
import '../../../email/presentation/screens/smtp_email_settings_screen.dart';
import '../../../security/presentation/app_lock_setup_screen.dart';
import '../../../text_defaults/presentation/screens/text_defaults_screen.dart';
import '../../../trash/presentation/screens/trash_screen.dart';
import '../../../help/presentation/screens/studio_academy_screen.dart';
import '../../../help/presentation/widgets/interactive_walkthrough_sheet.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'automations_settings_screen.dart';
import 'custom_recipes_screen.dart';
import 'backup_screen.dart';
import 'payment_profiles_screen.dart';
import 'calendar_settings_screen.dart';
import 'reminders_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _navigate(BuildContext context, Widget screen) {
    EtoleHaptics.light();
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(activeBrandProvider);
    final studioTheme = ref.watch(currentStudioThemeProvider);

    return Scaffold(
      backgroundColor: studioTheme.backgroundBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar with 84px left spacer for floating < HUB pill clearance
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 82,
                  ), // Clearance for floating < HUB glass pill
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SETTINGS & VAULT',
                          style: EtoleTypography.h2.copyWith(
                            color: EtoleColors.cream,
                            letterSpacing: 2.2,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Offline Vault, Payment & Security',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 12,
                          color: Color(0xFF818CF8),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AES-256',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Settings List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  // Brian Etole Official Identity Card
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: studioTheme.surfaceCardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5)
                              .withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        EtoleBrandLogo(
                          fontSize: 22,
                          showSubtitle: true,
                          tColor: Colors.white,
                          subtitleColor: Color(0xFF94A3B8),
                        ),
                        EtoleBauhausCluster(size: 44),
                      ],
                    ),
                  ),

                  // Settings Group 1: Business Operations
                  _buildSectionHeader('BUSINESS OPERATIONS'),
                  _buildSettingTile(
                    icon: Icons.palette_outlined,
                    color: const Color(0xFFF59E0B),
                    title: 'Branding & Socials',
                    subtitle: 'Logo, socials, brand name, website & official signature',
                    onTap: () => _navigate(
                      context,
                      BrandEditorScreen(brand: activeBrand),
                    ),
                  ),
                  _buildSettingTile(
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF007A3D),
                    title: 'Payment & Bank Profiles',
                    subtitle:
                        'M-Pesa till/paybill, bank accounts & invoice footers',
                    onTap: () =>
                        _navigate(context, const PaymentProfilesScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.gavel_outlined,
                    color: const Color(0xFF38B6DB),
                    title: 'Clauses & Contract Terms',
                    subtitle:
                        'Production terms, IP deliverables & intro templates',
                    onTap: () => _navigate(context, const TextDefaultsScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.tag_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Numbering Sequences',
                    subtitle: 'COS prefixes (COS-QT, COS-INV, COS-CON, COS-REC) & counters',
                    onTap: () =>
                        _navigate(context, const NumberingFormatScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.mark_email_read_rounded,
                    color: const Color(0xFF00E5FF),
                    title: 'SMTP Mail Setup (Direct Dispatch)',
                    subtitle: 'Configure custom domain or Gmail App Password without OAuth',
                    onTap: () =>
                        _navigate(context, const SmtpEmailSettingsScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.mail_outline_rounded,
                    color: const Color(0xFFEA4335),
                    title: 'Google OAuth & Email Templates',
                    subtitle: 'Manage Gmail OAuth connection & official email templates',
                    onTap: () =>
                        _navigate(context, const GoogleEmailSettingsScreen()),
                  ),

                  const SizedBox(height: 12),

                  // Settings Group 2: System, Privacy & Vault
                  _buildSectionHeader('SECURITY, VAULT & BACKUP'),
                  _buildSettingTile(
                    icon: Icons.fingerprint_rounded,
                    color: const Color(0xFF4F46E5),
                    title: 'Biometric & App Lock',
                    subtitle: 'Fingerprint auth, device credentials & passcode',
                    onTap: () => _navigate(context, const AppLockSetupScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.cloud_download_outlined,
                    color: const Color(0xFF007A3D),
                    title: 'Offline Vault Backup & Restore',
                    subtitle: '100% offline encrypted backup (.etole archive export/import)',
                    onTap: () => _navigate(context, const BackupScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.notifications_active_outlined,
                    color: const Color(0xFFF59E0B),
                    title: 'Reminders & Notifications',
                    subtitle: 'Occasion alerts, 1-day before default & overdue doc notices',
                    onTap: () => _navigate(context, const RemindersScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFF38B6DB),
                    title: 'Calendar & Schedule Sync',
                    subtitle: 'Pick calendar destination, direct background event sync & 7-day strip',
                    onTap: () =>
                        _navigate(context, const CalendarSettingsScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF00E5FF),
                    title: 'Studio Automation Engine & Watchdogs',
                    subtitle: 'Overdue chaser, stale deals, VIP reconnect & auto-backup routines',
                    onTap: () =>
                        _navigate(context, const AutomationsSettingsScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.tune_rounded,
                    color: const Color(0xFF38B6DB),
                    title: 'Custom Automation Recipes (IFTTT)',
                    subtitle: 'Trigger ➔ Condition ➔ Action event-driven automation builder',
                    onTap: () =>
                        _navigate(context, const CustomRecipesScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.delete_sweep_outlined,
                    color: const Color(0xFFDC2626),
                    title: 'Trash & Recovery',
                    subtitle: 'Restore deleted documents, contacts or items',
                    onTap: () => _navigate(context, const TrashScreen()),
                  ),
                  const SizedBox(height: 12),

                  // Settings Group: Studio Academy, Walkthrough & Manual
                  _buildSectionHeader('STUDIO ACADEMY & FIELD MANUAL'),
                  _buildSettingTile(
                    icon: Icons.school_rounded,
                    color: const Color(0xFF00E5FF),
                    title: 'Studio Academy & Navigation Manual',
                    subtitle: '10-Chapter Walkthrough, Sitemap, Mogul Playbooks & FAQ',
                    onTap: () =>
                        _navigate(context, const StudioAcademyScreen()),
                  ),
                  _buildSettingTile(
                    icon: Icons.auto_awesome_motion_rounded,
                    color: const Color(0xFFFFB300),
                    title: 'Interactive Feature Walkthrough',
                    subtitle: 'Visual guided tour through every module, gesture & superpower',
                    onTap: () {
                      EtoleHaptics.selection();
                      InteractiveWalkthroughSheet.show(context);
                    },
                  ),

                  _buildSettingTile(
                    icon: Icons.info_outline_rounded,
                    color: const Color(0xFF64748B),
                    title: 'About Creative OS',
                    subtitle: 'Version 2.2.0 · Designed & Architected by Brian Etole',
                    onTap: () => _navigate(context, const AboutScreen()),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
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
