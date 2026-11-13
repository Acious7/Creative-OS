import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'sanctuary_models.dart';

class SanctuaryStorageService {
  static final _secureStorage = const FlutterSecureStorage();
  static const _journalKeyName = 'etole_black_box_journal_key';

  static Future<Directory> _getSanctuaryDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/sanctuary');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // --- SECRET SPOTS ---
  static Future<List<SecretSpot>> loadSecretSpots() async {
    try {
      final dir = await _getSanctuaryDir();
      final file = File('${dir.path}/secret_spots.json');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list.map((e) => SecretSpot.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSecretSpot(SecretSpot spot) async {
    final spots = await loadSecretSpots();
    final existingIndex = spots.indexWhere((s) => s.id == spot.id);
    if (existingIndex >= 0) {
      spots[existingIndex] = spot;
    } else {
      spots.insert(0, spot);
    }
    final dir = await _getSanctuaryDir();
    final file = File('${dir.path}/secret_spots.json');
    await file.writeAsString(jsonEncode(spots.map((s) => s.toJson()).toList()));
  }

  static Future<void> deleteSecretSpot(String id) async {
    final spots = await loadSecretSpots();
    spots.removeWhere((s) => s.id == id);
    final dir = await _getSanctuaryDir();
    final file = File('${dir.path}/secret_spots.json');
    await file.writeAsString(jsonEncode(spots.map((s) => s.toJson()).toList()));
  }

  // --- SCRAPBOOK ITEMS ---
  static Future<List<ScrapbookItem>> loadScrapbookItems() async {
    try {
      final dir = await _getSanctuaryDir();
      final file = File('${dir.path}/scrapbook.json');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list.map((e) => ScrapbookItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveScrapbookItem(ScrapbookItem item) async {
    final items = await loadScrapbookItems();
    final index = items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.insert(0, item);
    }
    final dir = await _getSanctuaryDir();
    final file = File('${dir.path}/scrapbook.json');
    await file.writeAsString(jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  static Future<void> deleteScrapbookItem(String id) async {
    final items = await loadScrapbookItems();
    items.removeWhere((i) => i.id == id);
    final dir = await _getSanctuaryDir();
    final file = File('${dir.path}/scrapbook.json');
    await file.writeAsString(jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  // --- BLACK BOX BIOMETRIC JOURNAL ---
  static Future<List<BlackBoxJournalEntry>> loadJournalEntries() async {
    try {
      final dir = await _getSanctuaryDir();
      final file = File('${dir.path}/black_box_journal.dat');
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.isEmpty) return [];

      // Simple XOR obfuscation with secure-stored encryption key for local confidentiality
      String? key = await _secureStorage.read(key: _journalKeyName);
      if (key == null) {
        key = 'etole_sanctuary_${DateTime.now().millisecondsSinceEpoch}';
        await _secureStorage.write(key: _journalKeyName, value: key);
      }

      final decoded = _xorTransform(raw, key);
      final list = jsonDecode(decoded) as List<dynamic>;
      return list.map((e) => BlackBoxJournalEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveJournalEntry(BlackBoxJournalEntry entry) async {
    final entries = await loadJournalEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.insert(0, entry);
    }

    String? key = await _secureStorage.read(key: _journalKeyName);
    if (key == null) {
      key = 'etole_sanctuary_${DateTime.now().millisecondsSinceEpoch}';
      await _secureStorage.write(key: _journalKeyName, value: key);
    }

    final jsonStr = jsonEncode(entries.map((e) => e.toJson()).toList());
    final encrypted = _xorTransform(jsonStr, key);

    final dir = await _getSanctuaryDir();
    final file = File('${dir.path}/black_box_journal.dat');
    await file.writeAsString(encrypted);
  }

  static Future<void> deleteJournalEntry(String id) async {
    final entries = await loadJournalEntries();
    entries.removeWhere((e) => e.id == id);

    String? key = await _secureStorage.read(key: _journalKeyName);
    if (key == null) return;

    final jsonStr = jsonEncode(entries.map((e) => e.toJson()).toList());
    final encrypted = _xorTransform(jsonStr, key);

    final dir = await _getSanctuaryDir();
    final file = File('${dir.path}/black_box_journal.dat');
    await file.writeAsString(encrypted);
  }

  // --- INNER CIRCLE RELATIONSHIPS & GIFT DIARY ---
  static Future<Map<int, InnerCircleMetadata>> loadInnerCircleMap() async {
    try {
      final dir = await _getSanctuaryDir();
      final file = File('${dir.path}/inner_circle.json');
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final result = <int, InnerCircleMetadata>{};
      map.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null) {
          result[id] = InnerCircleMetadata.fromJson(v as Map<String, dynamic>);
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveInnerCircleMetadata(InnerCircleMetadata meta) async {
    final map = await loadInnerCircleMap();
    map[meta.personId] = meta;
    final dir = await _getSanctuaryDir();
    final file = File('${dir.path}/inner_circle.json');
    final out = <String, dynamic>{};
    map.forEach((k, v) => out[k.toString()] = v.toJson());
    await file.writeAsString(jsonEncode(out));
  }

  // --- 100% OFFLINE DATA SOVEREIGNTY EXPORT ---
  static Future<String> exportSanctuaryArchive() async {
    final spots = await loadSecretSpots();
    final scrapbook = await loadScrapbookItems();
    final journal = await loadJournalEntries();
    final innerCircle = await loadInnerCircleMap();

    final exportData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
      'app': 'Etole Studio Sanctuary',
      'secretSpots': spots.map((s) => s.toJson()).toList(),
      'scrapbook': scrapbook.map((s) => s.toJson()).toList(),
      'journal': journal.map((j) => j.toJson()).toList(),
      'innerCircle': innerCircle.map((k, v) => MapEntry(k.toString(), v.toJson())),
    };

    Directory docsDir = Directory('/storage/emulated/0/Documents/Etole');
    try {
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }
    } catch (_) {
      final appDir = await getApplicationDocumentsDirectory();
      docsDir = Directory('${appDir.path}/exports');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }
    }

    final backupFile = File(
      '${docsDir.path}/etole_sanctuary_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await backupFile.writeAsString(const JsonEncoder.withIndent('  ').convert(exportData));
    return backupFile.path;
  }

  /// Restores Sanctuary items from a backup archive without wiping existing data
  static Future<bool> importSanctuaryArchive(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // 1. Merge Secret Spots
      if (data['secretSpots'] is List) {
        final existingSpots = await loadSecretSpots();
        final existingIds = existingSpots.map((s) => s.id).toSet();
        for (final item in data['secretSpots'] as List) {
          final spot = SecretSpot.fromJson(item as Map<String, dynamic>);
          if (!existingIds.contains(spot.id)) {
            existingSpots.add(spot);
          }
        }
        final dir = await _getSanctuaryDir();
        await File('${dir.path}/secret_spots.json').writeAsString(
          jsonEncode(existingSpots.map((s) => s.toJson()).toList()),
        );
      }

      // 2. Merge Scrapbook Items
      if (data['scrapbook'] is List) {
        final existingItems = await loadScrapbookItems();
        final existingIds = existingItems.map((i) => i.id).toSet();
        for (final item in data['scrapbook'] as List) {
          final sb = ScrapbookItem.fromJson(item as Map<String, dynamic>);
          if (!existingIds.contains(sb.id)) {
            existingItems.add(sb);
          }
        }
        final dir = await _getSanctuaryDir();
        await File('${dir.path}/scrapbook.json').writeAsString(
          jsonEncode(existingItems.map((i) => i.toJson()).toList()),
        );
      }

      // 3. Merge Inner Circle Metadata
      if (data['innerCircle'] is Map) {
        final map = await loadInnerCircleMap();
        (data['innerCircle'] as Map<String, dynamic>).forEach((k, v) {
          final id = int.tryParse(k);
          if (id != null && !map.containsKey(id)) {
            map[id] = InnerCircleMetadata.fromJson(v as Map<String, dynamic>);
          }
        });
        final dir = await _getSanctuaryDir();
        final out = <String, dynamic>{};
        map.forEach((k, v) => out[k.toString()] = v.toJson());
        await File('${dir.path}/inner_circle.json').writeAsString(jsonEncode(out));
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static String _xorTransform(String input, String key) {
    final keyBytes = utf8.encode(key);
    final inputBytes = utf8.encode(input);
    final out = List<int>.filled(inputBytes.length, 0);
    for (int i = 0; i < inputBytes.length; i++) {
      out[i] = inputBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return base64Encode(out);
  }
}
