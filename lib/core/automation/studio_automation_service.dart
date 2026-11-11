import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../notifications/local_notification_service.dart';
import '../utils/currency_formatter.dart';
import '../../features/settings/data/backup_service.dart';

/// Top-level background execution dispatcher for native Android WorkManager
@pragma('vm:entry-point')
void studioAutomationBackgroundDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final db = AppDatabase();
      await StudioAutomationService.runAllAutomations(db);
    } catch (_) {}
    return Future.value(true);
  });
}

/// Configuration settings for the Studio Automation Engine
class StudioAutomationConfig {
  final bool enableOverdueWatchdog;
  final bool enableMilestoneAlerts;
  final bool enableStaleDealAlerts;
  final int staleDealDays;
  final bool enableVipReconnect;
  final int vipInactiveDays;
  final bool enableShootChecker;
  final bool enableWrapReconciliation;
  final bool enableMonthlyTaxRollup;
  final bool enableAutoBackup;
  final bool enableTrashPurge;
  final DateTime? lastRunTime;

  const StudioAutomationConfig({
    this.enableOverdueWatchdog = true,
    this.enableMilestoneAlerts = true,
    this.enableStaleDealAlerts = true,
    this.staleDealDays = 10,
    this.enableVipReconnect = true,
    this.vipInactiveDays = 30,
    this.enableShootChecker = true,
    this.enableWrapReconciliation = true,
    this.enableMonthlyTaxRollup = true,
    this.enableAutoBackup = true,
    this.enableTrashPurge = true,
    this.lastRunTime,
  });

  Map<String, dynamic> toJson() => {
    'enableOverdueWatchdog': enableOverdueWatchdog,
    'enableMilestoneAlerts': enableMilestoneAlerts,
    'enableStaleDealAlerts': enableStaleDealAlerts,
    'staleDealDays': staleDealDays,
    'enableVipReconnect': enableVipReconnect,
    'vipInactiveDays': vipInactiveDays,
    'enableShootChecker': enableShootChecker,
    'enableWrapReconciliation': enableWrapReconciliation,
    'enableMonthlyTaxRollup': enableMonthlyTaxRollup,
    'enableAutoBackup': enableAutoBackup,
    'enableTrashPurge': enableTrashPurge,
    'lastRunTime': lastRunTime?.toIso8601String(),
  };

  factory StudioAutomationConfig.fromJson(Map<String, dynamic> json) {
    return StudioAutomationConfig(
      enableOverdueWatchdog: json['enableOverdueWatchdog'] as bool? ?? true,
      enableMilestoneAlerts: json['enableMilestoneAlerts'] as bool? ?? true,
      enableStaleDealAlerts: json['enableStaleDealAlerts'] as bool? ?? true,
      staleDealDays: json['staleDealDays'] as int? ?? 10,
      enableVipReconnect: json['enableVipReconnect'] as bool? ?? true,
      vipInactiveDays: json['vipInactiveDays'] as int? ?? 30,
      enableShootChecker: json['enableShootChecker'] as bool? ?? true,
      enableWrapReconciliation:
          json['enableWrapReconciliation'] as bool? ?? true,
      enableMonthlyTaxRollup: json['enableMonthlyTaxRollup'] as bool? ?? true,
      enableAutoBackup: json['enableAutoBackup'] as bool? ?? true,
      enableTrashPurge: json['enableTrashPurge'] as bool? ?? true,
      lastRunTime: json['lastRunTime'] != null
          ? DateTime.tryParse(json['lastRunTime'] as String)
          : null,
    );
  }

  StudioAutomationConfig copyWith({
    bool? enableOverdueWatchdog,
    bool? enableMilestoneAlerts,
    bool? enableStaleDealAlerts,
    int? staleDealDays,
    bool? enableVipReconnect,
    int? vipInactiveDays,
    bool? enableShootChecker,
    bool? enableWrapReconciliation,
    bool? enableMonthlyTaxRollup,
    bool? enableAutoBackup,
    bool? enableTrashPurge,
    DateTime? lastRunTime,
  }) {
    return StudioAutomationConfig(
      enableOverdueWatchdog:
          enableOverdueWatchdog ?? this.enableOverdueWatchdog,
      enableMilestoneAlerts:
          enableMilestoneAlerts ?? this.enableMilestoneAlerts,
      enableStaleDealAlerts:
          enableStaleDealAlerts ?? this.enableStaleDealAlerts,
      staleDealDays: staleDealDays ?? this.staleDealDays,
      enableVipReconnect: enableVipReconnect ?? this.enableVipReconnect,
      vipInactiveDays: vipInactiveDays ?? this.vipInactiveDays,
      enableShootChecker: enableShootChecker ?? this.enableShootChecker,
      enableWrapReconciliation:
          enableWrapReconciliation ?? this.enableWrapReconciliation,
      enableMonthlyTaxRollup:
          enableMonthlyTaxRollup ?? this.enableMonthlyTaxRollup,
      enableAutoBackup: enableAutoBackup ?? this.enableAutoBackup,
      enableTrashPurge: enableTrashPurge ?? this.enableTrashPurge,
      lastRunTime: lastRunTime ?? this.lastRunTime,
    );
  }
}

