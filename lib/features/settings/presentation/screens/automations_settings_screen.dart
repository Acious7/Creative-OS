import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/automation/studio_automation_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import 'custom_recipes_screen.dart';

class AutomationsSettingsScreen extends ConsumerStatefulWidget {
  const AutomationsSettingsScreen({super.key});

  @override
  ConsumerState<AutomationsSettingsScreen> createState() =>
      _AutomationsSettingsScreenState();
}

class _AutomationsSettingsScreenState
    extends ConsumerState<AutomationsSettingsScreen> {
  StudioAutomationConfig _config = const StudioAutomationConfig();
  bool _isLoading = true;
  bool _isRunningNow = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await StudioAutomationService.loadConfig();
    if (mounted) {
      setState(() {
        _config = cfg;
        _isLoading = false;
      });
    }
  }

  Future<void> _save(StudioAutomationConfig updated) async {
    setState(() => _config = updated);
    await StudioAutomationService.saveConfig(updated);
    EtoleHaptics.selection();
  }

  Future<void> _runNow() async {
    setState(() => _isRunningNow = true);
    EtoleHaptics.medium();

    final db = ref.read(databaseProvider);
    final results = await StudioAutomationService.runAllAutomations(db);
    final updated = await StudioAutomationService.loadConfig();

    if (mounted) {
      setState(() {
        _config = updated;
        _isRunningNow = false;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF14171B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: EtoleColors.cyan.withValues(alpha: 0.35)),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00E5FF),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Automation Dispatch Complete',
                style: EtoleTypography.h3.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The Studio Watchdog scanned all active records:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildResultRow(
                'Overdue Invoices Analyzed',
                '${results['overdueInvoices'] ?? 0}',
              ),
              _buildResultRow(
                'Milestones Due Tomorrow',
                '${results['milestonesDue'] ?? 0}',
              ),
              _buildResultRow(
                'Stale Deals Flagged',
                '${results['staleDeals'] ?? 0}',
              ),
              _buildResultRow(
                'VIP Inactivity Checks',
                '${results['vipTouchpoints'] ?? 0}',
              ),
              _buildResultRow(
                'Upcoming Shoots Monitored',
                '${results['shootsUpcoming'] ?? 0}',
              ),
              _buildResultRow(
                'Items Cleaned From Trash',
                '${results['trashPurged'] ?? 0}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'DONE',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFF080B0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AUTOMATION ENGINE',
                          style: EtoleTypography.h2.copyWith(
                            color: EtoleColors.cream,
                            letterSpacing: 2.0,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Background Watchdogs, Triggers & Vault Routines',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: Color(0xFF00E5FF),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Status Telemetry Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14171B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF)
                                .withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.radar_rounded,
                                    color: Color(0xFF00E5FF),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'WATCHDOG STATUS',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _config.lastRunTime != null
                                    ? 'Last: ${dateFormat.format(_config.lastRunTime!)}'
                                    : 'Awaiting First Run',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Native Android WorkManager executes periodic background scans every 6 hours under partial wakelock without draining battery.',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Custom Recipe Builder Entry Banner
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E5FF).withValues(alpha: 0.12),
                            const Color(0xFF14171B),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00E5FF)
                              .withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Color(0xFF00E5FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CUSTOM RECIPES (IF-THIS-THEN-THAT)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'Event-driven triggers, deposit automations & stage jumps',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.65,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                EtoleHaptics.selection();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CustomRecipesScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.tune_rounded, size: 16),
                              label: const Text(
                                'MANAGE & CREATE RECIPES',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E5FF),
                                foregroundColor: const Color(0xFF080B0F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    _buildSectionHeader('FINANCIAL & CASHFLOW WATCHDOGS'),

                    _buildToggleTile(
                      icon: Icons.notification_important_rounded,
                      color: const Color(0xFFEF4444),
                      title: 'Overdue Invoice Watchdog',
                      subtitle: 'Monitors sent invoices past their due date and triggers high-priority WhatsApp chaser notifications',
                      value: _config.enableOverdueWatchdog,
                      onChanged: (v) =>
                          _save(_config.copyWith(enableOverdueWatchdog: v)),
                    ),

                    _buildToggleTile(
                      icon: Icons.event_available_rounded,
                      color: const Color(0xFFF59E0B),
                      title: '24h Milestone & Deposit Due Alerts',
                      subtitle: 'Warns 24 hours before contract delivery deadlines or invoice milestone due dates',
                      value: _config.enableMilestoneAlerts,
                      onChanged: (v) =>
                          _save(_config.copyWith(enableMilestoneAlerts: v)),
                    ),

                    _buildToggleTile(
                      icon: Icons.pie_chart_rounded,
                      color: const Color(0xFF10B981),
                      title: 'Monthly Tax & Profit Rollup',
                      subtitle: 'On the 1st of each month, calculates gross revenue, 5% WHT reserve, and 16% VAT portion',
                      value: _config.enableMonthlyTaxRollup,
                      onChanged: (v) =>
                          _save(_config.copyWith(enableMonthlyTaxRollup: v)),
                    ),

                    const SizedBox(height: 18),
                    _buildSectionHeader('CRM & RELATIONSHIP RADAR'),

                    _buildToggleTile(
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF38B6DB),
                      title: 'Stale Deal Follow-Up Radar',
                      subtitle:
                          'Alerts when a pitched deal has had no response or update for more than ${_config.staleDealDays} days',
                      value: _config.enableStaleDealAlerts,
                      onChanged: (v) =>
                          _save(_config.copyWith(enableStaleDealAlerts: v)),
                    ),

                    _buildToggleTile(
                      icon: Icons.handshake_rounded,
                      color: const Color(0xFF818CF8),
                      title: 'VIP Touchpoint Reconnect Timer',
                      subtitle:
                          'Prompts a friendly check-in when key VIP contacts haven’t had a recorded touchpoint in ${_config.vipInactiveDays} days',
                      value: _config.enableVipReconnect,
                      onChanged: (v) =>
                          _save(_config.copyWith(enableVipReconnect: v)),
                    ),

                    const SizedBox(height: 18),
                    _buildSectionHeader('PRODUCTION SLATE & GEAR ROUTINES'),

                    _buildToggleTile(
                      icon: Icons.movie_creation_rounded,
                      color: const Color(0xFF00838F),
                      title: 'T-24h Production Shoot Checker',
                      subtitle: 'Sends a shoot alert 24 hours prior to verify call sheets, locations, and crew availability',
                      value: _config.enableShootChecker,
                      onChanged: (v) =>
                          _save(_config.copyWith(enableShootChecker: v)),
                    ),

                    _buildToggleTile(
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFFD97706),
                      title: 'Wrap Day Gear Reconciliation',
                      subtitle: 'Triggers an equipment check-in reminder within 24 hours after a shoot wraps',
                      value: _config.enableWrapReconciliation,
                      onChanged: (v) =>
                          _save(_config.copyWith(enableWrapReconciliation: v)),
                    ),

                    const SizedBox(height: 18),
                    _buildSectionHeader('VAULT INTEGRITY & DATA SAFETY'),

                    _buildToggleTile(
                      icon: Icons.cloud_download_rounded,
                      color: const Color(0xFF007A3D),
                      title: 'Weekly Encrypted Auto-Backup',
                      subtitle: 'Silently compiles a password-encrypted .etole database snapshot once a week to local storage',
                      value: _config.enableAutoBackup,
                      onChanged: (v) =>
                          _save(_config.copyWith(enableAutoBackup: v)),
                    ),

                    _buildToggleTile(
                      icon: Icons.delete_sweep_rounded,
                      color: const Color(0xFFDC2626),
                      title: '30-Day Trash Auto-Purge',
                      subtitle: 'Permanently sweeps soft-deleted items after 30 days to keep your local database fast & lightweight',
                      value: _config.enableTrashPurge,
                      onChanged: (v) =>
                          _save(_config.copyWith(enableTrashPurge: v)),
                    ),

                    const SizedBox(height: 24),

                    // Manual Run Action
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: const Color(0xFF080B0F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isRunningNow ? null : _runNow,
                        child: _isRunningNow
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF080B0F),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'SCANNING DATABASE...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'RUN AUTOMATION DISPATCH NOW',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
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

  Widget _buildToggleTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14171B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(top: 2),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              activeColor: color,
              activeTrackColor: color.withValues(alpha: 0.25),
              inactiveThumbColor: const Color(0xFF64748B),
              inactiveTrackColor: const Color(0xFF1E293B),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
