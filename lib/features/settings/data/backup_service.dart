import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';

class BackupSummary {
  final DateTime createdAt;
  final int documentCount;
  final int clientCount;
  final int eventCount;
  final int leadCount;
  final int brandCount;
  final int itemCount;
  final int attachmentCount;

  BackupSummary({
    required this.createdAt,
    required this.documentCount,
    required this.clientCount,
    required this.eventCount,
    required this.leadCount,
    required this.brandCount,
    required this.itemCount,
    required this.attachmentCount,
  });
}

class DatabaseStats {
  final int documentCount;
  final int clientCount;
  final int eventCount;
  final int leadCount;
  final int itemCount;
  final int brandCount;
  final int cardCount;
  final int projectCount;
  final int attachmentCount;
  final int signatureCount;
  final int estimatedSizeBytes;

  DatabaseStats({
    required this.documentCount,
    required this.clientCount,
    required this.eventCount,
    required this.leadCount,
    required this.itemCount,
    required this.brandCount,
    required this.cardCount,
    this.projectCount = 0,
    required this.attachmentCount,
    required this.signatureCount,
    required this.estimatedSizeBytes,
  });
}

class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Fetch live database stats for the health dashboard
  Future<DatabaseStats> getDatabaseStats() async {
    final docs = await _db.select(_db.documents).get();
    final clients = await _db.select(_db.clients).get();
    final events = await _db.select(_db.networkingEvents).get();
    final leads = await _db.select(_db.networkingLeads).get();
    final items = await _db.select(_db.itemsLibrary).get();
    final brands = await _db.select(_db.brands).get();
    final cards = await _db.select(_db.businessCards).get();
    final projects = await _db.select(_db.productionProjects).get();
    final attachments = await _db.select(_db.documentAttachments).get();
    final signatures = await _db.select(_db.documentSignatures).get();

    int totalSize = 0;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${appDir.path}/etole_db.sqlite');
      if (await dbFile.exists()) {
        totalSize = await dbFile.length();
      }
    } catch (_) {}

    return DatabaseStats(
      documentCount: docs.length,
      clientCount: clients.length,
      eventCount: events.length,
      leadCount: leads.length,
      itemCount: items.length,
      brandCount: brands.length,
      cardCount: cards.length,
      projectCount: projects.length,
      attachmentCount: attachments.length,
      signatureCount: signatures.length,
      estimatedSizeBytes: totalSize,
    );
  }

  /// Generate full offline backup file (.etole zip)
  Future<File> createFullBackup({
    String? targetFolderPath,
    String? password,
  }) async {
    final brands = await _db.select(_db.brands).get();
    final clients = await _db.select(_db.clients).get();
    final items = await _db.select(_db.itemsLibrary).get();
    final numbering = await _db.select(_db.numberingSequences).get();
    final textDefaults = await _db.select(_db.textDefaults).get();
    final documents = await _db.select(_db.documents).get();
    final documentItems = await _db.select(_db.documentItems).get();
    final attachments = await _db.select(_db.documentAttachments).get();
    final signatures = await _db.select(_db.documentSignatures).get();
    final activityLogs = await _db.select(_db.documentActivityLogs).get();
    final paymentProfiles = await _db.select(_db.paymentProfiles).get();
    final cards = await _db.select(_db.businessCards).get();
    final events = await _db.select(_db.networkingEvents).get();
    final leads = await _db.select(_db.networkingLeads).get();
    final clauses = await _db.select(_db.reusableClauses).get();
    final projects = await _db.select(_db.productionProjects).get();
    final callSheets = await _db.select(_db.callSheets).get();
    final gearItems = await _db.select(_db.gearItems).get();

    final data = {
      'app': 'Etole',
      'version': 3,
      'createdAt': DateTime.now().toIso8601String(),
      'brands': brands.map((b) => b.toJson()).toList(),
      'clients': clients.map((c) => c.toJson()).toList(),
      'items': items.map((i) => i.toJson()).toList(),
      'numbering': numbering.map((n) => n.toJson()).toList(),
      'textDefaults': textDefaults.map((t) => t.toJson()).toList(),
      'documents': documents.map((d) => d.toJson()).toList(),
      'documentItems': documentItems.map((li) => li.toJson()).toList(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'signatures': signatures.map((s) => s.toJson()).toList(),
      'activityLogs': activityLogs.map((al) => al.toJson()).toList(),
      'paymentProfiles': paymentProfiles.map((p) => p.toJson()).toList(),
      'cards': cards.map((c) => c.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'leads': leads.map((l) => l.toJson()).toList(),
      'clauses': clauses.map((cl) => cl.toJson()).toList(),
      'projects': projects.map((pr) => pr.toJson()).toList(),
      'callSheets': callSheets.map((cs) => cs.toJson()).toList(),
      'gearItems': gearItems.map((gi) => gi.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonString);
    archive.addFile(ArchiveFile('database.json', jsonBytes.length, jsonBytes));

    // Include document attachments
    for (final attachment in attachments) {
      final file = File(attachment.filePath);
      if (await file.exists()) {
        final fileBytes = await file.readAsBytes();
        final name = attachment.fileName?.isNotEmpty == true
            ? attachment.fileName!
            : 'att_${attachment.id}.dat';
        archive.addFile(
          ArchiveFile('attachments/$name', fileBytes.length, fileBytes),
        );
      }
    }

    // Include signatures
    for (final sig in signatures) {
      final file = File(sig.signatureImagePath);
      if (await file.exists()) {
        final fileBytes = await file.readAsBytes();
        archive.addFile(
          ArchiveFile('signatures/${sig.id}.png', fileBytes.length, fileBytes),
        );
      }
    }

    final zipBytes = ZipEncoder().encode(archive);

    Directory targetDir;
    if (targetFolderPath != null) {
      targetDir = Directory(targetFolderPath);
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${appDir.path}/Backups');
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final backupFile = File('${targetDir.path}/Etole_Backup_$timestamp.etole');
    await backupFile.writeAsBytes(zipBytes!);

    await enforceRetentionPolicy(targetDir);

    return backupFile;
  }

  /// List saved local snapshots
  Future<List<File>> listLocalBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/Backups');
      if (!await targetDir.exists()) return [];

      final files =
          targetDir
              .listSync()
              .whereType<File>()
              .where(
                (f) => f.path.endsWith('.etole') || f.path.endsWith('.zip'),
              )
              .toList()
            ..sort(
              (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
            );

      return files;
    } catch (_) {
      return [];
    }
  }

  /// Enforce retention policy: keeps up to 7 snapshots
  Future<void> enforceRetentionPolicy(Directory backupDir) async {
    try {
      final files =
          backupDir
              .listSync()
              .whereType<File>()
              .where(
                (f) => f.path.endsWith('.etole') || f.path.endsWith('.zip'),
              )
              .toList()
            ..sort(
              (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
            );

      if (files.length > 7) {
        for (int i = 7; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (_) {}
  }

  /// Delete a specific backup file
  Future<bool> deleteBackupFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Share backup file via system share sheet
  Future<void> shareBackupFile([File? specificFile]) async {
    final file = specificFile ?? await createFullBackup();
    await Share.shareXFiles([XFile(file.path)], subject: 'Etole Full Backup');
  }

  /// Inspect and preview backup file contents before restoring
  Future<BackupSummary?> previewBackupFile(File backupFile) async {
    try {
      final bytes = await backupFile.readAsBytes();
      String? jsonContent;

      if (backupFile.path.endsWith('.etole') ||
          backupFile.path.endsWith('.zip')) {
        final archive = ZipDecoder().decodeBytes(bytes);
        final dbFile = archive.findFile('database.json');
        if (dbFile != null) {
          jsonContent = utf8.decode(dbFile.content as List<int>);
        }
      } else {
        jsonContent = utf8.decode(bytes);
      }

      if (jsonContent == null) return null;

      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final createdAtStr = data['createdAt'] as String?;
      final createdAt = createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now();

      return BackupSummary(
        createdAt: createdAt,
        documentCount: (data['documents'] as List<dynamic>?)?.length ?? 0,
        clientCount: (data['clients'] as List<dynamic>?)?.length ?? 0,
        eventCount: (data['events'] as List<dynamic>?)?.length ?? 0,
        leadCount: (data['leads'] as List<dynamic>?)?.length ?? 0,
        brandCount: (data['brands'] as List<dynamic>?)?.length ?? 0,
        itemCount: (data['items'] as List<dynamic>?)?.length ?? 0,
        attachmentCount: (data['attachments'] as List<dynamic>?)?.length ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Restore full database and media from backup archive
  Future<bool> restoreBackupFromFile(File backupFile) async {
    try {
      final bytes = await backupFile.readAsBytes();
      String? jsonContent;
      Archive? archive;

      if (backupFile.path.endsWith('.etole') ||
          backupFile.path.endsWith('.zip')) {
        archive = ZipDecoder().decodeBytes(bytes);
        final dbFile = archive.findFile('database.json');
        if (dbFile != null) {
          jsonContent = utf8.decode(dbFile.content as List<int>);
        }
      } else {
        jsonContent = utf8.decode(bytes);
      }

      if (jsonContent == null) return false;

      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Extract media/attachments back into application directory if archive present
      if (archive != null) {
        final appDir = await getApplicationDocumentsDirectory();
        for (final file in archive) {
          if (file.isFile && file.name != 'database.json') {
            final outPath = '${appDir.path}/${file.name}';
            final outFile = File(outPath);
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
          }
        }
      }

      await _db.transaction(() async {
        // Clear in proper foreign key order
        await _db.delete(_db.gearItems).go();
        await _db.delete(_db.callSheets).go();
        await _db.delete(_db.productionProjects).go();
        await _db.delete(_db.reusableClauses).go();
        await _db.delete(_db.networkingLeads).go();
        await _db.delete(_db.networkingEvents).go();
        await _db.delete(_db.businessCards).go();
        await _db.delete(_db.paymentProfiles).go();
        await _db.delete(_db.documentActivityLogs).go();
        await _db.delete(_db.documentSignatures).go();
        await _db.delete(_db.documentAttachments).go();
        await _db.delete(_db.documentItems).go();
        await _db.delete(_db.documents).go();
        await _db.delete(_db.textDefaults).go();
        await _db.delete(_db.numberingSequences).go();
        await _db.delete(_db.itemsLibrary).go();
        await _db.delete(_db.clients).go();
        await _db.delete(_db.brands).go();

        // 1. Brands
        final brands = (data['brands'] as List<dynamic>?) ?? [];
        for (final b in brands) {
          await _db.into(_db.brands).insert(Brand.fromJson(b));
        }

        // 2. Payment Profiles
        final paymentProfiles =
            (data['paymentProfiles'] as List<dynamic>?) ?? [];
        for (final p in paymentProfiles) {
          await _db
              .into(_db.paymentProfiles)
              .insert(PaymentProfile.fromJson(p));
        }

        // 3. Clients
        final clients = (data['clients'] as List<dynamic>?) ?? [];
        for (final c in clients) {
          await _db.into(_db.clients).insert(Client.fromJson(c));
        }

        // 4. Items Library
        final items = (data['items'] as List<dynamic>?) ?? [];
        for (final i in items) {
          await _db.into(_db.itemsLibrary).insert(ItemsLibraryData.fromJson(i));
        }

        // 5. Numbering Sequences
        final numbering = (data['numbering'] as List<dynamic>?) ?? [];
        for (final n in numbering) {
          await _db
              .into(_db.numberingSequences)
              .insert(NumberingSequence.fromJson(n));
        }

        // 6. Text Defaults
        final textDefaults = (data['textDefaults'] as List<dynamic>?) ?? [];
        for (final td in textDefaults) {
          await _db.into(_db.textDefaults).insert(TextDefault.fromJson(td));
        }

        // 7. Documents
        final documents = (data['documents'] as List<dynamic>?) ?? [];
        for (final d in documents) {
          await _db.into(_db.documents).insert(Document.fromJson(d));
        }

        // 8. Document Items
        final documentItems = (data['documentItems'] as List<dynamic>?) ?? [];
        for (final li in documentItems) {
          await _db.into(_db.documentItems).insert(DocumentItem.fromJson(li));
        }

        // 9. Attachments
        final attachments = (data['attachments'] as List<dynamic>?) ?? [];
        for (final a in attachments) {
          await _db
              .into(_db.documentAttachments)
              .insert(DocumentAttachment.fromJson(a));
        }

        // 10. Signatures
        final signatures = (data['signatures'] as List<dynamic>?) ?? [];
        for (final s in signatures) {
          await _db
              .into(_db.documentSignatures)
              .insert(DocumentSignature.fromJson(s));
        }

        // 11. Activity Logs
        final activityLogs = (data['activityLogs'] as List<dynamic>?) ?? [];
        for (final al in activityLogs) {
          await _db
              .into(_db.documentActivityLogs)
              .insert(DocumentActivityLog.fromJson(al));
        }

        // 12. Digital Cards
        final cards = (data['cards'] as List<dynamic>?) ?? [];
        for (final c in cards) {
          await _db.into(_db.businessCards).insert(BusinessCard.fromJson(c));
        }

        // 13. Networking Events
        final events = (data['events'] as List<dynamic>?) ?? [];
        for (final e in events) {
          await _db
              .into(_db.networkingEvents)
              .insert(NetworkingEvent.fromJson(e));
        }

        // 14. Networking Leads
        final leads = (data['leads'] as List<dynamic>?) ?? [];
        for (final l in leads) {
          await _db
              .into(_db.networkingLeads)
              .insert(NetworkingLead.fromJson(l));
        }

        // 15. Reusable Clauses
        final clauses = (data['clauses'] as List<dynamic>?) ?? [];
        for (final cl in clauses) {
          await _db
              .into(_db.reusableClauses)
              .insert(ReusableClause.fromJson(cl));
        }

        // 16. Production Projects
        final projects = (data['projects'] as List<dynamic>?) ?? [];
        for (final pr in projects) {
          await _db
              .into(_db.productionProjects)
              .insert(ProductionProject.fromJson(pr));
        }

        // 17. Call Sheets
        final callSheets = (data['callSheets'] as List<dynamic>?) ?? [];
        for (final cs in callSheets) {
          await _db.into(_db.callSheets).insert(CallSheet.fromJson(cs));
        }

        // 18. Gear Items
        final gearItems = (data['gearItems'] as List<dynamic>?) ?? [];
        for (final gi in gearItems) {
          await _db.into(_db.gearItems).insert(GearItem.fromJson(gi));
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}
