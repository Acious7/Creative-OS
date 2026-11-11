import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:creative_os/core/theme/brand_theme_provider.dart';
import 'package:creative_os/core/theme/app_theme.dart';
import 'package:creative_os/core/design_system/etole_colors.dart';
import 'package:creative_os/features/settings/presentation/screens/design_system_gallery_screen.dart';

Future<void> _loadFonts() async {
  // Load Bebas Neue
  final bebasData = File('assets/fonts/BebasNeue-Regular.ttf').readAsBytesSync();
  final bebasLoader = FontLoader('BebasNeue')..addFont(Future.value(ByteData.view(bebasData.buffer)));
  await bebasLoader.load();

  // Load Inter
  final interData = File('assets/fonts/Inter-Variable.ttf').readAsBytesSync();
  final interLoader = FontLoader('Inter')..addFont(Future.value(ByteData.view(interData.buffer)));
  await interLoader.load();

  // Load Material Icons
  final iconFile = File('C:/tools/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
  if (iconFile.existsSync()) {
    final iconData = iconFile.readAsBytesSync();
    final iconLoader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(iconData.buffer)));
    await iconLoader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture Design System Gallery Screenshots', (tester) async {
    await _loadFonts();

    // Set modern tall phone screen dimensions (412 x 915)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    final artifactDir = Directory('C:/Users/Etole/.gemini/antigravity-ide/brain/f2c59368-bb1a-4073-8d0f-80052a2985ca');
    if (!artifactDir.existsSync()) {
      artifactDir.createSync(recursive: true);
    }

    // 1. Capture Dark Mode — Top Section
    final darkKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeMode.dark),
          isOledModeProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp(
          theme: AppTheme.getDarkTheme(EtoleColors.ember),
          home: RepaintBoundary(
            key: darkKey,
            child: const DesignSystemGalleryScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = darkKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${artifactDir.path}/design_gallery_dark.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // Scroll down to capture Components & Inputs
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = darkKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${artifactDir.path}/design_gallery_dark_components.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // Scroll further down to capture List Rows, Glass, and Motion
    await tester.drag(find.byType(ListView), const Offset(0, -750));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = darkKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${artifactDir.path}/design_gallery_dark_lists_glass.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // 2. Capture Light Mode — Top Section
    final lightKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeMode.light),
          isOledModeProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp(
          theme: AppTheme.getLightTheme(EtoleColors.ember),
          home: RepaintBoundary(
            key: lightKey,
            child: const DesignSystemGalleryScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = lightKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${artifactDir.path}/design_gallery_light.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // Scroll down in Light Mode to capture Components & Inputs
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = lightKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${artifactDir.path}/design_gallery_light_components.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // Scroll further down in Light Mode to capture List Rows, Glass, and Motion
    await tester.drag(find.byType(ListView), const Offset(0, -750));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = lightKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${artifactDir.path}/design_gallery_light_lists_glass.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });
  });
}
