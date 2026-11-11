import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:creative_os/core/database/app_database.dart';
import 'package:creative_os/core/theme/brand_theme_provider.dart';
import 'package:creative_os/core/theme/app_theme.dart';
import 'package:creative_os/core/design_system/etole_colors.dart';
import 'package:creative_os/features/digital_cards/presentation/providers/cards_providers.dart';
import 'package:creative_os/features/digital_cards/presentation/widgets/card_designs.dart';
import 'package:creative_os/features/digital_cards/presentation/widgets/business_card_3d_flipper.dart';
import 'package:creative_os/features/digital_cards/presentation/screens/card_presentation_screen.dart';
import 'package:creative_os/features/digital_cards/presentation/screens/email_signature_screen.dart';

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

  final outDir = Directory('C:/Users/Etole/.gemini/antigravity-ide/brain/41d9e517-5821-419a-82c2-9746e5c15fde/stage_cards');
  final framesDir = Directory('C:/Users/Etole/.gemini/antigravity-ide/brain/41d9e517-5821-419a-82c2-9746e5c15fde/stage_frames');

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('github.com/clertonleal/screen_brightness'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('github.com/aaassseee/screen_brightness'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('wakelock_plus'),
      (call) async => null,
    );
  });

  final sampleBrand = Brand(
    id: 1,
    name: 'Etole Studio',
    accentColorHex: '#FF5722',
    website: 'https://brianetole.com',
    email: 'brian@etole.com',
    phone: '+254 718 013 579',
    defaultPdfTemplate: 'classic',
    isActive: true,
    defaultPageSize: 'A4',
    defaultRoundingRule: 'none',
    createdAt: DateTime.now(),
  );

  BusinessCard createCard(int id, String style) {
    return BusinessCard(
      id: id,
      brandId: 1,
      cardTitle: style.toUpperCase(),
      personName: 'Brian Etole',
      personRole: 'Creative Director / Cinematographer',
      companyName: 'Etole Studio',
      tagline: 'Hybrid Filmmaker & Photographer',
      email: 'brian@etole.com',
      primaryPhone: '+254 718 013 579',
      website: 'https://brianetole.com',
      address: 'Nairobi, Kenya',
      designStyle: style,
      defaultQrMode: 'vcard',
      isDefault: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDeleted: false,
    );
  }

  final styles = ['ember', 'savannah', 'ochre_line', 'night_market', 'clay'];

  testWidgets('Capture All 5 Tribal Card Designs Front and Back', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    int cardId = 1;
    for (final style in styles) {
      final card = createCard(cardId++, style);

      // 1. Capture Front
      final frontKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getDarkTheme(EtoleColors.ember),
          home: Scaffold(
            backgroundColor: const Color(0xFF0A0C0D),
            body: Center(
              child: RepaintBoundary(
                key: frontKey,
                child: SizedBox(
                  width: 380,
                  child: BusinessCardFrontView(card: card, brand: sampleBrand),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.runAsync(() async {
        final boundary = frontKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${outDir.path}/card_${style}_front.png');
        await file.writeAsBytes(byteData!.buffer.asUint8List());
      });

      // 2. Capture Back
      final backKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getDarkTheme(EtoleColors.ember),
          home: Scaffold(
            backgroundColor: const Color(0xFF0A0C0D),
            body: Center(
              child: RepaintBoundary(
                key: backKey,
                child: SizedBox(
                  width: 380,
                  child: BusinessCardBackView(
                    card: card,
                    brand: sampleBrand,
                    mode: QrDisplayMode.vCard,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.runAsync(() async {
        final boundary = backKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${outDir.path}/card_${style}_back.png');
        await file.writeAsBytes(byteData!.buffer.asUint8List());
      });
    }
  });

  testWidgets('Capture Full Stage Screen and Flip in Dark Mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    final card = createCard(99, 'ember');
    final screenKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBrandProvider.overrideWith((ref) => sampleBrand),
          defaultBrandCardProvider.overrideWith((ref) => Stream.value(card)),
          reduceMotionProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getDarkTheme(EtoleColors.ember),
          home: RepaintBoundary(
            key: screenKey,
            child: CardPresentationScreen(card: card),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    // Capture Stage Front
    await tester.runAsync(() async {
      final boundary = screenKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outDir.path}/stage_master_dark.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    int frameIndex = 0;
    Future<void> saveFrame() async {
      await tester.runAsync(() async {
        final boundary = screenKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${framesDir.path}/stage_frame_${frameIndex.toString().padLeft(2, '0')}.png');
        await file.writeAsBytes(byteData!.buffer.asUint8List());
        frameIndex++;
      });
    }

    // Save initial frame
    await saveFrame();

    // Tap card to start flip
    await tester.tap(find.byType(BusinessCard3DFlipper));
    for (int i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 80));
      await saveFrame();
    }
    await tester.pump(const Duration(milliseconds: 100));
    await saveFrame();

    // Capture Stage Back (Flipped - default Save contact / vCard)
    await tester.runAsync(() async {
      final boundary = screenKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outDir.path}/stage_flipped_back.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // Tap "WhatsApp me" on the QR Modes Ring
    await tester.tap(find.text('WhatsApp me'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      final boundary = screenKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outDir.path}/stage_flipped_whatsapp.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // Tap "Watch reel" on the QR Modes Ring
    await tester.tap(find.text('Watch reel'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      final boundary = screenKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outDir.path}/stage_flipped_reel.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // Tap "Show QR" button to open Hold-for-QR full screen overlay
    await tester.tap(find.text('Show QR'));
    await tester.pump(const Duration(milliseconds: 100));
    await saveFrame();
    await tester.pump(const Duration(milliseconds: 200));
    await saveFrame();

    // Capture Hold-for-QR Presentation Overlay
    await tester.runAsync(() async {
      final boundary = screenKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outDir.path}/stage_qr_overlay.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });
  });

  testWidgets('Capture Email Signature Screen from Drawer', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    final card = createCard(99, 'ember');
    final sigKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBrandProvider.overrideWith((ref) => sampleBrand),
          reduceMotionProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getDarkTheme(EtoleColors.ember),
          home: RepaintBoundary(
            key: sigKey,
            child: EmailSignatureScreen(card: card),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.runAsync(() async {
      final boundary = sigKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outDir.path}/stage_email_signature.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });
  });
}
