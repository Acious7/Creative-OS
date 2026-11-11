import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:creative_os/core/database/app_database.dart';
import 'package:creative_os/core/database/database_provider.dart';
import 'package:creative_os/core/theme/brand_theme_provider.dart';
import 'package:creative_os/core/theme/app_theme.dart';
import 'package:creative_os/core/design_system/etole_colors.dart';
import 'package:creative_os/features/digital_cards/presentation/providers/cards_providers.dart';
import 'package:creative_os/features/digital_cards/presentation/screens/network_hub_screen.dart';
import 'package:creative_os/features/digital_cards/presentation/screens/event_detail_screen.dart';
import 'package:creative_os/features/digital_cards/presentation/screens/person_profile_screen.dart';
import 'package:creative_os/features/digital_cards/presentation/widgets/add_person_sheet.dart';

Future<void> _loadFonts() async {
  final bebasFile = File('assets/fonts/BebasNeue-Regular.ttf');
  if (bebasFile.existsSync()) {
    final bebasData = bebasFile.readAsBytesSync();
    final bebasLoader = FontLoader('BebasNeue')..addFont(Future.value(ByteData.view(bebasData.buffer)));
    await bebasLoader.load();
  }

  final interFile = File('assets/fonts/Inter-Variable.ttf');
  if (interFile.existsSync()) {
    final interData = interFile.readAsBytesSync();
    final interLoader = FontLoader('Inter')..addFont(Future.value(ByteData.view(interData.buffer)));
    await interLoader.load();
  }
}

Future<void> _captureRepaintBoundary(
  GlobalKey key,
  File outFile,
) async {
  final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;
  final image = await boundary.toImage(pixelRatio: 2.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    outFile.writeAsBytesSync(byteData.buffer.asUint8List());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final outDir = Directory('C:/Users/Etole/.gemini/antigravity-ide/brain/41d9e517-5821-419a-82c2-9746e5c15fde/network_previews');

  setUpAll(() async {
    await _loadFonts();
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async => true,
    );
  });

  testWidgets('Render and capture Network Home, Event Detail & Person Profile', (tester) async {
    final binding = tester.binding;
    binding.window.physicalSizeTestValue = const Size(1080, 2400);
    binding.window.devicePixelRatioTestValue = 2.5;

    final db = AppDatabase();
    final brand = await (db.select(db.brands)..where((t) => t.isActive.equals(true))).getSingleOrNull();

    // 1. Network Home
    final key1 = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          if (brand != null) activeBrandProvider.overrideWith((ref) => brand),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getDarkTheme(EtoleColors.ember),
          home: RepaintBoundary(
            key: key1,
            child: const NetworkHubScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _captureRepaintBoundary(key1, File('${outDir.path}/01_network_home.png'));

    // 2. Event Detail Screen (Kalasha Film Festival)
    final events = await (db.select(db.networkingEvents)..where((t) => t.isDeleted.equals(false))).get();
    if (events.isNotEmpty) {
      final key2 = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            if (brand != null) activeBrandProvider.overrideWith((ref) => brand),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getDarkTheme(EtoleColors.ember),
            home: RepaintBoundary(
              key: key2,
              child: EventDetailScreen(eventId: events.first.id),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _captureRepaintBoundary(key2, File('${outDir.path}/02_event_detail.png'));
    }

    // 3. Person Profile Screen (Martin Kiarie)
    final leads = await (db.select(db.networkingLeads)..where((t) => t.isDeleted.equals(false))).get();
    if (leads.isNotEmpty) {
      final key3 = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            if (brand != null) activeBrandProvider.overrideWith((ref) => brand),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getDarkTheme(EtoleColors.ember),
            home: RepaintBoundary(
              key: key3,
              child: PersonProfileScreen(person: leads.first),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _captureRepaintBoundary(key3, File('${outDir.path}/03_person_profile.png'));
    }
  });
}
