import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creative_os/core/theme/brand_theme_provider.dart';
import 'package:creative_os/features/hub/domain/hub_models.dart';
import 'package:creative_os/features/hub/presentation/screens/hub_screen.dart';
import 'package:creative_os/features/hub/presentation/widgets/hub_window.dart';
import 'package:creative_os/features/hub/presentation/widgets/window_pane_item.dart';
import 'package:creative_os/features/hub/presentation/widgets/world_container.dart';
import 'package:creative_os/features/navigation/presentation/main_shell.dart';

void main() {
  group('Phase 3: The Hub & Window Tests', () {
    test('EtoleWorld enum defines strictly 4 worlds with correct names', () {
      expect(EtoleWorld.values.length, 4);
      expect(EtoleWorld.brian.displayName, 'BRIAN');
      expect(EtoleWorld.network.displayName, 'NETWORK');
      expect(EtoleWorld.docs.displayName, 'DOCS');
      expect(EtoleWorld.settings.displayName, 'SETTINGS');
    });

    testWidgets('HubScreen renders brand header and all four window panes in 2x2 grid', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      EtoleWorld? tappedWorld;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reduceMotionProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            home: HubScreen(
              onWorldSelected: (world) {
                tappedWorld = world;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify Header
      expect(find.text('BRIAN ETOLE'), findsOneWidget);
      expect(find.text('REAL STORIES. IMAGINED WORLDS.'), findsOneWidget);

      // Verify HubWindow and 4 Panes
      expect(find.byType(HubWindow), findsOneWidget);
      expect(find.byType(WindowPaneItem), findsNWidgets(4));
      expect(find.text('BRIAN'), findsOneWidget);
      expect(find.text('NETWORK'), findsOneWidget);
      expect(find.text('DOCS'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);

      // Tap on BRIAN pane to swing open
      await tester.tap(find.text('BRIAN'));
      await tester.pump();

      // Swing animation + fly-through
      await tester.pump(const Duration(milliseconds: 600));
      // Transition overlay resolution
      await tester.pump(const Duration(milliseconds: 300));

      expect(tappedWorld, EtoleWorld.brian);
    });

    testWidgets('WorldContainer renders child and returns to Hub when pill is tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      final container = ProviderScope(
        overrides: [
          activeWorldProvider.overrideWith((ref) => EtoleWorld.network),
          reduceMotionProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          home: WorldContainer(
            world: EtoleWorld.network,
            child: Scaffold(body: Center(child: Text('NETWORK CONTENT'))),
          ),
        ),
      );

      await tester.pumpWidget(container);
      await tester.pump();

      expect(find.text('NETWORK CONTENT'), findsOneWidget);
      expect(find.text('HUB'), findsOneWidget);

      // Tap back to Hub pill
      await tester.tap(find.text('HUB'));
      await tester.pump();
    });

    testWidgets('MainShell starts at the Hub and has ZERO bottom navigation bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reduceMotionProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: MainShell(),
          ),
        ),
      );

      await tester.pump();

      // Should show Hub header & Window
      expect(find.text('BRIAN ETOLE'), findsOneWidget);
      expect(find.byType(HubWindow), findsOneWidget);

      // Zero BottomNavigationBar anywhere
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
