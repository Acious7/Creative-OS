import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:creative_os/core/theme/app_theme.dart';
import 'package:creative_os/core/theme/brand_theme_provider.dart';
import 'package:creative_os/core/design_system/etole_colors.dart';
import 'package:creative_os/features/digital_cards/presentation/screens/network_hub_screen.dart';
import 'package:creative_os/features/hub/domain/hub_models.dart';
import 'package:creative_os/features/hub/presentation/screens/hub_screen.dart';
import 'package:creative_os/features/hub/presentation/widgets/world_container.dart';
import 'package:creative_os/features/hub/presentation/widgets/world_transition_overlay.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final outDir = Directory('C:/Users/Etole/.gemini/antigravity/brain/9b94690f-b154-4e55-ae67-0b790798df59');
  final framesDir = Directory('${outDir.path}/hub_frames');

  setUpAll(() async {
    await _loadFonts();
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    if (!framesDir.existsSync()) framesDir.createSync(recursive: true);
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
      (call) async => null,
    );
  });

  testWidgets('Capture Hub Dark Mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeMode.dark),
          isOledModeProvider.overrideWith((ref) => false),
          reduceMotionProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getDarkTheme(EtoleColors.ember),
          home: RepaintBoundary(
            key: key,
            child: HubScreen(onWorldSelected: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outDir.path}/hub_dark_master.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Capture Hub Light Mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeMode.light),
          isOledModeProvider.overrideWith((ref) => false),
          reduceMotionProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(EtoleColors.ember),
          home: RepaintBoundary(
            key: key,
            child: HubScreen(onWorldSelected: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outDir.path}/hub_light_master.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Capture Transition Frames', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getDarkTheme(EtoleColors.ember),
        home: RepaintBoundary(
          key: key,
          child: WorldTransitionOverlay(
            world: EtoleWorld.network,
            reduceMotion: false,
            onCompleted: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 30));

    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 65));

      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${framesDir.path}/trans_frame_${i.toString().padLeft(2, '0')}.png');
        await file.writeAsBytes(byteData!.buffer.asUint8List());
      });
    }

    final midTrans = File('${framesDir.path}/trans_frame_04.png');
    if (midTrans.existsSync()) {
      midTrans.copySync('${outDir.path}/hub_transition_letters.png');
    }

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Capture World Entry Screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeMode.dark),
          reduceMotionProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getDarkTheme(EtoleColors.ember),
          home: RepaintBoundary(
            key: key,
            child: const WorldContainer(
              world: EtoleWorld.network,
              child: NetworkHubScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outDir.path}/hub_world_entry.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