/// Central Automation & Background Watchdog Engine for Brian Etole Studio
class StudioAutomationService {
  static const _storage = FlutterSecureStorage();
  static const _configKey = 'etole_automation_config_v1';
  static const _lastBackupKey = 'etole_last_auto_backup_timestamp';
  static const _lastTaxRollupKey = 'etole_last_tax_rollup_month';

  /// Load user automation config
  static Future<StudioAutomationConfig> loadConfig() async {
    try {
      final raw = await _storage.read(key: _configKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return StudioAutomationConfig.fromJson(decoded);
      }
    } catch (_) {}
    return const StudioAutomationConfig();
  }

  /// Save user automation config
  static Future<void> saveConfig(StudioAutomationConfig config) async {
    try {
      await _storage.write(key: _configKey, value: jsonEncode(config.toJson()));
    } catch (_) {}
  }

  /// Initialize native WorkManager background task scheduler
  static Future<void> initBackgroundWorkmanager() async {
    try {
      await Workmanager().initialize(
        studioAutomationBackgroundDispatcher,
        isInDebugMode: false,
      );

      // Register periodic background watchdog every 6 hours
      await Workmanager().registerPeriodicTask(
        'etole_studio_automation_task',
        'etole_studio_periodic_automation',
        frequency: const Duration(hours: 6),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (_) {}
  }

  /// Run all automations against an open database connection
  static Future<Map<String, int>> runAllAutomations(AppDatabase db) async {
    final config = await loadConfig();
    final now = DateTime.now();

    final results = <String, int>{
      'overdueInvoices': 0,
      'milestonesDue': 0,
      'staleDeals': 0,
      'vipTouchpoints': 0,
      'shootsUpcoming': 0,
      'shootsWrapped': 0,
      'trashPurged': 0,
    };

    // 1. Overdue Invoice Watchdog
    if (config.enableOverdueWatchdog) {
      try {
        final overdueDocs =
            await (db.select(db.documents)..where(
                  (t) =>
                      t.isDeleted.equals(false) &
                      t.docType.equals('invoice') &
                      t.status.equals('sent') &
                      t.dueOrValidityDate.isNotNull() &
                      t.dueOrValidityDate.isSmallerThanValue(now),
                ))
                .get();

        for (final doc in overdueDocs) {
          String clientName = 'Client';
          if (doc.clientId != null) {
            final client = await (db.select(
              db.clients,
            )..where((c) => c.id.equals(doc.clientId!))).getSingleOrNull();
            if (client != null) clientName = client.name;
          }

          final amountStr = CurrencyFormatter.format(
            doc.balanceDue > 0 ? doc.balanceDue : doc.totalAmount,
            currencyCode: doc.currencyCode,
          );

          await LocalNotificationService.showOverdueInvoiceAlert(
            docId: doc.id,
            clientName: clientName,
            docNumber: doc.docNumber,
            amountStr: amountStr,
          );
          results['overdueInvoices'] = (results['overdueInvoices'] ?? 0) + 1;
        }
      } catch (_) {}
    }

    // 2. Deposit & Milestone Due Tomorrow (Within 24 Hours)
    if (config.enableMilestoneAlerts) {
      try {
        final tomorrow = now.add(const Duration(hours: 24));
        final upcomingMilestones =
            await (db.select(db.documents)..where(
                  (t) =>
                      t.isDeleted.equals(false) &
                      t.status.equals('sent') &
                      t.dueOrValidityDate.isNotNull() &
                      t.dueOrValidityDate.isBiggerOrEqualValue(now) &
                      t.dueOrValidityDate.isSmallerThanValue(tomorrow),
                ))
                .get();

        for (final doc in upcomingMilestones) {
          String clientName = 'Client';
          if (doc.clientId != null) {
            final client = await (db.select(
              db.clients,
            )..where((c) => c.id.equals(doc.clientId!))).getSingleOrNull();
            if (client != null) clientName = client.name;
          }

          final amountStr = CurrencyFormatter.format(
            doc.depositAmount > 0 ? doc.depositAmount : doc.totalAmount,
            currencyCode: doc.currencyCode,
          );

          await LocalNotificationService.showMilestoneDueAlert(
            docId: doc.id,
            clientName: clientName,
            docNumber: doc.docNumber,
            amountStr: amountStr,
          );
          results['milestonesDue'] = (results['milestonesDue'] ?? 0) + 1;
        }
      } catch (_) {}
    }

    // 3. Stale Deal Follow-Up Radar (>X days in pitched status)
    if (config.enableStaleDealAlerts) {
      try {
        final staleThreshold = now.subtract(
          Duration(days: config.staleDealDays),
        );
        final staleLeads =
            await (db.select(db.networkingLeads)..where(
                  (t) =>
                      t.isDeleted.equals(false) &
                      t.isArchived.equals(false) &
                      (t.followUpStatus.equals('pitched') |
                          t.status.equals('pitched') |
                          t.status.equals('lead')) &
                      t.updatedAt.isSmallerThanValue(staleThreshold),
                ))
                .get();

        for (final lead in staleLeads.take(3)) {
          final days = now.difference(lead.updatedAt).inDays;
          await LocalNotificationService.showStaleDealAlert(
            leadId: lead.id,
            leadName: lead.name,
            company: lead.organization ?? '',
            daysStale: days,
          );
          results['staleDeals'] = (results['staleDeals'] ?? 0) + 1;
        }
      } catch (_) {}
    }

    // 4. VIP Contact Reconnect Timer (>X days inactive)
    if (config.enableVipReconnect) {
      try {
        final vipThreshold = now.subtract(
          Duration(days: config.vipInactiveDays),
        );
        final vipContacts =
            await (db.select(db.networkingLeads)..where(
                  (t) =>
                      t.isDeleted.equals(false) &
                      t.isArchived.equals(false) &
                      t.updatedAt.isSmallerThanValue(vipThreshold),
                ))
                .get();

        for (final contact in vipContacts.take(2)) {
          final days = now.difference(contact.updatedAt).inDays;
          await LocalNotificationService.showVipTouchpointAlert(
            contactId: contact.id,
            contactName: contact.name,
            daysInactive: days,
          );
          results['vipTouchpoints'] = (results['vipTouchpoints'] ?? 0) + 1;
        }
      } catch (_) {}
    }

    // 5. T-24h Production Shoot & Call Sheet Checker
    if (config.enableShootChecker) {
      try {
        final tomorrow = now.add(const Duration(hours: 24));
        final upcomingProjects =
            await (db.select(db.productionProjects)..where(
                  (t) =>
                      t.isDeleted.equals(false) &
                      t.shootDate.isNotNull() &
                      t.shootDate.isBiggerOrEqualValue(now) &
                      t.shootDate.isSmallerThanValue(tomorrow),
                ))
                .get();

        for (final project in upcomingProjects) {
          await LocalNotificationService.showShootAlert(
            occasionId: project.id,
            occasionName: project.title,
            message:
                'Shoot tomorrow for ${project.clientName} at ${project.location ?? 'location'}. Verify call sheet & crew roster.',
          );
          results['shootsUpcoming'] = (results['shootsUpcoming'] ?? 0) + 1;
        }
      } catch (_) {}
    }

    // 6. Wrap Day Gear Reconciliation (Wrapped in the last 24h)
    if (config.enableWrapReconciliation) {
      try {
        final yesterday = now.subtract(const Duration(hours: 24));
        final wrappedProjects =
            await (db.select(db.productionProjects)..where(
                  (t) =>
                      t.isDeleted.equals(false) &
                      t.shootDate.isNotNull() &
                      t.shootDate.isSmallerThanValue(now) &
                      t.shootDate.isBiggerOrEqualValue(yesterday),
                ))
                .get();

        for (final project in wrappedProjects) {
          await LocalNotificationService.showGearReconciliationAlert(
            occasionId: project.id,
            occasionName: project.title,
          );
          results['shootsWrapped'] = (results['shootsWrapped'] ?? 0) + 1;
        }
      } catch (_) {}
    }

    // 7. Monthly Tax & Revenue Rollup (1st, 2nd, or 3rd of month)
    if (config.enableMonthlyTaxRollup && now.day <= 3) {
      try {
        final currentMonthKey = '${now.year}-${now.month}';
        final lastMonthKey = await _storage.read(key: _lastTaxRollupKey);

        if (lastMonthKey != currentMonthKey) {
          // Calculate previous month totals
          final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
          final firstDayOfPrevMonth = DateTime(
            now.month == 1 ? now.year - 1 : now.year,
            now.month == 1 ? 12 : now.month - 1,
            1,
          );

          final prevMonthInvoices =
              await (db.select(db.documents)..where(
                    (t) =>
                        t.isDeleted.equals(false) &
                        t.docType.equals('invoice') &
                        t.issueDate.isBiggerOrEqualValue(firstDayOfPrevMonth) &
                        t.issueDate.isSmallerThanValue(firstDayOfCurrentMonth),
                  ))
                  .get();

          double totalBilled = 0.0;
          for (final inv in prevMonthInvoices) {
            totalBilled += inv.totalAmount;
          }

          final estimatedWht = totalBilled * 0.05;
          final estimatedVat = (totalBilled / 1.16) * 0.16;

          final monthFormat = DateFormat('MMMM');
          final prevMonthName = monthFormat.format(firstDayOfPrevMonth);

          await LocalNotificationService.showMonthlyTaxRollupAlert(
            monthName: prevMonthName,
            revenueStr: CurrencyFormatter.format(totalBilled),
            whtStr: CurrencyFormatter.format(estimatedWht),
            vatStr: CurrencyFormatter.format(estimatedVat),
          );

          await _storage.write(key: _lastTaxRollupKey, value: currentMonthKey);
        }
      } catch (_) {}
    }

    // 8. Weekly Encrypted Auto-Backup
    if (config.enableAutoBackup) {
      try {
        final lastBackupStr = await _storage.read(key: _lastBackupKey);
        final lastBackupTime = lastBackupStr != null
            ? DateTime.tryParse(lastBackupStr)
            : null;

        if (lastBackupTime == null ||
            now.difference(lastBackupTime).inDays >= 7) {
          final backupService = BackupService(db);
          final backupFile = await backupService.createFullBackup();
          final sizeKb = (await backupFile.length()) / 1024;
          final sizeStr = sizeKb > 1024
              ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
              : '${sizeKb.toStringAsFixed(0)} KB';

          await LocalNotificationService.showBackupCompleteAlert(
            filename: backupFile.path.split('/').last,
            sizeStr: sizeStr,
          );

          await _storage.write(
            key: _lastBackupKey,
            value: now.toIso8601String(),
          );
        }
      } catch (_) {}
    }

    // 9. 30-Day Trash Auto-Purge
    if (config.enableTrashPurge) {
      try {
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));

        final deletedDocs =
            await (db.delete(db.documents)..where(
                  (t) =>
                      t.isDeleted.equals(true) &
                      t.updatedAt.isSmallerThanValue(thirtyDaysAgo),
                ))
                .go();

        final deletedClients =
            await (db.delete(db.clients)..where(
                  (t) =>
                      t.isDeleted.equals(true) &
                      (t.deletedAt.isNotNull() &
                              t.deletedAt.isSmallerThanValue(thirtyDaysAgo) |
                          t.createdAt.isSmallerThanValue(thirtyDaysAgo)),
                ))
                .go();

        final deletedItems =
            await (db.delete(db.itemsLibrary)..where(
                  (t) =>
                      t.isDeleted.equals(true) &
                      (t.deletedAt.isNotNull() &
                              t.deletedAt.isSmallerThanValue(thirtyDaysAgo) |
                          t.createdAt.isSmallerThanValue(thirtyDaysAgo)),
                ))
                .go();

        final deletedLeads =
            await (db.delete(db.networkingLeads)..where(
                  (t) =>
                      t.isDeleted.equals(true) &
                      t.updatedAt.isSmallerThanValue(thirtyDaysAgo),
                ))
                .go();

        results['trashPurged'] =
            deletedDocs + deletedClients + deletedItems + deletedLeads;
      } catch (_) {}
    }

    // 10. Sync Android Home Widget Data
    try {
      final activeInvoices =
          await (db.select(db.documents)..where(
                (t) =>
                    t.isDeleted.equals(false) &
                    t.docType.equals('invoice') &
                    t.status.equals('sent'),
              ))
              .get();

      double totalUnpaid = 0.0;
      for (final inv in activeInvoices) {
        totalUnpaid += (inv.balanceDue > 0 ? inv.balanceDue : inv.totalAmount);
      }

      await HomeWidget.saveWidgetData<String>(
        'etole_unpaid_amount',
        CurrencyFormatter.format(totalUnpaid),
      );
      await HomeWidget.saveWidgetData<int>(
        'etole_unpaid_count',
        activeInvoices.length,
      );
      await HomeWidget.updateWidget(
        name: 'EtoleStudioWidgetProvider',
        androidName: 'EtoleStudioWidgetProvider',
      );
    } catch (_) {}

    // Update last run time in storage
    final updatedConfig = config.copyWith(lastRunTime: now);
    await saveConfig(updatedConfig);

    return results;
  }

  /// Fast health check invoked on app foreground launch
  static Future<void> runHealthCheck(WidgetRef ref) async {
    try {
      final db = ref.read(databaseProvider);
      await runAllAutomations(db);
    } catch (_) {}
  }
}
