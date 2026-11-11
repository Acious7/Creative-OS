import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:creative_os/core/database/app_database.dart';
import 'package:creative_os/core/database/database_provider.dart';
import 'package:creative_os/core/theme/app_theme.dart';
import 'package:creative_os/core/design_system/etole_colors.dart';
import 'package:creative_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:creative_os/features/documents/presentation/screens/docs_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 8 Delivery Verification Tests', () {
    testWidgets('World 4 — Settings: The Workshop renders 01-11 numbered notebook list and BE header', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getDarkTheme(EtoleColors.ember),
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify Workshop header & clear spacer
      expect(find.text('04 · THE WORKSHOP'), findsOneWidget);
      expect(find.text('SETTINGS & PREFERENCES'), findsOneWidget);

      // Verify Numbered list entries
      expect(find.text('01'), findsOneWidget);
      expect(find.text('MY DETAILS'), findsOneWidget);

      expect(find.text('02'), findsOneWidget);
      expect(find.text('PAYMENT'), findsOneWidget);

      expect(find.text('03'), findsOneWidget);
      expect(find.text('CLAUSES & TERMS'), findsOneWidget);

      expect(find.text('04'), findsOneWidget);
      expect(find.text('NUMBERING'), findsOneWidget);

      expect(find.text('05'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);

      expect(find.text('06'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);

      expect(find.text('07'), findsOneWidget);
      expect(find.text('REMINDERS'), findsOneWidget);

      expect(find.text('08'), findsOneWidget);
      expect(find.text('SECURITY'), findsOneWidget);

      expect(find.text('09'), findsOneWidget);
      expect(find.text('BACKUP'), findsOneWidget);

      expect(find.text('10'), findsOneWidget);
      expect(find.text('TRASH'), findsOneWidget);

      expect(find.text('11'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('World 3 — Docs Home renders 3 glass cards and search bar without bottom nav', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getDarkTheme(EtoleColors.ember),
            home: DocsHomeScreen(
              onOpenDocument: (_) {},
              onNewDocument: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify 3 glass window cards
      expect(find.text('CONTACTS'), findsOneWidget);
      expect(find.text('RECENT DOCS'), findsOneWidget);
      expect(find.text('CREATE NEW'), findsOneWidget);

      // Verify search hint
      expect(find.text('Search number, client, item or amount...'), findsOneWidget);

      // Verify ZERO bottom navigation bar
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
